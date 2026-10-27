// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Portuguese (`pt`).
class AppLocalizationsPt extends AppLocalizations {
  AppLocalizationsPt([String locale = 'pt']) : super(locale);

  @override
  String get datesWeekdaysTitle => 'Segunda,Terça,Quarta,Quinta,Sexta,Sábado,Domingo';

  @override
  String get datesWeekdaysAbbr => 'SEG,TER,QUA,QUI,SEX,SÁB,DOM';

  @override
  String get datesWeekdayLetters => 'S,T,Q,Q,S,S,D';

  @override
  String get commonSave => 'Guardar';

  @override
  String get commonCancel => 'Cancelar';

  @override
  String get commonClose => 'Fechar';

  @override
  String get commonDelete => 'Apagar';

  @override
  String get commonRemove => 'Remover';

  @override
  String get commonEdit => 'Editar';

  @override
  String get commonAdd => 'Adicionar';

  @override
  String get commonDone => 'Concluído';

  @override
  String get commonOpen => 'Abrir';

  @override
  String get commonBack => 'Voltar';

  @override
  String get commonYes => 'Sim';

  @override
  String get commonNo => 'Não';

  @override
  String get commonOk => 'OK';

  @override
  String get commonToday => 'Hoje';

  @override
  String get commonTomorrow => 'Amanhã';

  @override
  String get commonYesterday => 'Ontem';

  @override
  String get commonOn => 'Ligado';

  @override
  String get commonOff => 'Desligado';

  @override
  String get commonLoading => 'A carregar…';

  @override
  String get commonRetry => 'Tentar de novo';

  @override
  String get commonNext => 'Seguinte';

  @override
  String get commonPrevious => 'Anterior';

  @override
  String get commonSeeAll => 'Ver tudo';

  @override
  String get commonNone => 'Nenhum';

  @override
  String get commonAuto => 'Automático';

  @override
  String get commonUnavailable => 'Indisponível';

  @override
  String get settingsLanguage => 'Idioma';

  @override
  String get settingsLanguageSub => 'O idioma do ecrã. Automático segue o Home Assistant.';

  @override
  String get settingsLanguageAuto => 'Automático (Home Assistant)';

  @override
  String get languageName => 'Português';

