#!/usr/bin/env python3
"""
Hikvision indoor-extension SIP UA (proof-of-concept) for the Pi.
Implements the flow reverse-engineered from the live KH8350:
  REGISTER(+<regXML>) -> 401 digest -> REGISTER(+digest, admin pw) -> 200
  keep-alive re-REGISTER; answer incoming INVITE (100/180/200+SDP, ACK);
  unlock via in-dialog INFO (application/dtmf-relay, Signal=#); BYE teardown.

Media: binds our RTP ports and COUNTS incoming packets (proves media reaches
us). Pass --media gst to also launch GStreamer (video window + audio + mic).

Usage:
  python3 -I hik_extension.py --server <indoor station IP> --number <extension number> \
      --password 'ADMIN_PW' [--local-ip 192.168.100.x] [--media none|gst] [--auto-answer]

Interactive keys while running:  a=answer  u=unlock  h=hangup  q=quit
"""
import argparse, hashlib, os, re, select, socket, subprocess, sys, threading, time, random

def md5(s): return hashlib.md5(s.encode()).hexdigest()

class UA:
    def __init__(s, a):
        s.a=a
        s.server=(a.server, a.server_port)
        # discover our source IP toward the server if not given
        if a.local_ip: s.ip=a.local_ip
        else:
            t=socket.socket(socket.AF_INET,socket.SOCK_DGRAM); t.connect(s.server); s.ip=t.getsockname()[0]; t.close()
        s.num=a.number; s.pw=a.password
        s.sip=socket.socket(socket.AF_INET,socket.SOCK_DGRAM)
        s.sip.setsockopt(socket.SOL_SOCKET,socket.SO_REUSEADDR,1)
        s.sip.bind((s.ip, a.sip_port)); s.sport=s.sip.getsockname()[1]
        s.aport=a.audio_port; s.vport=a.video_port
        s.call=None           # active dialog dict
        s.reg_cseq=0; s.running=True
        s.media_procs=[]
        s.rtp_counts={'audio':0,'video':0}

    # ---------- low level ----------
    def send(s, msg, to=None):
        s.sip.sendto(msg.encode(), to or s.server)

    def _req_line_hdrs(s, method, ruri, cseq, call_id, from_tag, to_hdr, extra=""):
        return (f"{method} {ruri} SIP/2.0\r\n"
                f"Via: SIP/2.0/UDP {s.ip}:{s.sport};rport;branch=z9hG4bK{random.randint(1,2**31)}\r\n"
                f"From: Indoor Extension 1 <sip:{s.num}@{s.ip}>;tag={from_tag}\r\n"
                f"To: {to_hdr}\r\n"
                f"Call-ID: {call_id}\r\n"
                f"CSeq: {cseq} {method}\r\n"
                f"Max-Forwards: 70\r\nUser-Agent: HKVS/2.0.0\r\n"+extra)

    # ---------- REGISTER ----------
    REG_BODY=("<regXML>\n<version>V2.0.0</version>\n"
              "<regDevName>Indoor Extension 1</regDevName>\n"
              "<regDevSerial>PI000000001</regDevSerial>\n"
              "<regDevMacAddr>{mac}</regDevMacAddr>\n</regXML>\n")
    def register(s):
        s.reg_cseq+=1
        call_id=f"reg-{s.num}-{int(time.time())}"
        tag=str(random.randint(1,2**31))
        ruri=f"sip:{s.num}@{s.a.server}:{s.a.server_port}"
        to=f"Indoor Extension 1 <sip:{s.num}@{s.ip}>"
        body=s.REG_BODY.format(mac=s.a.mac)
        contact=f"Contact: <sip:{s.num}@{s.ip}:{s.sport};line={random.getrandbits(56):014x}>\r\n"
        extra=contact+f"Expires: 900\r\nContent-Type: text/xml\r\nContent-Length:   {len(body)}\r\n\r\n"+body
        s.send(s._req_line_hdrs("REGISTER",ruri,s.reg_cseq,call_id,tag,to,extra))
        data=s._recv(3)
        if not data: print("[reg] no 401"); return False
        m=re.search(r'nonce="([^"]+)"',data)
        if not m: print("[reg] unexpected:",data.split('\r\n')[0]); return False
        nonce=m.group(1); realm=(re.search(r'realm="([^"]+)"',data) or [0,"Hikvision"])[1]
        op=re.search(r'opaque="([^"]+)"',data)
        ha1=md5(f"{s.num}:{realm}:{s.pw}"); ha2=md5(f"REGISTER:{ruri}")
        resp=md5(f"{ha1}:{nonce}:{ha2}")
        auth=f'Authorization: Digest username="{s.num}", realm="{realm}", nonce="{nonce}", uri="{ruri}", response="{resp}", algorithm=MD5'
        if op: auth+=f', opaque="{op.group(1)}"'
        auth+="\r\n"
        s.reg_cseq+=1
        extra2=contact+auth+f"Expires: 900\r\nContent-Type: text/xml\r\nContent-Length:   {len(body)}\r\n\r\n"+body
        s.send(s._req_line_hdrs("REGISTER",ruri,s.reg_cseq,call_id,tag,to,extra2))
        data=s._recv(3)
        ok=data and data.split('\r\n')[0].endswith("200 OK")
        print(f"[reg] {'REGISTERED 200 OK' if ok else data.split(chr(10))[0] if data else 'no reply'}")
        return ok

    def _recv(s, timeout):
        s.sip.settimeout(timeout)
        try:
            while True:
                d,_=s.sip.recvfrom(65535); return d.decode('latin1')
        except socket.timeout: return None

    def reg_loop(s):
        while s.running:
            try: s.register()
            except Exception as e: print("[reg] error",e)
            for _ in range(600):   # re-register ~every 600s (<900 Expires)
                if not s.running: return
                time.sleep(1)

    # ---------- incoming handling ----------
    def listen(s):
        s.sip.settimeout(0.5)
        while s.running:
            try: data,addr=s.sip.recvfrom(65535)
            except socket.timeout: continue
            except OSError: break
            try: s.handle(data.decode('latin1'), addr)
            except Exception as e: print("[rx] err",e)

    def _hdr(s, msg, name):
        m=re.search(rf'^{name}:\s*(.+)$', msg, re.I|re.M); return m.group(1).strip() if m else None

    def handle(s, msg, addr):
        line=msg.split('\r\n',1)[0]
        if line.startswith("OPTIONS"):
            s._reply(msg, addr, "200 OK"); return
        if line.startswith("INVITE"):
            s.on_invite(msg, addr); return
        if line.startswith("BYE"):
            print("[call] remote hung up (BYE)"); s._reply(msg, addr, "200 OK"); s.stop_media(); s.call=None; return
        if line.startswith("CANCEL"):
            # The station cancels our branch when the call is answered
            # elsewhere (e.g. on the main station) or the caller gives up.
            print("[call] CANCEL received -> answered elsewhere / caller gave up"); s._reply(msg, addr, "200 OK"); s.stop_media(); s.call=None; return
        if line.startswith("ACK"):
            return
        if line.startswith("MESSAGE"):
            s._reply(msg, addr, "200 OK"); return
        # responses to our requests (INFO/BYE) -> ignore

    def _reply(s, req, addr, status, extra=""):
        # echo Via/From/To/Call-ID/CSeq, add To-tag
        def g(n):
            m=re.search(rf'^{n}:\s*(.+)$',req,re.I|re.M); return m.group(1).strip() if m else ""
        via=g("Via"); frm=g("From"); to=g("To"); cid=g("Call-ID"); cseq=g("CSeq")
        if ";tag=" not in to: to=to+f";tag={random.randint(1,2**31)}"
        s.send(f"SIP/2.0 {status}\r\nVia: {via}\r\nFrom: {frm}\r\nTo: {to}\r\nCall-ID: {cid}\r\nCSeq: {cseq}\r\nUser-Agent: HKVS/2.0.0\r\n"+extra+"\r\n", addr)
        return to

    def on_invite(s, msg, addr):
        # parse door SDP
        body=msg.split('\r\n\r\n',1)[1] if '\r\n\r\n' in msg else ""
        cip=(re.search(r'c=IN IP4 ([\d.]+)',body) or [0,addr[0]])[1]
        ma=re.search(r'm=audio (\d+)',body); mv=re.search(r'm=video (\d+)',body)
        s.call=dict(addr=addr, msg=msg,
                    via=s._hdr(msg,"Via"), frm=s._hdr(msg,"From"), to=s._hdr(msg,"To"),
                    cid=s._hdr(msg,"Call-ID"), cseq=s._hdr(msg,"CSeq"),
                    contact=s._hdr(msg,"Contact"),
                    media_ip=cip, aport=int(ma.group(1)) if ma else 0, vport=int(mv.group(1)) if mv else 0)
        print(f"\n[CALL] incoming from {s.call['frm']}  media {cip} audio:{s.call['aport']} video:{s.call['vport']}")
        s._reply(msg, addr, "100 Trying")
        s._reply(msg, addr, "180 Ringing")
        if s.a.auto_answer: s.answer()
        else: print("       press 'a' to answer, 'u' to unlock, 'h' to hang up")

    def answer(s):
        c=s.call
        if not c: print("no call"); return
        sdp=("v=0\r\n"
             f"o={s.num} 0 0 IN IP4 {s.ip}\r\ns=Talk session\r\nc=IN IP4 {s.ip}\r\nt=0 0\r\n"
             f"m=audio {s.aport} RTP/AVP 0 8 101\r\na=rtpmap:0 PCMU/8000\r\na=rtpmap:8 PCMA/8000\r\n"
             "a=rtpmap:101 telephone-event/8000\r\na=sendrecv\r\n"
             f"m=video {s.vport} RTP/AVP 96\r\na=rtpmap:96 H264/90000\r\na=recvonly\r\n")
        to=s._reply(c['msg'], c['addr'], "200 OK",
                    f"Contact: <sip:{s.num}@{s.ip}:{s.sport}>\r\nContent-Type: application/sdp\r\nContent-Length: {len(sdp)}\r\n"+sdp)
        c['local_to']=to
        print("[call] 200 OK sent — media starting")
        s.start_media(c)

    def unlock(s):
        c=s.call
        if not c: print("[unlock] no active call (unlock is in-dialog). Ring first."); return
        # INFO to the door's From-URI within the dialog
        frm_uri=re.search(r'<sip:([^>]+)>', c['frm']); target=frm_uri.group(1) if frm_uri else f"{s.num}@{s.a.server}"
        body="Signal=#\r\nDuration=160\r\n"
        ruri=f"sip:{target.split(';')[0]}"
        # swap From/To for in-dialog request from our side
        info=(f"INFO {ruri} SIP/2.0\r\n"
              f"Via: SIP/2.0/UDP {s.ip}:{s.sport};rport;branch=z9hG4bK{random.randint(1,2**31)}\r\n"
              f"From: <sip:{s.num}@{s.ip}:{s.sport}>;tag={c['local_to'].split('tag=')[-1] if c.get('local_to') else random.randint(1,2**31)}\r\n"
              f"To: {c['frm']}\r\nCall-ID: {c['cid']}\r\nCSeq: 2 INFO\r\n"
              f"Contact: <sip:{s.num}@{s.ip}:{s.sport}>\r\nMax-Forwards: 70\r\nUser-Agent: HKVS/2.0.0\r\n"
              f"Content-Type: application/dtmf-relay\r\nContent-Length: {len(body)}\r\n\r\n"+body)
        s.send(info, c['addr'])
        print("[unlock] INFO Signal=# sent")

    def hangup(s):
        c=s.call
        if not c: return
        frm_uri=re.search(r'<sip:([^>]+)>', c['frm']); target=frm_uri.group(1) if frm_uri else f"{s.num}@{s.a.server}"
        bye=(f"BYE sip:{target.split(';')[0]} SIP/2.0\r\n"
             f"Via: SIP/2.0/UDP {s.ip}:{s.sport};rport;branch=z9hG4bK{random.randint(1,2**31)}\r\n"
             f"From: <sip:{s.num}@{s.ip}:{s.sport}>;tag={c.get('local_to','tag=x').split('tag=')[-1]}\r\n"
             f"To: {c['frm']}\r\nCall-ID: {c['cid']}\r\nCSeq: 3 BYE\r\nMax-Forwards: 70\r\nContent-Length: 0\r\n\r\n")
        s.send(bye, c['addr']); print("[call] BYE sent"); s.stop_media(); s.call=None

    # ---------- media ----------
    def start_media(s, c):
        if s.a.media=='audio':
            # Two-way AUDIO only (video is handled via RTSP in the kiosk).
            # recv door PCMU -> HDMI speaker (PipeWire pulse, like DoorAudio);
            # mic (default source; appears when a USB mic is plugged) -> door.
            pulse='server=unix:/run/user/1000/pulse/native'
            ar=(f"gst-launch-1.0 -q udpsrc port={s.aport} caps=\"application/x-rtp,media=audio,encoding-name=PCMU,payload=0,clock-rate=8000\" "
                f"! rtpjitterbuffer latency=120 ! rtppcmudepay ! mulawdec ! audioconvert ! audioresample ! pulsesink {pulse} sync=false")
            at=(f"gst-launch-1.0 -q pulsesrc {pulse} ! audioconvert ! audioresample ! audio/x-raw,rate=8000,channels=1 "
                f"! mulawenc ! rtppcmupay pt=0 ! udpsink host={c['media_ip']} port={c['aport']}")
            for cmd in (ar,at):
                try: s.media_procs.append(subprocess.Popen(cmd, shell=True))
                except Exception as e: print("[media] gst audio launch failed:",e)
            print(f"[media] 2-way audio up: door<->{s.ip}:{s.aport} (talk-back needs a mic; listen works now)")
            return
        if s.a.media=='gst':
            # video: recv H264 -> display ; audio recv PCMU -> speaker ; mic -> PCMU -> door
            v=(f"gst-launch-1.0 -q udpsrc port={s.vport} caps=\"application/x-rtp,media=video,encoding-name=H264,payload=96,clock-rate=90000\" "
               "! rtpjitterbuffer latency=120 ! rtph264depay ! h264parse ! avdec_h264 ! videoconvert ! autovideosink sync=false")
            ar=(f"gst-launch-1.0 -q udpsrc port={s.aport} caps=\"application/x-rtp,media=audio,encoding-name=PCMU,payload=0,clock-rate=8000\" "
                "! rtppcmudepay ! mulawdec ! audioconvert ! audioresample ! autoaudiosink sync=false")
            at=(f"gst-launch-1.0 -q autoaudiosrc ! audioconvert ! audioresample ! mulawenc ! rtppcmupay pt=0 "
                f"! udpsink host={c['media_ip']} port={c['aport']}")
            for cmd in (v,ar,at):
                try: s.media_procs.append(subprocess.Popen(cmd, shell=True))
                except Exception as e: print("[media] gst launch failed:",e)
            print("[media] gstreamer pipelines up (video window + 2-way audio)")
        else:
            # just bind and count RTP to prove media reaches us
            s._count_rtp()

    def _count_rtp(s):
        def counter(port, kind):
            r=socket.socket(socket.AF_INET,socket.SOCK_DGRAM); r.setsockopt(socket.SOL_SOCKET,socket.SO_REUSEADDR,1)
            try: r.bind((s.ip,port))
            except OSError as e: print(f"[media] bind {port} failed {e}"); return
            r.settimeout(0.5); t0=time.time()
            while s.call and time.time()-t0<30:
                try:
                    d,_=r.recvfrom(4096); s.rtp_counts[kind]+=1
                    if s.rtp_counts[kind] in (1,50): print(f"[media] {kind} RTP flowing: {s.rtp_counts[kind]} pkts ({len(d)}B)")
                except socket.timeout: pass
            r.close()
        for port,kind in ((s.aport,'audio'),(s.vport,'video')):
            threading.Thread(target=counter,args=(port,kind),daemon=True).start()
        print(f"[media] counting RTP on audio:{s.aport} video:{s.vport} (prove flow; use --media gst to see/hear)")

    def stop_media(s):
        for p in s.media_procs:
            try: p.terminate()
            except Exception: pass
        s.media_procs=[]
        if any(s.rtp_counts.values()): print(f"[media] totals {s.rtp_counts}")

    # ---------- run ----------
    def run(s):
        print(f"[ua] {s.num} @ {s.ip}:{s.sport} -> server {s.server}  media={s.a.media}")
        threading.Thread(target=s.reg_loop,daemon=True).start()
        threading.Thread(target=s.listen,daemon=True).start()
        time.sleep(1)
        # Background/unattended (no TTY): don't read stdin — just run, log
        # events, and auto-answer if asked. Used when launched over ssh/nohup.
        if not sys.stdin.isatty():
            print(f"[ua] unattended mode (auto_answer={s.a.auto_answer}); logging events, Ctrl-C/kill to stop")
            try:
                while s.running:
                    time.sleep(0.5)
            except KeyboardInterrupt:
                pass
            s.stop_media(); return
        print("keys: a=answer u=unlock h=hangup q=quit")
        while s.running:
            r,_,_=select.select([sys.stdin],[],[],0.5)
            if r:
                k=sys.stdin.readline().strip().lower()
                if k=='a': s.answer()
                elif k=='u': s.unlock()
                elif k=='h': s.hangup()
                elif k=='q': s.running=False
        s.stop_media()

def main():
    p=argparse.ArgumentParser()
    p.add_argument('--server',required=True); p.add_argument('--server-port',type=int,default=5065)
    p.add_argument('--number',required=True)
    # Password from --password, else the SIP_PASSWORD env var (keeps it off
    # the command line when launched via systemd EnvironmentFile).
    p.add_argument('--password',default=os.environ.get('SIP_PASSWORD'))
    p.add_argument('--local-ip',default=None); p.add_argument('--sip-port',type=int,default=5060)
    p.add_argument('--audio-port',type=int,default=20000); p.add_argument('--video-port',type=int,default=20002)
    p.add_argument('--mac',default='02:11:22:33:44:55')
    p.add_argument('--media',choices=['none','gst','audio'],default='none')
    p.add_argument('--auto-answer',action='store_true')
    a=p.parse_args()
    if not a.password:
        sys.exit('no password: pass --password or set SIP_PASSWORD in the environment')
    UA(a).run()

if __name__=='__main__': main()
