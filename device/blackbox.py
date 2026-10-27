#!/usr/bin/env python3
"""Flight recorder for unexplained reboots.

Once a second, appends the input voltage, temperatures, CPU/GPU clocks,
load, free memory and whether audio is playing to a file on the root disk
(not Armbian's zram /var/log, which an unclean reset loses), fsync'd, plus
every kernel warning or error as it arrives. After a reset, the tail of
/var/lib/blackbox/previous-boot.log shows what the board was doing.
Rotates at 20 MB. Installed by setup.sh as blackbox.service.
"""
import glob
import os
import subprocess
import threading
import time

DIR = "/var/lib/blackbox"
os.makedirs(DIR, exist_ok=True)
cur = os.path.join(DIR, "current.log")
if os.path.exists(cur):
    os.replace(cur, os.path.join(DIR, "previous-boot.log"))
out = open(cur, "a", buffering=1)
lock = threading.Lock()


def write(line):
    with lock:
        out.write(time.strftime("%H:%M:%S ") + line + "\n")
        out.flush()
        os.fsync(out.fileno())
        if out.tell() > 20_000_000:
            out.seek(0)
            out.truncate()


def read(path, default="?"):
    try:
        with open(path) as f:
            return f.read().strip()
    except OSError:
        return default


def kernel():
    p = subprocess.Popen(["dmesg", "-w", "-T", "--level=emerg,alert,crit,err,warn"], stdout=subprocess.PIPE, text=True)
    for line in p.stdout:
        write("KERN " + line.rstrip())


def input_volts():
    # Rock 5B: SARADC channel 6 senses the USB-C input through 100k/8.2k.
    raw = read("/sys/bus/iio/devices/iio:device0/in_voltage6_raw", "")
    return int(raw) / 4095 * 1.8 * (100 + 8.2) / 8.2 if raw.isdigit() else 0.0


def audio_state():
    try:
        sinks = subprocess.run(
            ["pactl", "list", "short", "sinks"],
            capture_output=True, text=True, timeout=2, env={"XDG_RUNTIME_DIR": "/run/user/1000"},
        ).stdout
        return "playing" if "RUNNING" in sinks else "idle"
    except Exception:
        return "?"


threading.Thread(target=kernel, daemon=True).start()
zones = sorted(glob.glob("/sys/class/thermal/thermal_zone*"))
names = [read(z + "/type").split("-")[0] for z in zones]
write("BOOT")
while True:
    temps = " ".join(f"{n}={int(read(z + '/temp', '0')) // 1000}" for n, z in zip(names, zones))
    mhz = " ".join(read(p, "0")[:-3] for p in sorted(glob.glob("/sys/devices/system/cpu/cpufreq/policy*/scaling_cur_freq")))
    gpu = read("/sys/class/devfreq/fb000000.gpu/cur_freq", "0")[:-6]
    load = read("/proc/loadavg").split()[0]
    avail = next((int(l.split()[1]) // 1024 for l in open("/proc/meminfo") if l.startswith("MemAvailable")), 0)
    write(f"Vin {input_volts():.2f} | {temps} | MHz {mhz} gpu {gpu} | load {load} | freeMB {avail} | audio {audio_state()}")
    time.sleep(1)
