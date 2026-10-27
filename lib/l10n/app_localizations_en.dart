// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get datesWeekdaysTitle => 'Monday,Tuesday,Wednesday,Thursday,Friday,Saturday,Sunday';

  @override
  String get datesWeekdaysAbbr => 'MON,TUE,WED,THU,FRI,SAT,SUN';

  @override
  String get datesWeekdayLetters => 'M,T,W,T,F,S,S';

  @override
  String get commonSave => 'Save';

  @override
  String get commonCancel => 'Cancel';

  @override
  String get commonClose => 'Close';

  @override
  String get commonDelete => 'Delete';

  @override
  String get commonRemove => 'Remove';

  @override
  String get commonEdit => 'Edit';

  @override
  String get commonAdd => 'Add';

  @override
  String get commonDone => 'Done';

  @override
  String get commonOpen => 'Open';

  @override
  String get commonBack => 'Back';

  @override
  String get commonYes => 'Yes';

  @override
  String get commonNo => 'No';

  @override
  String get commonOk => 'OK';

  @override
  String get commonToday => 'Today';

  @override
  String get commonTomorrow => 'Tomorrow';

  @override
  String get commonYesterday => 'Yesterday';

  @override
  String get commonOn => 'On';

  @override
  String get commonOff => 'Off';

  @override
  String get commonLoading => 'Loading…';

  @override
  String get commonRetry => 'Try again';

  @override
  String get commonNext => 'Next';

  @override
  String get commonPrevious => 'Previous';

  @override
  String get commonSeeAll => 'See all';

  @override
  String get commonNone => 'None';

  @override
  String get commonAuto => 'Automatic';

  @override
  String get commonUnavailable => 'Unavailable';

  @override
  String get settingsLanguage => 'Language';

  @override
  String get settingsLanguageSub => 'The screen\'s language. Automatic follows Home Assistant.';

  @override
  String get settingsLanguageAuto => 'Automatic (Home Assistant)';

  @override
  String get languageName => 'English';

  @override
  String assistantAgoDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: '$count days ago', one: '1 day ago');
    return '$_temp0';
  }

  @override
  String assistantAgoHours(int count) {
    return '$count h ago';
  }

  @override
  String assistantAgoMinutes(int count) {
    return '$count min ago';
  }

  @override
  String get assistantChooserNoPhones =>
      'Nobody has the Home Assistant app on their phone, or the person still needs to be chosen in the ByteHomeDash panel, under People.';

  @override
  String get assistantChooserNotRecognised => 'I didn’t recognise the voice. Choose who gets it on their phone.';

  @override
  String get assistantChooserSendTo => 'Send to…';

  @override
  String get assistantChooserWho => 'Who should I send it to?';

  @override
  String assistantClimateOn(String current, String target) {
    return 'On · $current → $target';
  }

  @override
  String get assistantCoverClosed => 'Closed';

  @override
  String get assistantCoverOpen => 'Open';

  @override
  String get assistantDefaultList => 'list';

  @override
  String get assistantDidntUnderstand => 'I didn’t quite get that. Could you say it another way?';

  @override
  String get assistantDone => 'Done.';

  @override
  String get assistantExamplesHeading => 'YOU CAN ASK, FOR EXAMPLE';

  @override
  String get assistantGotIt => 'Got it';

  @override
  String assistantItemsAdded(int count, String list) {
    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: '$count items in $list', one: '1 item in $list');
    return '$_temp0';
  }

  @override
  String assistantItemsPending(String list, int count) {
    return '$list · now $count to buy';
  }

  @override
  String get assistantKeyHowMuch => 'How much';

  @override
  String get assistantKeyPlay => 'Play';

  @override
  String get assistantKeyTurnOff => 'Turn off';

  @override
  String get assistantKeyTurnOn => 'Turn on';

  @override
  String get assistantKeyWhatIs => 'What is';

  @override
  String get assistantLightOff => 'Off';

  @override
  String get assistantLightOn => 'On';

  @override
  String assistantLightOnBrightness(int percent) {
    return 'On · $percent%';
  }

  @override
  String get assistantLocked => 'Locked';

  @override
  String get assistantMealsKept => 'Kept what was there';

  @override
  String get assistantMealsReplaced => 'Replaced';

  @override
  String get assistantMealsVoiceHint => 'or say “yes” or “no”';

  @override
  String get assistantMealsYesReplace => 'Yes, replace';

  @override
  String get assistantMediaPaused => 'Paused';

  @override
  String get assistantMediaPlaying => 'Playing';

  @override
  String get assistantNoConnection => 'Couldn’t reach Home Assistant. Try again.';

  @override
  String get assistantNotConfirmed => 'Home Assistant didn’t confirm the change';

  @override
  String get assistantOtherPerson => 'Someone else';

  @override
  String get assistantPhaseListening => 'Listening…';

  @override
  String get assistantPhaseReadyFresh => 'How can I help?';

  @override
  String get assistantPhaseReadyMore => 'Anything else?';

  @override
  String get assistantPhaseThinking => 'Let me see…';

  @override
  String assistantPrice(String amount, String currency) {
    return '$currency$amount';
  }

  @override
  String get assistantPromptSay => 'Say what you need…';

  @override
  String get assistantPromptTapMic => 'Tap the microphone to speak';

  @override
  String get assistantPromptType => 'Type what you need…';

  @override
  String get assistantRecognisingVoice => 'Recognising the voice…';

  @override
  String assistantResultSeen(String title) {
    return '$title · seen';
  }

  @override
  String assistantResultUndone(String title) {
    return '$title · undone';
  }

  @override
  String get assistantResults => 'Results';

  @override
  String get assistantSearchingAndWriting => 'Searching and writing… the final answer will appear shortly';

  @override
  String get assistantSeeHistory => 'See history';

  @override
  String get assistantSend => 'Send';

  @override
  String get assistantSent => 'Sent';

  @override
  String assistantSentToPhone(String name) {
    return 'Sent to $name’s phone';
  }

  @override
  String assistantServings(int count) {
    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: '$count servings', one: '1 serving');
    return '$_temp0';
  }

  @override
  String assistantSpeakerSemantics(String name) {
    return 'Talking to $name, recognised by voice';
  }

  @override
  String get assistantSpeakingNow => 'Speaking now';

  @override
  String get assistantStatusListening => 'Listening';

  @override
  String get assistantStatusReady => 'Ready';

  @override
  String get assistantStatusSpeaking => 'Answering';

  @override
  String get assistantStatusThinking => 'Thinking';

  @override
  String get assistantSubtitle => 'The house\'s assistant · Home Assistant';

  @override
  String get assistantSuggestDinner => 'What’s for dinner?';

  @override
  String get assistantSuggestDoorbell => 'Who rang the doorbell today?';

  @override
  String get assistantSuggestLightsOff => 'Turn off all the lights';

  @override
  String get assistantSuggestWeather => 'What’s the weather tomorrow?';

  @override
  String get assistantTypeHint => 'Type a question…';

  @override
  String get assistantUndo => 'Undo';

  @override
  String get assistantUnlocked => 'Unlocked';

  @override
  String assistantViews(int count) {
    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: '$count views', one: '1 view');
    return '$_temp0';
  }

  @override
  String assistantViewsMillions(String value) {
    return '${value}M views';
  }

  @override
  String assistantViewsThousands(int count) {
    return '${count}K views';
  }

  @override
  String get assistantWebLoading => 'LOADING';

  @override
  String get assistantWebNews => 'NEWS';

  @override
  String get assistantWebOther => 'ON THE WEB';

  @override
  String get assistantWebPlaces => 'PLACES NEAR HOME';

  @override
  String get assistantWebProducts => 'WHERE TO BUY';

  @override
  String get assistantWebRecipes => 'RECIPES ON THE WEB';

  @override
  String get assistantWebVideos => 'VIDEOS';

  @override
  String get assistantWriting => 'Writing…';

  @override
  String get narratorSearching1 => 'I’ll look it up online.';

  @override
  String get narratorSearching2 => 'Let me search for that.';

  @override
  String get narratorSearching3 => 'Let’s see what I can find.';

  @override
  String get narratorSearching4 => 'Searching now.';

  @override
  String get narratorStillWorking1 => 'Still looking, just a little longer.';

  @override
  String get narratorStillWorking2 => 'Almost there.';

  @override
  String get narratorStillWorking3 => 'Still searching, one moment.';

  @override
  String get narratorStillWorking4 => 'Just a little bit more.';

  @override
  String get narratorThinking1 => 'Let me think.';

  @override
  String get narratorThinking2 => 'Hmm, one moment.';

  @override
  String get narratorThinking3 => 'I’m thinking about it.';

  @override
  String get narratorThinking4 => 'Good question, let me see.';

  @override
  String recadoDayAt(String day, String time) {
    return '$day at $time';
  }

  @override
  String recadoFor(String name) {
    return 'For $name';
  }

  @override
  String get recadoForEveryone => 'For everyone';

  @override
  String recadoFrom(String name) {
    return 'from $name';
  }

  @override
  String get recadoFromUnknown => 'from someone · voice not recognised';

  @override
  String recadoGreeting(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Hi! First of all: there are $count unseen messages.',
      one: 'Hi! First of all: there’s an unseen message.',
    );
    return '$_temp0';
  }

  @override
  String get recadoLater => 'Later';

  @override
  String get recadoMarkAllSeen => 'Mark all as seen';

  @override
  String get recadoNow => 'just now';

  @override
  String recadoQuoted(String text) {
    return '“$text”';
  }

  @override
  String get recadoRow => 'Message';

  @override
  String recadoRowFrom(String name) {
    return 'Message from $name';
  }

  @override
  String recadoRowTo(String name) {
    return 'for $name';
  }

  @override
  String get recadoRowToEveryone => 'for everyone';

  @override
  String get recadoSeen => 'Seen';

  @override
  String recadoSeenBy(String name) {
    return 'Seen by $name';
  }

  @override
  String get recadoStayUntilSeen => 'They stay here until someone marks them as seen';

  @override
  String get recadoTitleEveryone => 'Message for everyone';

  @override
  String recadoTitleFor(String name) {
    return 'Message for $name';
  }

  @override
  String recadoUnseenCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: '$count unseen messages', one: '1 unseen message');
    return '$_temp0';
  }

  @override
  String get recadoVoiceHint => 'Say “Ok Nabu, seen” or “later”. Once marked as seen, it disappears from every screen.';

  @override
  String get voicesAlmostDone => 'Almost done';

  @override
  String get voicesDeleteBody =>
      'The assistant will stop recognising this voice and will no longer use this person’s calendar or list. You can register it again at any time.';

  @override
  String voicesDeleteTitle(String name) {
    return 'Delete $name’s voice?';
  }

  @override
  String voicesDeleted(String name) {
    return '$name’s voice deleted';
  }

  @override
  String voicesDoneBetter(String name) {
    return 'Done! The assistant now recognises $name’s voice better.';
  }

  @override
  String voicesDoneNew(String name) {
    return 'Done! The assistant now recognises $name’s voice.';
  }

  @override
  String voicesErrorIncompatible(String reason) {
    return 'The registered voices are from another model ($reason); delete them and register again.';
  }

  @override
  String voicesErrorNoResponse(String details) {
    return 'Voice identification didn’t respond ($details)';
  }

  @override
  String get voicesErrorUnknown => 'unknown error';

  @override
  String voicesIntroBody(String name, int count) {
    return '$name will read $count sentences aloud, one at a time, from where they usually talk to the screen, in their everyday voice.';
  }

  @override
  String voicesIntroSummary(int count) {
    return '$count sentences · about 1 minute';
  }

  @override
  String voicesIntroTakeLength(int seconds) {
    return 'Each recording lasts $seconds seconds. The assistant stays quiet meanwhile.';
  }

  @override
  String get voicesLoadError => 'Couldn’t read the registered voices.';

  @override
  String get voicesLoading => 'Loading voices…';

  @override
  String voicesMicError(String error) {
    return 'Couldn’t use the microphone ($error).';
  }

  @override
  String get voicesMoreSamples => 'More samples';

  @override
  String voicesMoreSamplesOf(String name) {
    return 'More samples of $name';
  }

  @override
  String get voicesNoPeopleBody => 'Add them in the ByteHomeDash panel in Home Assistant, under People. Then each person registers their voice here.';

  @override
  String get voicesNoPeopleTitle => 'No people yet';

  @override
  String get voicesNotInstalledBody => 'Voices can’t be registered without it. Check the installation in the ByteHomeDash panel in Home Assistant.';

  @override
  String get voicesNotInstalledTitle => 'The voice assistant isn’t installed on this screen.';

  @override
  String get voicesNotRecognised => 'The assistant doesn’t recognise this voice yet';

  @override
  String get voicesPhrase1 => 'Hi, it’s me. Turn on the living room lights and tell me what the weather’s like today.';

  @override
  String get voicesPhrase2 => 'What events do I have on the calendar for tomorrow morning?';

  @override
  String get voicesPhrase3 => 'Add milk, eggs and bread to the shopping list, please.';

  @override
  String get voicesPhrase4 => 'Play some calm music in the kitchen and turn the volume down a little.';

  @override
  String get voicesPhrase5 => 'Remind me to call grandma on Saturday at ten in the morning.';

  @override
  String voicesPhraseOf(int index, int count) {
    return 'Sentence $index of $count';
  }

  @override
  String voicesPhraseQuoted(String phrase) {
    return '“$phrase”';
  }

  @override
  String get voicesPrivacyNote =>
      'Everything stays on this screen: only a “fingerprint” of the voice is kept, never the recordings. Recognition is a convenience, not a password: it doesn’t open doors or turn off alarms.';

  @override
  String get voicesReadyHint => 'Tap Record and read the sentence aloud.';

  @override
  String get voicesRecord => 'Record';

  @override
  String get voicesRecordAgain => 'Record again';

  @override
  String voicesRecording(int seconds) {
    return 'Recording · $seconds s';
  }

  @override
  String voicesRecordingEnds(int seconds) {
    return 'Stops by itself after $seconds seconds.';
  }

  @override
  String get voicesRegister => 'Register voice';

  @override
  String get voicesRegisterFailed => 'Couldn’t register the voice.';

  @override
  String voicesRegisterOf(String name) {
    return 'Register $name’s voice';
  }

  @override
  String voicesRegistered(int count) {
    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: 'Voice registered · $count samples', one: 'Voice registered · 1 sample');
    return '$_temp0';
  }

  @override
  String voicesRejectedTakes(int count, int samples) {
    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: '$count recordings weren’t used', one: 'One recording wasn’t used');
    return '$_temp0 (too little speech), but $samples samples were kept.';
  }

  @override
  String get voicesRetry => 'I didn’t hear that well. Read it again, a little louder.';

  @override
  String voicesSamplesAdded(int count, String name) {
    return '$count more samples of $name’s voice were added.';
  }

  @override
  String voicesSamplesKept(int count, String name) {
    return '$count samples of $name’s voice were kept.';
  }

  @override
  String get voicesSaving => 'Saving the voice…';

  @override
  String get voicesSomethingWrong => 'Something went wrong';

  @override
  String get voicesStart => 'Start';

  @override
  String get voicesSubtitle => 'The assistant recognises who is speaking and uses that person’s calendar and reminders.';

  @override
  String get voicesTitle => 'Recognised voices';

  @override
  String get acModeHeat => 'Heat';

  @override
  String get acModeCool => 'Cool';

  @override
  String get acModeFan => 'Fan';

  @override
  String get acFanLow => 'Low';

  @override
  String get acFanQuiet => 'Quiet';

  @override
  String get acFanMedium => 'Medium';

  @override
  String get acFanHigh => 'High';

  @override
  String get houseLockLocked => 'Locked';

  @override
  String get houseLockUnlocked => 'Unlocked';

  @override
  String get houseGateClosed => 'Closed';

  @override
  String get houseGateOpen => 'Open';

  @override
  String get houseDoorClosed => 'Closed';

  @override
  String get houseDoorOpen => 'Open';

  @override
  String get houseLockUnlock => 'Unlock';

  @override
  String get houseLockLock => 'Lock';

  @override
  String get houseLocksSetupHint => 'Choose the locks in Home Assistant: ByteHomeDash › House';

  @override
  String roomExtraLocked(String name) {
    return '$name locked';
  }

  @override
  String roomExtraUnlocked(String name) {
    return '$name open';
  }

  @override
  String roomExtraClosed(String name) {
    return '$name closed';
  }

  @override
  String roomExtraOpen(String name) {
    return '$name open';
  }

  @override
  String get roomHighHumidity => 'High humidity';

  @override
  String get carAtHome => 'At home';

  @override
  String get carAway => 'Away';

  @override
  String get carDefaultName => 'Car';

  @override
  String get houseWeatherSunny => 'Sunny';

  @override
  String get houseWeatherClearNight => 'Clear sky';

  @override
  String get houseWeatherPartlyCloudy => 'Partly cloudy';

  @override
  String get houseWeatherCloudy => 'Cloudy';

  @override
  String get houseWeatherRainy => 'Rain';

  @override
  String get houseWeatherPouring => 'Heavy rain';

  @override
  String get houseWeatherLightning => 'Thunderstorm';

  @override
  String get houseWeatherSnowy => 'Snow';

  @override
  String get houseWeatherHail => 'Hail';

  @override
  String get houseWeatherFog => 'Fog';

  @override
  String get houseWeatherWindy => 'Wind';

  @override
  String get houseWeatherExceptional => 'Exceptional weather';

  @override
  String houseWhenToday(String time) {
    return 'today at $time';
  }

  @override
  String houseWhenYesterday(String time) {
    return 'yesterday at $time';
  }

  @override
  String houseWhenDay(String day, String time) {
    return '$day at $time';
  }

  @override
  String get houseCompassN => 'north';

  @override
  String get houseCompassNE => 'northeast';

  @override
  String get houseCompassE => 'east';

  @override
  String get houseCompassSE => 'southeast';

  @override
  String get houseCompassS => 'south';

  @override
  String get houseCompassSW => 'southwest';

  @override
  String get houseCompassW => 'west';

  @override
  String get houseCompassNW => 'northwest';

  @override
  String get houseUvLow => 'Low';

  @override
  String get houseUvModerate => 'Moderate';

  @override
  String get houseUvHigh => 'High';

  @override
  String get houseUvVeryHigh => 'Very high';

  @override
  String get houseUvExtreme => 'Extreme';

  @override
  String houseUvNow(String level) {
    return '$level now';
  }

  @override
  String get houseStationJustNow => 'weather station, just now';

  @override
  String houseStationMinutesAgo(int minutes) {
    return 'weather station, $minutes min ago';
  }

  @override
  String houseTodayDate(String weekday, String day, String month) {
    return 'Today, $weekday, $month $day';
  }

  @override
  String get houseTrendSteadyHour => 'Steady over the last hour';

  @override
  String houseTrendRisingHour(String degrees) {
    return 'Rising · +$degrees° in the last hour';
  }

  @override
  String houseTrendFallingHour(String degrees) {
    return 'Falling · −$degrees° in the last hour';
  }

  @override
  String get houseHumidity => 'Humidity';

  @override
  String houseDewPoint(String degrees) {
    return 'Dew point $degrees°';
  }

  @override
  String get houseOutdoorHumidity => 'Outdoor humidity';

  @override
  String get houseWind => 'Wind';

  @override
  String houseWindFrom(String direction) {
    return 'From the $direction';
  }

  @override
  String houseWindGustMax(String speed) {
    return 'max gust $speed';
  }

  @override
  String houseRainingRate(String rate) {
    return 'Raining · $rate mm/h';
  }

  @override
  String get houseRainAccumulatedToday => 'Total today · no rain now';

  @override
  String get houseRainToday => 'Rain today';

  @override
  String get housePressure => 'Pressure';

  @override
  String get houseTrendRising => 'Rising';

  @override
  String get houseTrendFalling => 'Falling';

  @override
  String get houseTrendSteady => 'Steady';

  @override
  String get houseAtmosphericPressure => 'Atmospheric pressure';

  @override
  String get houseUvIndex => 'UV index';

  @override
  String get houseSolarRadiation => 'Solar radiation';

  @override
  String get houseTrendIncreasing => 'Increasing';

  @override
  String get houseTrendDecreasing => 'Decreasing';

  @override
  String get houseOutdoorTemperature => 'Outdoor temperature';

  @override
  String energySummaryHome(String power) {
    return 'Right now the house uses $power';
  }

  @override
  String energySummaryHomeOwn(String power, int percent) {
    return 'Right now the house uses $power, $percent% from the sun and the battery';
  }

  @override
  String energySummaryBattery(int percent) {
    return 'battery at $percent%';
  }

  @override
  String energySummaryBatteryUntil(int percent, String time) {
    return 'battery at $percent%, lasts until $time';
  }

  @override
  String get vacuumStateDocked => 'Docked';

  @override
  String get vacuumStateCleaning => 'Cleaning';

  @override
  String get vacuumStatePaused => 'Paused';

  @override
  String get vacuumStateReturning => 'Returning to base';

  @override
  String get vacuumStateIdle => 'Stopped';

  @override
  String get vacuumStateError => 'Error';

  @override
  String get vacuumPartMainBrush => 'Main brush';

  @override
  String get vacuumPartSideBrush => 'Side brush';

  @override
  String get vacuumPartFilter => 'Filter';

  @override
  String get vacuumPartSensors => 'Sensors';

  @override
  String get vacuumPartWheels => 'Wheels';

  @override
  String get vacuumPartScaleInhibitor => 'Scale inhibitor';

  @override
  String get vacuumModeSweeping => 'Vacuum';

  @override
  String get vacuumModeMopping => 'Mop';

  @override
  String get vacuumModeSweepingAndMopping => 'Vacuum and mop';

  @override
  String get vacuumModeMoppingAfterSweeping => 'Mop after vacuuming';

  @override
  String get vacuumSuctionQuiet => 'Quiet';

  @override
  String get vacuumStandard => 'Standard';

  @override
  String get vacuumSuctionStrong => 'Strong';

  @override
  String get vacuumSuctionMax => 'Max';

  @override
  String get vacuumMopSlightlyDry => 'Slightly damp';

  @override
  String get vacuumMopMoist => 'Damp';

  @override
  String get vacuumMopWet => 'Wet';

  @override
  String get vacuumRouteQuick => 'Quick';

  @override
  String get vacuumRouteIntensive => 'Intensive';

  @override
  String get vacuumDeep => 'Deep';

  @override
  String get vacuumGeniusRoutine => 'Routine';

  @override
  String get vacuumErrorMainBrush => 'Main brush stuck';

  @override
  String get vacuumErrorMainBrushFix => 'Turn the robot over, remove hair or objects caught in the main brush and tap Resume.';

  @override
  String get vacuumErrorSideBrush => 'Side brush stuck';

  @override
  String get vacuumErrorSideBrushFix => 'Free the side brush and tap Resume.';

  @override
  String get vacuumErrorWheel => 'Wheel stuck';

  @override
  String get vacuumErrorWheelFix => 'Move the robot somewhere else and tap Resume.';

  @override
  String get vacuumErrorDrop => 'Wheels off the floor';

  @override
  String get vacuumErrorDropFix => 'Put the robot on the floor and tap Resume.';

  @override
  String get vacuumErrorBumper => 'Bumper stuck';

  @override
  String get vacuumErrorBumperFix => 'Check the bumper and tap Resume.';

  @override
  String get vacuumErrorDustBin => 'Dust bin missing';

  @override
  String get vacuumErrorDustBinFix => 'Put the dust bin back and tap Resume.';

  @override
  String get vacuumErrorWaterTank => 'Water tank missing';

  @override
  String get vacuumErrorWaterTankFix => 'Put the water tank back and tap Resume.';

  @override
  String get vacuumErrorLowBattery => 'Low battery';

  @override
  String get vacuumErrorLowBatteryFix => 'Take the robot to the base to charge.';

  @override
  String vacuumRoomFallback(int number) {
    return 'Room $number';
  }

  @override
  String get vacuumTankCleanWater => 'Clean water';

  @override
  String get vacuumTankDirtyWater => 'Dirty water';

  @override
  String get vacuumTankDustBag => 'Dust bag';

  @override
  String get vacuumTankDetergent => 'Detergent';

  @override
  String vacuumDaysLeft(int count) {
    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: '$count days', one: '1 day');
    return '$_temp0';
  }

  @override
  String vacuumBatteryHistory(String name) {
    return 'Battery · $name';
  }

  @override
  String get vacuumLocate => 'Locate';

  @override
  String vacuumSession(String area, String minutes) {
    return '$area m² in $minutes min';
  }

  @override
  String vacuumStoppedIn(String room) {
    return 'Stopped in the $room.';
  }

  @override
  String vacuumCleaningRoom(String room) {
    return 'Cleaning: $room';
  }

  @override
  String vacuumPausedRoom(String room) {
    return 'Paused: $room';
  }

  @override
  String get vacuumPausedHint => 'Tap Resume to carry on where it stopped.';

  @override
  String vacuumCleaningFinished(String session) {
    return 'Cleaning finished · $session';
  }

  @override
  String get vacuumIdleTitle => 'Stopped away from the base';

  @override
  String get vacuumIdleOffBase => 'It’s away from the base. You can start again or send it to the base.';

  @override
  String vacuumIdleInRoom(String room) {
    return 'It’s in the $room. You can start again or send it to the base.';
  }

  @override
  String get vacuumDockedWashing => 'At the base · washing the mop';

  @override
  String get vacuumDockedWashingHint => 'The station is washing the mop and refreshing its water.';

  @override
  String get vacuumDockedDrying => 'At the base · drying the mop';

  @override
  String get vacuumDryingHint => 'You can start a clean at any time.';

  @override
  String vacuumDryingLeftHint(String duration) {
    return '$duration to go. You can start a clean at any time.';
  }

  @override
  String get vacuumDockedEmptying => 'At the base · emptying the bin';

  @override
  String get vacuumDockedEmptyingHint => 'The dust goes into the station’s bag.';

  @override
  String get vacuumDockedCharging => 'At the base · charging';

  @override
  String get vacuumDockedFull => 'At the base · fully charged';

  @override
  String vacuumLastCleaning(String session) {
    return 'Last clean: $session';
  }

  @override
  String vacuumPendingConfirm(String action) {
    return '$action… waiting for Home Assistant to confirm.';
  }

  @override
  String vacuumMaintenanceNotice(String parts) {
    return 'Maintenance: $parts';
  }

  @override
  String get vacuumSeeMaintenance => 'See maintenance';

  @override
  String get vacuumMapLive => 'Live map';

  @override
  String get vacuumMap => 'Map';

  @override
  String vacuumStatHistory(String stat, String name) {
    return '$stat · $name';
  }

  @override
  String get vacuumAreaCleaned => 'Area cleaned';

  @override
  String get vacuumLastCleaningLabel => 'Last clean';

  @override
  String get vacuumTime => 'Time';

  @override
  String get vacuumDuration => 'Duration';

  @override
  String get vacuumCleaningTime => 'Cleaning time';

  @override
  String get vacuumDone => 'Done';

  @override
  String get vacuumProgress => 'Progress';

  @override
  String get vacuumTotalCleanings => 'Cleans in total';

  @override
  String get vacuumCleanings => 'Cleans';

  @override
  String get vacuumCleanAll => 'Clean everything';

  @override
  String vacuumCleanRooms(int count) {
    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: 'Clean $count rooms', one: 'Clean 1 room');
    return '$_temp0';
  }

  @override
  String get vacuumPause => 'Pause';

  @override
  String get vacuumReturnToBase => 'Return to base';

  @override
  String get vacuumResume => 'Resume';

  @override
  String get vacuumStop => 'Stop';

  @override
  String get vacuumBase => 'Base';

  @override
  String get vacuumTabCleaning => 'Cleaning';

  @override
  String get vacuumTabMaintenance => 'Maintenance';

  @override
  String get vacuumTabMore => 'More';

  @override
  String get vacuumRoomsHeaderNone => 'ROOMS · NONE · CLEANS THE WHOLE HOUSE';

  @override
  String vacuumRoomsHeaderSome(int selected, int total) {
    return 'ROOMS · $selected OF $total IN THE ORDER CHOSEN';
  }

  @override
  String get vacuumSelectAll => 'Select all';

  @override
  String get vacuumClearSelection => 'Clear selection';

  @override
  String get vacuumGeniusSubtitle => 'Smart automatic mode';

  @override
  String get vacuumGeniusHint => 'CleanGenius picks the mode, suction, mop humidity and route for each room on its own. Turn it off to choose by hand.';

  @override
  String get vacuumCleaningModeLabel => 'CLEANING MODE';

  @override
  String get vacuumSuctionLabel => 'SUCTION';

  @override
  String get vacuumMopHumidityLabel => 'MOP HUMIDITY';

  @override
  String get vacuumRouteLabel => 'ROUTE';

  @override
  String get vacuumFineTune => 'Fine tuning';

  @override
  String get vacuumInstalled => 'Installed';

  @override
  String get vacuumMissing => 'Missing';

  @override
  String get vacuumStation => 'Station';

  @override
  String get vacuumStationIdle => 'Idle';

  @override
  String get vacuumStationWashing => 'Washing';

  @override
  String get vacuumStationDrying => 'Drying';

  @override
  String get vacuumAutoEmpty => 'Auto-empty';

  @override
  String get vacuumEmptying => 'Emptying';

  @override
  String get vacuumAutoEmptyIdle => 'Idle';

  @override
  String get vacuumLowWater => 'Low water';

  @override
  String get vacuumActionEmptyBin => 'Empty dust bin';

  @override
  String get vacuumActionWashMop => 'Wash mop';

  @override
  String get vacuumActionDryMop => 'Dry mop';

  @override
  String get vacuumActionCleanBase => 'Clean the base';

  @override
  String get vacuumDryingMop => 'Drying the mop';

  @override
  String vacuumDryingProgress(int percent, String duration) {
    return '$percent% · $duration to go';
  }

  @override
  String get vacuumStationLabel => 'STATION';

  @override
  String vacuumBaseHistory(String label) {
    return '$label · base';
  }

  @override
  String get vacuumBaseActionsLabel => 'BASE ACTIONS';

  @override
  String get vacuumNoWearInfo => 'This vacuum doesn’t report how worn its parts are.';

  @override
  String vacuumPartLifeHistory(String part) {
    return '$part · life left';
  }

  @override
  String get vacuumReset => 'Reset';

  @override
  String vacuumResetAskClean(String part) {
    return 'Reset the $part counter? Do it after cleaning the part.';
  }

  @override
  String vacuumResetAskReplace(String part) {
    return 'Reset the $part counter? Do it after replacing the part.';
  }

  @override
  String get vacuumResetTo100 => 'Reset to 100%';

  @override
  String vacuumPartLeft(int percent, String time) {
    return '$percent% · $time left';
  }

  @override
  String get vacuumTotalArea => 'Total area';

  @override
  String get vacuumTotalTime => 'Total time';

  @override
  String get vacuumDnd => 'Do not disturb';

  @override
  String get vacuumDndHint => 'Doesn’t clean or speak during these hours';

  @override
  String get vacuumStartsAt => 'Starts at';

  @override
  String get vacuumEndsAt => 'Ends at';

  @override
  String get vacuumChildLock => 'Child lock';

  @override
  String get vacuumChildLockHint => 'The robot’s buttons stop working';

  @override
  String get vacuumStatsLabel => 'STATISTICS';

  @override
  String get vacuumVoiceVolume => 'Voice volume';

  @override
  String get houseTitle => 'House';

  @override
  String get houseDoorsClosed => 'Doors closed';

  @override
  String houseDoorsOpen(int count) {
    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: '$count doors open', one: '1 door open');
    return '$_temp0';
  }

  @override
  String get houseWindowsClosed => 'Windows closed';

  @override
  String houseWindowsOpen(int count) {
    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: '$count windows open', one: '1 window open');
    return '$_temp0';
  }

  @override
  String get houseLightsOff => 'Lights off';

  @override
  String houseLightsOn(int count) {
    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: '$count lights on', one: '1 light on');
    return '$_temp0';
  }

  @override
  String get roomLights => 'Lights';

  @override
  String get roomWindow => 'Window';

  @override
  String get roomBlinds => 'Blinds';

  @override
  String get acTitle => 'Air conditioning';

  @override
  String get roomVentilation => 'Ventilation';

  @override
  String get roomRooms => 'Rooms';

  @override
  String get roomAllLightsOff => 'Turn off all lights';

  @override
  String get roomVentOn => 'On';

  @override
  String get energySolar => 'Solar';

  @override
  String energyOfForecast(String amount) {
    return 'Of $amount kWh forecast';
  }

  @override
  String get energyConsumption => 'Consumption';

  @override
  String energyYesterdayThisTime(String amount) {
    return 'Yesterday at this time: $amount';
  }

  @override
  String get energySelfUse => 'Self-consumption';

  @override
  String get energyFromSunAndBattery => 'From the sun and the battery';

  @override
  String get energyGrid => 'Grid';

  @override
  String energyImportedSold(String amount) {
    return 'Imported · $amount sold';
  }

  @override
  String energyLessThanToday(int percent) {
    return '$percent% less than today';
  }

  @override
  String energyMoreThanToday(int percent) {
    return '$percent% more than today';
  }

  @override
  String get energyNowLabel => 'NOW';

  @override
  String get energyTitle => 'Energy';

  @override
  String get houseSeeMore => 'See more';

  @override
  String get energyTodayLabel => 'TODAY';

  @override
  String get energyTomorrowLabel => 'TOMORROW';

  @override
  String get energySolarForecast => 'Solar forecast';

  @override
  String get houseSecurity => 'Security';

  @override
  String get houseAllClosed => 'All closed';

  @override
  String houseOpenCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: '$count open', one: '1 open');
    return '$_temp0';
  }

  @override
  String houseLockLastOpened(String kind, String when) {
    String _temp0 = intl.Intl.selectLogic(kind, {'lock': 'Last unlocked $when', 'door': 'Last opened $when', 'other': 'Last opened $when'});
    return '$_temp0';
  }

  @override
  String houseLockOpenSince(String kind, String time) {
    String _temp0 = intl.Intl.selectLogic(kind, {'lock': 'Unlocked since $time', 'door': 'Open since $time', 'other': 'Open since $time'});
    return '$_temp0';
  }

  @override
  String houseLockOpenJustNow(String kind) {
    String _temp0 = intl.Intl.selectLogic(kind, {'lock': 'Unlocked just now', 'door': 'Opened just now', 'other': 'Opened just now'});
    return '$_temp0';
  }

  @override
  String houseFeelsLike(String degrees) {
    return 'Feels like $degrees°';
  }

  @override
  String houseTodayMaxMin(String max, String min) {
    return 'today high $max°, low $min°';
  }

  @override
  String get houseOutdoor => 'Outdoor';

  @override
  String vacuumCountCleaning(int count) {
    return '$count cleaning';
  }

  @override
  String get vacuumBothDocked => 'Both docked';

  @override
  String get vacuumAllDocked => 'All docked';

  @override
  String get vacuumNoneCleaning => 'None cleaning';

  @override
  String get vacuumTitle => 'Robot vacuums';

  @override
  String vacuumErrorInRoom(String error, String room) {
    return '$error in the $room';
  }

  @override
  String vacuumBusyFoot(String battery, String area, String minutes) {
    return 'Battery $battery% · $area m² · $minutes min';
  }

  @override
  String vacuumLastCleaningShort(String session) {
    return 'Last clean $session';
  }

  @override
  String get vacuumOfCleaning => 'of the clean';

  @override
  String get vacuumBatteryCharging => 'battery · charging';

  @override
  String get vacuumBatteryWord => 'battery';

  @override
  String get acSectionTitle => 'Air conditioning';

  @override
  String get acNone => 'No air conditioning';

  @override
  String get acAllOff => 'All off';

  @override
  String acOnOfTotal(int on, int total) {
    return '$on of $total on';
  }

  @override
  String get houseSeeAll => 'See all';

  @override
  String acNowTemp(String temp) {
    return 'Now $temp';
  }

  @override
  String get houseAllLocked => 'All locked';

  @override
  String houseAccessesOpen(int count) {
    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: '$count entrances open', one: '1 entrance open');
    return '$_temp0';
  }

  @override
  String get houseAlarmTriggered => 'Alarm triggered';

  @override
  String get houseAlarmOff => 'Alarm off';

  @override
  String get houseAlarmHome => 'Alarm home';

  @override
  String get houseAlarmAway => 'Alarm away';

  @override
  String get houseWaterHeating => 'Heating';

  @override
  String get houseWaterOff => 'Off';

  @override
  String get houseWaterReady => 'Ready';

  @override
  String get houseHotWater => 'Hot water';

  @override
  String get houseHotWaterTemperature => 'Hot water · temperature';

  @override
  String houseWaterTarget(String degrees) {
    return 'Target $degrees ºC';
  }

  @override
  String get houseHeatPump => 'Heat pump';

  @override
  String get houseJustNow => 'just now';

  @override
  String houseMinutesAgo(int minutes) {
    return '$minutes min ago';
  }

  @override
  String houseHoursAgo(int hours) {
    return '$hours h ago';
  }

  @override
  String houseDaysAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: '$count days ago', one: '1 day ago');
    return '$_temp0';
  }

  @override
  String houseMissedCalls(int count) {
    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: '$count missed calls', one: '1 missed call');
    return '$_temp0';
  }

  @override
  String get houseBuildingDoor => 'Door';

  @override
  String houseMissedShort(int count) {
    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: '$count missed', one: '1 missed');
    return '$_temp0';
  }

  @override
  String get houseIntercom => 'Intercom';

  @override
  String get cameraLive => 'LIVE';

  @override
  String get cameraUnavailable => 'Camera unavailable';

  @override
  String roomTemperatureHistory(String room) {
    return 'Temperature · $room';
  }

  @override
  String get roomNoTemperatureSensor => 'No temperature sensor';

  @override
  String roomHumidityHistory(String room) {
    return 'Humidity · $room';
  }

  @override
  String roomHumidityValue(int percent) {
    return 'humidity $percent%';
  }

  @override
  String roomWindowHistory(String room) {
    return 'Window · $room';
  }

  @override
  String get roomLightsOff => 'Off';

  @override
  String get roomBrightness => 'Brightness';

  @override
  String get roomBlindsOpening => 'Opening';

  @override
  String get roomBlindsClosing => 'Closing';

  @override
  String get roomBlindsClosed => 'Closed';

  @override
  String get roomBlindsOpen => 'Open';

  @override
  String roomBlindsOpenAt(int percent) {
    return 'Open $percent%';
  }

  @override
  String get roomBlindsHalf => 'Half';

  @override
  String get roomBlindsAperture => 'Opening';

  @override
  String get roomVentOff => 'Off';

  @override
  String acNowMode(String temp, String mode) {
    String _temp0 = intl.Intl.selectLogic(mode, {
      'heat': 'Now $temp · heating',
      'cool': 'Now $temp · cooling',
      'fan': 'Now $temp · fan',
      'other': 'Now $temp · auto',
    });
    return '$_temp0';
  }

  @override
  String acNowOff(String temp) {
    return 'Now $temp · off';
  }

  @override
  String get acTargetTemperature => 'Target temperature';

  @override
  String get acOffTurnOnToAdjust => 'Off · turn on to adjust';

  @override
  String get acModeLabel => 'MODE';

  @override
  String get acFanLabel => 'FAN';

  @override
  String get acAllUnits => 'All air conditioners';

  @override
  String get acTurnOff => 'Turn off';

  @override
  String get acTurnOn => 'Turn on';

  @override
  String acNowLower(String temp) {
    return 'now $temp';
  }

  @override
  String get acHeating => 'Heating';

  @override
  String get acCooling => 'Cooling';

  @override
  String get acVentilating => 'Fan';

  @override
  String get acNoUnits => 'No units';

  @override
  String acHouseTemp(String temp) {
    return 'House $temp';
  }

  @override
  String acHouseTempNoHeating(String temp) {
    return 'House $temp · no heating';
  }

  @override
  String acOutside(String degrees) {
    return 'Outside $degrees°';
  }

  @override
  String get acTurnOffAll => 'Turn all off';

  @override
  String get acNoneConfigured => 'No air conditioning set up.';

  @override
  String get energySolarTodayLabel => 'SOLAR TODAY';

  @override
  String get energyConsumptionLabel => 'CONSUMPTION';

  @override
  String get energySelfUseLabel => 'SELF-CONSUMPTION';

  @override
  String get energyCameFromSunOrBattery => 'Came from the sun or the battery';

  @override
  String get energySavingsLabel => 'SAVINGS';

  @override
  String get energySavingsVsGrid => 'Today, compared with grid only';

  @override
  String get energyNow => 'Now';

  @override
  String energyBatterySupplying(String power) {
    return 'Supplying $power';
  }

  @override
  String energyBatteryCharging(String power) {
    return 'Charging $power';
  }

  @override
  String get energyBatteryIdle => 'Idle';

  @override
  String get energyBatteryLastsUntil => 'At the current rate it lasts until';

  @override
  String get energyBatteryRechargesAt => 'Charges again (forecast)';

  @override
  String energyBatteryRechargesWithSun(String time) {
    return '≈ $time, with the sun';
  }

  @override
  String get energyCapacity => 'Capacity';

  @override
  String get energyGridIdle => 'No exchange';

  @override
  String energyGridImporting(String power) {
    return 'Importing $power';
  }

  @override
  String energyGridSelling(String power) {
    return 'Selling $power';
  }

  @override
  String get energyImportedToday => 'Imported today';

  @override
  String get energySoldToday => 'Sold today';

  @override
  String get energyTariffNow => 'Tariff now';

  @override
  String get energyPriceNow => 'Price now';

  @override
  String get energyOther => 'Other';

  @override
  String get energyTodayByHour => 'Today, hour by hour';

  @override
  String get energyForecast => 'Forecast';

  @override
  String get energySolarForecastTitle => 'Solar forecast';

  @override
  String get energyBattery => 'Battery';

  @override
  String get energyConsumptionNow => 'Consumption now';

  @override
  String get energyLast7Days => 'Last 7 days';

  @override
  String get energyProduced => 'Produced';

  @override
  String get energyConsumed => 'Consumed';

  @override
  String get energyExported => 'Exported';

  @override
  String energyWeekSummary(String produced, String consumed, String exported) {
    return 'Last 7 days: $produced kWh produced, $consumed kWh consumed, $exported kWh exported.';
  }

  @override
  String energyWeekSummarySavings(String produced, String consumed, String exported, String savings) {
    return 'Last 7 days: $produced kWh produced, $consumed kWh consumed, $exported kWh exported · estimated savings $savings.';
  }

  @override
  String get energyNotConfigured => 'The totals, forecast and history come from Home Assistant’s Energy dashboard, which isn’t set up.';

  @override
  String energyModalToday(String date) {
    return 'Today, $date';
  }

  @override
  String energyModalTodayUpdated(String date, String time) {
    return 'Today, $date · updated at $time';
  }

  @override
  String energyForecastPeak(String power, String time) {
    return 'Forecast peak $power · $time';
  }

  @override
  String get energyFlowLabel => 'ENERGY';

  @override
  String get energyPowerGrid => 'Power grid';

  @override
  String get energySolarProduction => 'Solar production';

  @override
  String get energyHouseBattery => 'House battery';

  @override
  String get energyHouseConsumption => 'House consumption';

  @override
  String get carLocked => 'Locked';

  @override
  String get carUnlocked => 'Unlocked';

  @override
  String get carNoState => 'No status';

  @override
  String get carCharging => 'Charging';

  @override
  String get carBatteryLow => 'Battery low';

  @override
  String get carWaitingToCharge => 'Waiting to charge';

  @override
  String get carUnplugged => 'Unplugged';

  @override
  String carUpdatedAt(String time) {
    return 'Updated at $time';
  }

  @override
  String get carRefuelSoon => 'refuel soon';

  @override
  String carChargeLimit(int percent) {
    return 'up to $percent%';
  }

  @override
  String get carPlugIn => 'plug in';

  @override
  String carFuelHistory(String name) {
    return '$name · fuel';
  }

  @override
  String carBatteryHistory(String name) {
    return '$name · battery';
  }

  @override
  String cameraSubtitle(String place) {
    return 'Camera · $place';
  }

  @override
  String get cameraLiveShort => 'Live';

  @override
  String get speakersWholeHouse => 'Whole house';

  @override
  String speakersOnly(String name) {
    return 'Only $name';
  }

  @override
  String speakersPlayingInSync(int count) {
    return '$count speakers playing in sync';
  }

  @override
  String speakersPlayingOnlyOn(String name) {
    return 'Playing only on $name';
  }

  @override
  String get speakersTitle => 'Speakers';

  @override
  String get speakersIntro => 'Tap a speaker to add it to or remove it from the group. The music keeps playing.';

  @override
  String get speakersNoConnection => 'No connection to Music Assistant.';

  @override
  String get speakersAlsoPlaying => 'ALSO PLAYING';

  @override
  String get speakersPlaying => 'Playing';

  @override
  String get speakersControl => 'Control';

  @override
  String get speakersQuickGroups => 'QUICK GROUPS';

  @override
  String get speakersGroupVolume => 'GROUP VOLUME';

  @override
  String get speakersHouseSpeakers => 'SPEAKERS IN THE HOUSE';

  @override
  String get speakersMixedBrandsNote => 'Speakers from different systems play together in a Music Assistant group. There may be a small delay between them.';

  @override
  String get speakersSpeaker => 'Speaker';

  @override
  String speakersSubOff(String model) {
    return '$model · off';
  }

  @override
  String speakersSubPlaying(String model, String title) {
    return '$model · playing $title';
  }

  @override
  String speakersSubCantGroup(String model, String name) {
    return '$model · can’t group with $name';
  }

  @override
  String get speakersChipInGroup => 'In group';

  @override
  String get speakersChipBusy => 'Busy';

  @override
  String get speakersChipFree => 'Free';

  @override
  String get musicRadio => 'Radio';

  @override
  String get musicLocalLibrary => 'Local library';

  @override
  String musicDurationHoursMinutes(int hours, int minutes) {
    return '$hours h $minutes min';
  }

  @override
  String musicDurationMinutes(int minutes) {
    return '$minutes min';
  }

  @override
  String get musicLive => 'LIVE';

  @override
  String get musicPlaylist => 'Playlist';

  @override
  String musicPlaylistBy(String owner) {
    return 'Playlist · $owner';
  }

  @override
  String get musicArtist => 'Artist';

  @override
  String get musicPodcast => 'Podcast';

  @override
  String musicPodcastBy(String owner) {
    return 'Podcast · $owner';
  }

  @override
  String get musicSaveFailed => 'Couldn’t save';

  @override
  String musicPlayingOn(String target) {
    return 'PLAYING ON $target';
  }

  @override
  String get musicQueue => 'Queue';

  @override
  String musicUpNext(int count) {
    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: 'UP NEXT · $count tracks', one: 'UP NEXT · 1 track');
    return '$_temp0';
  }

  @override
  String get musicClearQueue => 'Clear queue';

  @override
  String get musicQueueEmpty => 'The queue is empty. Tap “Add to queue” on a playlist or album.';

  @override
  String get musicFavoriteSongs => 'Favourite songs';

  @override
  String get musicFamily => 'Family';

  @override
  String get musicContextLiveRadio => 'LIVE RADIO';

  @override
  String get musicContextPlaylist => 'PLAYING FROM PLAYLIST';

  @override
  String get musicContextAlbum => 'PLAYING FROM ALBUM';

  @override
  String get musicContextArtist => 'PLAYING FROM ARTIST';

  @override
  String get musicContextPodcast => 'PLAYING FROM PODCAST';

  @override
  String get musicContextPlaying => 'NOW PLAYING';

  @override
  String get musicContextArtistRadio => 'ARTIST RADIO';

  @override
  String get musicTabListenNow => 'Listen now';

  @override
  String get musicTabSearch => 'Search';

  @override
  String get musicTabLibrary => 'Library';

  @override
  String get musicMaUnavailable => 'Music Assistant unavailable';

  @override
  String get musicMaConnecting => 'Connecting to Music Assistant…';

  @override
  String get musicMaNotFound => 'The Music Assistant add-on wasn’t found in Home Assistant.';

  @override
  String get musicGreetingMorning => 'Good morning, family';

  @override
  String get musicGreetingAfternoon => 'Good afternoon, family';

  @override
  String get musicGreetingEvening => 'Good evening, family';

  @override
  String get musicRecentlyPlayed => 'Recently played';

  @override
  String get musicInThisHouse => 'In this house';

  @override
  String get musicYourPlaylists => 'Your playlists';

  @override
  String get musicRadios => 'Radios';

  @override
  String get musicLiveNote => 'Live';

  @override
  String get musicPodcasts => 'Podcasts';

  @override
  String get musicFavoriteArtists => 'Favourite artists';

  @override
  String get musicGenrePortuguese => 'Portuguese';

  @override
  String get musicGenreClassical => 'Classical';

  @override
  String get musicGenreRelax => 'Relax';

  @override
  String get musicGenreParty => 'Party';

  @override
  String get musicGenreWorkout => 'Workout';

  @override
  String get musicGenreSleep => 'Sleep';

  @override
  String get musicGenre80s => '80s';

  @override
  String get musicSearchHint => 'Artists, songs, albums, radios or podcasts';

  @override
  String get musicRecentSearches => 'RECENT SEARCHES';

  @override
  String get musicBrowseAll => 'Browse all';

  @override
  String get musicFilterAll => 'All';

  @override
  String get musicSongs => 'Songs';

  @override
  String get musicArtists => 'Artists';

  @override
  String get musicAlbums => 'Albums';

  @override
  String get musicPlaylists => 'Playlists';

  @override
  String get musicPodcastsAndRadios => 'Podcasts and radios';

  @override
  String musicNoResults(String query) {
    return 'No results for “$query”';
  }

  @override
  String get musicNoResultsDetail => 'We searched every service connected to Music Assistant.';

  @override
  String get musicCaptionArtist => 'ARTIST';

  @override
  String get musicCaptionAlbum => 'ALBUM';

  @override
  String get musicCaptionPlaylist => 'PLAYLIST';

  @override
  String get musicCaptionRadio => 'RADIO';

  @override
  String get musicCaptionPodcast => 'PODCAST';

  @override
  String get musicTopResult => 'Top result';

  @override
  String get musicSortRecent => 'Recent';

  @override
  String get musicSortAdded => 'Added';

  @override
  String get musicLibraryEmpty => 'Nothing saved here yet.';

  @override
  String musicFavoritesSummary(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Playlist · $count songs · Music Assistant',
      one: 'Playlist · 1 song · Music Assistant',
    );
    return '$_temp0';
  }

  @override
  String get musicAlbum => 'Album';

  @override
  String musicEpisodesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: '$count episodes', one: '1 episode');
    return '$_temp0';
  }

  @override
  String musicSongsAndDuration(int count, String duration) {
    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: '$count songs, $duration', one: '1 song, $duration');
    return '$_temp0';
  }

  @override
  String get musicFavoritesDescription => 'The songs marked with a heart.';

  @override
  String get musicAddedToQueue => 'Added to queue';

  @override
  String musicPlaysOn(String target) {
    return 'Plays on $target';
  }

  @override
  String get musicColumnEpisode => 'EPISODE';

  @override
  String get musicColumnTitle => 'TITLE';

  @override
  String get musicColumnDuration => 'DURATION';

  @override
  String get musicNoTracks => 'No tracks.';

  @override
  String get musicFollowingArtist => 'You follow this artist';

  @override
  String get musicFollowing => 'Following';

  @override
  String get musicFollow => 'Follow';

  @override
  String get musicArtistRadio => 'Artist radio';

  @override
  String get musicPopular => 'Popular';

  @override
  String get musicDiscography => 'Discography';

  @override
  String get musicLoadFailed => 'Couldn’t load.';

  @override
  String get browserFavWeather => 'Weather';

  @override
  String get browserFavNews => 'News';

  @override
  String get browserUnavailable => 'The browser isn’t available on this screen.';

  @override
  String get browserKeySearch => 'Search';

  @override
  String get browserKeySend => 'Send';

  @override
  String get browserKeyGo => 'Go';

  @override
  String get browserTitle => 'Browser';

  @override
  String get browserReturnToStart => 'Back to the browser · start page';

  @override
  String browserReturnTo(String site) {
    return 'Back to the browser · $site';
  }

  @override
  String get browserVolume => 'Browser volume';

  @override
  String get browserMuted => 'Muted';

  @override
  String get browserVolumeNote => 'Only for sound from websites (videos, music). The screen volume stays the same, in Settings.';

  @override
  String browserAddressHint(String engine) {
    return 'Search $engine or type an address';
  }

  @override
  String get browserStartPage => 'Start page';

  @override
  String get browserStartTitle => 'Where to?';

  @override
  String get browserFavorites => 'FAVOURITES';

  @override
  String get browserRecentlyVisited => 'RECENTLY VISITED';

  @override
  String get browserJustNow => 'just now';

  @override
  String browserMinutesAgo(int minutes) {
    return '$minutes min ago';
  }

  @override
  String browserHoursAgo(int hours) {
    return '$hours h ago';
  }

  @override
  String get browserYesterday => 'yesterday';

  @override
  String get doorbellGroupClassic => 'Classic';

  @override
  String get doorbellGroupCustom => 'My ringtones';

  @override
  String get doorbellGroupIntercom => 'Intercom';

  @override
  String get doorbellGroupModern => 'Modern';

  @override
  String get doorbellToneAurora => 'Aurora';

  @override
  String get doorbellToneAuroraDesc => 'Slow chord, for the night';

  @override
  String get doorbellToneBolhas => 'Bubbles';

  @override
  String get doorbellToneBolhasDesc => 'Rising bubbles, playful';

  @override
  String get doorbellToneCarrilhao => 'Carillon';

  @override
  String get doorbellToneCarrilhaoDesc => 'Cascading bells';

  @override
  String get doorbellToneCustomDesc => 'Your file · plays continuously';

  @override
  String get doorbellToneDigital => 'Digital';

  @override
  String get doorbellToneDigitalDesc => 'Double intercom beep';

  @override
  String get doorbellToneDingdong => 'Ding-dong';

  @override
  String get doorbellToneDingdongDesc => 'Classic two-tone doorbell';

  @override
  String get doorbellToneDoisToques => 'Two rings';

  @override
  String get doorbellToneDoisToquesDesc => 'Electronic ring, repeated';

  @override
  String get doorbellToneHarpa => 'Harp';

  @override
  String get doorbellToneHarpaDesc => 'Delicate harp arpeggio';

  @override
  String get doorbellToneKalimba => 'Kalimba';

  @override
  String get doorbellToneKalimbaDesc => 'Thumb piano, soft';

  @override
  String get doorbellToneMarimba => 'Marimba';

  @override
  String get doorbellToneMarimbaDesc => 'Wooden notes, cheerful';

  @override
  String get doorbellToneMelodia => 'Melody';

  @override
  String get doorbellToneMelodiaDesc => 'Polyphonic monitor melody';

  @override
  String get doorbellTonePortaria => 'Concierge';

  @override
  String get doorbellTonePortariaDesc => 'The trill of building intercom monitors';

  @override
  String get doorbellTonePulsar => 'Pulsar';

  @override
  String get doorbellTonePulsarDesc => 'Synthesiser arpeggio';

  @override
  String get doorbellToneRetro => 'Retro';

  @override
  String get doorbellToneRetroDesc => '8-bit game';

  @override
  String get doorbellToneSuave => 'Gentle';

  @override
  String get doorbellToneSuaveDesc => 'Two calm tones';

  @override
  String get doorbellToneTresTons => 'Three tones';

  @override
  String get doorbellToneTresTonsDesc => 'Rising chord, short';

  @override
  String get doorbellToneTriangulo => 'Triangle';

  @override
  String get doorbellToneTrianguloDesc => 'Three metallic strikes';

  @override
  String get doorbellToneTrrrim => 'Brrring';

  @override
  String get doorbellToneTrrrimDesc => 'Electric hammer bell';

  @override
  String get doorbellToneVidro => 'Glass';

  @override
  String get doorbellToneVidroDesc => 'Crystal bells, clean';

  @override
  String get doorbellToneWestminster => 'Westminster';

  @override
  String get doorbellToneWestminsterDesc => 'Four-note chime';

  @override
  String get doorbellToneXilofone => 'Xylophone';

  @override
  String get doorbellToneXilofoneDesc => 'Quick, cheerful scale';

  @override
  String headerMax(String temp) {
    return 'High $temp°';
  }

  @override
  String headerMin(String temp) {
    return 'Low $temp°';
  }

  @override
  String headerNextHoliday(String name, String weekday, String date) {
    return 'Next holiday: $name, $weekday $date';
  }

  @override
  String get headerSeeForecast => 'See the weather forecast';

  @override
  String headerWeek(int week) {
    return 'Week $week';
  }

  @override
  String historyAtTime(String time) {
    return 'at $time';
  }

  @override
  String get historyAverage => 'Average';

  @override
  String historyDayAt(String weekday, String date, String time) {
    return '$weekday, $date at $time';
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
  String get historyFooter => 'History kept by Home Assistant (recorder). Slide your finger across the chart to see each moment.';

  @override
  String get historyInPeriod => 'in the period';

  @override
  String get historyInTotal => 'in total';

  @override
  String get historyLast24h => 'Last 24 hours';

  @override
  String get historyLast30d => 'Last 30 days';

  @override
  String get historyLast7d => 'Last 7 days';

  @override
  String get historyLastChange => 'Last change';

  @override
  String get historyMax => 'Maximum';

  @override
  String get historyMin => 'Minimum';

  @override
  String get historyNoChanges => 'no changes';

  @override
  String get historyNoData => 'No data';

  @override
  String get historyNone => 'No history';

  @override
  String get historyNow => 'Now';

  @override
  String historyPercentOfTime(int percent) {
    return '$percent% of the time';
  }

  @override
  String get historyRange24h => '24 hours';

  @override
  String get historyRange30d => '30 days';

  @override
  String get historyRange7d => '7 days';

  @override
  String historyTimeIn(String state) {
    return 'Time $state';
  }

  @override
  String historyTimes(int count) {
    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: '$count times', one: '1 time');
    return '$_temp0';
  }

  @override
  String historyTodayAt(String time) {
    return 'Today at $time';
  }

  @override
  String get intercomAnswer => 'Answer';

  @override
  String get intercomBuildingDoor => 'Building door';

  @override
  String get intercomCallAtBuildingDoor => 'Call at the building door';

  @override
  String intercomCallCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: '$count calls', one: '1 call');
    return '$_temp0';
  }

  @override
  String get intercomConnecting => 'Connecting…';

  @override
  String get intercomDoorCalls => 'Door calls';

  @override
  String get intercomDoorNotOpened => 'Door was not opened';

  @override
  String get intercomDoorNotOpenedSub => 'No device opened the door.';

  @override
  String get intercomDoorOpened => 'Door open';

  @override
  String get intercomDoorOpenedSub => 'During or right after the call.';

  @override
  String get intercomDoorUnlocked => 'Door unlocked';

  @override
  String get intercomEmptySub => 'Whenever someone rings the doorbell, we keep a picture of the door here, the time and what happened.';

  @override
  String get intercomEmptyTitle => 'No calls yet since this screen started logging them.';

  @override
  String get intercomEndOfList => 'End of the list. This screen keeps the last 200 calls.';

  @override
  String get intercomHangUp => 'Hang up';

  @override
  String get intercomHistory => 'History';

  @override
  String get intercomIgnore => 'Ignore';

  @override
  String get intercomIgnoreHint => 'Ignore only closes this screen. The indoor station keeps ringing and can be answered there.';

  @override
  String get intercomInCall => 'In a call';

  @override
  String get intercomLive => 'Live';

  @override
  String get intercomLoggedHere => 'Intercom · logged by this screen';

  @override
  String get intercomMicOff => 'Mic off';

  @override
  String intercomMissedCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: '$count not answered', one: '1 not answered');
    return '$_temp0';
  }

  @override
  String get intercomMute => 'Mute';

  @override
  String get intercomNewTag => 'NEW';

  @override
  String get intercomNewestFirst => 'Newest first';

  @override
  String get intercomNoPicture => 'No picture';

  @override
  String get intercomNotConnected => 'The intercom isn’t connected to this screen yet';

  @override
  String get intercomOpenDoor => 'Open door';

  @override
  String get intercomOutcomeHere => 'Answered on this screen';

  @override
  String get intercomOutcomeHereSub => 'The door was heard through this screen.';

  @override
  String get intercomOutcomeIndoor => 'Answered on the intercom';

  @override
  String get intercomOutcomeIndoorSub => 'They talked through the indoor station.';

  @override
  String get intercomOutcomeMissed => 'Not answered';

  @override
  String get intercomOutcomeMissedSub => 'Nobody answered, neither here nor on the intercom.';

  @override
  String get intercomOutcomeRinging => 'Ringing now';

  @override
  String get intercomOutcomeRingingSub => 'You can still answer on the intercom.';

  @override
  String intercomOutcomeWithDuration(String outcome, String duration) {
    return '$outcome Duration: $duration.';
  }

  @override
  String get intercomPictureFailed => 'Couldn’t capture the picture';

  @override
  String get intercomPictureFailedSub => 'The camera didn’t respond when they rang.';

  @override
  String intercomPosition(int index, int total) {
    return '$index of $total';
  }

  @override
  String intercomRelocksIn(int seconds) {
    return 'Locks again in $seconds s';
  }

  @override
  String get intercomRinging => 'Ringing…';

  @override
  String get intercomSeeCamera => 'View camera';

  @override
  String get intercomSnapshots => 'Images';

  @override
  String get intercomSomeoneRang => 'Someone rang the doorbell';

  @override
  String get intercomSubBuildingDoor => 'Intercom · Building door';

  @override
  String get intercomTalk => 'Talk';

  @override
  String get intercomVideoUnavailable => 'Video unavailable';

  @override
  String get navCalendar => 'Calendar';

  @override
  String get navHome => 'Home';

  @override
  String get navHouse => 'House';

  @override
  String get navLists => 'Lists';

  @override
  String get navMeals => 'Meals';

  @override
  String get navMusic => 'Music';

  @override
  String get navSettings => 'Settings';

  @override
  String get navTasks => 'Tasks';

  @override
  String get settingsAddTone => 'Add ringtone';

  @override
  String settingsAddToneHow(String group) {
    return 'Your own ringtones come with the app: put .wav files in the project’s assets/ringtones/custom folder. They appear in \"$group\" with the next update of this screen.';
  }

  @override
  String get settingsAddToneNotHere => 'Can’t be added from the screen';

  @override
  String get settingsAddToneSub => 'Your own .wav files. They become available like any other ringtone.';

  @override
  String get settingsAppearance => 'Appearance';

  @override
  String get settingsAssistantLanguage => 'Language';

  @override
  String get settingsBrightness => 'Brightness';

  @override
  String get settingsBrightnessFailed => 'Couldn’t change the brightness';

  @override
  String get settingsBrightnessSub => 'The monitor’s brightness, over DDC/CI.';

  @override
  String get settingsBuildingDoorToneSub => 'Rings until you answer or the call ends. The button to the right of each ringtone lets you hear it.';

  @override
  String get settingsConfigureEntities => 'Set up entities';

  @override
  String get settingsConfigureEntitiesSub => 'People, rooms, energy and cars are set up in the \"ByteHomeDash\" panel in Home Assistant.';

  @override
  String get settingsConnections => 'Connections';

  @override
  String settingsHaSub(String host, int count) {
    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: '$count entities', one: '1 entity');
    return '$host · $_temp0';
  }

  @override
  String get settingsIntercom => 'Intercom';

  @override
  String get settingsIntercomBuildingDoor => 'Hikvision · Building door';

  @override
  String get settingsIntercomConnection => 'Connection';

  @override
  String get settingsIntercomDoorCamera => 'Hikvision · door camera';

  @override
  String get settingsIntercomNotConfigured => 'Hikvision · not set up on this screen';

  @override
  String get settingsIntercomPageSub => 'This screen’s ringtone when someone rings from the building intercom.';

  @override
  String settingsIntercomToneSub(String tone) {
    return 'Building door: $tone';
  }

  @override
  String get settingsIntercomTones => 'Ringtones and volume';

  @override
  String get settingsMaAddonMissing => 'Add-on not found in Home Assistant';

  @override
  String settingsMaSpeakersFound(int count) {
    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: '$count speakers found', one: '1 speaker found');
    return '$_temp0';
  }

  @override
  String get settingsMaViaHa => 'Through Home Assistant';

  @override
  String get settingsManage => 'Manage';

  @override
  String get settingsMicNotConnected => 'The microphone isn’t connected to this screen yet.';

  @override
  String get settingsNetNoCable => 'No cable or no address';

  @override
  String settingsNetSignal(int percent) {
    return 'signal $percent%';
  }

  @override
  String settingsOwnTones(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count of your own ringtones',
      one: '1 of your own ringtones',
      zero: 'None of your own ringtones yet',
    );
    return '$_temp0';
  }

  @override
  String get settingsRebootFailed => 'Couldn’t restart';

  @override
  String get settingsRebootScreen => 'Restart the screen';

  @override
  String get settingsRebootScreenSub => 'Restarts the device. Takes about 1 minute.';

  @override
  String get settingsRebootScreenText => 'The device restarts. The screen is unavailable for about 1 minute, intercom included.';

  @override
  String get settingsRebootScreenTitle => 'Restart the screen?';

  @override
  String get settingsRebootingScreen => 'Restarting the screen…';

  @override
  String get settingsRecognizedVoices => 'Recognised voices';

  @override
  String get settingsRecognizedVoicesSub => 'Who the assistant recognises by voice.';

  @override
  String get settingsRestart => 'Restart';

  @override
  String get settingsRestartApp => 'Restart the app';

  @override
  String get settingsRestartAppSub => 'Reloads the screen. Takes a few seconds.';

  @override
  String get settingsRestartAppText => 'The screen goes blank for a few seconds and comes back on the Home page.';

  @override
  String get settingsRestartAppTitle => 'Restart the app?';

  @override
  String get settingsRestartingApp => 'Restarting the app…';

  @override
  String get settingsScreenAndSound => 'Screen and sound';

  @override
  String get settingsScreenOff => 'Turn off the screen';

  @override
  String get settingsScreenOffButton => 'Turn off';

  @override
  String get settingsScreenOffSub => 'Goes dark right away. Touch it to wake it up.';

  @override
  String get settingsSetInHa => 'Set in Home Assistant.';

  @override
  String get settingsStatusConnected => 'Connected';

  @override
  String get settingsStatusConnecting => 'Connecting';

  @override
  String get settingsStatusDisconnected => 'Not connected';

  @override
  String get settingsSystem => 'System';

  @override
  String get settingsTapClockHint => 'Tap the clock on any page to come back here.';

  @override
  String get settingsThemeAlwaysDark => 'Always dark';

  @override
  String get settingsThemeAlwaysLight => 'Always light';

  @override
  String get settingsThemeAtSunsetSunrise => 'At sunset and sunrise';

  @override
  String get settingsThemeBySun => 'Follows the sun';

  @override
  String get settingsThemeDark => 'Dark';

  @override
  String get settingsThemeDarkAtSunset => 'Dark at sunset';

  @override
  String get settingsThemeDarkFrom => 'Dark from';

  @override
  String get settingsThemeFixedTimes => 'At fixed times';

  @override
  String get settingsThemeLight => 'Light';

  @override
  String get settingsThemeLightAtSunrise => 'Light at sunrise';

  @override
  String get settingsThemeLightFrom => 'Light from';

  @override
  String settingsThemeNowDark(String time) {
    return 'Dark now · light at $time';
  }

  @override
  String settingsThemeNowLight(String time) {
    return 'Light now · dark at $time';
  }

  @override
  String get settingsThemeSunToday => 'Today’s times, from the Home Assistant sun (sun.sun). They follow the seasons by themselves.';

  @override
  String settingsThemeTip(String command, String entity) {
    return 'You can also ask the assistant: $command. In Home Assistant the theme is available as $entity, for use in automations (for example, dark when a film starts).';
  }

  @override
  String settingsThemeVoiceCommand(String wakePhrase) {
    return '“$wakePhrase, switch to dark mode”';
  }

  @override
  String settingsThemeWaitingForSun(String darkTime, String lightTime) {
    return 'Waiting for the sun times from Home Assistant (sun.sun). Until then, it switches at $darkTime and at $lightTime.';
  }

  @override
  String get settingsThemeWhen => 'When to switch';

  @override
  String get settingsTitle => 'Settings';

  @override
  String settingsToneCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: '$count ringtones', one: '1 ringtone');
    return '$_temp0';
  }

  @override
  String get settingsToneMine => 'MINE';

  @override
  String settingsTonePlaying(String name, int percent) {
    return '“$name” · volume $percent%';
  }

  @override
  String get settingsToneVolume => 'Ringtone volume';

  @override
  String get settingsToneVolumeSub => 'Through the monitor’s speakers. Doesn’t change the music or intercom volume.';

  @override
  String get settingsUnavailableOnScreen => 'Not available on this screen.';

  @override
  String get settingsVersion => 'Version';

  @override
  String get settingsVersionSub => 'Updated by the deploy on the device.';

  @override
  String get settingsVoiceAssistant => 'Voice assistant';

  @override
  String get settingsVolume => 'Volume';

  @override
  String get settingsVolumeFailed => 'Couldn’t change the volume';

  @override
  String settingsVolumePercent(int percent) {
    return 'Volume $percent%';
  }

  @override
  String get settingsVolumeSub => 'This screen’s overall volume.';

  @override
  String get settingsWakeWord => 'Wake word';

  @override
  String settingsWakeWordSub(String wakePhrase) {
    return 'Say “$wakePhrase” to talk to the assistant.';
  }

  @override
  String get settingsWebBrowser => 'Web browser';

  @override
  String get shellDoorbellWontRing => 'The doorbell won’t ring on this screen';

  @override
  String get shellNoHaConnection => 'No connection to Home Assistant';

  @override
  String get shellRetryingAuto => 'Trying again automatically…';

  @override
  String get shellScreenSettings => 'Screen settings';

  @override
  String get calendarHolidayNewYear => 'New Year’s Day';

  @override
  String get calendarHolidayCarnival => 'Carnival';

  @override
  String get calendarHolidayGoodFriday => 'Good Friday';

  @override
  String get calendarHolidayEaster => 'Easter';

  @override
  String get calendarHolidayFreedomDay => 'Freedom Day';

  @override
  String get calendarHolidayLabourDay => 'Labour Day';

  @override
  String get calendarHolidayPortugalDay => 'Portugal Day';

  @override
  String get calendarHolidayCorpusChristi => 'Corpus Christi';

  @override
  String get calendarHolidaySaintAnthony => 'Saint Anthony’s Day';

  @override
  String get calendarHolidayAssumption => 'Assumption Day';

  @override
  String get calendarHolidayRepublicDay => 'Republic Day';

  @override
  String get calendarHolidayAllSaints => 'All Saints’ Day';

  @override
  String get calendarHolidayRestorationOfIndependence => 'Restoration of Independence';

  @override
  String get calendarHolidayImmaculateConception => 'Immaculate Conception';

  @override
  String get calendarHolidayChristmas => 'Christmas Day';

  @override
  String eventNotConfirmed(String title) {
    return 'Home Assistant didn’t confirm the event \"$title\"';
  }

  @override
  String get eventSuggestionDinner => 'Dinner';

  @override
  String get eventSuggestionLunch => 'Lunch';

  @override
  String get eventSuggestionAppointment => 'Appointment';

  @override
  String get eventSuggestionBirthday => 'Birthday';

  @override
  String get eventSuggestionSchool => 'School';

  @override
  String get eventSuggestionGym => 'Gym';

  @override
  String get eventSuggestionMeeting => 'Meeting';

  @override
  String eventCreatedAllDay(String title, String date) {
    return 'Event created: $title · $date, all day';
  }

  @override
  String eventCreatedAt(String title, String date, String time) {
    return 'Event created: $title · $date, $time';
  }

  @override
  String eventDurationDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: '$count days', one: '1 day');
    return '$_temp0';
  }

  @override
  String get eventNewTitle => 'New event';

  @override
  String get eventFieldTitle => 'TITLE';

  @override
  String get eventTitleHint => 'E.g. Dinner with friends';

  @override
  String get eventFieldForWhom => 'FOR WHOM';

  @override
  String get eventNoWritableCalendar => 'No writable calendar set up.';

  @override
  String get eventFieldDate => 'DATE';

  @override
  String eventFieldEndDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: 'END · $count DAYS', one: 'END · 1 DAY');
    return '$_temp0';
  }

  @override
  String get eventFieldEnd => 'END';

  @override
  String get eventFieldStart => 'START';

  @override
  String get eventSameDay => 'Same day';

  @override
  String get eventFieldTime => 'TIME';

  @override
  String get eventAllDay => 'All day';

  @override
  String eventStartOn(String date) {
    return 'Start · $date';
  }

  @override
  String get eventStart => 'Start';

  @override
  String eventEndOn(String date) {
    return 'End · $date';
  }

  @override
  String get eventEnd => 'End';

  @override
  String eventDuration(String duration) {
    return 'Duration: $duration';
  }

  @override
  String get eventFieldPlace => 'PLACE';

  @override
  String get eventPlaceHint => 'E.g. Grandma’s house';

  @override
  String get eventFieldRepeat => 'REPEAT';

  @override
  String get eventRepeatNone => 'Doesn’t repeat';

  @override
  String get eventRepeatDaily => 'Every day';

  @override
  String get eventRepeatWeekly => 'Every week';

  @override
  String get eventRepeatMonthly => 'Every month';

  @override
  String get eventFieldNotes => 'NOTES';

  @override
  String get eventNotesHint => 'Details, what to bring, contacts…';

  @override
  String get eventSave => 'Save event';

  @override
  String get eventNoCalendarToSave => 'No calendar to save it to';

  @override
  String eventWillBeAddedTo(String name) {
    return 'Will be added to $name’s calendar';
  }

  @override
  String get eventTitleRequired => 'Type a title to save';

  @override
  String get calendarViewDay => 'Day';

  @override
  String get calendarViewWeek => 'Week';

  @override
  String get calendarViewMonth => 'Month';

  @override
  String get calendarViewAgenda => 'Agenda';

  @override
  String calendarDaySubtitleToday(String year, String week) {
    return 'Today · $year · Week $week';
  }

  @override
  String calendarDaySubtitle(String year, String week) {
    return '$year · Week $week';
  }

  @override
  String calendarWeekSubtitle(String week, String range) {
    return 'Week $week · $range';
  }

  @override
  String get calendarMonthHint => 'Tap a day to see its details';

  @override
  String calendarAgendaSubtitle(String weekday, String date) {
    return 'Next 3 weeks, from $weekday, $date';
  }

  @override
  String get calendarDayFree => 'Free day';

  @override
  String get calendarNothingScheduled => 'Nothing scheduled';

  @override
  String get calendarDayIsFree => 'This day is free.';

  @override
  String get calendarAllDayStacked => 'ALL\nDAY';

  @override
  String get calendarNoAllDayEvents => 'No all-day events';

  @override
  String get calendarDaySummary => 'Day summary';

  @override
  String calendarEventCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: '$count events', one: '1 event');
    return '$_temp0';
  }

  @override
  String get calendarUpcomingHolidays => 'Upcoming holidays';

  @override
  String calendarMore(int count) {
    return '+$count more';
  }

  @override
  String get calendarAllDay => 'All day';

  @override
  String get calendarDayFreeNothingScheduled => 'Free day · nothing scheduled';

  @override
  String forecastSubtitleDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: 'Next $count days', one: 'Next day');
    return '$_temp0';
  }

  @override
  String forecastSubtitleDaysUpdated(int count, String time) {
    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: 'Next $count days · updated at $time', one: 'Next day · updated at $time');
    return '$_temp0';
  }

  @override
  String get forecastSubtitleHours => 'Next 48 hours';

  @override
  String forecastSubtitleHoursUpdated(String time) {
    return 'Next 48 hours · updated at $time';
  }

  @override
  String get forecastNoEntity => 'No weather entity set up.';

  @override
  String get forecastLoadFailed => 'Couldn’t get the forecast.';

  @override
  String get forecastLoading => 'Loading the forecast…';

  @override
  String get forecastUnavailable => 'Forecast unavailable.';

  @override
  String get forecastTodayDotHint => 'The dot on today’s bar marks the current temperature.';

  @override
  String get forecastHoursHint => 'Tap the chart or an hour to see its details.';

  @override
  String get forecastTitle => 'Weather forecast';

  @override
  String get forecastTabDays => 'Days';

  @override
  String forecastTabDaysCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: '$count days', one: '1 day');
    return '$_temp0';
  }

  @override
  String get forecastTabHours => '48 hours';

  @override
  String get forecastNow => 'Now';

  @override
  String forecastNowOn(String date) {
    return 'Now · $date';
  }

  @override
  String forecastRain(String pct) {
    return 'Rain $pct%';
  }

  @override
  String forecastWind(String speed, String unit) {
    return 'Wind $speed $unit';
  }

  @override
  String forecastMax(String temp) {
    return 'max $temp';
  }

  @override
  String forecastMin(String temp) {
    return 'min $temp';
  }

  @override
  String forecastSunrise(String time) {
    return 'Sunrise $time';
  }

  @override
  String forecastSunset(String time) {
    return 'Sunset $time';
  }

  @override
  String forecastHeadToday(String day) {
    return '$day · TODAY';
  }

  @override
  String get weatherNoWarnings => 'No warnings in effect';

  @override
  String weatherWarningFrom(String when) {
    return 'from $when';
  }

  @override
  String weatherWarningUntil(String when) {
    return 'until $when';
  }

  @override
  String get weatherWarningActive => 'Warning in effect';

  @override
  String get weatherWarningLabel => 'WARNING';

  @override
  String get weatherWarningGreen => 'Green';

  @override
  String get weatherWarningYellow => 'Yellow';

  @override
  String get weatherWarningOrange => 'Orange';

  @override
  String get weatherWarningRed => 'Red';

  @override
  String weatherUvAtHour(String time) {
    return 'At $time';
  }

  @override
  String weatherUvAtHourWithMax(String time, String max, String maxTime) {
    return 'At $time · max. $max at $maxTime';
  }

  @override
  String weatherUvNowWithMax(String max, String maxTime) {
    return 'Now · max. $max at $maxTime';
  }

  @override
  String get weatherUvTodayMax => 'Today’s forecast peak';

  @override
  String get weatherUvLow => 'Low';

  @override
  String get weatherLevelModerate => 'Moderate';

  @override
  String get weatherLevelHigh => 'High';

  @override
  String get weatherLevelVeryHigh => 'Very high';

  @override
  String get weatherUvExtreme => 'Extreme';

  @override
  String get weatherUvLabel => 'UV INDEX';

  @override
  String get weatherUvNoSun => 'No sun';

  @override
  String get weatherFireRiskLabel => 'FIRE RISK';

  @override
  String get weatherFireLow => 'Low';

  @override
  String get weatherFireMaximum => 'Maximum';

  @override
  String get weatherFireAdvice => 'Avoid bonfires and burning';

  @override
  String get weatherFireTodayIpma => 'Today · IPMA forecast';

  @override
  String weatherAtTime(String time) {
    return 'at $time';
  }

  @override
  String weatherTomorrowAtTime(String time) {
    return 'tomorrow at $time';
  }

  @override
  String weatherDayAtTime(String day, String time) {
    return '$day at $time';
  }

  @override
  String get homeHouseTitle => 'House';

  @override
  String get homeHolidayTag => 'HOLIDAY';

  @override
  String get homeAllDayTag => 'ALL DAY';

  @override
  String get homeNow => 'Now';

  @override
  String get homeTasksTitle => 'Tasks';

  @override
  String get homeTasksNothingToday => 'Nothing for today';

  @override
  String homeTasksDone(int done, int total) {
    return '$done of $total done';
  }

  @override
  String get homeNoTasksToday => 'No tasks for today';

  @override
  String get homeEnjoyFreeDay => 'Enjoy the free day.';

  @override
  String get homeMealsTitle => 'Meals';

  @override
  String get homeMealPlan => '+ Plan';

  @override
  String homeMealOut(String dish) {
    return 'Out · $dish';
  }

  @override
  String homeMealDelivery(String dish) {
    return '$dish · Takeaway';
  }

  @override
  String get homeMealTomorrowUnplanned => 'Tomorrow: not planned';

  @override
  String homeMealTomorrow(String dish) {
    return 'Tomorrow: $dish';
  }

  @override
  String get homeShoppingTitle => 'Shopping';

  @override
  String get homeNoList => 'No list';

  @override
  String homeSeeAllCount(int count) {
    return 'See all ($count)';
  }

  @override
  String get homeOpenList => 'Open list';

  @override
  String get kitchenRecipeDefaultTitle => 'Recipe';

  @override
  String get kitchenVoiceNextStep => 'By voice · “next step”';

  @override
  String get kitchenVoiceRepeat => 'By voice · “repeat”';

  @override
  String get kitchenVoiceBack => 'By voice · “go back”';

  @override
  String kitchenVoiceStep(int step) {
    return 'By voice · step $step';
  }

  @override
  String kitchenStepN(int step) {
    return 'Step $step';
  }

  @override
  String get kitchenTimerEndedShort => 'done!';

  @override
  String kitchenTimerPaused(String time) {
    return '$time · paused';
  }

  @override
  String get kitchenExitTitle => 'Leave the recipe?';

  @override
  String kitchenExitBodyWithTimer(int step, int total) {
    return 'You’re on step $step of $total. The timer stops and the recipe closes. You can minimize it and come back later from the bubble.';
  }

  @override
  String kitchenExitBody(int step, int total) {
    return 'You’re on step $step of $total. The recipe closes. You can minimize it and come back later from the bubble.';
  }

  @override
  String get kitchenExitVoiceHint => 'Say “Ok Nabu, exit”, “minimize” or “continue”.';

  @override
  String get kitchenContinue => 'Continue';

  @override
  String get kitchenMinimize => 'Minimize';

  @override
  String get kitchenExit => 'Exit';

  @override
  String get kitchenModeLabel => 'COOKING MODE';

  @override
  String kitchenProgress(int step, String ofTotal) {
    return 'Step $step $ofTotal';
  }

  @override
  String kitchenOfTotal(int total) {
    return 'of $total';
  }

  @override
  String get kitchenAllSteps => 'All steps';

  @override
  String get kitchenTabStep => 'Step';

  @override
  String kitchenTabIngredients(int count) {
    return 'Ingredients · $count';
  }

  @override
  String get kitchenTimerRunning => 'Timer running';

  @override
  String get kitchenPause => 'Pause';

  @override
  String get kitchenTimeUp => 'Time’s up!';

  @override
  String get kitchenStopAlarm => 'Stop alarm';

  @override
  String kitchenTimerMinutes(int minutes) {
    return 'Timer · $minutes min';
  }

  @override
  String get kitchenStart => 'Start';

  @override
  String kitchenIngredientsReady(int ready, int total) {
    return '$ready of $total ready';
  }

  @override
  String get kitchenIngredientsTapHint => 'Tap to cross off what you already have';

  @override
  String get kitchenNoServings => 'The recipe doesn’t say how many it serves';

  @override
  String kitchenNoServingsReady(int ready, int total) {
    return 'The recipe doesn’t say how many it serves · $ready of $total ready';
  }

  @override
  String get kitchenIngredients => 'Ingredients';

  @override
  String get kitchenServesFor => 'For';

  @override
  String kitchenScaledNote(String from, String to) {
    return 'Quantities adjusted from $from to $to. Step times don’t change.';
  }

  @override
  String get kitchenEnjoy => 'Enjoy your meal!';

  @override
  String kitchenRecipeDone(int count) {
    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: 'Recipe done · $count steps', one: 'Recipe done · 1 step');
    return '$_temp0';
  }

  @override
  String get kitchenReviewSteps => 'Review the steps';

  @override
  String get kitchenExitMode => 'Exit cooking mode';

  @override
  String kitchenVoiceHint(String command) {
    return 'Say $command, “repeat”, “go back” or “ingredients”. The screen stays on while you cook.';
  }

  @override
  String get kitchenVoiceHintCommand => '“Ok Nabu, next step”';

  @override
  String get kitchenFinish => 'Finish';

  @override
  String kitchenPeople(int count) {
    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: '$count people', one: '1 person');
    return '$_temp0';
  }

  @override
  String kitchenBubbleStep(int step, int total) {
    return 'Step $step/$total';
  }

  @override
  String get kitchenTimerEnded => 'Done!';

  @override
  String kitchenBubbleSemantics(String title) {
    return 'Back to the recipe $title';
  }

  @override
  String kitchenBubbleSemanticsTimer(String title, String time) {
    return 'Back to the recipe $title, timer $time';
  }

  @override
  String kitchenBubbleSemanticsTimerEnded(String title) {
    return 'Back to the recipe $title, timer done';
  }

  @override
  String get choresOnlyThisDay => 'Only on this day';

  @override
  String get choresEveryDay => 'Every day';

  @override
  String get choresWeekdays => 'Weekdays';

  @override
  String choresMetaDue(String repeat, String time) {
    return '$repeat · by $time';
  }

  @override
  String get tasksTitle => 'Tasks';

  @override
  String tasksWeekdayDate(String weekday, String date) {
    return '$weekday, $date';
  }

  @override
  String get tasksSummaryNone => 'no tasks';

  @override
  String tasksSummaryDone(int done, int total) {
    return '$done of $total done';
  }

  @override
  String get tasksNew => 'New task';

  @override
  String get tasksEdit => 'Edit task';

  @override
  String get tasksCreate => 'Create task';

  @override
  String get tasksFree => 'Free';

  @override
  String tasksCountOf(int done, int total) {
    return '$done of $total';
  }

  @override
  String get tasksAllDone => 'All done!';

  @override
  String get tasksNoneTitle => 'No tasks';

  @override
  String get tasksHouseholdFreeToday => 'Nothing for the family today';

  @override
  String get tasksHouseholdFreeDay => 'Nothing for the family on this day';

  @override
  String tasksMemberFreeToday(String name) {
    return '$name is free today';
  }

  @override
  String tasksMemberFreeDay(String name) {
    return '$name is free on this day';
  }

  @override
  String get tasksEmptyDayTitle => 'No tasks on this day';

  @override
  String get tasksEmptyDayBodyToday => 'No one has tasks set for today.';

  @override
  String tasksEmptyDayBody(String date) {
    return 'No one has tasks set for $date.';
  }

  @override
  String get tasksFieldTask => 'TASK';

  @override
  String get tasksNameHint => 'e.g. Tidy the bedroom';

  @override
  String get tasksFieldWho => 'FOR WHOM';

  @override
  String get tasksFieldRepeat => 'REPEAT';

  @override
  String get tasksRepeatNone => 'Doesn\'t repeat';

  @override
  String get tasksRepeatDays => 'Specific days';

  @override
  String get tasksFieldDue => 'DEADLINE';

  @override
  String get tasksDueToggle => 'By a set time';

  @override
  String get tasksDueBy => 'By';

  @override
  String get tasksSuggestTidyRoom => 'Tidy the bedroom';

  @override
  String get tasksSuggestMakeBed => 'Make the bed';

  @override
  String get tasksSuggestDust => 'Dust';

  @override
  String get tasksSuggestHangLaundry => 'Hang out the washing';

  @override
  String get tasksSuggestWashCar => 'Wash the car';

  @override
  String get tasksSuggestEmptyDishwasher => 'Empty the dishwasher';

  @override
  String get tasksSuggestTakeOutRubbish => 'Take out the rubbish';

  @override
  String get tasksSuggestWaterPlants => 'Water the plants';

  @override
  String get mealsTitle => 'Meals';

  @override
  String mealsWeekRange(int week, String from, String to) {
    return 'Week $week · $from – $to';
  }

  @override
  String get mealsBreakfast => 'Breakfast';

  @override
  String get mealsLunch => 'Lunch';

  @override
  String get mealsDinner => 'Dinner';

  @override
  String get mealsPlaceHome => 'At home';

  @override
  String get mealsPlaceOut => 'Eating out';

  @override
  String get mealsPlaceDelivery => 'Takeaway';

  @override
  String mealsCopiedTo(String dish, String meal, String weekday, int day) {
    return '$dish copied to $meal on $weekday $day';
  }

  @override
  String get mealsUndo => 'Undo';

  @override
  String get mealsCopyHere => 'Copy here';

  @override
  String get mealsPlan => 'Plan';

  @override
  String get mealsRecipe => 'Recipe';

  @override
  String get mealsRecipeNoSteps => 'the recipe page has no steps';

  @override
  String get mealsFieldDish => 'DISH';

  @override
  String get mealsDishHint => 'e.g. Vegetable soup';

  @override
  String get mealsOpenSite => 'Open the site';

  @override
  String get mealsOpening => 'Opening…';

  @override
  String get mealsKitchenMode => 'Cooking mode';

  @override
  String mealsRecipeSearch(String dish) {
    return '$dish recipe';
  }

  @override
  String get mealsSearchRecipe => 'Search for a recipe online';

  @override
  String get mealsFieldFavorites => 'FAVOURITES';

  @override
  String get mealsFieldWhere => 'WHERE';

  @override
  String get mealsFieldTime => 'TIME';

  @override
  String get mealsFieldNotes => 'NOTES';

  @override
  String get mealsNoteHint => 'e.g. defrost in the morning';

  @override
  String get mealsDishToastFruit => 'Toast and fruit';

  @override
  String get mealsDishOatPancakes => 'Oat pancakes';

  @override
  String get mealsDishYogurtGranola => 'Yoghurt with granola';

  @override
  String get mealsDishPorridge => 'Porridge';

  @override
  String get mealsDishScrambledEggs => 'Scrambled eggs';

  @override
  String get mealsDishSoupSandwich => 'Soup and a sandwich';

  @override
  String get mealsDishTunaSalad => 'Tuna salad';

  @override
  String get mealsDishBitoque => 'Steak with fried egg';

  @override
  String get mealsDishVegetablePasta => 'Pasta with vegetables';

  @override
  String get mealsDishGrilledChicken => 'Grilled chicken';

  @override
  String get mealsDishBacalhauBras => 'Cod à Brás';

  @override
  String get mealsDishDuckRice => 'Duck rice';

  @override
  String get mealsDishBolognese => 'Spaghetti bolognese';

  @override
  String get mealsDishRoastChicken => 'Roast chicken';

  @override
  String get mealsDishVegetableSoup => 'Vegetable soup';

  @override
  String get mealsDishGrilledSalmon => 'Grilled salmon';

  @override
  String get mealsDishLasagne => 'Lasagne';

  @override
  String get mealsDishPizza => 'Pizza';

  @override
  String get listsTitle => 'Lists';

  @override
  String get listsNew => 'New list';

  @override
  String get listsNoneInHa => 'No lists in Home Assistant';

  @override
  String get listsAllDone => 'All done';

  @override
  String listsItemsPending(int count) {
    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: '$count items to do', one: '1 item to do');
    return '$_temp0';
  }

  @override
  String listsPendingCount(int count) {
    return '$count to do';
  }

  @override
  String get listsClearDone => 'Clear completed';

  @override
  String get listsAddItem => 'Add item…';

  @override
  String get listsNothingPending => 'Nothing to do on this list';

  @override
  String listsDoneCount(int count) {
    return 'Completed ($count)';
  }

  @override
  String get listsMessagesTitle => 'Messages';

  @override
  String listsMessagesUnseen(int count) {
    return '$count unseen';
  }

  @override
  String get listsMessagesNone => 'No messages';

  @override
  String get listsMessagesAllSeen => 'All seen';

  @override
  String get listsMessagesExpiry => 'deleted after 7 days';

  @override
  String get listsMessagesEmptyBody => 'Messages left by voice show up here until someone sees them, and delete themselves after 7 days.';

  @override
  String get listsMessagesUnseenBadge => 'Unseen';

  @override
  String get listsMessagesMarkSeen => 'Mark as seen';

  @override
  String listsMessagesDeletesIn(int count) {
    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: 'Deleted in $count days', one: 'Deleted tomorrow');
    return '$_temp0';
  }

  @override
  String listsCreated(String name) {
    return 'List created: $name';
  }

  @override
  String get listsFieldName => 'NAME';

  @override
  String get listsNameHint => 'e.g. Attic clear-out';

  @override
  String get listsCreateShort => 'Create';

  @override
  String get listsFieldIcon => 'ICON';

  @override
  String get listsCreate => 'Create list';

  @override
  String get itemNew => 'New item';

  @override
  String get itemEdit => 'Edit item';

  @override
  String get itemFieldItem => 'ITEM';

  @override
  String get itemFieldQuantity => 'QUANTITY';

  @override
  String get itemNoQuantity => 'No quantity';

  @override
  String get itemFieldNote => 'NOTE';

  @override
  String get itemNoteHint => 'e.g. whole beans, brand, lactose-free…';

  @override
  String get itemSuggestOliveOil => 'Olive oil';

  @override
  String get itemSuggestRice => 'Rice';

  @override
  String get itemSuggestButter => 'Butter';

  @override
  String get itemSuggestFruit => 'Fruit';

  @override
  String get itemSuggestWater => 'Water';

  @override
  String get itemSuggestToiletPaper => 'Toilet paper';

  @override
  String get itemSuggestCheese => 'Cheese';

  @override
  String get itemSuggestMilk => 'Milk';

  @override
  String get itemSuggestBread => 'Bread';

  @override
  String get itemSuggestEggs => 'Eggs';

  @override
  String get itemSuggestIbuprofen => 'Ibuprofen';

  @override
  String get itemSuggestParacetamol => 'Paracetamol';

  @override
  String get itemSuggestSaline => 'Saline solution';

  @override
  String get itemSuggestThermometer => 'Thermometer';

  @override
  String get itemSuggestPlasters => 'Plasters';

  @override
  String get itemSuggestBatteries => 'Batteries';

  @override
  String get itemSuggestLightBulbs => 'Light bulbs';

  @override
  String get itemSuggestSilicone => 'Silicone';

  @override
  String get itemSuggestScrews => 'Screws';

  @override
  String get todoUnitPieceOne => 'pc';

  @override
  String get todoUnitPieceMany => 'pcs';

  @override
  String get todoUnitPackOne => 'pack';

  @override
  String get todoUnitPackMany => 'packs';

  @override
  String get todoUnitDozenOne => 'dozen';

  @override
  String get todoUnitDozenMany => 'dozen';

  @override
  String get todoNotConfirmed => 'Home Assistant didn\'t confirm the change to the list';

  @override
  String get todoNoConnection => 'Not connected to Home Assistant';

  @override
  String get familyHolidays => 'Holidays';

  @override
  String get entitiesNotConfirmed => 'Home Assistant didn\'t confirm the change';

  @override
  String get uiOptionalSuffix => '(optional)';

  @override
  String get uiSaving => 'Saving…';

  @override
  String uiActionFailed(String reason) {
    return 'Couldn\'t finish: $reason';
  }

  @override
  String get keyboardSpace => 'space';

  @override
  String get keyboardFloat => 'Float';

  @override
  String get powerSensorIconGeneric => 'Generic';

  @override
  String get powerSensorIconWasher => 'Washing machine';

  @override
  String get powerSensorIconFridge => 'Fridge';

  @override
  String get powerSensorIconAirConditioning => 'Air conditioning';

  @override
  String get powerSensorIconHeatPump => 'Heat pump (hot water)';

  @override
  String get powerSensorIconOven => 'Oven';

  @override
  String get optimisticMusicNotConfirmed => 'Music Assistant didn\'t confirm the change';

  @override
  String get miscMusicNoSpeakers => 'No speakers';

  @override
  String miscMusicSpeakersMore(String name, int count) {
    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: '$count speakers', one: '1 speaker');
    return '$name + $_temp0';
  }

  @override
  String get miscMusicUnavailable => 'Music Assistant unavailable';

  @override
  String get miscMusicChooseSpeaker => 'Choose a speaker';

  @override
  String miscMusicCannotGroup(String speaker, String target) {
    return '$speaker can\'t play in a group with $target';
  }

  @override
  String get miscMusicNotConnected => 'Music Assistant isn\'t connected';

  @override
  String miscMusicNoReply(String command) {
    return 'No reply from Music Assistant ($command)';
  }

  @override
  String get haCreateListsDeviceOnly => 'Creating lists only works on the screen at home';

  @override
  String get themeLight => 'Light';

  @override
  String get themeDark => 'Dark';

  @override
  String get themeMqttSelectName => 'Theme';

  @override
  String doorIndoorNotYetConnected(String host) {
    return 'Not connected to the home intercom yet ($host).';
  }

  @override
  String get doorIndoorLinkStopped => 'The connection to the home intercom stopped; reconnecting.';

  @override
  String doorIndoorStartFailed(String details) {
    return 'Couldn\'t start the connection to the home intercom: $details';
  }

  @override
  String doorIndoorNoLibrary(String path) {
    return 'The intercom library is missing ($path).';
  }

  @override
  String doorIndoorSdkFailed(String code) {
    return 'The intercom SDK didn\'t start (error $code).';
  }

  @override
  String get doorIndoorBadPassword => 'Wrong username or password for the home intercom.';

  @override
  String get doorIndoorLocked => 'The home intercom blocked access (too many attempts); trying again in 10 min.';

  @override
  String doorIndoorStoppedResponding(String code) {
    return 'The home intercom stopped responding (error $code); reconnecting.';
  }

  @override
  String doorIndoorLoginFailed(String host, String code) {
    return 'Couldn\'t connect to the home intercom ($host, error $code).';
  }

  @override
  String get doorIndoorNotConfigured => 'The home intercom isn\'t set up on this screen (INDOOR_HOST).';

  @override
  String get doorSipConnecting => 'Connecting to the main station (SIP)…';

  @override
  String doorSipNoConnection(String server) {
    return 'No connection to the main station (SIP $server).';
  }

  @override
  String doorSipStartFailed(String details) {
    return 'Couldn\'t start the SIP extension: $details';
  }

  @override
  String get doorSipRegistrationRefused => 'SIP registration refused (number/password). Check the extension and the admin password.';

  @override
  String get doorSipDeviceOnly => 'The SIP extension only works on the device, not in the web preview.';

  @override
  String get doorCameraReconnecting => 'Reconnecting to the camera…';

  @override
  String get doorCameraConnecting => 'Connecting to the building\'s door camera…';

  @override
  String doorOpenFailed(String status) {
    return 'Couldn\'t open the door (HTTP $status)';
  }

  @override
  String doorTalkRefused(String status) {
    return 'The door didn\'t accept talking right now (HTTP $status)';
  }

  @override
  String get settingsBrowserEngineDuckSub => 'duckduckgo.com · doesn’t keep what you search';

  @override
  String get settingsBrowserEngineEcosiaSub => 'ecosia.org · plants trees with your searches';

  @override
  String get browserMenuAddToMeal => 'Add to a meal';

  @override
  String get browserMenuAddToMealSub => 'Keeps this page’s link';

  @override
  String get browserMenuAddToMealNoSite => 'Open a website’s page first';

  @override
  String get browserMenuSendToPhone => 'Send to phone';

  @override
  String get browserMenuHome => 'Home page';

  @override
  String browserMealAddedToday(String meal) {
    return 'Added to today’s $meal, with the link';
  }

  @override
  String browserMealAddedTomorrow(String meal) {
    return 'Added to tomorrow’s $meal, with the link';
  }

  @override
  String browserMealAddedOn(String meal, String day) {
    return 'Added to $day’s $meal, with the link';
  }

  @override
  String get browserMealDish => 'DISH';

  @override
  String get browserMealDishHint => 'Name of the dish';

  @override
  String browserMealKeepsLink(String site) {
    return 'Keeps the link: $site';
  }

  @override
  String get browserMealDay => 'DAY';

  @override
  String get browserMealMeal => 'MEAL';

  @override
  String get browserMealSlotFree => 'free';

  @override
  String browserMealReplaces(String dish, String meal) {
    return 'There’s already $dish for this $meal. Adding replaces it.';
  }

  @override
  String get browserMealReplace => 'Replace';

  @override
  String get settingsBrowserOpenSub => 'Opens with the home page and mode chosen in the browser settings.';

  @override
  String get settingsBrowserSettings => 'Browser settings';

  @override
  String get settingsBrowserSettingsSub => 'Home page, search engine and how it opens.';

  @override
  String get settingsBrowserManage => 'Manage';

  @override
  String get settingsBrowserTitle => 'Web browser';

  @override
  String get settingsBrowserSubtitle => 'Choose the home page, the search engine and how the browser opens.';

  @override
  String get settingsBrowserOpen => 'Open browser';

  @override
  String get settingsBrowserEngine => 'Search engine';

  @override
  String get settingsBrowserEngineSub => 'Used when what you type isn’t an address.';

  @override
  String get settingsBrowserMode => 'Open by default';

  @override
  String get settingsBrowserModeSub => 'How the browser appears when it opens. You can always change it in the browser’s bar.';

  @override
  String get settingsBrowserHome => 'Home page';

  @override
  String get settingsBrowserHomeSub => 'What shows when it opens and on the home button.';

  @override
  String get settingsBrowserHomeStart => 'Favourites and search';

  @override
  String get settingsBrowserHomeStartSub => 'The browser’s start page';

  @override
  String get settingsBrowserHomeHaMissing => 'Not connected to Home Assistant yet';

  @override
  String get settingsBrowserHomeOther => 'Another page';

  @override
  String get settingsBrowserHomeOtherSub => 'Choose an address';

  @override
  String get settingsBrowserHomeUrlHint => 'Tap to type the address';

  @override
  String get settingsBrowserModeWindow => 'Floating window';

  @override
  String get settingsBrowserModeWindowSub => 'The app stays behind it';

  @override
  String get settingsBrowserModeModal => 'Modal';

  @override
  String get settingsBrowserModeModalSub => 'Centred, background dimmed';

  @override
  String get settingsBrowserModeFull => 'Full screen';

  @override
  String get settingsBrowserModeFullSub => 'Fills the whole screen';

  @override
  String get settingsIntercomOff => 'Intercom off';

  @override
  String get settingsIntercomOffSub => 'To answer the door on this screen, set up the door station in this screen\'s settings (/etc/bytehomedash.env).';

  @override
  String get settingsIntercomOffValue => 'Off';

  @override
  String get listsMessagesWrite => 'Write a message…';

  @override
  String listsMessagesByVoice(String name) {
    return 'Or by voice: “Ok Nabu, leave a message for $name: …”';
  }

  @override
  String get listsMessagesByVoiceEveryone => 'Or by voice: “Ok Nabu, leave a message for everyone: …”';

  @override
  String get recadoNewTitle => 'New message';

  @override
  String get recadoNewSubtitle => 'Shows on the screen until someone sees it · deleted after 7 days';

  @override
  String get recadoNewEveryone => 'Everyone';

  @override
  String get recadoNewText => 'MESSAGE';

  @override
  String get recadoNewHint => 'E.g. Dinner is in the oven, just heat it up.';

  @override
  String get recadoNewFrom => 'FROM';

  @override
  String get recadoNewAnonymous => 'Don\'t say';

  @override
  String get recadoNewPhone => 'Also send to their phone';

  @override
  String get recadoNewPhoneEveryone => 'Also send to everyone\'s phones';

  @override
  String recadoNewPhoneOf(String name) {
    return 'Also send to $name\'s phone';
  }

  @override
  String get recadoNewPhoneSub => 'Through the Home Assistant app';

  @override
  String get recadoNewSave => 'Leave message';

  @override
  String get recadoNewSuggestDinner => 'Dinner is in the oven';

  @override
  String get recadoNewSuggestBack => 'Back at 7 pm';

  @override
  String get recadoNewSuggestDontForget => 'Don\'t forget to';
}