  @override
  String assistantAgoDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: 'há $count dias', one: 'há 1 dia');
    return '$_temp0';
  }

  @override
  String assistantAgoHours(int count) {
    return 'há $count h';
  }

  @override
  String assistantAgoMinutes(int count) {
    return 'há $count min';
  }

  @override
  String get assistantChooserNoPhones => 'Ninguém tem a app do Home Assistant no telemóvel, ou falta escolher a pessoa no painel ByteHomeDash, em Pessoas.';

  @override
  String get assistantChooserNotRecognised => 'Não reconheci a voz. Escolha quem recebe no telemóvel.';

  @override
  String get assistantChooserSendTo => 'Enviar para…';

  @override
  String get assistantChooserWho => 'Para quem envio?';

  @override
  String assistantClimateOn(String current, String target) {
    return 'Ligado · $current → $target';
  }

  @override
  String get assistantCoverClosed => 'Fechado';

  @override
  String get assistantCoverOpen => 'Aberto';

  @override
  String get assistantDefaultList => 'lista';

  @override
  String get assistantDidntUnderstand => 'Não percebi bem. Pode dizer de outra maneira?';

  @override
  String get assistantDone => 'Feito.';

  @override
  String get assistantExamplesHeading => 'PODE PERGUNTAR, POR EXEMPLO';

  @override
  String get assistantGotIt => 'Percebido';

  @override
  String assistantItemsAdded(int count, String list) {
    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: '$count artigos em $list', one: '1 artigo em $list');
    return '$_temp0';
  }

  @override
  String assistantItemsPending(String list, int count) {
    return '$list · agora $count por comprar';
  }

  @override
  String get assistantKeyHowMuch => 'Quanto';

  @override
  String get assistantKeyPlay => 'Põe';

  @override
  String get assistantKeyTurnOff => 'Apaga';

  @override
  String get assistantKeyTurnOn => 'Liga';

  @override
  String get assistantKeyWhatIs => 'Qual é';

  @override
  String get assistantLightOff => 'Apagada';

  @override
  String get assistantLightOn => 'Acesa';

  @override
  String assistantLightOnBrightness(int percent) {
    return 'Acesa · $percent%';
  }

  @override
  String get assistantLocked => 'Trancada';

  @override
  String get assistantMealsKept => 'Mantive o que estava';

  @override
  String get assistantMealsReplaced => 'Substituído';

  @override
  String get assistantMealsVoiceHint => 'ou diga «sim» ou «não»';

  @override
  String get assistantMealsYesReplace => 'Sim, substituir';

  @override
  String get assistantMediaPaused => 'Em pausa';

  @override
  String get assistantMediaPlaying => 'A tocar';

  @override
  String get assistantNoConnection => 'Não consegui falar com o Home Assistant. Tente de novo.';

  @override
  String get assistantNotConfirmed => 'O Home Assistant não confirmou a alteração';

  @override
  String get assistantOtherPerson => 'Outra pessoa';

  @override
  String get assistantPhaseListening => 'A ouvir…';

  @override
  String get assistantPhaseReadyFresh => 'Em que posso ajudar?';

  @override
  String get assistantPhaseReadyMore => 'Mais alguma coisa?';

  @override
  String get assistantPhaseThinking => 'Deixe-me ver…';

  @override
  String assistantPrice(String amount, String currency) {
    return '$amount $currency';
  }

  @override
  String get assistantPromptSay => 'Diga o que precisa…';

  @override
  String get assistantPromptTapMic => 'Toque no microfone para falar';

  @override
  String get assistantPromptType => 'Escreva o que precisa…';

  @override
  String get assistantRecognisingVoice => 'A reconhecer a voz…';

  @override
  String assistantResultSeen(String title) {
    return '$title · visto';
  }

  @override
  String assistantResultUndone(String title) {
    return '$title · desfeito';
  }

  @override
  String get assistantResults => 'Resultados';

  @override
  String get assistantSearchingAndWriting => 'A pesquisar e a escrever… a resposta final aparece daqui a pouco';

  @override
  String get assistantSeeHistory => 'Ver histórico';

  @override
  String get assistantSend => 'Enviar';

  @override
  String get assistantSent => 'Enviado';

  @override
  String assistantSentToPhone(String name) {
    return 'Enviado para o telemóvel de $name';
  }

  @override
  String assistantServings(int count) {
    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: '$count pessoas', one: '1 pessoa');
    return '$_temp0';
  }

  @override
  String assistantSpeakerSemantics(String name) {
    return 'A falar com $name, reconhecido pela voz';
  }

  @override
  String get assistantSpeakingNow => 'A falar agora';

  @override
  String get assistantStatusListening => 'A ouvir';

  @override
  String get assistantStatusReady => 'Pronta';

  @override
  String get assistantStatusSpeaking => 'A responder';

  @override
  String get assistantStatusThinking => 'A pensar';

  @override
  String get assistantSubtitle => 'Assistente da casa · Home Assistant';

  @override
  String get assistantSuggestDinner => 'O que há para o jantar?';

  @override
  String get assistantSuggestDoorbell => 'Quem tocou à porta hoje?';

  @override
  String get assistantSuggestLightsOff => 'Apaga as luzes todas';

  @override
  String get assistantSuggestWeather => 'Que tempo vai fazer amanhã?';

  @override
  String get assistantTypeHint => 'Escreva uma pergunta…';

  @override
  String get assistantUndo => 'Desfazer';

  @override
  String get assistantUnlocked => 'Destrancada';

  @override
  String assistantViews(int count) {
    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: '$count visualizações');
    return '$_temp0';
  }

  @override
  String assistantViewsMillions(String value) {
    return '$value M visualizações';
  }

  @override
  String assistantViewsThousands(int count) {
    return '$count mil visualizações';
  }

  @override
  String get assistantWebLoading => 'A CARREGAR';

  @override
  String get assistantWebNews => 'NOTÍCIAS';

  @override
  String get assistantWebOther => 'NA WEB';

  @override
  String get assistantWebPlaces => 'LOCAIS PERTO DE CASA';

  @override
  String get assistantWebProducts => 'ONDE COMPRAR';

  @override
  String get assistantWebRecipes => 'RECEITAS NA WEB';

  @override
  String get assistantWebVideos => 'VÍDEOS';

  @override
  String get assistantWriting => 'A escrever…';

  @override
  String get narratorSearching1 => 'Vou procurar na internet.';

  @override
  String get narratorSearching2 => 'Deixa-me pesquisar isso.';

  @override
  String get narratorSearching3 => 'Vou ver o que encontro.';

  @override
  String get narratorSearching4 => 'Estou a pesquisar.';

  @override
  String get narratorStillWorking1 => 'Ainda estou a ver, só mais um pouco.';

  @override
  String get narratorStillWorking2 => 'Está quase.';

  @override
  String get narratorStillWorking3 => 'Continuo a procurar, um instante.';

  @override
  String get narratorStillWorking4 => 'Só mais um bocadinho.';

  @override
  String get narratorThinking1 => 'Deixa-me pensar.';

  @override
  String get narratorThinking2 => 'Hum, um momento.';

  @override
  String get narratorThinking3 => 'Estou a pensar nisso.';

  @override
  String get narratorThinking4 => 'Boa pergunta, deixa-me ver.';

  @override
  String recadoDayAt(String day, String time) {
    return '$day às $time';
  }

  @override
  String recadoFor(String name) {
    return 'Para $name';
  }

  @override
  String get recadoForEveryone => 'Para todos';

  @override
  String recadoFrom(String name) {
    return 'de $name';
  }

  @override
  String get recadoFromUnknown => 'de alguém · voz não reconhecida';

  @override
  String recadoGreeting(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Olá! Antes de mais: há $count recados por ver.',
      one: 'Olá! Antes de mais: há um recado por ver.',
    );
    return '$_temp0';
  }

  @override
  String get recadoLater => 'Mais tarde';

  @override
  String get recadoMarkAllSeen => 'Marcar todos como vistos';

  @override
  String get recadoNow => 'agora';

  @override
  String recadoQuoted(String text) {
    return '«$text»';
  }

  @override
  String get recadoRow => 'Recado';

  @override
  String recadoRowFrom(String name) {
    return 'Recado de $name';
  }

  @override
  String recadoRowTo(String name) {
    return 'para $name';
  }

  @override
  String get recadoRowToEveryone => 'para todos';

  @override
  String get recadoSeen => 'Visto';

  @override
  String recadoSeenBy(String name) {
    return 'Visto por $name';
  }

  @override
  String get recadoStayUntilSeen => 'Ficam aqui até alguém os marcar como vistos';

  @override
  String get recadoTitleEveryone => 'Recado para todos';

  @override
  String recadoTitleFor(String name) {
    return 'Recado para $name';
  }

  @override
  String recadoUnseenCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: '$count recados por ver', one: '1 recado por ver');
    return '$_temp0';
  }

  @override
  String get recadoVoiceHint => 'Diga «Ok Nabu, visto» ou «mais tarde». Ao marcar como visto, desaparece de todos os ecrãs.';

  @override
  String get voicesAlmostDone => 'Quase pronto';

  @override
  String get voicesDeleteBody =>
      'O assistente deixa de reconhecer esta voz e não usa mais o calendário nem a lista desta pessoa. Pode registar de novo quando quiser.';

  @override
  String voicesDeleteTitle(String name) {
    return 'Apagar a voz de $name?';
  }

  @override
  String voicesDeleted(String name) {
    return 'Voz de $name apagada';
  }

  @override
  String voicesDoneBetter(String name) {
    return 'Pronto! O assistente reconhece melhor a voz de $name.';
  }

  @override
  String voicesDoneNew(String name) {
    return 'Pronto! O assistente já reconhece a voz de $name.';
  }

  @override
  String voicesErrorIncompatible(String reason) {
    return 'As vozes registadas são de outro modelo ($reason); apague-as e registe de novo.';
  }

  @override
  String voicesErrorNoResponse(String details) {
    return 'A identificação de voz não respondeu ($details)';
  }

  @override
  String get voicesErrorUnknown => 'erro desconhecido';

  @override
  String voicesIntroBody(String name, int count) {
    return '$name vai ler $count frases em voz alta, uma de cada vez, de onde costuma falar com o ecrã e com a voz de todos os dias.';
  }

  @override
  String voicesIntroSummary(int count) {
    return '$count frases · cerca de 1 minuto';
  }

  @override
  String voicesIntroTakeLength(int seconds) {
    return 'Cada gravação dura $seconds segundos. O assistente fica em silêncio entretanto.';
  }

  @override
  String get voicesLoadError => 'Não foi possível ler as vozes registadas.';

  @override
  String get voicesLoading => 'A carregar as vozes…';

  @override
  String voicesMicError(String error) {
    return 'Não consegui usar o microfone ($error).';
  }

  @override
  String get voicesMoreSamples => 'Mais amostras';

  @override
  String voicesMoreSamplesOf(String name) {
    return 'Mais amostras de $name';
  }

  @override
  String get voicesNoPeopleBody => 'Adicione-as no painel ByteHomeDash do Home Assistant, em Pessoas. Depois, cada pessoa regista aqui a sua voz.';

  @override
  String get voicesNoPeopleTitle => 'Ainda não há pessoas';

  @override
  String get voicesNotInstalledBody => 'Sem ele não é possível registar vozes. Confirme a instalação no painel ByteHomeDash do Home Assistant.';

  @override
  String get voicesNotInstalledTitle => 'O assistente de voz não está instalado neste ecrã.';

  @override
  String get voicesNotRecognised => 'O assistente ainda não reconhece esta voz';

  @override
  String get voicesPhrase1 => 'Olá, sou eu. Liga as luzes da sala e diz-me como está o tempo hoje.';

  @override
  String get voicesPhrase2 => 'Quais são os eventos que tenho no calendário para amanhã de manhã?';

  @override
  String get voicesPhrase3 => 'Adiciona leite, ovos e pão à lista de compras, por favor.';

  @override
  String get voicesPhrase4 => 'Põe a tocar música calma na cozinha e baixa um pouco o volume.';

  @override
  String get voicesPhrase5 => 'Lembra-me de ligar à avó no sábado às dez da manhã.';

  @override
  String voicesPhraseOf(int index, int count) {
    return 'Frase $index de $count';
  }

  @override
  String voicesPhraseQuoted(String phrase) {
    return '«$phrase»';
  }

  @override
  String get voicesPrivacyNote =>
      'Fica tudo neste ecrã: guarda-se uma «impressão» da voz, nunca as gravações. O reconhecimento é uma comodidade, não uma senha: não abre portas nem desliga alarmes.';

  @override
  String get voicesReadyHint => 'Toque em Gravar e leia a frase em voz alta.';

  @override
  String get voicesRecord => 'Gravar';

  @override
  String get voicesRecordAgain => 'Gravar de novo';

  @override
  String voicesRecording(int seconds) {
    return 'A gravar · $seconds s';
  }

  @override
  String voicesRecordingEnds(int seconds) {
    return 'Termina sozinho ao fim de $seconds segundos.';
  }

  @override
  String get voicesRegister => 'Registar voz';

  @override
  String get voicesRegisterFailed => 'Não foi possível registar a voz.';

  @override
  String voicesRegisterOf(String name) {
    return 'Registar a voz de $name';
  }

  @override
  String voicesRegistered(int count) {
    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: 'Voz registada · $count amostras', one: 'Voz registada · 1 amostra');
    return '$_temp0';
  }

  @override
  String voicesRejectedTakes(int count, int samples) {
    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: '$count gravações não foram usadas', one: 'Uma gravação não foi usada');
    return '$_temp0 (pouca fala), mas ficaram $samples amostras.';
  }

  @override
  String get voicesRetry => 'Não ouvi bem. Leia outra vez, um pouco mais alto.';

  @override
  String voicesSamplesAdded(int count, String name) {
    return 'Ficaram mais $count amostras da voz de $name.';
  }

  @override
  String voicesSamplesKept(int count, String name) {
    return 'Ficaram $count amostras da voz de $name.';
  }

  @override
  String get voicesSaving => 'A guardar a voz…';

  @override
  String get voicesSomethingWrong => 'Algo correu mal';

  @override
  String get voicesStart => 'Começar';

  @override
  String get voicesSubtitle => 'O assistente reconhece quem fala e usa o calendário e os lembretes dessa pessoa.';

  @override
  String get voicesTitle => 'Vozes reconhecidas';

  @override
  String get acModeHeat => 'Aquecer';

  @override
  String get acModeCool => 'Arrefecer';

  @override
  String get acModeFan => 'Ventilar';

  @override
  String get acFanLow => 'Baixa';

  @override
  String get acFanQuiet => 'Silencioso';

  @override
  String get acFanMedium => 'Média';

  @override
  String get acFanHigh => 'Alta';

  @override
  String get houseLockLocked => 'Trancada';

  @override
  String get houseLockUnlocked => 'Destrancada';

  @override
  String get houseGateClosed => 'Fechado';

  @override
  String get houseGateOpen => 'Aberto';

  @override
  String get houseDoorClosed => 'Fechada';

  @override
  String get houseDoorOpen => 'Aberta';

  @override
  String get houseLockUnlock => 'Destrancar';

  @override
  String get houseLockLock => 'Trancar';

  @override
  String get houseLocksSetupHint => 'Escolha as fechaduras no Home Assistant: ByteHomeDash › Casa';

  @override
  String roomExtraLocked(String name) {
    return '$name trancada';
  }

  @override
  String roomExtraUnlocked(String name) {
    return '$name aberta';
  }

  @override
  String roomExtraClosed(String name) {
    return '$name fechado';
  }

  @override
  String roomExtraOpen(String name) {
    return '$name aberto';
  }

  @override
  String get roomHighHumidity => 'Humidade alta';

  @override
  String get carAtHome => 'Em casa';

  @override
  String get carAway => 'Fora de casa';

  @override
  String get carDefaultName => 'Carro';

  @override
  String get houseWeatherSunny => 'Sol';

  @override
  String get houseWeatherClearNight => 'Céu limpo';

  @override
  String get houseWeatherPartlyCloudy => 'Parcialmente nublado';

  @override
  String get houseWeatherCloudy => 'Nublado';

  @override
  String get houseWeatherRainy => 'Chuva';

  @override
  String get houseWeatherPouring => 'Chuva forte';

  @override
  String get houseWeatherLightning => 'Trovoada';

  @override
  String get houseWeatherSnowy => 'Neve';

  @override
  String get houseWeatherHail => 'Granizo';

  @override
  String get houseWeatherFog => 'Nevoeiro';

  @override
  String get houseWeatherWindy => 'Vento';

  @override
  String get houseWeatherExceptional => 'Tempo excecional';

  @override
  String houseWhenToday(String time) {
    return 'hoje às $time';
  }

  @override
  String houseWhenYesterday(String time) {
    return 'ontem às $time';
  }

  @override
  String houseWhenDay(String day, String time) {
    return '$day às $time';
  }

  @override
  String get houseCompassN => 'norte';

  @override
  String get houseCompassNE => 'nordeste';

  @override
  String get houseCompassE => 'este';

  @override
  String get houseCompassSE => 'sudeste';

  @override
  String get houseCompassS => 'sul';

  @override
  String get houseCompassSW => 'sudoeste';

  @override
  String get houseCompassW => 'oeste';

  @override
  String get houseCompassNW => 'noroeste';

  @override
  String get houseUvLow => 'Baixo';

  @override
  String get houseUvModerate => 'Moderado';

  @override
  String get houseUvHigh => 'Alto';

  @override
  String get houseUvVeryHigh => 'Muito alto';

  @override
  String get houseUvExtreme => 'Extremo';

  @override
  String houseUvNow(String level) {
    return '$level agora';
  }

  @override
  String get houseStationJustNow => 'estação meteorológica, agora mesmo';

  @override
  String houseStationMinutesAgo(int minutes) {
    return 'estação meteorológica, há $minutes min';
  }

  @override
  String houseTodayDate(String weekday, String day, String month) {
    return 'Hoje, $weekday $day de $month';
  }

  @override
  String get houseTrendSteadyHour => 'Estável na última hora';

  @override
  String houseTrendRisingHour(String degrees) {
    return 'A subir · +$degrees° na última hora';
  }

  @override
  String houseTrendFallingHour(String degrees) {
    return 'A descer · −$degrees° na última hora';
  }

  @override
  String get houseHumidity => 'Humidade';

  @override
  String houseDewPoint(String degrees) {
    return 'Ponto de orvalho $degrees°';
  }

  @override
  String get houseOutdoorHumidity => 'Humidade exterior';

  @override
  String get houseWind => 'Vento';

  @override
  String houseWindFrom(String direction) {
    return 'De $direction';
  }

  @override
  String houseWindGustMax(String speed) {
    return 'rajada máx. $speed';
  }

  @override
  String houseRainingRate(String rate) {
    return 'A chover · $rate mm/h';
  }

  @override
  String get houseRainAccumulatedToday => 'Acumulada hoje · sem chuva agora';

  @override
  String get houseRainToday => 'Chuva hoje';

  @override
  String get housePressure => 'Pressão';

  @override
  String get houseTrendRising => 'A subir';

  @override
  String get houseTrendFalling => 'A descer';

  @override
  String get houseTrendSteady => 'Estável';

  @override
  String get houseAtmosphericPressure => 'Pressão atmosférica';

  @override
  String get houseUvIndex => 'Índice UV';

  @override
  String get houseSolarRadiation => 'Radiação solar';

  @override
  String get houseTrendIncreasing => 'A aumentar';

  @override
  String get houseTrendDecreasing => 'A diminuir';

  @override
  String get houseOutdoorTemperature => 'Temperatura exterior';

  @override
  String energySummaryHome(String power) {
    return 'Agora a casa usa $power';
  }

  @override
  String energySummaryHomeOwn(String power, int percent) {
    return 'Agora a casa usa $power, $percent% do sol e da bateria';
  }

  @override
  String energySummaryBattery(int percent) {
    return 'bateria a $percent%';
  }

  @override
  String energySummaryBatteryUntil(int percent, String time) {
    return 'bateria a $percent%, dura até às $time';
  }

  @override
  String get vacuumStateDocked => 'Na base';

  @override
  String get vacuumStateCleaning => 'A limpar';

  @override
  String get vacuumStatePaused => 'Em pausa';

  @override
  String get vacuumStateReturning => 'A voltar à base';

  @override
  String get vacuumStateIdle => 'Parado';

  @override
  String get vacuumStateError => 'Erro';

  @override
  String get vacuumPartMainBrush => 'Escova principal';

  @override
  String get vacuumPartSideBrush => 'Escova lateral';

  @override
  String get vacuumPartFilter => 'Filtro';

  @override
  String get vacuumPartSensors => 'Sensores';

  @override
  String get vacuumPartWheels => 'Rodas';

  @override
  String get vacuumPartScaleInhibitor => 'Inibidor de calcário';

  @override
  String get vacuumModeSweeping => 'Aspirar';

  @override
  String get vacuumModeMopping => 'Lavar';

  @override
  String get vacuumModeSweepingAndMopping => 'Aspirar e lavar';

  @override
  String get vacuumModeMoppingAfterSweeping => 'Lavar depois de aspirar';

  @override
  String get vacuumSuctionQuiet => 'Silencioso';

  @override
  String get vacuumStandard => 'Normal';

  @override
  String get vacuumSuctionStrong => 'Forte';

  @override
  String get vacuumSuctionMax => 'Máxima';

  @override
  String get vacuumMopSlightlyDry => 'Pouco húmida';

  @override
  String get vacuumMopMoist => 'Húmida';

  @override
  String get vacuumMopWet => 'Molhada';

  @override
  String get vacuumRouteQuick => 'Rápida';

  @override
  String get vacuumRouteIntensive => 'Intensiva';

  @override
  String get vacuumDeep => 'Profunda';

  @override
  String get vacuumGeniusRoutine => 'Rotina';

  @override
  String get vacuumErrorMainBrush => 'Escova principal presa';

  @override
  String get vacuumErrorMainBrushFix => 'Vire o robô, retire cabelos ou objetos presos na escova principal e toque em Retomar.';

  @override
  String get vacuumErrorSideBrush => 'Escova lateral presa';

  @override
  String get vacuumErrorSideBrushFix => 'Liberte a escova lateral e toque em Retomar.';

  @override
  String get vacuumErrorWheel => 'Roda presa';

  @override
  String get vacuumErrorWheelFix => 'Mude o robô de sítio e toque em Retomar.';

  @override
  String get vacuumErrorDrop => 'Rodas no ar';

  @override
  String get vacuumErrorDropFix => 'Ponha o robô no chão e toque em Retomar.';

  @override
  String get vacuumErrorBumper => 'Para-choques preso';

  @override
  String get vacuumErrorBumperFix => 'Verifique o para-choques e toque em Retomar.';

  @override
  String get vacuumErrorDustBin => 'Depósito de pó em falta';

  @override
  String get vacuumErrorDustBinFix => 'Volte a pôr o depósito de pó e toque em Retomar.';

  @override
  String get vacuumErrorWaterTank => 'Depósito de água em falta';

  @override
  String get vacuumErrorWaterTankFix => 'Volte a pôr o depósito de água e toque em Retomar.';

  @override
  String get vacuumErrorLowBattery => 'Bateria fraca';

  @override
  String get vacuumErrorLowBatteryFix => 'Leve o robô à base para carregar.';

  @override
  String vacuumRoomFallback(int number) {
    return 'Divisão $number';
  }

  @override
  String get vacuumTankCleanWater => 'Água limpa';

  @override
  String get vacuumTankDirtyWater => 'Água suja';

  @override
  String get vacuumTankDustBag => 'Saco do pó';

  @override
  String get vacuumTankDetergent => 'Detergente';

  @override
  String vacuumDaysLeft(int count) {
    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: '$count dias', one: '1 dia');
    return '$_temp0';
  }

  @override
  String vacuumBatteryHistory(String name) {
    return 'Bateria · $name';
  }

  @override
  String get vacuumLocate => 'Localizar';

  @override
  String vacuumSession(String area, String minutes) {
    return '$area m² em $minutes min';
  }

  @override
  String vacuumStoppedIn(String room) {
    return 'Parou na $room.';
  }

  @override
  String vacuumCleaningRoom(String room) {
    return 'A limpar: $room';
  }

  @override
  String vacuumPausedRoom(String room) {
    return 'Em pausa: $room';
  }

  @override
  String get vacuumPausedHint => 'Toque em Retomar para continuar de onde parou.';

  @override
  String vacuumCleaningFinished(String session) {
    return 'Limpeza terminada · $session';
  }

  @override
  String get vacuumIdleTitle => 'Parado fora da base';

  @override
  String get vacuumIdleOffBase => 'Está fora da base. Pode iniciar de novo ou mandá-lo para a base.';

  @override
  String vacuumIdleInRoom(String room) {
    return 'Está na $room. Pode iniciar de novo ou mandá-lo para a base.';
  }

  @override
  String get vacuumDockedWashing => 'Na base · a lavar a mopa';

  @override
  String get vacuumDockedWashingHint => 'A estação está a lavar e a renovar a água da mopa.';

  @override
  String get vacuumDockedDrying => 'Na base · a secar a mopa';

  @override
  String get vacuumDryingHint => 'Pode iniciar uma limpeza a qualquer momento.';

  @override
  String vacuumDryingLeftHint(String duration) {
    return 'Faltam $duration. Pode iniciar uma limpeza a qualquer momento.';
  }

  @override
  String get vacuumDockedEmptying => 'Na base · a esvaziar o depósito';

  @override
  String get vacuumDockedEmptyingHint => 'O pó passa para o saco da estação.';

  @override
  String get vacuumDockedCharging => 'Na base · a carregar';

  @override
  String get vacuumDockedFull => 'Na base · carga completa';

  @override
  String vacuumLastCleaning(String session) {
    return 'Última limpeza: $session';
  }

  @override
  String vacuumPendingConfirm(String action) {
    return '$action… a aguardar confirmação do Home Assistant.';
  }

  @override
  String vacuumMaintenanceNotice(String parts) {
    return 'Manutenção: $parts';
  }

  @override
  String get vacuumSeeMaintenance => 'Ver manutenção';

  @override
  String get vacuumMapLive => 'Mapa ao vivo';

  @override
  String get vacuumMap => 'Mapa';

  @override
  String vacuumStatHistory(String stat, String name) {
    return '$stat · $name';
  }

  @override
  String get vacuumAreaCleaned => 'Área limpa';

  @override
  String get vacuumLastCleaningLabel => 'Última limpeza';

  @override
  String get vacuumTime => 'Tempo';

  @override
  String get vacuumDuration => 'Duração';

  @override
  String get vacuumCleaningTime => 'Tempo de limpeza';

  @override
  String get vacuumDone => 'Concluído';

  @override
  String get vacuumProgress => 'Progresso';

  @override
  String get vacuumTotalCleanings => 'Limpezas no total';

  @override
  String get vacuumCleanings => 'Limpezas';

  @override
  String get vacuumCleanAll => 'Limpar tudo';

  @override
  String vacuumCleanRooms(int count) {
    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: 'Limpar $count divisões', one: 'Limpar 1 divisão');
    return '$_temp0';
  }

  @override
  String get vacuumPause => 'Pausar';

  @override
  String get vacuumReturnToBase => 'Voltar à base';

  @override
  String get vacuumResume => 'Retomar';

  @override
  String get vacuumStop => 'Parar';

  @override
  String get vacuumBase => 'Base';

  @override
  String get vacuumTabCleaning => 'Limpeza';

  @override
  String get vacuumTabMaintenance => 'Manutenção';

  @override
  String get vacuumTabMore => 'Mais';

  @override
  String get vacuumRoomsHeaderNone => 'DIVISÕES · NENHUMA · LIMPA A CASA TODA';

  @override
  String vacuumRoomsHeaderSome(int selected, int total) {
    return 'DIVISÕES · $selected DE $total PELA ORDEM ESCOLHIDA';
  }

  @override
  String get vacuumSelectAll => 'Selecionar todas';

  @override
  String get vacuumClearSelection => 'Limpar seleção';

  @override
  String get vacuumGeniusSubtitle => 'Modo automático inteligente';

  @override
  String get vacuumGeniusHint =>
      'O CleanGenius escolhe sozinho o modo, a sucção, a humidade da mopa e a rota para cada divisão. Desligue-o para escolher à mão.';

  @override
  String get vacuumCleaningModeLabel => 'MODO DE LIMPEZA';

  @override
  String get vacuumSuctionLabel => 'SUCÇÃO';

  @override
  String get vacuumMopHumidityLabel => 'HUMIDADE DA MOPA';

  @override
  String get vacuumRouteLabel => 'ROTA';

  @override
  String get vacuumFineTune => 'Ajuste fino';

  @override
  String get vacuumInstalled => 'Instalado';

  @override
  String get vacuumMissing => 'Em falta';

  @override
  String get vacuumStation => 'Estação';

  @override
  String get vacuumStationIdle => 'Inativa';

  @override
  String get vacuumStationWashing => 'A lavar';

  @override
  String get vacuumStationDrying => 'A secar';

  @override
  String get vacuumAutoEmpty => 'Autoesvaziamento';

  @override
  String get vacuumEmptying => 'A esvaziar';

  @override
  String get vacuumAutoEmptyIdle => 'Inativo';

  @override
  String get vacuumLowWater => 'Pouca água';

  @override
  String get vacuumActionEmptyBin => 'Esvaziar depósito de pó';

  @override
  String get vacuumActionWashMop => 'Lavar mopa';

  @override
  String get vacuumActionDryMop => 'Secar mopa';

  @override
  String get vacuumActionCleanBase => 'Limpar a base';

  @override
  String get vacuumDryingMop => 'A secar a mopa';

  @override
  String vacuumDryingProgress(int percent, String duration) {
    return '$percent% · faltam $duration';
  }

  @override
  String get vacuumStationLabel => 'ESTAÇÃO';

  @override
  String vacuumBaseHistory(String label) {
    return '$label · base';
  }

  @override
  String get vacuumBaseActionsLabel => 'AÇÕES DA BASE';

  @override
  String get vacuumNoWearInfo => 'Este aspirador não indica o desgaste das peças.';

  @override
  String vacuumPartLifeHistory(String part) {
    return '$part · vida restante';
  }

  @override
  String get vacuumReset => 'Repor';

  @override
  String vacuumResetAskClean(String part) {
    return 'Repor o contador de $part? Faça-o depois de limpar a peça.';
  }

  @override
  String vacuumResetAskReplace(String part) {
    return 'Repor o contador de $part? Faça-o depois de trocar a peça.';
  }

  @override
  String get vacuumResetTo100 => 'Repor a 100%';

  @override
  String vacuumPartLeft(int percent, String time) {
    return '$percent% · $time restantes';
  }

  @override
  String get vacuumTotalArea => 'Área total';

  @override
  String get vacuumTotalTime => 'Tempo total';

  @override
  String get vacuumDnd => 'Não incomodar';

  @override
  String get vacuumDndHint => 'Não limpa nem fala neste horário';

  @override
  String get vacuumStartsAt => 'Começa às';

  @override
  String get vacuumEndsAt => 'Termina às';

  @override
  String get vacuumChildLock => 'Bloqueio para crianças';

  @override
  String get vacuumChildLockHint => 'Os botões do robô deixam de funcionar';

  @override
  String get vacuumStatsLabel => 'ESTATÍSTICAS';

  @override
  String get vacuumVoiceVolume => 'Volume da voz';

  @override
  String get houseTitle => 'Casa';

  @override
  String get houseDoorsClosed => 'Portas fechadas';

  @override
  String houseDoorsOpen(int count) {
    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: '$count portas abertas', one: '1 porta aberta');
    return '$_temp0';
  }

  @override
  String get houseWindowsClosed => 'Janelas fechadas';

  @override
  String houseWindowsOpen(int count) {
    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: '$count janelas abertas', one: '1 janela aberta');
    return '$_temp0';
  }

  @override
  String get houseLightsOff => 'Luzes apagadas';

  @override
  String houseLightsOn(int count) {
    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: '$count luzes acesas', one: '1 luz acesa');
    return '$_temp0';
  }

  @override
  String get roomLights => 'Luzes';

  @override
  String get roomWindow => 'Janela';

  @override
  String get roomBlinds => 'Estores';

  @override
  String get acTitle => 'Ar condicionado';

  @override
  String get roomVentilation => 'Ventilação';

  @override
  String get roomRooms => 'Divisões';

  @override
  String get roomAllLightsOff => 'Apagar todas as luzes';

  @override
  String get roomVentOn => 'Ligada';

  @override
  String get energySolar => 'Solar';

  @override
  String energyOfForecast(String amount) {
    return 'De $amount kWh previstos';
  }

  @override
  String get energyConsumption => 'Consumo';

  @override
  String energyYesterdayThisTime(String amount) {
    return 'Ontem a esta hora: $amount';
  }

  @override
  String get energySelfUse => 'Autoconsumo';

  @override
  String get energyFromSunAndBattery => 'Do sol e da bateria';

  @override
  String get energyGrid => 'Rede';

  @override
  String energyImportedSold(String amount) {
    return 'Importados · $amount vendidos';
  }

  @override
  String energyLessThanToday(int percent) {
    return 'menos $percent% do que hoje';
  }

  @override
  String energyMoreThanToday(int percent) {
    return 'mais $percent% do que hoje';
  }

  @override
  String get energyNowLabel => 'AGORA';

  @override
  String get energyTitle => 'Energia';

  @override
  String get houseSeeMore => 'Ver mais';

  @override
  String get energyTodayLabel => 'HOJE';

  @override
  String get energyTomorrowLabel => 'AMANHÃ';

  @override
  String get energySolarForecast => 'Solar previsto';

  @override
  String get houseSecurity => 'Segurança';

  @override
  String get houseAllClosed => 'Tudo fechado';

  @override
  String houseOpenCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: '$count abertas', one: '1 aberta');
    return '$_temp0';
  }

  @override
  String houseLockLastOpened(String kind, String when) {
    String _temp0 = intl.Intl.selectLogic(kind, {
      'lock': 'Destrancada pela última vez $when',
      'door': 'Aberta pela última vez $when',
      'other': 'Aberto pela última vez $when',
    });
    return '$_temp0';
  }

  @override
  String houseLockOpenSince(String kind, String time) {
    String _temp0 = intl.Intl.selectLogic(kind, {'lock': 'Destrancada desde $time', 'door': 'Aberta desde $time', 'other': 'Aberto desde $time'});
    return '$_temp0';
  }

  @override
  String houseLockOpenJustNow(String kind) {
    String _temp0 = intl.Intl.selectLogic(kind, {
      'lock': 'Destrancada desde agora mesmo',
      'door': 'Aberta desde agora mesmo',
      'other': 'Aberto desde agora mesmo',
    });
    return '$_temp0';
  }

  @override
  String houseFeelsLike(String degrees) {
    return 'Sensação $degrees°';
  }

  @override
  String houseTodayMaxMin(String max, String min) {
    return 'hoje máx. $max°, mín. $min°';
  }

  @override
  String get houseOutdoor => 'Exterior';

  @override
  String vacuumCountCleaning(int count) {
    return '$count a limpar';
  }

  @override
  String get vacuumBothDocked => 'Ambos na base';

  @override
  String get vacuumAllDocked => 'Todos na base';

  @override
  String get vacuumNoneCleaning => 'Nenhum a limpar';

  @override
  String get vacuumTitle => 'Aspiradores';

  @override
  String vacuumErrorInRoom(String error, String room) {
    return '$error na $room';
  }

  @override
  String vacuumBusyFoot(String battery, String area, String minutes) {
    return 'Bateria $battery% · $area m² · $minutes min';
  }

  @override
  String vacuumLastCleaningShort(String session) {
    return 'Última limpeza $session';
  }

  @override
  String get vacuumOfCleaning => 'da limpeza';

  @override
  String get vacuumBatteryCharging => 'bateria · a carregar';

  @override
  String get vacuumBatteryWord => 'bateria';

  @override
  String get acSectionTitle => 'Ar Condicionado';

  @override
  String get acNone => 'Sem ar condicionado';

  @override
  String get acAllOff => 'Todos desligados';

  @override
  String acOnOfTotal(int on, int total) {
    return '$on de $total ligados';
  }

  @override
  String get houseSeeAll => 'Ver todos';

  @override
  String acNowTemp(String temp) {
    return 'Agora $temp';
  }

  @override
  String get houseAllLocked => 'Tudo trancado';

  @override
  String houseAccessesOpen(int count) {
    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: '$count acessos abertos', one: '1 acesso aberto');
    return '$_temp0';
  }

  @override
  String get houseAlarmTriggered => 'Alarme disparado';

  @override
  String get houseAlarmOff => 'Alarme desligado';

  @override
  String get houseAlarmHome => 'Alarme em casa';

  @override
  String get houseAlarmAway => 'Alarme ausente';

  @override
  String get houseWaterHeating => 'A aquecer';

  @override
  String get houseWaterOff => 'Desligada';

  @override
  String get houseWaterReady => 'Pronta';

  @override
  String get houseHotWater => 'Água quente';

  @override
  String get houseHotWaterTemperature => 'Água quente · temperatura';

  @override
  String houseWaterTarget(String degrees) {
    return 'Alvo $degrees ºC';
  }

  @override
  String get houseHeatPump => 'Bomba de calor';

  @override
  String get houseJustNow => 'agora mesmo';

  @override
  String houseMinutesAgo(int minutes) {
    return 'há $minutes min';
  }

  @override
  String houseHoursAgo(int hours) {
    return 'há $hours h';
  }

  @override
  String houseDaysAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: 'há $count dias', one: 'há 1 dia');
    return '$_temp0';
  }

  @override
  String houseMissedCalls(int count) {
    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: '$count chamadas não atendidas', one: '1 chamada não atendida');
    return '$_temp0';
  }

  @override
  String get houseBuildingDoor => 'Porta';

  @override
  String houseMissedShort(int count) {
    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: '$count não atendidas', one: '1 não atendida');
    return '$_temp0';
  }

  @override
  String get houseIntercom => 'Intercomunicador';

  @override
  String get cameraLive => 'AO VIVO';

  @override
  String get cameraUnavailable => 'Câmara indisponível';

  @override
  String roomTemperatureHistory(String room) {
    return 'Temperatura · $room';
  }

  @override
  String get roomNoTemperatureSensor => 'Sem sensor de temperatura';

  @override
  String roomHumidityHistory(String room) {
    return 'Humidade · $room';
  }

  @override
  String roomHumidityValue(int percent) {
    return 'humidade $percent%';
  }

  @override
  String roomWindowHistory(String room) {
    return 'Janela · $room';
  }

  @override
  String get roomLightsOff => 'Apagadas';

  @override
  String get roomBrightness => 'Brilho';

  @override
  String get roomBlindsOpening => 'A abrir';

  @override
  String get roomBlindsClosing => 'A fechar';

  @override
  String get roomBlindsClosed => 'Fechados';

  @override
  String get roomBlindsOpen => 'Abertos';

  @override
  String roomBlindsOpenAt(int percent) {
    return 'Abertos a $percent%';
  }

  @override
  String get roomBlindsHalf => 'Meio';

  @override
  String get roomBlindsAperture => 'Abertura';

  @override
  String get roomVentOff => 'Desligada';

  @override
  String acNowMode(String temp, String mode) {
    String _temp0 = intl.Intl.selectLogic(mode, {
      'heat': 'Agora $temp · a aquecer',
      'cool': 'Agora $temp · a arrefecer',
      'fan': 'Agora $temp · a ventilar',
      'other': 'Agora $temp · a automático',
    });
    return '$_temp0';
  }

  @override
  String acNowOff(String temp) {
    return 'Agora $temp · desligado';
  }

  @override
  String get acTargetTemperature => 'Temperatura pretendida';

  @override
  String get acOffTurnOnToAdjust => 'Desligado · ligue para ajustar';

  @override
  String get acModeLabel => 'MODO';

  @override
  String get acFanLabel => 'VENTILADOR';

  @override
  String get acAllUnits => 'Todos os ar condicionados';

  @override
  String get acTurnOff => 'Desligar';

  @override
  String get acTurnOn => 'Ligar';

  @override
  String acNowLower(String temp) {
    return 'agora $temp';
  }

  @override
  String get acHeating => 'A aquecer';

  @override
  String get acCooling => 'A arrefecer';

  @override
  String get acVentilating => 'A ventilar';

  @override
  String get acNoUnits => 'Sem unidades';

  @override
  String acHouseTemp(String temp) {
    return 'Casa $temp';
  }

  @override
  String acHouseTempNoHeating(String temp) {
    return 'Casa $temp · sem aquecimento';
  }

  @override
  String acOutside(String degrees) {
    return 'Exterior $degrees°';
  }

  @override
  String get acTurnOffAll => 'Desligar todos';

  @override
  String get acNoneConfigured => 'Nenhum ar condicionado configurado.';

  @override
  String get energySolarTodayLabel => 'SOLAR HOJE';

  @override
  String get energyConsumptionLabel => 'CONSUMO';

  @override
  String get energySelfUseLabel => 'AUTOCONSUMO';

  @override
  String get energyCameFromSunOrBattery => 'Veio do sol ou da bateria';

  @override
  String get energySavingsLabel => 'POUPANÇA';

  @override
  String get energySavingsVsGrid => 'Hoje, face a só rede';

  @override
  String get energyNow => 'Agora';

  @override
  String energyBatterySupplying(String power) {
    return 'A fornecer $power';
  }

  @override
  String energyBatteryCharging(String power) {
    return 'A carregar $power';
  }

  @override
  String get energyBatteryIdle => 'Em repouso';

  @override
  String get energyBatteryLastsUntil => 'Ao ritmo atual dura até';

  @override
  String get energyBatteryRechargesAt => 'Volta a carregar (previsão)';

  @override
  String energyBatteryRechargesWithSun(String time) {
    return '≈ $time, com o sol';
  }

  @override
  String get energyCapacity => 'Capacidade';

  @override
  String get energyGridIdle => 'Sem trocas';

  @override
  String energyGridImporting(String power) {
    return 'A importar $power';
  }

  @override
  String energyGridSelling(String power) {
    return 'A vender $power';
  }

  @override
  String get energyImportedToday => 'Importado hoje';

  @override
  String get energySoldToday => 'Vendido hoje';

  @override
  String get energyTariffNow => 'Tarifa agora';

  @override
  String get energyPriceNow => 'Preço agora';

  @override
  String get energyOther => 'Outros';

  @override
  String get energyTodayByHour => 'Hoje, hora a hora';

  @override
  String get energyForecast => 'Previsão';

  @override
  String get energySolarForecastTitle => 'Previsão solar';

  @override
  String get energyBattery => 'Bateria';

  @override
  String get energyConsumptionNow => 'Consumo agora';

  @override
  String get energyLast7Days => 'Últimos 7 dias';

  @override
  String get energyProduced => 'Produzido';

  @override
  String get energyConsumed => 'Consumido';

  @override
  String get energyExported => 'Exportado';

  @override
  String energyWeekSummary(String produced, String consumed, String exported) {
    return 'Últimos 7 dias: $produced kWh produzidos, $consumed kWh consumidos, $exported kWh exportados.';
  }

  @override
  String energyWeekSummarySavings(String produced, String consumed, String exported, String savings) {
    return 'Últimos 7 dias: $produced kWh produzidos, $consumed kWh consumidos, $exported kWh exportados · poupança estimada $savings.';
  }

  @override
  String get energyNotConfigured => 'Os totais, a previsão e o histórico vêm do painel Energia do Home Assistant, que não está configurado.';

  @override
  String energyModalToday(String date) {
    return 'Hoje, $date';
  }

  @override
  String energyModalTodayUpdated(String date, String time) {
    return 'Hoje, $date · atualizado às $time';
  }

  @override
  String energyForecastPeak(String power, String time) {
    return 'Pico previsto $power · $time';
  }

  @override
  String get energyFlowLabel => 'ENERGIA';

  @override
  String get energyPowerGrid => 'Rede elétrica';

  @override
  String get energySolarProduction => 'Produção solar';

  @override
  String get energyHouseBattery => 'Bateria da casa';

  @override
  String get energyHouseConsumption => 'Consumo da casa';

  @override
  String get carLocked => 'Trancado';

  @override
  String get carUnlocked => 'Destrancado';

  @override
  String get carNoState => 'Sem estado';

  @override
  String get carCharging => 'A carregar';

  @override
  String get carBatteryLow => 'Bateria baixa';

  @override
  String get carWaitingToCharge => 'À espera de carga';

  @override
  String get carUnplugged => 'Desligado da ficha';

  @override
  String carUpdatedAt(String time) {
    return 'Atualizado às $time';
  }

  @override
  String get carRefuelSoon => 'abastecer em breve';

  @override
  String carChargeLimit(int percent) {
    return 'até $percent%';
  }

  @override
  String get carPlugIn => 'ligar à ficha';

  @override
  String carFuelHistory(String name) {
    return '$name · combustível';
  }

  @override
  String carBatteryHistory(String name) {
    return '$name · bateria';
  }

  @override
  String cameraSubtitle(String place) {
    return 'Câmara · $place';
  }

  @override
  String get cameraLiveShort => 'Ao vivo';

  @override
  String get speakersWholeHouse => 'Toda a casa';

  @override
  String speakersOnly(String name) {
    return 'Só $name';
  }

  @override
  String speakersPlayingInSync(int count) {
    return '$count colunas a tocar em sincronia';
  }

  @override
  String speakersPlayingOnlyOn(String name) {
    return 'A tocar só em $name';
  }

  @override
  String get speakersTitle => 'Colunas';

  @override
  String get speakersIntro => 'Toque numa coluna para a juntar ou tirar do grupo. A música continua sem parar.';

  @override
  String get speakersNoConnection => 'Sem ligação ao Music Assistant.';

  @override
  String get speakersAlsoPlaying => 'TAMBÉM A TOCAR';

  @override
  String get speakersPlaying => 'A tocar';

  @override
  String get speakersControl => 'Controlar';

  @override
  String get speakersQuickGroups => 'GRUPOS RÁPIDOS';

  @override
  String get speakersGroupVolume => 'VOLUME DO GRUPO';

  @override
  String get speakersHouseSpeakers => 'COLUNAS DA CASA';

  @override
  String get speakersMixedBrandsNote => 'Colunas de sistemas diferentes tocam juntas num grupo do Music Assistant. Pode haver um pequeno atraso entre elas.';

  @override
  String get speakersSpeaker => 'Coluna';

  @override
  String speakersSubOff(String model) {
    return '$model · desligada';
  }

  @override
  String speakersSubPlaying(String model, String title) {
    return '$model · a tocar $title';
  }

  @override
  String speakersSubCantGroup(String model, String name) {
    return '$model · não agrupa com $name';
  }

  @override
  String get speakersChipInGroup => 'No grupo';

  @override
  String get speakersChipBusy => 'Ocupada';

  @override
  String get speakersChipFree => 'Livre';

  @override
  String get musicRadio => 'Rádio';

  @override
  String get musicLocalLibrary => 'Biblioteca local';

  @override
  String musicDurationHoursMinutes(int hours, int minutes) {
    return '$hours h $minutes min';
  }

  @override
  String musicDurationMinutes(int minutes) {
    return '$minutes min';
  }

  @override
  String get musicLive => 'EM DIRETO';

  @override
  String get musicPlaylist => 'Playlist';

  @override
  String musicPlaylistBy(String owner) {
    return 'Playlist · $owner';
  }

  @override
  String get musicArtist => 'Artista';

  @override
  String get musicPodcast => 'Podcast';

  @override
  String musicPodcastBy(String owner) {
    return 'Podcast · $owner';
  }

  @override
  String get musicSaveFailed => 'Não foi possível guardar';

  @override
  String musicPlayingOn(String target) {
    return 'A TOCAR EM $target';
  }

  @override
  String get musicQueue => 'Fila';

  @override
  String musicUpNext(int count) {
    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: 'A SEGUIR · $count faixas', one: 'A SEGUIR · 1 faixa');
    return '$_temp0';
  }

  @override
  String get musicClearQueue => 'Limpar fila';

  @override
  String get musicQueueEmpty => 'A fila está vazia. Toque em \"Adicionar à fila\" numa playlist ou álbum.';

  @override
  String get musicFavoriteSongs => 'Músicas favoritas';

  @override
  String get musicFamily => 'Família';

  @override
  String get musicContextLiveRadio => 'RÁDIO EM DIRETO';

  @override
  String get musicContextPlaylist => 'A TOCAR DA PLAYLIST';

  @override
  String get musicContextAlbum => 'A TOCAR DO ÁLBUM';

  @override
  String get musicContextArtist => 'A TOCAR DO ARTISTA';

  @override
  String get musicContextPodcast => 'A TOCAR DO PODCAST';

  @override
  String get musicContextPlaying => 'A TOCAR';

  @override
  String get musicContextArtistRadio => 'RÁDIO DO ARTISTA';

  @override
  String get musicTabListenNow => 'Ouvir agora';

  @override
  String get musicTabSearch => 'Pesquisar';

  @override
  String get musicTabLibrary => 'Biblioteca';

  @override
  String get musicMaUnavailable => 'Music Assistant indisponível';

  @override
  String get musicMaConnecting => 'A ligar ao Music Assistant…';

  @override
  String get musicMaNotFound => 'O add-on Music Assistant não foi encontrado no Home Assistant.';

  @override
  String get musicGreetingMorning => 'Bom dia, família';

  @override
  String get musicGreetingAfternoon => 'Boa tarde, família';

  @override
  String get musicGreetingEvening => 'Boa noite, família';

  @override
  String get musicRecentlyPlayed => 'Tocado recentemente';

  @override
  String get musicInThisHouse => 'Nesta casa';

  @override
  String get musicYourPlaylists => 'As vossas playlists';

  @override
  String get musicRadios => 'Rádios';

  @override
  String get musicLiveNote => 'Em direto';

  @override
  String get musicPodcasts => 'Podcasts';

  @override
  String get musicFavoriteArtists => 'Artistas favoritos';

  @override
  String get musicGenrePortuguese => 'Português';

  @override
  String get musicGenreClassical => 'Clássica';

  @override
  String get musicGenreRelax => 'Relax';

  @override
  String get musicGenreParty => 'Festa';

  @override
  String get musicGenreWorkout => 'Treino';

  @override
  String get musicGenreSleep => 'Dormir';

  @override
  String get musicGenre80s => 'Anos 80';

  @override
  String get musicSearchHint => 'Artistas, músicas, álbuns, rádios ou podcasts';

  @override
  String get musicRecentSearches => 'PESQUISAS RECENTES';

  @override
  String get musicBrowseAll => 'Explorar tudo';

  @override
  String get musicFilterAll => 'Tudo';

  @override
  String get musicSongs => 'Músicas';

  @override
  String get musicArtists => 'Artistas';

  @override
  String get musicAlbums => 'Álbuns';

  @override
  String get musicPlaylists => 'Playlists';

  @override
  String get musicPodcastsAndRadios => 'Podcasts e rádios';

  @override
  String musicNoResults(String query) {
    return 'Sem resultados para \"$query\"';
  }

  @override
  String get musicNoResultsDetail => 'Pesquisámos em todos os serviços ligados ao Music Assistant.';

  @override
  String get musicCaptionArtist => 'ARTISTA';

  @override
  String get musicCaptionAlbum => 'ÁLBUM';

  @override
  String get musicCaptionPlaylist => 'PLAYLIST';

  @override
  String get musicCaptionRadio => 'RÁDIO';

  @override
  String get musicCaptionPodcast => 'PODCAST';

  @override
  String get musicTopResult => 'Melhor resultado';

  @override
  String get musicSortRecent => 'Recentes';

  @override
  String get musicSortAdded => 'Adicionados';

  @override
  String get musicLibraryEmpty => 'Nada guardado aqui ainda.';

  @override
  String musicFavoritesSummary(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Playlist · $count músicas · Music Assistant',
      one: 'Playlist · 1 música · Music Assistant',
    );
    return '$_temp0';
  }

  @override
  String get musicAlbum => 'Álbum';

  @override
  String musicEpisodesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: '$count episódios', one: '1 episódio');
    return '$_temp0';
  }

  @override
  String musicSongsAndDuration(int count, String duration) {
    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: '$count músicas, $duration', one: '1 música, $duration');
    return '$_temp0';
  }

  @override
  String get musicFavoritesDescription => 'As músicas marcadas com coração.';

  @override
  String get musicAddedToQueue => 'Adicionado à fila';

  @override
  String musicPlaysOn(String target) {
    return 'Toca em $target';
  }

  @override
  String get musicColumnEpisode => 'EPISÓDIO';

  @override
  String get musicColumnTitle => 'TÍTULO';

  @override
  String get musicColumnDuration => 'DURAÇÃO';

  @override
  String get musicNoTracks => 'Sem faixas.';

  @override
  String get musicFollowingArtist => 'Segue este artista';

  @override
  String get musicFollowing => 'A seguir';

  @override
  String get musicFollow => 'Seguir';

  @override
  String get musicArtistRadio => 'Rádio do artista';

  @override
  String get musicPopular => 'Populares';

  @override
  String get musicDiscography => 'Discografia';

  @override
  String get musicLoadFailed => 'Não foi possível carregar.';

  @override
  String get browserFavWeather => 'Tempo';

  @override
  String get browserFavNews => 'Notícias';

  @override
  String get browserUnavailable => 'O navegador não está disponível neste ecrã.';

  @override
  String get browserKeySearch => 'Pesquisar';

  @override
  String get browserKeySend => 'Enviar';

  @override
  String get browserKeyGo => 'Ir';

  @override
  String get browserTitle => 'Navegador';

  @override
  String get browserReturnToStart => 'Voltar ao navegador · página inicial';

  @override
  String browserReturnTo(String site) {
    return 'Voltar ao navegador · $site';
  }

  @override
  String get browserVolume => 'Volume do navegador';

  @override
  String get browserMuted => 'Sem som';

  @override
  String get browserVolumeNote => 'Só para o som dos sites (vídeos, música). O volume do ecrã fica igual, nas Definições.';

  @override
  String browserAddressHint(String engine) {
    return 'Pesquisar no $engine ou escrever um endereço';
  }

  @override
  String get browserStartPage => 'Página inicial';

  @override
  String get browserStartTitle => 'Para onde vamos?';

  @override
  String get browserFavorites => 'FAVORITOS';

  @override
  String get browserRecentlyVisited => 'VISITADOS RECENTEMENTE';

  @override
  String get browserJustNow => 'agora mesmo';

  @override
  String browserMinutesAgo(int minutes) {
    return 'há $minutes min';
  }

  @override
  String browserHoursAgo(int hours) {
    return 'há $hours h';
  }

  @override
  String get browserYesterday => 'ontem';

  @override
  String get doorbellGroupClassic => 'Clássicos';

  @override
  String get doorbellGroupCustom => 'Os meus toques';

  @override
  String get doorbellGroupIntercom => 'Intercomunicador';

  @override
  String get doorbellGroupModern => 'Modernos';

  @override
  String get doorbellToneAurora => 'Aurora';

  @override
  String get doorbellToneAuroraDesc => 'Acorde lento, para a noite';

  @override
  String get doorbellToneBolhas => 'Bolhas';

  @override
  String get doorbellToneBolhasDesc => 'Bolhas a subir, divertido';

  @override
  String get doorbellToneCarrilhao => 'Carrilhão';

  @override
  String get doorbellToneCarrilhaoDesc => 'Sinos em cascata';

  @override
  String get doorbellToneCustomDesc => 'O seu ficheiro · toca em contínuo';

  @override
  String get doorbellToneDigital => 'Digital';

  @override
  String get doorbellToneDigitalDesc => 'Bip duplo de intercomunicador';

  @override
  String get doorbellToneDingdong => 'Ding-dong';

  @override
  String get doorbellToneDingdongDesc => 'Campainha clássica de dois tons';

  @override
  String get doorbellToneDoisToques => 'Dois toques';

  @override
  String get doorbellToneDoisToquesDesc => 'Toque eletrónico, repetido';

  @override
  String get doorbellToneHarpa => 'Harpa';

  @override
  String get doorbellToneHarpaDesc => 'Arpejo de harpa, delicado';

  @override
  String get doorbellToneKalimba => 'Kalimba';

  @override
  String get doorbellToneKalimbaDesc => 'Piano de polegar, suave';

  @override
  String get doorbellToneMarimba => 'Marimba';

  @override
  String get doorbellToneMarimbaDesc => 'Notas de madeira, alegre';

  @override
  String get doorbellToneMelodia => 'Melodia';

  @override
  String get doorbellToneMelodiaDesc => 'Melodia polifónica de monitor';

  @override
  String get doorbellTonePortaria => 'Portaria';

  @override
  String get doorbellTonePortariaDesc => 'O trinado dos monitores de prédio';

  @override
  String get doorbellTonePulsar => 'Pulsar';

  @override
  String get doorbellTonePulsarDesc => 'Arpejo de sintetizador';

  @override
  String get doorbellToneRetro => 'Retro';

  @override
  String get doorbellToneRetroDesc => 'Jogo de 8 bits';

  @override
  String get doorbellToneSuave => 'Suave';

  @override
  String get doorbellToneSuaveDesc => 'Dois tons calmos';

  @override
  String get doorbellToneTresTons => 'Três tons';

  @override
  String get doorbellToneTresTonsDesc => 'Acorde ascendente, curto';

  @override
  String get doorbellToneTriangulo => 'Triângulo';

  @override
  String get doorbellToneTrianguloDesc => 'Três toques metálicos';

  @override
  String get doorbellToneTrrrim => 'Trrrim';

  @override
  String get doorbellToneTrrrimDesc => 'Campainha elétrica, de martelo';

  @override
  String get doorbellToneVidro => 'Vidro';

  @override
  String get doorbellToneVidroDesc => 'Sinos de cristal, limpos';

  @override
  String get doorbellToneWestminster => 'Westminster';

  @override
  String get doorbellToneWestminsterDesc => 'Carrilhão de quatro notas';

  @override
  String get doorbellToneXilofone => 'Xilofone';

  @override
  String get doorbellToneXilofoneDesc => 'Escala rápida e alegre';

  @override
  String headerMax(String temp) {
    return 'Máx $temp°';
  }

  @override
  String headerMin(String temp) {
    return 'Mín $temp°';
  }

  @override
  String headerNextHoliday(String name, String weekday, String date) {
    return 'Próximo feriado: $name, $weekday $date';
  }

  @override
  String get headerSeeForecast => 'Ver a previsão do tempo';

  @override
  String headerWeek(int week) {
    return 'Semana $week';
  }

  @override
  String historyAtTime(String time) {
    return 'às $time';
  }

  @override
  String get historyAverage => 'Média';

  @override
  String historyDayAt(String weekday, String date, String time) {
    return '$weekday, $date às $time';
  }

  @override
  String historyDurationHm(int hours, int minutes) {
    return '$hours h $minutes min';
  }

  @override
  String historyDurationM(int minutes) {
    return '$minutes min';
  }

  @override
  String get historyFooter => 'Histórico guardado pelo Home Assistant (recorder). Deslize o dedo no gráfico para ver cada momento.';

  @override
  String get historyInPeriod => 'no período';

  @override
  String get historyInTotal => 'no total';

  @override
  String get historyLast24h => 'Últimas 24 horas';

  @override
  String get historyLast30d => 'Últimos 30 dias';

  @override
  String get historyLast7d => 'Últimos 7 dias';

  @override
  String get historyLastChange => 'Última mudança';

  @override
  String get historyMax => 'Máximo';

  @override
  String get historyMin => 'Mínimo';

  @override
  String get historyNoChanges => 'sem mudanças';

  @override
  String get historyNoData => 'Sem dados';

  @override
  String get historyNone => 'Sem histórico';

  @override
  String get historyNow => 'Agora';

  @override
  String historyPercentOfTime(int percent) {
    return '$percent% do tempo';
  }

  @override
  String get historyRange24h => '24 horas';

  @override
  String get historyRange30d => '30 dias';

  @override
  String get historyRange7d => '7 dias';

  @override
  String historyTimeIn(String state) {
    return 'Tempo $state';
  }

  @override
  String historyTimes(int count) {
    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: '$count vezes', one: '1 vez');
    return '$_temp0';
  }

  @override
  String historyTodayAt(String time) {
    return 'Hoje às $time';
  }

  @override
  String get intercomAnswer => 'Atender';

  @override
  String get intercomBuildingDoor => 'Porta do Prédio';

  @override
  String get intercomCallAtBuildingDoor => 'Chamada na Porta do Prédio';

  @override
  String intercomCallCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: '$count chamadas', one: '1 chamada');
    return '$_temp0';
  }

  @override
  String get intercomConnecting => 'A ligar…';

  @override
  String get intercomDoorCalls => 'Chamadas na porta';

  @override
  String get intercomDoorNotOpened => 'Porta não foi aberta';

  @override
  String get intercomDoorNotOpenedSub => 'Nenhum dispositivo abriu a porta.';

  @override
  String get intercomDoorOpened => 'Porta aberta';

  @override
  String get intercomDoorOpenedSub => 'Durante ou logo a seguir à chamada.';

  @override
  String get intercomDoorUnlocked => 'Porta destrancada';

  @override
  String get intercomEmptySub => 'Sempre que tocarem à campainha, guardamos aqui uma imagem da porta, a hora e o que aconteceu.';

  @override
  String get intercomEmptyTitle => 'Ainda não houve chamadas desde que este ecrã as regista.';

  @override
  String get intercomEndOfList => 'Fim da lista. Este ecrã guarda as últimas 200 chamadas.';

  @override
  String get intercomHangUp => 'Desligar';

  @override
  String get intercomHistory => 'Histórico';

  @override
  String get intercomIgnore => 'Ignorar';

  @override
  String get intercomIgnoreHint => 'Ignorar só fecha este ecrã. O intercomunicador interior continua a tocar e pode ser atendido lá.';

  @override
  String get intercomInCall => 'Em chamada';

  @override
  String get intercomLive => 'Ao vivo';

  @override
  String get intercomLoggedHere => 'Intercomunicador · registadas por este ecrã';

  @override
  String get intercomMicOff => 'Microfone desligado';

  @override
  String intercomMissedCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: '$count não atendidas', one: '1 não atendida');
    return '$_temp0';
  }

  @override
  String get intercomMute => 'Silenciar';

  @override
  String get intercomNewTag => 'NOVA';

  @override
  String get intercomNewestFirst => 'Mais recentes primeiro';

  @override
  String get intercomNoPicture => 'Sem imagem';

  @override
  String get intercomNotConnected => 'O intercomunicador ainda não está ligado a este ecrã';

  @override
  String get intercomOpenDoor => 'Abrir porta';

  @override
  String get intercomOutcomeHere => 'Atendida neste ecrã';

  @override
  String get intercomOutcomeHereSub => 'Ouviram a porta por este ecrã.';

  @override
  String get intercomOutcomeIndoor => 'Atendida no intercomunicador';

  @override
  String get intercomOutcomeIndoorSub => 'Falaram pelo intercomunicador interior.';

  @override
  String get intercomOutcomeMissed => 'Não atendida';

  @override
  String get intercomOutcomeMissedSub => 'Ninguém atendeu, aqui nem no intercomunicador.';

  @override
  String get intercomOutcomeRinging => 'A tocar agora';

  @override
  String get intercomOutcomeRingingSub => 'Ainda pode atender no intercomunicador.';

  @override
  String intercomOutcomeWithDuration(String outcome, String duration) {
    return '$outcome Duração: $duration.';
  }

  @override
  String get intercomPictureFailed => 'Não foi possível captar a imagem';

  @override
  String get intercomPictureFailedSub => 'A câmara não respondeu no momento em que tocaram.';

  @override
  String intercomPosition(int index, int total) {
    return '$index de $total';
  }

  @override
  String intercomRelocksIn(int seconds) {
    return 'Volta a trancar em $seconds s';
  }

  @override
  String get intercomRinging => 'A tocar…';

  @override
  String get intercomSeeCamera => 'Ver câmara';

  @override
  String get intercomSnapshots => 'Imagens';

  @override
  String get intercomSomeoneRang => 'Alguém tocou à campainha';

  @override
  String get intercomSubBuildingDoor => 'Intercomunicador · Porta do Prédio';

  @override
  String get intercomTalk => 'Falar';

  @override
  String get intercomVideoUnavailable => 'Vídeo indisponível';

  @override
  String get navCalendar => 'Calendário';

  @override
  String get navHome => 'Início';

  @override
  String get navHouse => 'Casa';

  @override
  String get navLists => 'Listas';

  @override
  String get navMeals => 'Refeições';

  @override
  String get navMusic => 'Música';

  @override
  String get navSettings => 'Definições';

  @override
  String get navTasks => 'Tarefas';

  @override
  String get settingsAddTone => 'Adicionar toque';

  @override
  String settingsAddToneHow(String group) {
    return 'Os toques próprios vêm com a app: coloque ficheiros .wav na pasta assets/ringtones/custom do projeto. Aparecem em \"$group\" na próxima atualização deste ecrã.';
  }

  @override
  String get settingsAddToneNotHere => 'Não dá para adicionar a partir do ecrã';

  @override
  String get settingsAddToneSub => 'Os seus próprios ficheiros .wav. Ficam disponíveis como qualquer outro toque.';

  @override
  String get settingsAppearance => 'Aspeto';

  @override
  String get settingsAssistantLanguage => 'Idioma';

  @override
  String get settingsBrightness => 'Brilho';

  @override
  String get settingsBrightnessFailed => 'Não foi possível alterar o brilho';

  @override
  String get settingsBrightnessSub => 'O brilho do monitor, por DDC/CI.';

  @override
  String get settingsBuildingDoorToneSub => 'Toca até atender ou a chamada acabar. O botão à direita de cada toque deixa-o ouvir.';

  @override
  String get settingsConfigureEntities => 'Configurar entidades';

  @override
  String get settingsConfigureEntitiesSub => 'Pessoas, divisões, energia e carros configuram-se no painel \"ByteHomeDash\" do Home Assistant.';

  @override
  String get settingsConnections => 'Ligações';

  @override
  String settingsHaSub(String host, int count) {
    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: '$count entidades', one: '1 entidade');
    return '$host · $_temp0';
  }

  @override
  String get settingsIntercom => 'Intercomunicador';

  @override
  String get settingsIntercomBuildingDoor => 'Hikvision · Porta do Prédio';

  @override
  String get settingsIntercomConnection => 'Ligação';

  @override
  String get settingsIntercomDoorCamera => 'Hikvision · câmara da porta';

  @override
  String get settingsIntercomNotConfigured => 'Hikvision · não configurado neste ecrã';

  @override
  String get settingsIntercomPageSub => 'O toque deste ecrã quando tocam do intercomunicador do prédio.';

  @override
  String settingsIntercomToneSub(String tone) {
    return 'Porta do Prédio: $tone';
  }

  @override
  String get settingsIntercomTones => 'Toques e volume';

  @override
  String get settingsMaAddonMissing => 'Add-on não encontrado no Home Assistant';

  @override
  String settingsMaSpeakersFound(int count) {
    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: '$count colunas encontradas', one: '1 coluna encontrada');
    return '$_temp0';
  }

  @override
  String get settingsMaViaHa => 'Através do Home Assistant';

  @override
  String get settingsManage => 'Gerir';

  @override
  String get settingsMicNotConnected => 'O microfone ainda não está ligado a este ecrã.';

  @override
  String get settingsNetNoCable => 'Sem cabo ou sem endereço';

  @override
  String settingsNetSignal(int percent) {
    return 'sinal $percent%';
  }

  @override
  String settingsOwnTones(int count) {
    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: '$count toques seus', one: '1 toque seu', zero: 'Ainda sem toques seus');
    return '$_temp0';
  }

  @override
  String get settingsRebootFailed => 'Não foi possível reiniciar';

  @override
  String get settingsRebootScreen => 'Reiniciar o ecrã';

  @override
  String get settingsRebootScreenSub => 'Reinicia o dispositivo. Demora cerca de 1 minuto.';

  @override
  String get settingsRebootScreenText => 'O dispositivo reinicia. O ecrã fica indisponível durante cerca de 1 minuto, incluindo o intercomunicador.';

  @override
  String get settingsRebootScreenTitle => 'Reiniciar o ecrã?';

  @override
  String get settingsRebootingScreen => 'A reiniciar o ecrã…';

  @override
  String get settingsRecognizedVoices => 'Vozes reconhecidas';

  @override
  String get settingsRecognizedVoicesSub => 'Quem o assistente reconhece pela voz.';

  @override
  String get settingsRestart => 'Reiniciar';

  @override
  String get settingsRestartApp => 'Reiniciar a app';

  @override
  String get settingsRestartAppSub => 'Recarrega o ecrã. Demora uns segundos.';

  @override
  String get settingsRestartAppText => 'O ecrã fica em branco durante uns segundos e volta à página Início.';

  @override
  String get settingsRestartAppTitle => 'Reiniciar a app?';

  @override
  String get settingsRestartingApp => 'A reiniciar a app…';

  @override
  String get settingsScreenAndSound => 'Ecrã e som';

  @override
  String get settingsScreenOff => 'Desligar o ecrã';

  @override
  String get settingsScreenOffButton => 'Desligar';

  @override
  String get settingsScreenOffSub => 'Apaga já. Volta a acender ao tocar.';

  @override
  String get settingsSetInHa => 'Definido no Home Assistant.';

  @override
  String get settingsStatusConnected => 'Ligado';

  @override
  String get settingsStatusConnecting => 'A ligar';

  @override
  String get settingsStatusDisconnected => 'Sem ligação';

  @override
  String get settingsSystem => 'Sistema';

  @override
  String get settingsTapClockHint => 'Toque no relógio, em qualquer página, para voltar aqui.';

  @override
  String get settingsThemeAlwaysDark => 'Sempre escuro';

  @override
  String get settingsThemeAlwaysLight => 'Sempre claro';

  @override
  String get settingsThemeAtSunsetSunrise => 'Ao pôr e nascer do sol';

  @override
  String get settingsThemeBySun => 'Segue o sol';

  @override
  String get settingsThemeDark => 'Escuro';

  @override
  String get settingsThemeDarkAtSunset => 'Escuro ao pôr do sol';

  @override
  String get settingsThemeDarkFrom => 'Escuro a partir das';

  @override
  String get settingsThemeFixedTimes => 'A horas fixas';

  @override
  String get settingsThemeLight => 'Claro';

  @override
  String get settingsThemeLightAtSunrise => 'Claro ao nascer do sol';

  @override
  String get settingsThemeLightFrom => 'Claro a partir das';

  @override
  String settingsThemeNowDark(String time) {
    return 'Agora escuro · claro às $time';
  }

  @override
  String settingsThemeNowLight(String time) {
    return 'Agora claro · escuro às $time';
  }

  @override
  String get settingsThemeSunToday => 'Horas de hoje, do sol do Home Assistant (sun.sun). Acompanham as estações sozinhas.';

  @override
  String settingsThemeTip(String command, String entity) {
    return 'Também pode pedir ao assistente: $command. No Home Assistant o tema fica disponível como $entity, para usar em automações (por exemplo, escuro ao começar um filme).';
  }

  @override
  String settingsThemeVoiceCommand(String wakePhrase) {
    return '«$wakePhrase, muda para o modo escuro»';
  }

  @override
  String settingsThemeWaitingForSun(String darkTime, String lightTime) {
    return 'À espera das horas do sol do Home Assistant (sun.sun). Até lá, muda às $darkTime e às $lightTime.';
  }

  @override
  String get settingsThemeWhen => 'Quando mudar';

  @override
  String get settingsTitle => 'Definições';

  @override
  String settingsToneCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: '$count toques', one: '1 toque');
    return '$_temp0';
  }

  @override
  String get settingsToneMine => 'MEU';

  @override
  String settingsTonePlaying(String name, int percent) {
    return '«$name» · volume $percent%';
  }

  @override
  String get settingsToneVolume => 'Volume do toque';

  @override
  String get settingsToneVolumeSub => 'Nas colunas do monitor. Não muda o volume da música nem do intercomunicador.';

  @override
  String get settingsUnavailableOnScreen => 'Indisponível neste ecrã.';

  @override
  String get settingsVersion => 'Versão';

  @override
  String get settingsVersionSub => 'Atualizada pelo deploy no dispositivo.';

  @override
  String get settingsVoiceAssistant => 'Assistente de voz';

  @override
  String get settingsVolume => 'Volume';

  @override
  String get settingsVolumeFailed => 'Não foi possível alterar o volume';

  @override
  String settingsVolumePercent(int percent) {
    return 'Volume $percent%';
  }

  @override
  String get settingsVolumeSub => 'O volume geral deste ecrã.';

  @override
  String get settingsWakeWord => 'Palavra de ativação';

  @override
  String settingsWakeWordSub(String wakePhrase) {
    return 'Diga \"$wakePhrase\" para falar com o assistente.';
  }

  @override
  String get settingsWebBrowser => 'Navegador web';

  @override
  String get shellDoorbellWontRing => 'A campainha não vai tocar neste ecrã';

  @override
  String get shellNoHaConnection => 'Sem ligação ao Home Assistant';

  @override
  String get shellRetryingAuto => 'A tentar de novo automaticamente…';

  @override
  String get shellScreenSettings => 'Definições do ecrã';

  @override
  String get calendarHolidayNewYear => 'Ano Novo';

  @override
  String get calendarHolidayCarnival => 'Carnaval';

  @override
  String get calendarHolidayGoodFriday => 'Sexta-feira Santa';

  @override
  String get calendarHolidayEaster => 'Páscoa';

  @override
  String get calendarHolidayFreedomDay => 'Dia da Liberdade';

  @override
  String get calendarHolidayLabourDay => 'Dia do Trabalhador';

  @override
  String get calendarHolidayPortugalDay => 'Dia de Portugal';

  @override
  String get calendarHolidayCorpusChristi => 'Corpo de Deus';

  @override
  String get calendarHolidaySaintAnthony => 'Santo António';

  @override
  String get calendarHolidayAssumption => 'Assunção de Nossa Senhora';

  @override
  String get calendarHolidayRepublicDay => 'Implantação da República';

  @override
  String get calendarHolidayAllSaints => 'Todos-os-Santos';

  @override
  String get calendarHolidayRestorationOfIndependence => 'Restauração da Independência';

  @override
  String get calendarHolidayImmaculateConception => 'Imaculada Conceição';

  @override
  String get calendarHolidayChristmas => 'Natal';

  @override
  String eventNotConfirmed(String title) {
    return 'O Home Assistant não confirmou o evento \"$title\"';
  }

  @override
  String get eventSuggestionDinner => 'Jantar';

  @override
  String get eventSuggestionLunch => 'Almoço';

  @override
  String get eventSuggestionAppointment => 'Consulta';

  @override
  String get eventSuggestionBirthday => 'Aniversário';

  @override
  String get eventSuggestionSchool => 'Escola';

  @override
  String get eventSuggestionGym => 'Ginásio';

  @override
  String get eventSuggestionMeeting => 'Reunião';

  @override
  String eventCreatedAllDay(String title, String date) {
    return 'Evento criado: $title · $date, dia todo';
  }

  @override
  String eventCreatedAt(String title, String date, String time) {
    return 'Evento criado: $title · $date, $time';
  }

  @override
  String eventDurationDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: '$count dias', one: '1 dia');
    return '$_temp0';
  }

  @override
  String get eventNewTitle => 'Novo evento';

  @override
  String get eventFieldTitle => 'TÍTULO';

  @override
  String get eventTitleHint => 'Ex.: Jantar com amigos';

  @override
  String get eventFieldForWhom => 'PARA QUEM';

  @override
  String get eventNoWritableCalendar => 'Nenhum calendário com escrita configurado.';

  @override
  String get eventFieldDate => 'DATA';

  @override
  String eventFieldEndDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: 'FIM · $count DIAS', one: 'FIM · 1 DIA');
    return '$_temp0';
  }

  @override
  String get eventFieldEnd => 'FIM';

  @override
  String get eventFieldStart => 'INÍCIO';

  @override
  String get eventSameDay => 'Mesmo dia';

  @override
  String get eventFieldTime => 'HORÁRIO';

  @override
  String get eventAllDay => 'Dia inteiro';

  @override
  String eventStartOn(String date) {
    return 'Início · $date';
  }

  @override
  String get eventStart => 'Início';

  @override
  String eventEndOn(String date) {
    return 'Fim · $date';
  }

  @override
  String get eventEnd => 'Fim';

  @override
  String eventDuration(String duration) {
    return 'Duração: $duration';
  }

  @override
  String get eventFieldPlace => 'LOCAL';

  @override
  String get eventPlaceHint => 'Ex.: Casa da avó';

  @override
  String get eventFieldRepeat => 'REPETIR';

  @override
  String get eventRepeatNone => 'Não repete';

  @override
  String get eventRepeatDaily => 'Todos os dias';

  @override
  String get eventRepeatWeekly => 'Todas as semanas';

  @override
  String get eventRepeatMonthly => 'Todos os meses';

  @override
  String get eventFieldNotes => 'NOTAS';

  @override
  String get eventNotesHint => 'Detalhes, o que levar, contactos…';

  @override
  String get eventSave => 'Guardar evento';

  @override
  String get eventNoCalendarToSave => 'Sem calendário onde guardar';

  @override
  String eventWillBeAddedTo(String name) {
    return 'Será adicionado ao calendário de $name';
  }

  @override
  String get eventTitleRequired => 'Escreva um título para guardar';

  @override
  String get calendarViewDay => 'Dia';

  @override
  String get calendarViewWeek => 'Semana';

  @override
  String get calendarViewMonth => 'Mês';

  @override
  String get calendarViewAgenda => 'Agenda';

  @override
  String calendarDaySubtitleToday(String year, String week) {
    return 'Hoje · $year · Semana $week';
  }

  @override
  String calendarDaySubtitle(String year, String week) {
    return '$year · Semana $week';
  }

  @override
  String calendarWeekSubtitle(String week, String range) {
    return 'Semana $week · $range';
  }

  @override
  String get calendarMonthHint => 'Toque num dia para ver o detalhe';

  @override
  String calendarAgendaSubtitle(String weekday, String date) {
    return 'Próximas 3 semanas, a partir de $weekday, $date';
  }

  @override
  String get calendarDayFree => 'Dia livre';

  @override
  String get calendarNothingScheduled => 'Nada agendado';

  @override
  String get calendarDayIsFree => 'Este dia está livre.';

  @override
  String get calendarAllDayStacked => 'DIA\nTODO';

  @override
  String get calendarNoAllDayEvents => 'Sem eventos de dia inteiro';

  @override
  String get calendarDaySummary => 'Resumo do dia';

  @override
  String calendarEventCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: '$count eventos', one: '1 evento');
    return '$_temp0';
  }

  @override
  String get calendarUpcomingHolidays => 'Próximos feriados';

  @override
  String calendarMore(int count) {
    return '+$count mais';
  }

  @override
  String get calendarAllDay => 'Dia todo';

  @override
  String get calendarDayFreeNothingScheduled => 'Dia livre · nada agendado';

  @override
  String forecastSubtitleDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: 'Próximos $count dias', one: 'Próximo dia');
    return '$_temp0';
  }

  @override
  String forecastSubtitleDaysUpdated(int count, String time) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Próximos $count dias · atualizada às $time',
      one: 'Próximo dia · atualizada às $time',
    );
    return '$_temp0';
  }

  @override
  String get forecastSubtitleHours => 'Próximas 48 horas';

  @override
  String forecastSubtitleHoursUpdated(String time) {
    return 'Próximas 48 horas · atualizada às $time';
  }

  @override
  String get forecastNoEntity => 'Nenhuma entidade de meteorologia configurada.';

  @override
  String get forecastLoadFailed => 'Não foi possível obter a previsão.';

  @override
  String get forecastLoading => 'A carregar a previsão…';

  @override
  String get forecastUnavailable => 'Previsão indisponível.';

  @override
  String get forecastTodayDotHint => 'O ponto na barra de hoje marca a temperatura atual.';

  @override
  String get forecastHoursHint => 'Toque no gráfico ou numa hora para ver o detalhe.';

  @override
  String get forecastTitle => 'Previsão do tempo';

  @override
  String get forecastTabDays => 'Dias';

  @override
  String forecastTabDaysCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: '$count dias', one: '1 dia');
    return '$_temp0';
  }

  @override
  String get forecastTabHours => '48 horas';

  @override
  String get forecastNow => 'Agora';

  @override
  String forecastNowOn(String date) {
    return 'Agora · $date';
  }

  @override
  String forecastRain(String pct) {
    return 'Chuva $pct%';
  }

  @override
  String forecastWind(String speed, String unit) {
    return 'Vento $speed $unit';
  }

  @override
  String forecastMax(String temp) {
    return 'máx $temp';
  }

  @override
  String forecastMin(String temp) {
    return 'mín $temp';
  }

  @override
  String forecastSunrise(String time) {
    return 'Nascer $time';
  }

  @override
  String forecastSunset(String time) {
    return 'Pôr $time';
  }

  @override
  String forecastHeadToday(String day) {
    return '$day · HOJE';
  }

  @override
  String get weatherNoWarnings => 'Sem avisos em vigor';

  @override
  String weatherWarningFrom(String when) {
    return 'a partir de $when';
  }

  @override
  String weatherWarningUntil(String when) {
    return 'até $when';
  }

  @override
  String get weatherWarningActive => 'Aviso em vigor';

  @override
  String get weatherWarningLabel => 'AVISO';

  @override
  String get weatherWarningGreen => 'Verde';

  @override
  String get weatherWarningYellow => 'Amarelo';

  @override
  String get weatherWarningOrange => 'Laranja';

  @override
  String get weatherWarningRed => 'Vermelho';

  @override
  String weatherUvAtHour(String time) {
    return 'Às $time';
  }

  @override
  String weatherUvAtHourWithMax(String time, String max, String maxTime) {
    return 'Às $time · máx. $max às $maxTime';
  }

  @override
  String weatherUvNowWithMax(String max, String maxTime) {
    return 'Agora · máx. $max às $maxTime';
  }

  @override
  String get weatherUvTodayMax => 'Máximo previsto para hoje';

  @override
  String get weatherUvLow => 'Baixo';

  @override
  String get weatherLevelModerate => 'Moderado';

  @override
  String get weatherLevelHigh => 'Elevado';

  @override
  String get weatherLevelVeryHigh => 'Muito elevado';

  @override
  String get weatherUvExtreme => 'Extremo';

  @override
  String get weatherUvLabel => 'ÍNDICE UV';

  @override
  String get weatherUvNoSun => 'Sem sol';

  @override
  String get weatherFireRiskLabel => 'RISCO DE INCÊNDIO';

  @override
  String get weatherFireLow => 'Reduzido';

  @override
  String get weatherFireMaximum => 'Máximo';

  @override
  String get weatherFireAdvice => 'Evite fogueiras e queimadas';

  @override
  String get weatherFireTodayIpma => 'Hoje · previsão do IPMA';

  @override
  String weatherAtTime(String time) {
    return 'às $time';
  }

  @override
  String weatherTomorrowAtTime(String time) {
    return 'amanhã às $time';
  }

  @override
  String weatherDayAtTime(String day, String time) {
    return '$day às $time';
  }

  @override
  String get homeHouseTitle => 'Casa';

  @override
  String get homeHolidayTag => 'FERIADO';

  @override
  String get homeAllDayTag => 'DIA TODO';

  @override
  String get homeNow => 'Agora';

  @override
  String get homeTasksTitle => 'Tarefas';

  @override
  String get homeTasksNothingToday => 'Nada para hoje';

  @override
  String homeTasksDone(int done, int total) {
    return '$done de $total feitas';
  }

  @override
  String get homeNoTasksToday => 'Sem tarefas para hoje';

  @override
  String get homeEnjoyFreeDay => 'Aproveitem o dia livre.';

  @override
  String get homeMealsTitle => 'Refeições';

  @override
  String get homeMealPlan => '+ Planear';

  @override
  String homeMealOut(String dish) {
    return 'Fora · $dish';
  }

  @override
  String homeMealDelivery(String dish) {
    return '$dish · Encomenda';
  }

  @override
  String get homeMealTomorrowUnplanned => 'Amanhã: por planear';

  @override
  String homeMealTomorrow(String dish) {
    return 'Amanhã: $dish';
  }

  @override
  String get homeShoppingTitle => 'Compras';

  @override
  String get homeNoList => 'Sem lista';

  @override
  String homeSeeAllCount(int count) {
    return 'Ver todos ($count)';
  }

  @override
  String get homeOpenList => 'Abrir lista';

  @override
  String get kitchenRecipeDefaultTitle => 'Receita';

  @override
  String get kitchenVoiceNextStep => 'Por voz · «próximo passo»';

  @override
  String get kitchenVoiceRepeat => 'Por voz · «repete»';

  @override
  String get kitchenVoiceBack => 'Por voz · «volta atrás»';

  @override
  String kitchenVoiceStep(int step) {
    return 'Por voz · passo $step';
  }

  @override
  String kitchenStepN(int step) {
    return 'Passo $step';
  }

  @override
  String get kitchenTimerEndedShort => 'acabou!';

  @override
  String kitchenTimerPaused(String time) {
    return '$time · pausa';
  }

  @override
  String get kitchenExitTitle => 'Sair da receita?';

  @override
  String kitchenExitBodyWithTimer(int step, int total) {
    return 'Está no passo $step de $total. O temporizador para e a receita fecha. Pode minimizar e voltar depois pela bolha.';
  }

  @override
  String kitchenExitBody(int step, int total) {
    return 'Está no passo $step de $total. A receita fecha. Pode minimizar e voltar depois pela bolha.';
  }

  @override
  String get kitchenExitVoiceHint => 'Diga «Ok Nabu, sair», «minimizar» ou «continuar».';

  @override
  String get kitchenContinue => 'Continuar';

  @override
  String get kitchenMinimize => 'Minimizar';

  @override
  String get kitchenExit => 'Sair';

  @override
  String get kitchenModeLabel => 'MODO COZINHAR';

  @override
  String kitchenProgress(int step, String ofTotal) {
    return 'Passo $step $ofTotal';
  }

  @override
  String kitchenOfTotal(int total) {
    return 'de $total';
  }

  @override
  String get kitchenAllSteps => 'Todos os passos';

  @override
  String get kitchenTabStep => 'Passo';

  @override
  String kitchenTabIngredients(int count) {
    return 'Ingredientes · $count';
  }

  @override
  String get kitchenTimerRunning => 'Temporizador a contar';

  @override
  String get kitchenPause => 'Pausar';

  @override
  String get kitchenTimeUp => 'O tempo acabou!';

  @override
  String get kitchenStopAlarm => 'Parar alarme';

  @override
  String kitchenTimerMinutes(int minutes) {
    return 'Temporizador · $minutes min';
  }

  @override
  String get kitchenStart => 'Iniciar';

  @override
  String kitchenIngredientsReady(int ready, int total) {
    return '$ready de $total prontos';
  }

  @override
  String get kitchenIngredientsTapHint => 'Toque para riscar o que já tem à mão';

  @override
  String get kitchenNoServings => 'A receita não indica para quantas pessoas é';

  @override
  String kitchenNoServingsReady(int ready, int total) {
    return 'A receita não indica para quantas pessoas é · $ready de $total prontos';
  }

  @override
  String get kitchenIngredients => 'Ingredientes';

  @override
  String get kitchenServesFor => 'Para';

  @override
  String kitchenScaledNote(String from, String to) {
    return 'Quantidades ajustadas de $from para $to. Os tempos dos passos não mudam.';
  }

  @override
  String get kitchenEnjoy => 'Bom apetite!';

  @override
  String kitchenRecipeDone(int count) {
    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: 'Receita concluída · $count passos', one: 'Receita concluída · 1 passo');
    return '$_temp0';
  }

  @override
  String get kitchenReviewSteps => 'Rever os passos';

  @override
  String get kitchenExitMode => 'Sair do modo cozinhar';

  @override
  String kitchenVoiceHint(String command) {
    return 'Diga $command, «repete», «volta atrás» ou «ingredientes». O ecrã não se apaga enquanto cozinha.';
  }

  @override
  String get kitchenVoiceHintCommand => '«Ok Nabu, próximo passo»';

  @override
  String get kitchenFinish => 'Concluir';

  @override
  String kitchenPeople(int count) {
    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: '$count pessoas', one: '1 pessoa');
    return '$_temp0';
  }

  @override
  String kitchenBubbleStep(int step, int total) {
    return 'Passo $step/$total';
  }

  @override
  String get kitchenTimerEnded => 'Acabou!';

  @override
  String kitchenBubbleSemantics(String title) {
    return 'Voltar à receita $title';
  }

  @override
  String kitchenBubbleSemanticsTimer(String title, String time) {
    return 'Voltar à receita $title, temporizador $time';
  }

  @override
  String kitchenBubbleSemanticsTimerEnded(String title) {
    return 'Voltar à receita $title, temporizador acabou';
  }

  @override
  String get choresOnlyThisDay => 'Só neste dia';

  @override
  String get choresEveryDay => 'Todos os dias';

  @override
  String get choresWeekdays => 'Dias úteis';

  @override
  String choresMetaDue(String repeat, String time) {
    return '$repeat · até às $time';
  }

  @override
  String get tasksTitle => 'Tarefas';

  @override
  String tasksWeekdayDate(String weekday, String date) {
    return '$weekday, $date';
  }

  @override
  String get tasksSummaryNone => 'sem tarefas';

  @override
  String tasksSummaryDone(int done, int total) {
    return '$done de $total feitas';
  }

  @override
  String get tasksNew => 'Nova tarefa';

  @override
  String get tasksEdit => 'Editar tarefa';

  @override
  String get tasksCreate => 'Criar tarefa';

  @override
  String get tasksFree => 'Livre';

  @override
  String tasksCountOf(int done, int total) {
    return '$done de $total';
  }

  @override
  String get tasksAllDone => 'Tudo feito!';

  @override
  String get tasksNoneTitle => 'Sem tarefas';

  @override
  String get tasksHouseholdFreeToday => 'Nada para a família hoje';

  @override
  String get tasksHouseholdFreeDay => 'Nada para a família neste dia';

  @override
  String tasksMemberFreeToday(String name) {
    return '$name está livre hoje';
  }

  @override
  String tasksMemberFreeDay(String name) {
    return '$name está livre neste dia';
  }

  @override
  String get tasksEmptyDayTitle => 'Sem tarefas neste dia';

  @override
  String get tasksEmptyDayBodyToday => 'Ninguém tem tarefas marcadas para hoje.';

  @override
  String tasksEmptyDayBody(String date) {
    return 'Ninguém tem tarefas marcadas para $date.';
  }

  @override
  String get tasksFieldTask => 'TAREFA';

  @override
  String get tasksNameHint => 'Ex.: Arrumar o quarto';

  @override
  String get tasksFieldWho => 'PARA QUEM';

  @override
  String get tasksFieldRepeat => 'REPETIR';

  @override
  String get tasksRepeatNone => 'Não repete';

  @override
  String get tasksRepeatDays => 'Dias específicos';

  @override
  String get tasksFieldDue => 'HORA LIMITE';

  @override
  String get tasksDueToggle => 'Até uma hora';

  @override
  String get tasksDueBy => 'Até às';

  @override
  String get tasksSuggestTidyRoom => 'Arrumar o quarto';

  @override
  String get tasksSuggestMakeBed => 'Fazer a cama';

  @override
  String get tasksSuggestDust => 'Limpar o pó';

  @override
  String get tasksSuggestHangLaundry => 'Estender a roupa';

  @override
  String get tasksSuggestWashCar => 'Lavar o carro';

  @override
  String get tasksSuggestEmptyDishwasher => 'Esvaziar a máquina da loiça';

  @override
  String get tasksSuggestTakeOutRubbish => 'Levar o lixo';

  @override
  String get tasksSuggestWaterPlants => 'Regar as plantas';

  @override
  String get mealsTitle => 'Refeições';

  @override
  String mealsWeekRange(int week, String from, String to) {
    return 'Semana $week · $from – $to';
  }

  @override
  String get mealsBreakfast => 'Pequeno-almoço';

  @override
  String get mealsLunch => 'Almoço';

  @override
  String get mealsDinner => 'Jantar';

  @override
  String get mealsPlaceHome => 'Em casa';

  @override
  String get mealsPlaceOut => 'Fora';

  @override
  String get mealsPlaceDelivery => 'Encomenda';

  @override
  String mealsCopiedTo(String dish, String meal, String weekday, int day) {
    return '$dish copiado para o $meal de $weekday, $day';
  }

  @override
  String get mealsUndo => 'Desfazer';

  @override
  String get mealsCopyHere => 'Copiar para aqui';

  @override
  String get mealsPlan => 'Planear';

  @override
  String get mealsRecipe => 'Receita';

  @override
  String get mealsRecipeNoSteps => 'a página da receita não tem passos';

  @override
  String get mealsFieldDish => 'PRATO';

  @override
  String get mealsDishHint => 'Ex.: Sopa de legumes';

  @override
  String get mealsOpenSite => 'Abrir o site';

  @override
  String get mealsOpening => 'A abrir…';

  @override
  String get mealsKitchenMode => 'Modo cozinhar';

  @override
  String mealsRecipeSearch(String dish) {
    return 'receita $dish';
  }

  @override
  String get mealsSearchRecipe => 'Procurar receita na internet';

  @override
  String get mealsFieldFavorites => 'FAVORITOS';

  @override
  String get mealsFieldWhere => 'ONDE';

  @override
  String get mealsFieldTime => 'HORA';

  @override
  String get mealsFieldNotes => 'NOTAS';

  @override
  String get mealsNoteHint => 'Ex.: descongelar de manhã';

  @override
  String get mealsDishToastFruit => 'Torradas e fruta';

  @override
  String get mealsDishOatPancakes => 'Panquecas de aveia';

  @override
  String get mealsDishYogurtGranola => 'Iogurte com granola';

  @override
  String get mealsDishPorridge => 'Papas de aveia';

  @override
  String get mealsDishScrambledEggs => 'Ovos mexidos';

  @override
  String get mealsDishSoupSandwich => 'Sopa e sandes';

  @override
  String get mealsDishTunaSalad => 'Salada de atum';

  @override
  String get mealsDishBitoque => 'Bitoque';

  @override
  String get mealsDishVegetablePasta => 'Massa com legumes';

  @override
  String get mealsDishGrilledChicken => 'Frango grelhado';

  @override
  String get mealsDishBacalhauBras => 'Bacalhau à Brás';

  @override
  String get mealsDishDuckRice => 'Arroz de pato';

  @override
  String get mealsDishBolognese => 'Massa à bolonhesa';

  @override
  String get mealsDishRoastChicken => 'Frango assado';

  @override
  String get mealsDishVegetableSoup => 'Sopa de legumes';

  @override
  String get mealsDishGrilledSalmon => 'Salmão grelhado';

  @override
  String get mealsDishLasagne => 'Lasanha';

  @override
  String get mealsDishPizza => 'Pizza';

  @override
  String get listsTitle => 'Listas';

  @override
  String get listsNew => 'Nova lista';

  @override
  String get listsNoneInHa => 'Nenhuma lista no Home Assistant';

  @override
  String get listsAllDone => 'Tudo feito';

  @override
  String listsItemsPending(int count) {
    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: '$count artigos por fazer', one: '1 artigo por fazer');
    return '$_temp0';
  }

  @override
  String listsPendingCount(int count) {
    return '$count por fazer';
  }

  @override
  String get listsClearDone => 'Limpar concluídos';

  @override
  String get listsAddItem => 'Adicionar artigo…';

  @override
  String get listsNothingPending => 'Nada por fazer nesta lista';

  @override
  String listsDoneCount(int count) {
    return 'Concluídos ($count)';
  }

  @override
  String get listsMessagesTitle => 'Recados';

  @override
  String listsMessagesUnseen(int count) {
    return '$count por ver';
  }

  @override
  String get listsMessagesNone => 'Sem recados';

  @override
  String get listsMessagesAllSeen => 'Todos vistos';

  @override
  String get listsMessagesExpiry => 'apagam-se ao fim de 7 dias';

  @override
  String get listsMessagesEmptyBody => 'Os recados deixados por voz aparecem aqui até alguém os ver, e apagam-se sozinhos ao fim de 7 dias.';

  @override
  String get listsMessagesUnseenBadge => 'Por ver';

  @override
  String get listsMessagesMarkSeen => 'Marcar como visto';

  @override
  String listsMessagesDeletesIn(int count) {
    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: 'Apaga-se em $count dias', one: 'Apaga-se amanhã');
    return '$_temp0';
  }

  @override
  String listsCreated(String name) {
    return 'Lista criada: $name';
  }

  @override
  String get listsFieldName => 'NOME';

  @override
  String get listsNameHint => 'Ex.: Arrumações do sótão';

  @override
  String get listsCreateShort => 'Criar';

  @override
  String get listsFieldIcon => 'ÍCONE';

  @override
  String get listsCreate => 'Criar lista';

  @override
  String get itemNew => 'Novo artigo';

  @override
  String get itemEdit => 'Editar artigo';

  @override
  String get itemFieldItem => 'ARTIGO';

  @override
  String get itemFieldQuantity => 'QUANTIDADE';

  @override
  String get itemNoQuantity => 'Sem quantidade';

  @override
  String get itemFieldNote => 'NOTA';

  @override
  String get itemNoteHint => 'Ex.: em grão, marca, sem lactose…';

  @override
  String get itemSuggestOliveOil => 'Azeite';

  @override
  String get itemSuggestRice => 'Arroz';

  @override
  String get itemSuggestButter => 'Manteiga';

  @override
  String get itemSuggestFruit => 'Fruta';

  @override
  String get itemSuggestWater => 'Água';

  @override
  String get itemSuggestToiletPaper => 'Papel higiénico';

  @override
  String get itemSuggestCheese => 'Queijo';

  @override
  String get itemSuggestMilk => 'Leite';

  @override
  String get itemSuggestBread => 'Pão';

  @override
  String get itemSuggestEggs => 'Ovos';

  @override
  String get itemSuggestIbuprofen => 'Ibuprofeno';

  @override
  String get itemSuggestParacetamol => 'Paracetamol';

  @override
  String get itemSuggestSaline => 'Soro fisiológico';

  @override
  String get itemSuggestThermometer => 'Termómetro';

  @override
  String get itemSuggestPlasters => 'Pensos rápidos';

  @override
  String get itemSuggestBatteries => 'Pilhas';

  @override
  String get itemSuggestLightBulbs => 'Lâmpadas';

  @override
  String get itemSuggestSilicone => 'Silicone';

  @override
  String get itemSuggestScrews => 'Parafusos';

  @override
  String get todoUnitPieceOne => 'un.';

  @override
  String get todoUnitPieceMany => 'un.';

  @override
  String get todoUnitPackOne => 'pacote';

  @override
  String get todoUnitPackMany => 'pacotes';

  @override
  String get todoUnitDozenOne => 'dúzia';

  @override
  String get todoUnitDozenMany => 'dúzias';

  @override
  String get todoNotConfirmed => 'O Home Assistant não confirmou a alteração à lista';

  @override
  String get todoNoConnection => 'Sem ligação ao Home Assistant';

  @override
  String get familyHolidays => 'Feriados';

  @override
  String get entitiesNotConfirmed => 'O Home Assistant não confirmou a alteração';

  @override
  String get uiOptionalSuffix => '(opcional)';

  @override
  String get uiSaving => 'A guardar…';

  @override
  String uiActionFailed(String reason) {
    return 'Não foi possível concluir: $reason';
  }

  @override
  String get keyboardSpace => 'espaço';

  @override
  String get keyboardFloat => 'Flutuar';

  @override
  String get powerSensorIconGeneric => 'Genérico';

  @override
  String get powerSensorIconWasher => 'Máquina de lavar';

  @override
  String get powerSensorIconFridge => 'Frigorífico';

  @override
  String get powerSensorIconAirConditioning => 'Ar condicionado';

  @override
  String get powerSensorIconHeatPump => 'Bomba de calor (AQS)';

  @override
  String get powerSensorIconOven => 'Forno';

  @override
  String get optimisticMusicNotConfirmed => 'O Music Assistant não confirmou a alteração';

  @override
  String get miscMusicNoSpeakers => 'Sem colunas';

  @override
  String miscMusicSpeakersMore(String name, int count) {
    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: '$count colunas', one: '1 coluna');
    return '$name + $_temp0';
  }

  @override
  String get miscMusicUnavailable => 'Music Assistant indisponível';

  @override
  String get miscMusicChooseSpeaker => 'Escolha uma coluna';

  @override
  String miscMusicCannotGroup(String speaker, String target) {
    return '$speaker não pode tocar em grupo com $target';
  }

  @override
  String get miscMusicNotConnected => 'Music Assistant não está ligado';

  @override
  String miscMusicNoReply(String command) {
    return 'Sem resposta do Music Assistant ($command)';
  }

  @override
  String get haCreateListsDeviceOnly => 'Criar listas só funciona no ecrã da casa';

  @override
  String get themeLight => 'Claro';

  @override
  String get themeDark => 'Escuro';

  @override
  String get themeMqttSelectName => 'Tema';

  @override
  String doorIndoorNotYetConnected(String host) {
    return 'Ainda sem ligação ao intercomunicador de casa ($host).';
  }

  @override
  String get doorIndoorLinkStopped => 'A ligação ao intercomunicador de casa parou; a religar.';

  @override
  String doorIndoorStartFailed(String details) {
    return 'Não consegui arrancar a ligação ao intercomunicador de casa: $details';
  }

  @override
  String doorIndoorNoLibrary(String path) {
    return 'Falta a biblioteca do intercomunicador ($path).';
  }

  @override
  String doorIndoorSdkFailed(String code) {
    return 'O SDK do intercomunicador não arrancou (erro $code).';
  }

  @override
  String get doorIndoorBadPassword => 'Utilizador ou palavra-passe do intercomunicador de casa errados.';

  @override
  String get doorIndoorLocked => 'O intercomunicador de casa bloqueou o acesso (demasiadas tentativas); nova tentativa em 10 min.';

  @override
  String doorIndoorStoppedResponding(String code) {
    return 'O intercomunicador de casa deixou de responder (erro $code); a religar.';
  }

  @override
  String doorIndoorLoginFailed(String host, String code) {
    return 'Não consegui ligar ao intercomunicador de casa ($host, erro $code).';
  }

  @override
  String get doorIndoorNotConfigured => 'O intercomunicador de casa não está configurado neste ecrã (INDOOR_HOST).';

  @override
  String get doorSipConnecting => 'A ligar à estação principal (SIP)…';

  @override
  String doorSipNoConnection(String server) {
    return 'Sem ligação à estação principal (SIP $server).';
  }

  @override
  String doorSipStartFailed(String details) {
    return 'Não consegui arrancar a extensão SIP: $details';
  }

  @override
  String get doorSipRegistrationRefused => 'Registo SIP recusado (número/senha). Verifique a extensão e a password de admin.';

  @override
  String get doorSipDeviceOnly => 'A extensão SIP só funciona no dispositivo, não na pré-visualização web.';

  @override
  String get doorCameraReconnecting => 'A reconectar à câmara…';

  @override
  String get doorCameraConnecting => 'A ligar à câmara da porta do prédio…';

  @override
  String doorOpenFailed(String status) {
    return 'Não foi possível abrir a porta (HTTP $status)';
  }

  @override
  String doorTalkRefused(String status) {
    return 'A porta não aceitou falar agora (HTTP $status)';
  }

  @override
  String get settingsBrowserEngineDuckSub => 'duckduckgo.com · não guarda o que pesquisa';

  @override
  String get settingsBrowserEngineEcosiaSub => 'ecosia.org · planta árvores com as pesquisas';

  @override
  String get browserMenuAddToMeal => 'Adicionar a uma refeição';

  @override
  String get browserMenuAddToMealSub => 'Fica com o link desta página';

  @override
  String get browserMenuAddToMealNoSite => 'Abra a página de um site primeiro';

  @override
  String get browserMenuSendToPhone => 'Enviar para o telemóvel';

  @override
  String get browserMenuHome => 'Página inicial';

  @override
  String browserMealAddedToday(String meal) {
    return 'Adicionado ao $meal de hoje, com o link';
  }

  @override
  String browserMealAddedTomorrow(String meal) {
    return 'Adicionado ao $meal de amanhã, com o link';
  }

  @override
  String browserMealAddedOn(String meal, String day) {
    return 'Adicionado ao $meal de $day, com o link';
  }

  @override
  String get browserMealDish => 'PRATO';

  @override
  String get browserMealDishHint => 'Nome do prato';

  @override
  String browserMealKeepsLink(String site) {
    return 'Fica com o link: $site';
  }

  @override
  String get browserMealDay => 'DIA';

  @override
  String get browserMealMeal => 'REFEIÇÃO';

  @override
  String get browserMealSlotFree => 'livre';

  @override
  String browserMealReplaces(String dish, String meal) {
    return 'Já há $dish neste $meal. Ao adicionar, substitui.';
  }

  @override
  String get browserMealReplace => 'Substituir';

  @override
  String get settingsBrowserOpenSub => 'Abre com a página inicial e o modo escolhidos nas definições do navegador.';

  @override
  String get settingsBrowserSettings => 'Definições do navegador';

  @override
  String get settingsBrowserSettingsSub => 'Página inicial, motor de busca e como abre.';

  @override
  String get settingsBrowserManage => 'Gerir';

  @override
  String get settingsBrowserTitle => 'Navegador web';

  @override
  String get settingsBrowserSubtitle => 'Escolha a página inicial, o motor de busca e como o navegador abre.';

  @override
  String get settingsBrowserOpen => 'Abrir navegador';

  @override
  String get settingsBrowserEngine => 'Motor de busca';

  @override
  String get settingsBrowserEngineSub => 'Usado quando escreve algo que não é um endereço.';

  @override
  String get settingsBrowserMode => 'Abrir por defeito';

  @override
  String get settingsBrowserModeSub => 'Como o navegador aparece ao abrir. Pode sempre mudar na barra do navegador.';

  @override
  String get settingsBrowserHome => 'Página inicial';

  @override
  String get settingsBrowserHomeSub => 'O que aparece ao abrir e no botão de início.';

  @override
  String get settingsBrowserHomeStart => 'Favoritos e pesquisa';

  @override
  String get settingsBrowserHomeStartSub => 'A página inicial do navegador';

  @override
  String get settingsBrowserHomeHaMissing => 'Ainda sem ligação ao Home Assistant';

  @override
  String get settingsBrowserHomeOther => 'Outra página';

  @override
  String get settingsBrowserHomeOtherSub => 'Escolha um endereço';

  @override
  String get settingsBrowserHomeUrlHint => 'Toque para escrever o endereço';

  @override
  String get settingsBrowserModeWindow => 'Janela flutuante';

  @override
  String get settingsBrowserModeWindowSub => 'A app continua por trás';

  @override
  String get settingsBrowserModeModal => 'Modal';

  @override
  String get settingsBrowserModeModalSub => 'Centrado, fundo escurecido';

  @override
  String get settingsBrowserModeFull => 'Ecrã inteiro';

  @override
  String get settingsBrowserModeFullSub => 'Ocupa o ecrã todo';

  @override
  String get settingsIntercomOff => 'Intercomunicador desativado';

  @override
  String get settingsIntercomOffSub => 'Para atender a porta neste ecrã, configure a estação de porta nas definições do ecrã (/etc/bytehomedash.env).';

  @override
  String get settingsIntercomOffValue => 'Desativado';

  @override
  String get listsMessagesWrite => 'Escrever um recado…';

  @override
  String listsMessagesByVoice(String name) {
    return 'Ou por voz: «Ok Nabu, deixa um recado para $name: …»';
  }

  @override
  String get listsMessagesByVoiceEveryone => 'Ou por voz: «Ok Nabu, deixa um recado a todos: …»';

  @override
  String get recadoNewTitle => 'Novo recado';

  @override
  String get recadoNewSubtitle => 'Aparece no ecrã até alguém o ver · apaga-se ao fim de 7 dias';

  @override
  String get recadoNewEveryone => 'Todos';

  @override
  String get recadoNewText => 'RECADO';

  @override
  String get recadoNewHint => 'Ex.: O jantar está no forno, é só aquecer.';

  @override
  String get recadoNewFrom => 'DE QUEM';

  @override
  String get recadoNewAnonymous => 'Não dizer';

  @override
  String get recadoNewPhone => 'Enviar também para o telemóvel';

  @override
  String get recadoNewPhoneEveryone => 'Enviar também para os telemóveis de todos';

  @override
  String recadoNewPhoneOf(String name) {
    return 'Enviar também para o telemóvel de $name';
  }

  @override
  String get recadoNewPhoneSub => 'Pela app do Home Assistant';

  @override
  String get recadoNewSave => 'Deixar recado';

  @override
  String get recadoNewSuggestDinner => 'O jantar está no forno';

  @override
  String get recadoNewSuggestBack => 'Volto às 19h';

  @override
  String get recadoNewSuggestDontForget => 'Não se esqueçam de';
}
