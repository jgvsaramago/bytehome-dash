import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_pt.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale) : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates = <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[Locale('en'), Locale('pt')];

  /// Weekdays Monday to Sunday as standalone titles, comma-separated, no spaces.
  ///
  /// In en, this message translates to:
  /// **'Monday,Tuesday,Wednesday,Thursday,Friday,Saturday,Sunday'**
  String get datesWeekdaysTitle;

  /// Three-letter uppercase weekday abbreviations Monday to Sunday, comma-separated.
  ///
  /// In en, this message translates to:
  /// **'MON,TUE,WED,THU,FRI,SAT,SUN'**
  String get datesWeekdaysAbbr;

  /// One-letter weekday column heads Monday to Sunday, comma-separated.
  ///
  /// In en, this message translates to:
  /// **'M,T,W,T,F,S,S'**
  String get datesWeekdayLetters;

  /// No description provided for @commonSave.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get commonSave;

  /// No description provided for @commonCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get commonCancel;

  /// No description provided for @commonClose.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get commonClose;

  /// No description provided for @commonDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get commonDelete;

  /// No description provided for @commonRemove.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get commonRemove;

  /// No description provided for @commonEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get commonEdit;

  /// No description provided for @commonAdd.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get commonAdd;

  /// No description provided for @commonDone.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get commonDone;

  /// No description provided for @commonOpen.
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get commonOpen;

  /// No description provided for @commonBack.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get commonBack;

  /// No description provided for @commonYes.
  ///
  /// In en, this message translates to:
  /// **'Yes'**
  String get commonYes;

  /// No description provided for @commonNo.
  ///
  /// In en, this message translates to:
  /// **'No'**
  String get commonNo;

  /// No description provided for @commonOk.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get commonOk;

  /// No description provided for @commonToday.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get commonToday;

  /// No description provided for @commonTomorrow.
  ///
  /// In en, this message translates to:
  /// **'Tomorrow'**
  String get commonTomorrow;

  /// No description provided for @commonYesterday.
  ///
  /// In en, this message translates to:
  /// **'Yesterday'**
  String get commonYesterday;

  /// No description provided for @commonOn.
  ///
  /// In en, this message translates to:
  /// **'On'**
  String get commonOn;

  /// No description provided for @commonOff.
  ///
  /// In en, this message translates to:
  /// **'Off'**
  String get commonOff;

  /// No description provided for @commonLoading.
  ///
  /// In en, this message translates to:
  /// **'Loading…'**
  String get commonLoading;

  /// No description provided for @commonRetry.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get commonRetry;

  /// No description provided for @commonNext.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get commonNext;

  /// No description provided for @commonPrevious.
  ///
  /// In en, this message translates to:
  /// **'Previous'**
  String get commonPrevious;

  /// No description provided for @commonSeeAll.
  ///
  /// In en, this message translates to:
  /// **'See all'**
  String get commonSeeAll;

  /// No description provided for @commonNone.
  ///
  /// In en, this message translates to:
  /// **'None'**
  String get commonNone;

  /// No description provided for @commonAuto.
  ///
  /// In en, this message translates to:
  /// **'Automatic'**
  String get commonAuto;

  /// No description provided for @commonUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Unavailable'**
  String get commonUnavailable;

  /// No description provided for @settingsLanguage.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get settingsLanguage;

  /// No description provided for @settingsLanguageSub.
  ///
  /// In en, this message translates to:
  /// **'The screen\'s language. Automatic follows Home Assistant.'**
  String get settingsLanguageSub;

  /// No description provided for @settingsLanguageAuto.
  ///
  /// In en, this message translates to:
  /// **'Automatic (Home Assistant)'**
  String get settingsLanguageAuto;

  /// This language's own name, shown in the language picker.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get languageName;

  /// No description provided for @assistantAgoDays.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 day ago} other{{count} days ago}}'**
  String assistantAgoDays(int count);

  /// No description provided for @assistantAgoHours.
  ///
  /// In en, this message translates to:
  /// **'{count} h ago'**
  String assistantAgoHours(int count);

  /// No description provided for @assistantAgoMinutes.
  ///
  /// In en, this message translates to:
  /// **'{count} min ago'**
  String assistantAgoMinutes(int count);

  /// No description provided for @assistantChooserNoPhones.
  ///
  /// In en, this message translates to:
  /// **'Nobody has the Home Assistant app on their phone, or the person still needs to be chosen in the ByteHomeDash panel, under People.'**
  String get assistantChooserNoPhones;

  /// No description provided for @assistantChooserNotRecognised.
  ///
  /// In en, this message translates to:
  /// **'I didn’t recognise the voice. Choose who gets it on their phone.'**
  String get assistantChooserNotRecognised;

  /// No description provided for @assistantChooserSendTo.
  ///
  /// In en, this message translates to:
  /// **'Send to…'**
  String get assistantChooserSendTo;

  /// No description provided for @assistantChooserWho.
  ///
  /// In en, this message translates to:
  /// **'Who should I send it to?'**
  String get assistantChooserWho;

  /// No description provided for @assistantClimateOn.
  ///
  /// In en, this message translates to:
  /// **'On · {current} → {target}'**
  String assistantClimateOn(String current, String target);

  /// State of a blind/shutter.
  ///
  /// In en, this message translates to:
  /// **'Closed'**
  String get assistantCoverClosed;

  /// State of a blind/shutter.
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get assistantCoverOpen;

  /// Fallback name of a to-do list, used mid-sentence.
  ///
  /// In en, this message translates to:
  /// **'list'**
  String get assistantDefaultList;

  /// No description provided for @assistantDidntUnderstand.
  ///
  /// In en, this message translates to:
  /// **'I didn’t quite get that. Could you say it another way?'**
  String get assistantDidntUnderstand;

  /// The assistant’s answer when the request was carried out without a reply.
  ///
  /// In en, this message translates to:
  /// **'Done.'**
  String get assistantDone;

  /// No description provided for @assistantExamplesHeading.
  ///
  /// In en, this message translates to:
  /// **'YOU CAN ASK, FOR EXAMPLE'**
  String get assistantExamplesHeading;

  /// No description provided for @assistantGotIt.
  ///
  /// In en, this message translates to:
  /// **'Got it'**
  String get assistantGotIt;

  /// No description provided for @assistantItemsAdded.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 item in {list}} other{{count} items in {list}}}'**
  String assistantItemsAdded(int count, String list);

  /// No description provided for @assistantItemsPending.
  ///
  /// In en, this message translates to:
  /// **'{list} · now {count} to buy'**
  String assistantItemsPending(String list, int count);

  /// Word suggestion on the on-screen keyboard to start a request.
  ///
  /// In en, this message translates to:
  /// **'How much'**
  String get assistantKeyHowMuch;

  /// Word suggestion on the on-screen keyboard to start a request.
  ///
  /// In en, this message translates to:
  /// **'Play'**
  String get assistantKeyPlay;

  /// Word suggestion on the on-screen keyboard to start a request.
  ///
  /// In en, this message translates to:
  /// **'Turn off'**
  String get assistantKeyTurnOff;

  /// Word suggestion on the on-screen keyboard to start a request.
  ///
  /// In en, this message translates to:
  /// **'Turn on'**
  String get assistantKeyTurnOn;

  /// Word suggestion on the on-screen keyboard to start a request.
  ///
  /// In en, this message translates to:
  /// **'What is'**
  String get assistantKeyWhatIs;

  /// State of a light.
  ///
  /// In en, this message translates to:
  /// **'Off'**
  String get assistantLightOff;

  /// State of a light.
  ///
  /// In en, this message translates to:
  /// **'On'**
  String get assistantLightOn;

  /// No description provided for @assistantLightOnBrightness.
  ///
  /// In en, this message translates to:
  /// **'On · {percent}%'**
  String assistantLightOnBrightness(int percent);

  /// State of a lock.
  ///
  /// In en, this message translates to:
  /// **'Locked'**
  String get assistantLocked;

  /// Shown after the user declined to replace planned meals.
  ///
  /// In en, this message translates to:
  /// **'Kept what was there'**
  String get assistantMealsKept;

  /// Shown after the user agreed to replace planned meals.
  ///
  /// In en, this message translates to:
  /// **'Replaced'**
  String get assistantMealsReplaced;

  /// No description provided for @assistantMealsVoiceHint.
  ///
  /// In en, this message translates to:
  /// **'or say “yes” or “no”'**
  String get assistantMealsVoiceHint;

  /// No description provided for @assistantMealsYesReplace.
  ///
  /// In en, this message translates to:
  /// **'Yes, replace'**
  String get assistantMealsYesReplace;

  /// No description provided for @assistantMediaPaused.
  ///
  /// In en, this message translates to:
  /// **'Paused'**
  String get assistantMediaPaused;

  /// No description provided for @assistantMediaPlaying.
  ///
  /// In en, this message translates to:
  /// **'Playing'**
  String get assistantMediaPlaying;

  /// No description provided for @assistantNoConnection.
  ///
  /// In en, this message translates to:
  /// **'Couldn’t reach Home Assistant. Try again.'**
  String get assistantNoConnection;

  /// No description provided for @assistantNotConfirmed.
  ///
  /// In en, this message translates to:
  /// **'Home Assistant didn’t confirm the change'**
  String get assistantNotConfirmed;

  /// Button to send a web page to a different person’s phone.
  ///
  /// In en, this message translates to:
  /// **'Someone else'**
  String get assistantOtherPerson;

  /// No description provided for @assistantPhaseListening.
  ///
  /// In en, this message translates to:
  /// **'Listening…'**
  String get assistantPhaseListening;

  /// No description provided for @assistantPhaseReadyFresh.
  ///
  /// In en, this message translates to:
  /// **'How can I help?'**
  String get assistantPhaseReadyFresh;

  /// No description provided for @assistantPhaseReadyMore.
  ///
  /// In en, this message translates to:
  /// **'Anything else?'**
  String get assistantPhaseReadyMore;

  /// No description provided for @assistantPhaseThinking.
  ///
  /// In en, this message translates to:
  /// **'Let me see…'**
  String get assistantPhaseThinking;

  /// No description provided for @assistantPrice.
  ///
  /// In en, this message translates to:
  /// **'{currency}{amount}'**
  String assistantPrice(String amount, String currency);

  /// No description provided for @assistantPromptSay.
  ///
  /// In en, this message translates to:
  /// **'Say what you need…'**
  String get assistantPromptSay;

  /// No description provided for @assistantPromptTapMic.
  ///
  /// In en, this message translates to:
  /// **'Tap the microphone to speak'**
  String get assistantPromptTapMic;

  /// No description provided for @assistantPromptType.
  ///
  /// In en, this message translates to:
  /// **'Type what you need…'**
  String get assistantPromptType;

  /// No description provided for @assistantRecognisingVoice.
  ///
  /// In en, this message translates to:
  /// **'Recognising the voice…'**
  String get assistantRecognisingVoice;

  /// No description provided for @assistantResultSeen.
  ///
  /// In en, this message translates to:
  /// **'{title} · seen'**
  String assistantResultSeen(String title);

  /// No description provided for @assistantResultUndone.
  ///
  /// In en, this message translates to:
  /// **'{title} · undone'**
  String assistantResultUndone(String title);

  /// No description provided for @assistantResults.
  ///
  /// In en, this message translates to:
  /// **'Results'**
  String get assistantResults;

  /// No description provided for @assistantSearchingAndWriting.
  ///
  /// In en, this message translates to:
  /// **'Searching and writing… the final answer will appear shortly'**
  String get assistantSearchingAndWriting;

  /// Opens the doorbell call history.
  ///
  /// In en, this message translates to:
  /// **'See history'**
  String get assistantSeeHistory;

  /// Keyboard button that sends the typed request.
  ///
  /// In en, this message translates to:
  /// **'Send'**
  String get assistantSend;

  /// No description provided for @assistantSent.
  ///
  /// In en, this message translates to:
  /// **'Sent'**
  String get assistantSent;

  /// No description provided for @assistantSentToPhone.
  ///
  /// In en, this message translates to:
  /// **'Sent to {name}’s phone'**
  String assistantSentToPhone(String name);

  /// No description provided for @assistantServings.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 serving} other{{count} servings}}'**
  String assistantServings(int count);

  /// No description provided for @assistantSpeakerSemantics.
  ///
  /// In en, this message translates to:
  /// **'Talking to {name}, recognised by voice'**
  String assistantSpeakerSemantics(String name);

  /// No description provided for @assistantSpeakingNow.
  ///
  /// In en, this message translates to:
  /// **'Speaking now'**
  String get assistantSpeakingNow;

  /// Status chip.
  ///
  /// In en, this message translates to:
  /// **'Listening'**
  String get assistantStatusListening;

  /// Status chip; the assistant (Nabu) is ready.
  ///
  /// In en, this message translates to:
  /// **'Ready'**
  String get assistantStatusReady;

  /// Status chip.
  ///
  /// In en, this message translates to:
  /// **'Answering'**
  String get assistantStatusSpeaking;

  /// Status chip.
  ///
  /// In en, this message translates to:
  /// **'Thinking'**
  String get assistantStatusThinking;

  /// Subtitle under the assistant’s name; the second part is the product name.
  ///
  /// In en, this message translates to:
  /// **'The house\'s assistant · Home Assistant'**
  String get assistantSubtitle;

  /// Example request the user can tap to send to the assistant.
  ///
  /// In en, this message translates to:
  /// **'What’s for dinner?'**
  String get assistantSuggestDinner;

  /// Example request the user can tap to send to the assistant.
  ///
  /// In en, this message translates to:
  /// **'Who rang the doorbell today?'**
  String get assistantSuggestDoorbell;

  /// Example request the user can tap to send to the assistant.
  ///
  /// In en, this message translates to:
  /// **'Turn off all the lights'**
  String get assistantSuggestLightsOff;

  /// Example request the user can tap to send to the assistant.
  ///
  /// In en, this message translates to:
  /// **'What’s the weather tomorrow?'**
  String get assistantSuggestWeather;

  /// No description provided for @assistantTypeHint.
  ///
  /// In en, this message translates to:
  /// **'Type a question…'**
  String get assistantTypeHint;

  /// No description provided for @assistantUndo.
  ///
  /// In en, this message translates to:
  /// **'Undo'**
  String get assistantUndo;

  /// State of a lock.
  ///
  /// In en, this message translates to:
  /// **'Unlocked'**
  String get assistantUnlocked;

  /// No description provided for @assistantViews.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 view} other{{count} views}}'**
  String assistantViews(int count);

  /// No description provided for @assistantViewsMillions.
  ///
  /// In en, this message translates to:
  /// **'{value}M views'**
  String assistantViewsMillions(String value);

  /// No description provided for @assistantViewsThousands.
  ///
  /// In en, this message translates to:
  /// **'{count}K views'**
  String assistantViewsThousands(int count);

  /// Heading above web result cards still loading (all caps).
  ///
  /// In en, this message translates to:
  /// **'LOADING'**
  String get assistantWebLoading;

  /// Heading above a row of web result cards (all caps).
  ///
  /// In en, this message translates to:
  /// **'NEWS'**
  String get assistantWebNews;

  /// Heading above a row of web result cards (all caps).
  ///
  /// In en, this message translates to:
  /// **'ON THE WEB'**
  String get assistantWebOther;

  /// Heading above a row of web result cards (all caps).
  ///
  /// In en, this message translates to:
  /// **'PLACES NEAR HOME'**
  String get assistantWebPlaces;

  /// Heading above a row of web result cards (all caps).
  ///
  /// In en, this message translates to:
  /// **'WHERE TO BUY'**
  String get assistantWebProducts;

  /// Heading above a row of web result cards (all caps).
  ///
  /// In en, this message translates to:
  /// **'RECIPES ON THE WEB'**
  String get assistantWebRecipes;

  /// Heading above a row of web result cards (all caps).
  ///
  /// In en, this message translates to:
  /// **'VIDEOS'**
  String get assistantWebVideos;

  /// No description provided for @assistantWriting.
  ///
  /// In en, this message translates to:
  /// **'Writing…'**
  String get assistantWriting;

  /// Spoken (text-to-speech) while the assistant is working on an answer.
  ///
  /// In en, this message translates to:
  /// **'I’ll look it up online.'**
  String get narratorSearching1;

  /// Spoken (text-to-speech) while the assistant is working on an answer.
  ///
  /// In en, this message translates to:
  /// **'Let me search for that.'**
  String get narratorSearching2;

  /// Spoken (text-to-speech) while the assistant is working on an answer.
  ///
  /// In en, this message translates to:
  /// **'Let’s see what I can find.'**
  String get narratorSearching3;

  /// Spoken (text-to-speech) while the assistant is working on an answer.
  ///
  /// In en, this message translates to:
  /// **'Searching now.'**
  String get narratorSearching4;

  /// Spoken (text-to-speech) while the assistant is working on an answer.
  ///
  /// In en, this message translates to:
  /// **'Still looking, just a little longer.'**
  String get narratorStillWorking1;

  /// Spoken (text-to-speech) while the assistant is working on an answer.
  ///
  /// In en, this message translates to:
  /// **'Almost there.'**
  String get narratorStillWorking2;

  /// Spoken (text-to-speech) while the assistant is working on an answer.
  ///
  /// In en, this message translates to:
  /// **'Still searching, one moment.'**
  String get narratorStillWorking3;

  /// Spoken (text-to-speech) while the assistant is working on an answer.
  ///
  /// In en, this message translates to:
  /// **'Just a little bit more.'**
  String get narratorStillWorking4;

  /// Spoken (text-to-speech) while the assistant is working on an answer.
  ///
  /// In en, this message translates to:
  /// **'Let me think.'**
  String get narratorThinking1;

  /// Spoken (text-to-speech) while the assistant is working on an answer.
  ///
  /// In en, this message translates to:
  /// **'Hmm, one moment.'**
  String get narratorThinking2;

  /// Spoken (text-to-speech) while the assistant is working on an answer.
  ///
  /// In en, this message translates to:
  /// **'I’m thinking about it.'**
  String get narratorThinking3;

  /// Spoken (text-to-speech) while the assistant is working on an answer.
  ///
  /// In en, this message translates to:
  /// **'Good question, let me see.'**
  String get narratorThinking4;

  /// No description provided for @recadoDayAt.
  ///
  /// In en, this message translates to:
  /// **'{day} at {time}'**
  String recadoDayAt(String day, String time);

  /// No description provided for @recadoFor.
  ///
  /// In en, this message translates to:
  /// **'For {name}'**
  String recadoFor(String name);

  /// No description provided for @recadoForEveryone.
  ///
  /// In en, this message translates to:
  /// **'For everyone'**
  String get recadoForEveryone;

  /// No description provided for @recadoFrom.
  ///
  /// In en, this message translates to:
  /// **'from {name}'**
  String recadoFrom(String name);

  /// No description provided for @recadoFromUnknown.
  ///
  /// In en, this message translates to:
  /// **'from someone · voice not recognised'**
  String get recadoFromUnknown;

  /// No description provided for @recadoGreeting.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Hi! First of all: there’s an unseen message.} other{Hi! First of all: there are {count} unseen messages.}}'**
  String recadoGreeting(int count);

  /// No description provided for @recadoLater.
  ///
  /// In en, this message translates to:
  /// **'Later'**
  String get recadoLater;

  /// No description provided for @recadoMarkAllSeen.
  ///
  /// In en, this message translates to:
  /// **'Mark all as seen'**
  String get recadoMarkAllSeen;

  /// No description provided for @recadoNow.
  ///
  /// In en, this message translates to:
  /// **'just now'**
  String get recadoNow;

  /// No description provided for @recadoQuoted.
  ///
  /// In en, this message translates to:
  /// **'“{text}”'**
  String recadoQuoted(String text);

  /// No description provided for @recadoRow.
  ///
  /// In en, this message translates to:
  /// **'Message'**
  String get recadoRow;

  /// No description provided for @recadoRowFrom.
  ///
  /// In en, this message translates to:
  /// **'Message from {name}'**
  String recadoRowFrom(String name);

  /// No description provided for @recadoRowTo.
  ///
  /// In en, this message translates to:
  /// **'for {name}'**
  String recadoRowTo(String name);

  /// No description provided for @recadoRowToEveryone.
  ///
  /// In en, this message translates to:
  /// **'for everyone'**
  String get recadoRowToEveryone;

  /// No description provided for @recadoSeen.
  ///
  /// In en, this message translates to:
  /// **'Seen'**
  String get recadoSeen;

  /// No description provided for @recadoSeenBy.
  ///
  /// In en, this message translates to:
  /// **'Seen by {name}'**
  String recadoSeenBy(String name);

  /// No description provided for @recadoStayUntilSeen.
  ///
  /// In en, this message translates to:
  /// **'They stay here until someone marks them as seen'**
  String get recadoStayUntilSeen;

  /// No description provided for @recadoTitleEveryone.
  ///
  /// In en, this message translates to:
  /// **'Message for everyone'**
  String get recadoTitleEveryone;

  /// No description provided for @recadoTitleFor.
  ///
  /// In en, this message translates to:
  /// **'Message for {name}'**
  String recadoTitleFor(String name);

  /// No description provided for @recadoUnseenCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 unseen message} other{{count} unseen messages}}'**
  String recadoUnseenCount(int count);

  /// No description provided for @recadoVoiceHint.
  ///
  /// In en, this message translates to:
  /// **'Say “Ok Nabu, seen” or “later”. Once marked as seen, it disappears from every screen.'**
  String get recadoVoiceHint;

  /// No description provided for @voicesAlmostDone.
  ///
  /// In en, this message translates to:
  /// **'Almost done'**
  String get voicesAlmostDone;

  /// No description provided for @voicesDeleteBody.
  ///
  /// In en, this message translates to:
  /// **'The assistant will stop recognising this voice and will no longer use this person’s calendar or list. You can register it again at any time.'**
  String get voicesDeleteBody;

  /// No description provided for @voicesDeleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete {name}’s voice?'**
  String voicesDeleteTitle(String name);

  /// No description provided for @voicesDeleted.
  ///
  /// In en, this message translates to:
  /// **'{name}’s voice deleted'**
  String voicesDeleted(String name);

  /// No description provided for @voicesDoneBetter.
  ///
  /// In en, this message translates to:
  /// **'Done! The assistant now recognises {name}’s voice better.'**
  String voicesDoneBetter(String name);

  /// No description provided for @voicesDoneNew.
  ///
  /// In en, this message translates to:
  /// **'Done! The assistant now recognises {name}’s voice.'**
  String voicesDoneNew(String name);

  /// No description provided for @voicesErrorIncompatible.
  ///
  /// In en, this message translates to:
  /// **'The registered voices are from another model ({reason}); delete them and register again.'**
  String voicesErrorIncompatible(String reason);

  /// No description provided for @voicesErrorNoResponse.
  ///
  /// In en, this message translates to:
  /// **'Voice identification didn’t respond ({details})'**
  String voicesErrorNoResponse(String details);

  /// No description provided for @voicesErrorUnknown.
  ///
  /// In en, this message translates to:
  /// **'unknown error'**
  String get voicesErrorUnknown;

  /// No description provided for @voicesIntroBody.
  ///
  /// In en, this message translates to:
  /// **'{name} will read {count} sentences aloud, one at a time, from where they usually talk to the screen, in their everyday voice.'**
  String voicesIntroBody(String name, int count);

  /// No description provided for @voicesIntroSummary.
  ///
  /// In en, this message translates to:
  /// **'{count} sentences · about 1 minute'**
  String voicesIntroSummary(int count);

  /// No description provided for @voicesIntroTakeLength.
  ///
  /// In en, this message translates to:
  /// **'Each recording lasts {seconds} seconds. The assistant stays quiet meanwhile.'**
  String voicesIntroTakeLength(int seconds);

  /// No description provided for @voicesLoadError.
  ///
  /// In en, this message translates to:
  /// **'Couldn’t read the registered voices.'**
  String get voicesLoadError;

  /// No description provided for @voicesLoading.
  ///
  /// In en, this message translates to:
  /// **'Loading voices…'**
  String get voicesLoading;

  /// No description provided for @voicesMicError.
  ///
  /// In en, this message translates to:
  /// **'Couldn’t use the microphone ({error}).'**
  String voicesMicError(String error);

  /// No description provided for @voicesMoreSamples.
  ///
  /// In en, this message translates to:
  /// **'More samples'**
  String get voicesMoreSamples;

  /// No description provided for @voicesMoreSamplesOf.
  ///
  /// In en, this message translates to:
  /// **'More samples of {name}'**
  String voicesMoreSamplesOf(String name);

  /// No description provided for @voicesNoPeopleBody.
  ///
  /// In en, this message translates to:
  /// **'Add them in the ByteHomeDash panel in Home Assistant, under People. Then each person registers their voice here.'**
  String get voicesNoPeopleBody;

  /// No description provided for @voicesNoPeopleTitle.
  ///
  /// In en, this message translates to:
  /// **'No people yet'**
  String get voicesNoPeopleTitle;

  /// No description provided for @voicesNotInstalledBody.
  ///
  /// In en, this message translates to:
  /// **'Voices can’t be registered without it. Check the installation in the ByteHomeDash panel in Home Assistant.'**
  String get voicesNotInstalledBody;

  /// No description provided for @voicesNotInstalledTitle.
  ///
  /// In en, this message translates to:
  /// **'The voice assistant isn’t installed on this screen.'**
  String get voicesNotInstalledTitle;

  /// No description provided for @voicesNotRecognised.
  ///
  /// In en, this message translates to:
  /// **'The assistant doesn’t recognise this voice yet'**
  String get voicesNotRecognised;

  /// A sentence the person reads aloud to enrol their voice; should sound like an ordinary request to the assistant.
  ///
  /// In en, this message translates to:
  /// **'Hi, it’s me. Turn on the living room lights and tell me what the weather’s like today.'**
  String get voicesPhrase1;

  /// Read aloud when enrolling a voice.
  ///
  /// In en, this message translates to:
  /// **'What events do I have on the calendar for tomorrow morning?'**
  String get voicesPhrase2;

  /// Read aloud when enrolling a voice.
  ///
  /// In en, this message translates to:
  /// **'Add milk, eggs and bread to the shopping list, please.'**
  String get voicesPhrase3;

  /// Read aloud when enrolling a voice.
  ///
  /// In en, this message translates to:
  /// **'Play some calm music in the kitchen and turn the volume down a little.'**
  String get voicesPhrase4;

  /// Read aloud when enrolling a voice.
  ///
  /// In en, this message translates to:
  /// **'Remind me to call grandma on Saturday at ten in the morning.'**
  String get voicesPhrase5;

  /// No description provided for @voicesPhraseOf.
  ///
  /// In en, this message translates to:
  /// **'Sentence {index} of {count}'**
  String voicesPhraseOf(int index, int count);

  /// No description provided for @voicesPhraseQuoted.
  ///
  /// In en, this message translates to:
  /// **'“{phrase}”'**
  String voicesPhraseQuoted(String phrase);

  /// No description provided for @voicesPrivacyNote.
  ///
  /// In en, this message translates to:
  /// **'Everything stays on this screen: only a “fingerprint” of the voice is kept, never the recordings. Recognition is a convenience, not a password: it doesn’t open doors or turn off alarms.'**
  String get voicesPrivacyNote;

  /// No description provided for @voicesReadyHint.
  ///
  /// In en, this message translates to:
  /// **'Tap Record and read the sentence aloud.'**
  String get voicesReadyHint;

  /// No description provided for @voicesRecord.
  ///
  /// In en, this message translates to:
  /// **'Record'**
  String get voicesRecord;

  /// No description provided for @voicesRecordAgain.
  ///
  /// In en, this message translates to:
  /// **'Record again'**
  String get voicesRecordAgain;

  /// No description provided for @voicesRecording.
  ///
  /// In en, this message translates to:
  /// **'Recording · {seconds} s'**
  String voicesRecording(int seconds);

  /// No description provided for @voicesRecordingEnds.
  ///
  /// In en, this message translates to:
  /// **'Stops by itself after {seconds} seconds.'**
  String voicesRecordingEnds(int seconds);

  /// No description provided for @voicesRegister.
  ///
  /// In en, this message translates to:
  /// **'Register voice'**
  String get voicesRegister;

  /// No description provided for @voicesRegisterFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn’t register the voice.'**
  String get voicesRegisterFailed;

  /// No description provided for @voicesRegisterOf.
  ///
  /// In en, this message translates to:
  /// **'Register {name}’s voice'**
  String voicesRegisterOf(String name);

  /// No description provided for @voicesRegistered.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Voice registered · 1 sample} other{Voice registered · {count} samples}}'**
  String voicesRegistered(int count);

  /// No description provided for @voicesRejectedTakes.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{One recording wasn’t used} other{{count} recordings weren’t used}} (too little speech), but {samples} samples were kept.'**
  String voicesRejectedTakes(int count, int samples);

  /// No description provided for @voicesRetry.
  ///
  /// In en, this message translates to:
  /// **'I didn’t hear that well. Read it again, a little louder.'**
  String get voicesRetry;

  /// No description provided for @voicesSamplesAdded.
  ///
  /// In en, this message translates to:
  /// **'{count} more samples of {name}’s voice were added.'**
  String voicesSamplesAdded(int count, String name);

  /// No description provided for @voicesSamplesKept.
  ///
  /// In en, this message translates to:
  /// **'{count} samples of {name}’s voice were kept.'**
  String voicesSamplesKept(int count, String name);

  /// No description provided for @voicesSaving.
  ///
  /// In en, this message translates to:
  /// **'Saving the voice…'**
  String get voicesSaving;

  /// No description provided for @voicesSomethingWrong.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong'**
  String get voicesSomethingWrong;

  /// No description provided for @voicesStart.
  ///
  /// In en, this message translates to:
  /// **'Start'**
  String get voicesStart;

  /// No description provided for @voicesSubtitle.
  ///
  /// In en, this message translates to:
  /// **'The assistant recognises who is speaking and uses that person’s calendar and reminders.'**
  String get voicesSubtitle;

  /// No description provided for @voicesTitle.
  ///
  /// In en, this message translates to:
  /// **'Recognised voices'**
  String get voicesTitle;

  /// No description provided for @acModeHeat.
  ///
  /// In en, this message translates to:
  /// **'Heat'**
  String get acModeHeat;

  /// No description provided for @acModeCool.
  ///
  /// In en, this message translates to:
  /// **'Cool'**
  String get acModeCool;

  /// No description provided for @acModeFan.
  ///
  /// In en, this message translates to:
  /// **'Fan'**
  String get acModeFan;

  /// No description provided for @acFanLow.
  ///
  /// In en, this message translates to:
  /// **'Low'**
  String get acFanLow;

  /// No description provided for @acFanQuiet.
  ///
  /// In en, this message translates to:
  /// **'Quiet'**
  String get acFanQuiet;

  /// No description provided for @acFanMedium.
  ///
  /// In en, this message translates to:
  /// **'Medium'**
  String get acFanMedium;

  /// No description provided for @acFanHigh.
  ///
  /// In en, this message translates to:
  /// **'High'**
  String get acFanHigh;

  /// No description provided for @houseLockLocked.
  ///
  /// In en, this message translates to:
  /// **'Locked'**
  String get houseLockLocked;

  /// No description provided for @houseLockUnlocked.
  ///
  /// In en, this message translates to:
  /// **'Unlocked'**
  String get houseLockUnlocked;

  /// State of a gate or door sensor (masculine in Portuguese, e.g. "portão")
  ///
  /// In en, this message translates to:
  /// **'Closed'**
  String get houseGateClosed;

  /// State of a gate or door sensor (masculine in Portuguese, e.g. "portão")
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get houseGateOpen;

  /// State of a door (feminine in Portuguese, "porta")
  ///
  /// In en, this message translates to:
  /// **'Closed'**
  String get houseDoorClosed;

  /// State of a door (feminine in Portuguese, "porta")
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get houseDoorOpen;

  /// No description provided for @houseLockUnlock.
  ///
  /// In en, this message translates to:
  /// **'Unlock'**
  String get houseLockUnlock;

  /// No description provided for @houseLockLock.
  ///
  /// In en, this message translates to:
  /// **'Lock'**
  String get houseLockLock;

  /// No description provided for @houseLocksSetupHint.
  ///
  /// In en, this message translates to:
  /// **'Choose the locks in Home Assistant: ByteHomeDash › House'**
  String get houseLocksSetupHint;

  /// No description provided for @roomExtraLocked.
  ///
  /// In en, this message translates to:
  /// **'{name} locked'**
  String roomExtraLocked(String name);

  /// A lock entity that is not locked
  ///
  /// In en, this message translates to:
  /// **'{name} open'**
  String roomExtraUnlocked(String name);

  /// A cover (blind, gate) that is closed
  ///
  /// In en, this message translates to:
  /// **'{name} closed'**
  String roomExtraClosed(String name);

  /// A cover (blind, gate) that is open
  ///
  /// In en, this message translates to:
  /// **'{name} open'**
  String roomExtraOpen(String name);

  /// No description provided for @roomHighHumidity.
  ///
  /// In en, this message translates to:
  /// **'High humidity'**
  String get roomHighHumidity;

  /// No description provided for @carAtHome.
  ///
  /// In en, this message translates to:
  /// **'At home'**
  String get carAtHome;

  /// No description provided for @carAway.
  ///
  /// In en, this message translates to:
  /// **'Away'**
  String get carAway;

  /// No description provided for @carDefaultName.
  ///
  /// In en, this message translates to:
  /// **'Car'**
  String get carDefaultName;

  /// No description provided for @houseWeatherSunny.
  ///
  /// In en, this message translates to:
  /// **'Sunny'**
  String get houseWeatherSunny;

  /// No description provided for @houseWeatherClearNight.
  ///
  /// In en, this message translates to:
  /// **'Clear sky'**
  String get houseWeatherClearNight;

  /// No description provided for @houseWeatherPartlyCloudy.
  ///
  /// In en, this message translates to:
  /// **'Partly cloudy'**
  String get houseWeatherPartlyCloudy;

  /// No description provided for @houseWeatherCloudy.
  ///
  /// In en, this message translates to:
  /// **'Cloudy'**
  String get houseWeatherCloudy;

  /// No description provided for @houseWeatherRainy.
  ///
  /// In en, this message translates to:
  /// **'Rain'**
  String get houseWeatherRainy;

  /// No description provided for @houseWeatherPouring.
  ///
  /// In en, this message translates to:
  /// **'Heavy rain'**
  String get houseWeatherPouring;

  /// No description provided for @houseWeatherLightning.
  ///
  /// In en, this message translates to:
  /// **'Thunderstorm'**
  String get houseWeatherLightning;

  /// No description provided for @houseWeatherSnowy.
  ///
  /// In en, this message translates to:
  /// **'Snow'**
  String get houseWeatherSnowy;

  /// No description provided for @houseWeatherHail.
  ///
  /// In en, this message translates to:
  /// **'Hail'**
  String get houseWeatherHail;

  /// No description provided for @houseWeatherFog.
  ///
  /// In en, this message translates to:
  /// **'Fog'**
  String get houseWeatherFog;

  /// No description provided for @houseWeatherWindy.
  ///
  /// In en, this message translates to:
  /// **'Wind'**
  String get houseWeatherWindy;

  /// No description provided for @houseWeatherExceptional.
  ///
  /// In en, this message translates to:
  /// **'Exceptional weather'**
  String get houseWeatherExceptional;

  /// No description provided for @houseWhenToday.
  ///
  /// In en, this message translates to:
  /// **'today at {time}'**
  String houseWhenToday(String time);

  /// No description provided for @houseWhenYesterday.
  ///
  /// In en, this message translates to:
  /// **'yesterday at {time}'**
  String houseWhenYesterday(String time);

  /// day is a short weekday ("sat") or a short date ("12 oct")
  ///
  /// In en, this message translates to:
  /// **'{day} at {time}'**
  String houseWhenDay(String day, String time);

  /// Wind direction, used in "From {direction}"
  ///
  /// In en, this message translates to:
  /// **'north'**
  String get houseCompassN;

  /// No description provided for @houseCompassNE.
  ///
  /// In en, this message translates to:
  /// **'northeast'**
  String get houseCompassNE;

  /// No description provided for @houseCompassE.
  ///
  /// In en, this message translates to:
  /// **'east'**
  String get houseCompassE;

  /// No description provided for @houseCompassSE.
  ///
  /// In en, this message translates to:
  /// **'southeast'**
  String get houseCompassSE;

  /// No description provided for @houseCompassS.
  ///
  /// In en, this message translates to:
  /// **'south'**
  String get houseCompassS;

  /// No description provided for @houseCompassSW.
  ///
  /// In en, this message translates to:
  /// **'southwest'**
  String get houseCompassSW;

  /// No description provided for @houseCompassW.
  ///
  /// In en, this message translates to:
  /// **'west'**
  String get houseCompassW;

  /// No description provided for @houseCompassNW.
  ///
  /// In en, this message translates to:
  /// **'northwest'**
  String get houseCompassNW;

  /// UV index level
  ///
  /// In en, this message translates to:
  /// **'Low'**
  String get houseUvLow;

  /// No description provided for @houseUvModerate.
  ///
  /// In en, this message translates to:
  /// **'Moderate'**
  String get houseUvModerate;

  /// No description provided for @houseUvHigh.
  ///
  /// In en, this message translates to:
  /// **'High'**
  String get houseUvHigh;

  /// No description provided for @houseUvVeryHigh.
  ///
  /// In en, this message translates to:
  /// **'Very high'**
  String get houseUvVeryHigh;

  /// No description provided for @houseUvExtreme.
  ///
  /// In en, this message translates to:
  /// **'Extreme'**
  String get houseUvExtreme;

  /// level is a UV level such as "Moderate"
  ///
  /// In en, this message translates to:
  /// **'{level} now'**
  String houseUvNow(String level);

  /// No description provided for @houseStationJustNow.
  ///
  /// In en, this message translates to:
  /// **'weather station, just now'**
  String get houseStationJustNow;

  /// No description provided for @houseStationMinutesAgo.
  ///
  /// In en, this message translates to:
  /// **'weather station, {minutes} min ago'**
  String houseStationMinutesAgo(int minutes);

  /// No description provided for @houseTodayDate.
  ///
  /// In en, this message translates to:
  /// **'Today, {weekday}, {month} {day}'**
  String houseTodayDate(String weekday, String day, String month);

  /// No description provided for @houseTrendSteadyHour.
  ///
  /// In en, this message translates to:
  /// **'Steady over the last hour'**
  String get houseTrendSteadyHour;

  /// No description provided for @houseTrendRisingHour.
  ///
  /// In en, this message translates to:
  /// **'Rising · +{degrees}° in the last hour'**
  String houseTrendRisingHour(String degrees);

  /// No description provided for @houseTrendFallingHour.
  ///
  /// In en, this message translates to:
  /// **'Falling · −{degrees}° in the last hour'**
  String houseTrendFallingHour(String degrees);

  /// No description provided for @houseHumidity.
  ///
  /// In en, this message translates to:
  /// **'Humidity'**
  String get houseHumidity;

  /// No description provided for @houseDewPoint.
  ///
  /// In en, this message translates to:
  /// **'Dew point {degrees}°'**
  String houseDewPoint(String degrees);

  /// No description provided for @houseOutdoorHumidity.
  ///
  /// In en, this message translates to:
  /// **'Outdoor humidity'**
  String get houseOutdoorHumidity;

  /// No description provided for @houseWind.
  ///
  /// In en, this message translates to:
  /// **'Wind'**
  String get houseWind;

  /// direction is a compass word such as "north"
  ///
  /// In en, this message translates to:
  /// **'From the {direction}'**
  String houseWindFrom(String direction);

  /// No description provided for @houseWindGustMax.
  ///
  /// In en, this message translates to:
  /// **'max gust {speed}'**
  String houseWindGustMax(String speed);

  /// No description provided for @houseRainingRate.
  ///
  /// In en, this message translates to:
  /// **'Raining · {rate} mm/h'**
  String houseRainingRate(String rate);

  /// No description provided for @houseRainAccumulatedToday.
  ///
  /// In en, this message translates to:
  /// **'Total today · no rain now'**
  String get houseRainAccumulatedToday;

  /// No description provided for @houseRainToday.
  ///
  /// In en, this message translates to:
  /// **'Rain today'**
  String get houseRainToday;

  /// No description provided for @housePressure.
  ///
  /// In en, this message translates to:
  /// **'Pressure'**
  String get housePressure;

  /// No description provided for @houseTrendRising.
  ///
  /// In en, this message translates to:
  /// **'Rising'**
  String get houseTrendRising;

  /// No description provided for @houseTrendFalling.
  ///
  /// In en, this message translates to:
  /// **'Falling'**
  String get houseTrendFalling;

  /// No description provided for @houseTrendSteady.
  ///
  /// In en, this message translates to:
  /// **'Steady'**
  String get houseTrendSteady;

  /// No description provided for @houseAtmosphericPressure.
  ///
  /// In en, this message translates to:
  /// **'Atmospheric pressure'**
  String get houseAtmosphericPressure;

  /// No description provided for @houseUvIndex.
  ///
  /// In en, this message translates to:
  /// **'UV index'**
  String get houseUvIndex;

  /// No description provided for @houseSolarRadiation.
  ///
  /// In en, this message translates to:
  /// **'Solar radiation'**
  String get houseSolarRadiation;

  /// No description provided for @houseTrendIncreasing.
  ///
  /// In en, this message translates to:
  /// **'Increasing'**
  String get houseTrendIncreasing;

  /// No description provided for @houseTrendDecreasing.
  ///
  /// In en, this message translates to:
  /// **'Decreasing'**
  String get houseTrendDecreasing;

  /// No description provided for @houseOutdoorTemperature.
  ///
  /// In en, this message translates to:
  /// **'Outdoor temperature'**
  String get houseOutdoorTemperature;

  /// No description provided for @energySummaryHome.
  ///
  /// In en, this message translates to:
  /// **'Right now the house uses {power}'**
  String energySummaryHome(String power);

  /// No description provided for @energySummaryHomeOwn.
  ///
  /// In en, this message translates to:
  /// **'Right now the house uses {power}, {percent}% from the sun and the battery'**
  String energySummaryHomeOwn(String power, int percent);

  /// Joined after the house usage with " · ", capitalised if first
  ///
  /// In en, this message translates to:
  /// **'battery at {percent}%'**
  String energySummaryBattery(int percent);

  /// No description provided for @energySummaryBatteryUntil.
  ///
  /// In en, this message translates to:
  /// **'battery at {percent}%, lasts until {time}'**
  String energySummaryBatteryUntil(int percent, String time);

  /// No description provided for @vacuumStateDocked.
  ///
  /// In en, this message translates to:
  /// **'Docked'**
  String get vacuumStateDocked;

  /// No description provided for @vacuumStateCleaning.
  ///
  /// In en, this message translates to:
  /// **'Cleaning'**
  String get vacuumStateCleaning;

  /// No description provided for @vacuumStatePaused.
  ///
  /// In en, this message translates to:
  /// **'Paused'**
  String get vacuumStatePaused;

  /// No description provided for @vacuumStateReturning.
  ///
  /// In en, this message translates to:
  /// **'Returning to base'**
  String get vacuumStateReturning;

  /// No description provided for @vacuumStateIdle.
  ///
  /// In en, this message translates to:
  /// **'Stopped'**
  String get vacuumStateIdle;

  /// No description provided for @vacuumStateError.
  ///
  /// In en, this message translates to:
  /// **'Error'**
  String get vacuumStateError;

  /// No description provided for @vacuumPartMainBrush.
  ///
  /// In en, this message translates to:
  /// **'Main brush'**
  String get vacuumPartMainBrush;

  /// No description provided for @vacuumPartSideBrush.
  ///
  /// In en, this message translates to:
  /// **'Side brush'**
  String get vacuumPartSideBrush;

  /// No description provided for @vacuumPartFilter.
  ///
  /// In en, this message translates to:
  /// **'Filter'**
  String get vacuumPartFilter;

  /// No description provided for @vacuumPartSensors.
  ///
  /// In en, this message translates to:
  /// **'Sensors'**
  String get vacuumPartSensors;

  /// No description provided for @vacuumPartWheels.
  ///
  /// In en, this message translates to:
  /// **'Wheels'**
  String get vacuumPartWheels;

  /// No description provided for @vacuumPartScaleInhibitor.
  ///
  /// In en, this message translates to:
  /// **'Scale inhibitor'**
  String get vacuumPartScaleInhibitor;

  /// Robot vacuum cleaning mode
  ///
  /// In en, this message translates to:
  /// **'Vacuum'**
  String get vacuumModeSweeping;

  /// Robot vacuum cleaning mode
  ///
  /// In en, this message translates to:
  /// **'Mop'**
  String get vacuumModeMopping;

  /// No description provided for @vacuumModeSweepingAndMopping.
  ///
  /// In en, this message translates to:
  /// **'Vacuum and mop'**
  String get vacuumModeSweepingAndMopping;

  /// No description provided for @vacuumModeMoppingAfterSweeping.
  ///
  /// In en, this message translates to:
  /// **'Mop after vacuuming'**
  String get vacuumModeMoppingAfterSweeping;

  /// No description provided for @vacuumSuctionQuiet.
  ///
  /// In en, this message translates to:
  /// **'Quiet'**
  String get vacuumSuctionQuiet;

  /// Suction level or cleaning route
  ///
  /// In en, this message translates to:
  /// **'Standard'**
  String get vacuumStandard;

  /// No description provided for @vacuumSuctionStrong.
  ///
  /// In en, this message translates to:
  /// **'Strong'**
  String get vacuumSuctionStrong;

  /// No description provided for @vacuumSuctionMax.
  ///
  /// In en, this message translates to:
  /// **'Max'**
  String get vacuumSuctionMax;

  /// Mop pad humidity
  ///
  /// In en, this message translates to:
  /// **'Slightly damp'**
  String get vacuumMopSlightlyDry;

  /// Mop pad humidity
  ///
  /// In en, this message translates to:
  /// **'Damp'**
  String get vacuumMopMoist;

  /// Mop pad humidity
  ///
  /// In en, this message translates to:
  /// **'Wet'**
  String get vacuumMopWet;

  /// Cleaning route
  ///
  /// In en, this message translates to:
  /// **'Quick'**
  String get vacuumRouteQuick;

  /// Cleaning route
  ///
  /// In en, this message translates to:
  /// **'Intensive'**
  String get vacuumRouteIntensive;

  /// Cleaning route / CleanGenius mode
  ///
  /// In en, this message translates to:
  /// **'Deep'**
  String get vacuumDeep;

  /// CleanGenius mode
  ///
  /// In en, this message translates to:
  /// **'Routine'**
  String get vacuumGeniusRoutine;

  /// No description provided for @vacuumErrorMainBrush.
  ///
  /// In en, this message translates to:
  /// **'Main brush stuck'**
  String get vacuumErrorMainBrush;

  /// No description provided for @vacuumErrorMainBrushFix.
  ///
  /// In en, this message translates to:
  /// **'Turn the robot over, remove hair or objects caught in the main brush and tap Resume.'**
  String get vacuumErrorMainBrushFix;

  /// No description provided for @vacuumErrorSideBrush.
  ///
  /// In en, this message translates to:
  /// **'Side brush stuck'**
  String get vacuumErrorSideBrush;

  /// No description provided for @vacuumErrorSideBrushFix.
  ///
  /// In en, this message translates to:
  /// **'Free the side brush and tap Resume.'**
  String get vacuumErrorSideBrushFix;

  /// No description provided for @vacuumErrorWheel.
  ///
  /// In en, this message translates to:
  /// **'Wheel stuck'**
  String get vacuumErrorWheel;

  /// No description provided for @vacuumErrorWheelFix.
  ///
  /// In en, this message translates to:
  /// **'Move the robot somewhere else and tap Resume.'**
  String get vacuumErrorWheelFix;

  /// No description provided for @vacuumErrorDrop.
  ///
  /// In en, this message translates to:
  /// **'Wheels off the floor'**
  String get vacuumErrorDrop;

  /// No description provided for @vacuumErrorDropFix.
  ///
  /// In en, this message translates to:
  /// **'Put the robot on the floor and tap Resume.'**
  String get vacuumErrorDropFix;

  /// No description provided for @vacuumErrorBumper.
  ///
  /// In en, this message translates to:
  /// **'Bumper stuck'**
  String get vacuumErrorBumper;

  /// No description provided for @vacuumErrorBumperFix.
  ///
  /// In en, this message translates to:
  /// **'Check the bumper and tap Resume.'**
  String get vacuumErrorBumperFix;

  /// No description provided for @vacuumErrorDustBin.
  ///
  /// In en, this message translates to:
  /// **'Dust bin missing'**
  String get vacuumErrorDustBin;

  /// No description provided for @vacuumErrorDustBinFix.
  ///
  /// In en, this message translates to:
  /// **'Put the dust bin back and tap Resume.'**
  String get vacuumErrorDustBinFix;

  /// No description provided for @vacuumErrorWaterTank.
  ///
  /// In en, this message translates to:
  /// **'Water tank missing'**
  String get vacuumErrorWaterTank;

  /// No description provided for @vacuumErrorWaterTankFix.
  ///
  /// In en, this message translates to:
  /// **'Put the water tank back and tap Resume.'**
  String get vacuumErrorWaterTankFix;

  /// No description provided for @vacuumErrorLowBattery.
  ///
  /// In en, this message translates to:
  /// **'Low battery'**
  String get vacuumErrorLowBattery;

  /// No description provided for @vacuumErrorLowBatteryFix.
  ///
  /// In en, this message translates to:
  /// **'Take the robot to the base to charge.'**
  String get vacuumErrorLowBatteryFix;

  /// No description provided for @vacuumRoomFallback.
  ///
  /// In en, this message translates to:
  /// **'Room {number}'**
  String vacuumRoomFallback(int number);

  /// No description provided for @vacuumTankCleanWater.
  ///
  /// In en, this message translates to:
  /// **'Clean water'**
  String get vacuumTankCleanWater;

  /// No description provided for @vacuumTankDirtyWater.
  ///
  /// In en, this message translates to:
  /// **'Dirty water'**
  String get vacuumTankDirtyWater;

  /// No description provided for @vacuumTankDustBag.
  ///
  /// In en, this message translates to:
  /// **'Dust bag'**
  String get vacuumTankDustBag;

  /// No description provided for @vacuumTankDetergent.
  ///
  /// In en, this message translates to:
  /// **'Detergent'**
  String get vacuumTankDetergent;

  /// Time left on a consumable
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 day} other{{count} days}}'**
  String vacuumDaysLeft(int count);

  /// History chart title; name is the robot's name
  ///
  /// In en, this message translates to:
  /// **'Battery · {name}'**
  String vacuumBatteryHistory(String name);

  /// Makes the robot beep so it can be found
  ///
  /// In en, this message translates to:
  /// **'Locate'**
  String get vacuumLocate;

  /// No description provided for @vacuumSession.
  ///
  /// In en, this message translates to:
  /// **'{area} m² in {minutes} min'**
  String vacuumSession(String area, String minutes);

  /// room is a room name, e.g. "kitchen"
  ///
  /// In en, this message translates to:
  /// **'Stopped in the {room}.'**
  String vacuumStoppedIn(String room);

  /// No description provided for @vacuumCleaningRoom.
  ///
  /// In en, this message translates to:
  /// **'Cleaning: {room}'**
  String vacuumCleaningRoom(String room);

  /// No description provided for @vacuumPausedRoom.
  ///
  /// In en, this message translates to:
  /// **'Paused: {room}'**
  String vacuumPausedRoom(String room);

  /// No description provided for @vacuumPausedHint.
  ///
  /// In en, this message translates to:
  /// **'Tap Resume to carry on where it stopped.'**
  String get vacuumPausedHint;

  /// session is e.g. "24 m² in 31 min"
  ///
  /// In en, this message translates to:
  /// **'Cleaning finished · {session}'**
  String vacuumCleaningFinished(String session);

  /// No description provided for @vacuumIdleTitle.
  ///
  /// In en, this message translates to:
  /// **'Stopped away from the base'**
  String get vacuumIdleTitle;

  /// No description provided for @vacuumIdleOffBase.
  ///
  /// In en, this message translates to:
  /// **'It’s away from the base. You can start again or send it to the base.'**
  String get vacuumIdleOffBase;

  /// No description provided for @vacuumIdleInRoom.
  ///
  /// In en, this message translates to:
  /// **'It’s in the {room}. You can start again or send it to the base.'**
  String vacuumIdleInRoom(String room);

  /// No description provided for @vacuumDockedWashing.
  ///
  /// In en, this message translates to:
  /// **'At the base · washing the mop'**
  String get vacuumDockedWashing;

  /// No description provided for @vacuumDockedWashingHint.
  ///
  /// In en, this message translates to:
  /// **'The station is washing the mop and refreshing its water.'**
  String get vacuumDockedWashingHint;

  /// No description provided for @vacuumDockedDrying.
  ///
  /// In en, this message translates to:
  /// **'At the base · drying the mop'**
  String get vacuumDockedDrying;

  /// No description provided for @vacuumDryingHint.
  ///
  /// In en, this message translates to:
  /// **'You can start a clean at any time.'**
  String get vacuumDryingHint;

  /// duration is e.g. "1 h 20 min"
  ///
  /// In en, this message translates to:
  /// **'{duration} to go. You can start a clean at any time.'**
  String vacuumDryingLeftHint(String duration);

  /// No description provided for @vacuumDockedEmptying.
  ///
  /// In en, this message translates to:
  /// **'At the base · emptying the bin'**
  String get vacuumDockedEmptying;

  /// No description provided for @vacuumDockedEmptyingHint.
  ///
  /// In en, this message translates to:
  /// **'The dust goes into the station’s bag.'**
  String get vacuumDockedEmptyingHint;

  /// No description provided for @vacuumDockedCharging.
  ///
  /// In en, this message translates to:
  /// **'At the base · charging'**
  String get vacuumDockedCharging;

  /// No description provided for @vacuumDockedFull.
  ///
  /// In en, this message translates to:
  /// **'At the base · fully charged'**
  String get vacuumDockedFull;

  /// session is e.g. "24 m² in 31 min"
  ///
  /// In en, this message translates to:
  /// **'Last clean: {session}'**
  String vacuumLastCleaning(String session);

  /// action is a button label such as "Pause"
  ///
  /// In en, this message translates to:
  /// **'{action}… waiting for Home Assistant to confirm.'**
  String vacuumPendingConfirm(String action);

  /// parts is a list like "filter 12%, side brush 8%"
  ///
  /// In en, this message translates to:
  /// **'Maintenance: {parts}'**
  String vacuumMaintenanceNotice(String parts);

  /// No description provided for @vacuumSeeMaintenance.
  ///
  /// In en, this message translates to:
  /// **'See maintenance'**
  String get vacuumSeeMaintenance;

  /// No description provided for @vacuumMapLive.
  ///
  /// In en, this message translates to:
  /// **'Live map'**
  String get vacuumMapLive;

  /// No description provided for @vacuumMap.
  ///
  /// In en, this message translates to:
  /// **'Map'**
  String get vacuumMap;

  /// History chart title: a statistic and the robot's name
  ///
  /// In en, this message translates to:
  /// **'{stat} · {name}'**
  String vacuumStatHistory(String stat, String name);

  /// No description provided for @vacuumAreaCleaned.
  ///
  /// In en, this message translates to:
  /// **'Area cleaned'**
  String get vacuumAreaCleaned;

  /// No description provided for @vacuumLastCleaningLabel.
  ///
  /// In en, this message translates to:
  /// **'Last clean'**
  String get vacuumLastCleaningLabel;

  /// No description provided for @vacuumTime.
  ///
  /// In en, this message translates to:
  /// **'Time'**
  String get vacuumTime;

  /// No description provided for @vacuumDuration.
  ///
  /// In en, this message translates to:
  /// **'Duration'**
  String get vacuumDuration;

  /// No description provided for @vacuumCleaningTime.
  ///
  /// In en, this message translates to:
  /// **'Cleaning time'**
  String get vacuumCleaningTime;

  /// Cleaning progress label, next to a percentage
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get vacuumDone;

  /// No description provided for @vacuumProgress.
  ///
  /// In en, this message translates to:
  /// **'Progress'**
  String get vacuumProgress;

  /// No description provided for @vacuumTotalCleanings.
  ///
  /// In en, this message translates to:
  /// **'Cleans in total'**
  String get vacuumTotalCleanings;

  /// No description provided for @vacuumCleanings.
  ///
  /// In en, this message translates to:
  /// **'Cleans'**
  String get vacuumCleanings;

  /// No description provided for @vacuumCleanAll.
  ///
  /// In en, this message translates to:
  /// **'Clean everything'**
  String get vacuumCleanAll;

  /// No description provided for @vacuumCleanRooms.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Clean 1 room} other{Clean {count} rooms}}'**
  String vacuumCleanRooms(int count);

  /// No description provided for @vacuumPause.
  ///
  /// In en, this message translates to:
  /// **'Pause'**
  String get vacuumPause;

  /// No description provided for @vacuumReturnToBase.
  ///
  /// In en, this message translates to:
  /// **'Return to base'**
  String get vacuumReturnToBase;

  /// No description provided for @vacuumResume.
  ///
  /// In en, this message translates to:
  /// **'Resume'**
  String get vacuumResume;

  /// No description provided for @vacuumStop.
  ///
  /// In en, this message translates to:
  /// **'Stop'**
  String get vacuumStop;

  /// The robot's docking station (button and tab)
  ///
  /// In en, this message translates to:
  /// **'Base'**
  String get vacuumBase;

  /// No description provided for @vacuumTabCleaning.
  ///
  /// In en, this message translates to:
  /// **'Cleaning'**
  String get vacuumTabCleaning;

  /// No description provided for @vacuumTabMaintenance.
  ///
  /// In en, this message translates to:
  /// **'Maintenance'**
  String get vacuumTabMaintenance;

  /// No description provided for @vacuumTabMore.
  ///
  /// In en, this message translates to:
  /// **'More'**
  String get vacuumTabMore;

  /// Section heading, all caps
  ///
  /// In en, this message translates to:
  /// **'ROOMS · NONE · CLEANS THE WHOLE HOUSE'**
  String get vacuumRoomsHeaderNone;

  /// Section heading, all caps
  ///
  /// In en, this message translates to:
  /// **'ROOMS · {selected} OF {total} IN THE ORDER CHOSEN'**
  String vacuumRoomsHeaderSome(int selected, int total);

  /// No description provided for @vacuumSelectAll.
  ///
  /// In en, this message translates to:
  /// **'Select all'**
  String get vacuumSelectAll;

  /// No description provided for @vacuumClearSelection.
  ///
  /// In en, this message translates to:
  /// **'Clear selection'**
  String get vacuumClearSelection;

  /// No description provided for @vacuumGeniusSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Smart automatic mode'**
  String get vacuumGeniusSubtitle;

  /// No description provided for @vacuumGeniusHint.
  ///
  /// In en, this message translates to:
  /// **'CleanGenius picks the mode, suction, mop humidity and route for each room on its own. Turn it off to choose by hand.'**
  String get vacuumGeniusHint;

  /// Section heading, all caps
  ///
  /// In en, this message translates to:
  /// **'CLEANING MODE'**
  String get vacuumCleaningModeLabel;

  /// Section heading, all caps
  ///
  /// In en, this message translates to:
  /// **'SUCTION'**
  String get vacuumSuctionLabel;

  /// Section heading, all caps
  ///
  /// In en, this message translates to:
  /// **'MOP HUMIDITY'**
  String get vacuumMopHumidityLabel;

  /// Section heading, all caps
  ///
  /// In en, this message translates to:
  /// **'ROUTE'**
  String get vacuumRouteLabel;

  /// No description provided for @vacuumFineTune.
  ///
  /// In en, this message translates to:
  /// **'Fine tuning'**
  String get vacuumFineTune;

  /// No description provided for @vacuumInstalled.
  ///
  /// In en, this message translates to:
  /// **'Installed'**
  String get vacuumInstalled;

  /// No description provided for @vacuumMissing.
  ///
  /// In en, this message translates to:
  /// **'Missing'**
  String get vacuumMissing;

  /// No description provided for @vacuumStation.
  ///
  /// In en, this message translates to:
  /// **'Station'**
  String get vacuumStation;

  /// Station state (feminine in Portuguese)
  ///
  /// In en, this message translates to:
  /// **'Idle'**
  String get vacuumStationIdle;

  /// No description provided for @vacuumStationWashing.
  ///
  /// In en, this message translates to:
  /// **'Washing'**
  String get vacuumStationWashing;

  /// No description provided for @vacuumStationDrying.
  ///
  /// In en, this message translates to:
  /// **'Drying'**
  String get vacuumStationDrying;

  /// No description provided for @vacuumAutoEmpty.
  ///
  /// In en, this message translates to:
  /// **'Auto-empty'**
  String get vacuumAutoEmpty;

  /// No description provided for @vacuumEmptying.
  ///
  /// In en, this message translates to:
  /// **'Emptying'**
  String get vacuumEmptying;

  /// Auto-empty state (masculine in Portuguese)
  ///
  /// In en, this message translates to:
  /// **'Idle'**
  String get vacuumAutoEmptyIdle;

  /// No description provided for @vacuumLowWater.
  ///
  /// In en, this message translates to:
  /// **'Low water'**
  String get vacuumLowWater;

  /// No description provided for @vacuumActionEmptyBin.
  ///
  /// In en, this message translates to:
  /// **'Empty dust bin'**
  String get vacuumActionEmptyBin;

  /// No description provided for @vacuumActionWashMop.
  ///
  /// In en, this message translates to:
  /// **'Wash mop'**
  String get vacuumActionWashMop;

  /// No description provided for @vacuumActionDryMop.
  ///
  /// In en, this message translates to:
  /// **'Dry mop'**
  String get vacuumActionDryMop;

  /// No description provided for @vacuumActionCleanBase.
  ///
  /// In en, this message translates to:
  /// **'Clean the base'**
  String get vacuumActionCleanBase;

  /// No description provided for @vacuumDryingMop.
  ///
  /// In en, this message translates to:
  /// **'Drying the mop'**
  String get vacuumDryingMop;

  /// No description provided for @vacuumDryingProgress.
  ///
  /// In en, this message translates to:
  /// **'{percent}% · {duration} to go'**
  String vacuumDryingProgress(int percent, String duration);

  /// Section heading, all caps
  ///
  /// In en, this message translates to:
  /// **'STATION'**
  String get vacuumStationLabel;

  /// History chart title for a station sensor
  ///
  /// In en, this message translates to:
  /// **'{label} · base'**
  String vacuumBaseHistory(String label);

  /// Section heading, all caps
  ///
  /// In en, this message translates to:
  /// **'BASE ACTIONS'**
  String get vacuumBaseActionsLabel;

  /// No description provided for @vacuumNoWearInfo.
  ///
  /// In en, this message translates to:
  /// **'This vacuum doesn’t report how worn its parts are.'**
  String get vacuumNoWearInfo;

  /// No description provided for @vacuumPartLifeHistory.
  ///
  /// In en, this message translates to:
  /// **'{part} · life left'**
  String vacuumPartLifeHistory(String part);

  /// No description provided for @vacuumReset.
  ///
  /// In en, this message translates to:
  /// **'Reset'**
  String get vacuumReset;

  /// part is a lower-case part name, e.g. "sensors"
  ///
  /// In en, this message translates to:
  /// **'Reset the {part} counter? Do it after cleaning the part.'**
  String vacuumResetAskClean(String part);

  /// part is a lower-case part name, e.g. "filter"
  ///
  /// In en, this message translates to:
  /// **'Reset the {part} counter? Do it after replacing the part.'**
  String vacuumResetAskReplace(String part);

  /// No description provided for @vacuumResetTo100.
  ///
  /// In en, this message translates to:
  /// **'Reset to 100%'**
  String get vacuumResetTo100;

  /// time is e.g. "172 h" or "22 days"
  ///
  /// In en, this message translates to:
  /// **'{percent}% · {time} left'**
  String vacuumPartLeft(int percent, String time);

  /// No description provided for @vacuumTotalArea.
  ///
  /// In en, this message translates to:
  /// **'Total area'**
  String get vacuumTotalArea;

  /// No description provided for @vacuumTotalTime.
  ///
  /// In en, this message translates to:
  /// **'Total time'**
  String get vacuumTotalTime;

  /// No description provided for @vacuumDnd.
  ///
  /// In en, this message translates to:
  /// **'Do not disturb'**
  String get vacuumDnd;

  /// No description provided for @vacuumDndHint.
  ///
  /// In en, this message translates to:
  /// **'Doesn’t clean or speak during these hours'**
  String get vacuumDndHint;

  /// No description provided for @vacuumStartsAt.
  ///
  /// In en, this message translates to:
  /// **'Starts at'**
  String get vacuumStartsAt;

  /// No description provided for @vacuumEndsAt.
  ///
  /// In en, this message translates to:
  /// **'Ends at'**
  String get vacuumEndsAt;

  /// No description provided for @vacuumChildLock.
  ///
  /// In en, this message translates to:
  /// **'Child lock'**
  String get vacuumChildLock;

  /// No description provided for @vacuumChildLockHint.
  ///
  /// In en, this message translates to:
  /// **'The robot’s buttons stop working'**
  String get vacuumChildLockHint;

  /// Section heading, all caps
  ///
  /// In en, this message translates to:
  /// **'STATISTICS'**
  String get vacuumStatsLabel;

  /// No description provided for @vacuumVoiceVolume.
  ///
  /// In en, this message translates to:
  /// **'Voice volume'**
  String get vacuumVoiceVolume;

  /// Page title
  ///
  /// In en, this message translates to:
  /// **'House'**
  String get houseTitle;

  /// No description provided for @houseDoorsClosed.
  ///
  /// In en, this message translates to:
  /// **'Doors closed'**
  String get houseDoorsClosed;

  /// No description provided for @houseDoorsOpen.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 door open} other{{count} doors open}}'**
  String houseDoorsOpen(int count);

  /// No description provided for @houseWindowsClosed.
  ///
  /// In en, this message translates to:
  /// **'Windows closed'**
  String get houseWindowsClosed;

  /// No description provided for @houseWindowsOpen.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 window open} other{{count} windows open}}'**
  String houseWindowsOpen(int count);

  /// No description provided for @houseLightsOff.
  ///
  /// In en, this message translates to:
  /// **'Lights off'**
  String get houseLightsOff;

  /// No description provided for @houseLightsOn.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 light on} other{{count} lights on}}'**
  String houseLightsOn(int count);

  /// No description provided for @roomLights.
  ///
  /// In en, this message translates to:
  /// **'Lights'**
  String get roomLights;

  /// No description provided for @roomWindow.
  ///
  /// In en, this message translates to:
  /// **'Window'**
  String get roomWindow;

  /// No description provided for @roomBlinds.
  ///
  /// In en, this message translates to:
  /// **'Blinds'**
  String get roomBlinds;

  /// No description provided for @acTitle.
  ///
  /// In en, this message translates to:
  /// **'Air conditioning'**
  String get acTitle;

  /// No description provided for @roomVentilation.
  ///
  /// In en, this message translates to:
  /// **'Ventilation'**
  String get roomVentilation;

  /// Section title: the house's rooms
  ///
  /// In en, this message translates to:
  /// **'Rooms'**
  String get roomRooms;

  /// No description provided for @roomAllLightsOff.
  ///
  /// In en, this message translates to:
  /// **'Turn off all lights'**
  String get roomAllLightsOff;

  /// A fan/ventilation that is running (feminine in Portuguese)
  ///
  /// In en, this message translates to:
  /// **'On'**
  String get roomVentOn;

  /// No description provided for @energySolar.
  ///
  /// In en, this message translates to:
  /// **'Solar'**
  String get energySolar;

  /// No description provided for @energyOfForecast.
  ///
  /// In en, this message translates to:
  /// **'Of {amount} kWh forecast'**
  String energyOfForecast(String amount);

  /// No description provided for @energyConsumption.
  ///
  /// In en, this message translates to:
  /// **'Consumption'**
  String get energyConsumption;

  /// No description provided for @energyYesterdayThisTime.
  ///
  /// In en, this message translates to:
  /// **'Yesterday at this time: {amount}'**
  String energyYesterdayThisTime(String amount);

  /// No description provided for @energySelfUse.
  ///
  /// In en, this message translates to:
  /// **'Self-consumption'**
  String get energySelfUse;

  /// No description provided for @energyFromSunAndBattery.
  ///
  /// In en, this message translates to:
  /// **'From the sun and the battery'**
  String get energyFromSunAndBattery;

  /// No description provided for @energyGrid.
  ///
  /// In en, this message translates to:
  /// **'Grid'**
  String get energyGrid;

  /// No description provided for @energyImportedSold.
  ///
  /// In en, this message translates to:
  /// **'Imported · {amount} sold'**
  String energyImportedSold(String amount);

  /// No description provided for @energyLessThanToday.
  ///
  /// In en, this message translates to:
  /// **'{percent}% less than today'**
  String energyLessThanToday(int percent);

  /// No description provided for @energyMoreThanToday.
  ///
  /// In en, this message translates to:
  /// **'{percent}% more than today'**
  String energyMoreThanToday(int percent);

  /// Label, all caps
  ///
  /// In en, this message translates to:
  /// **'NOW'**
  String get energyNowLabel;

  /// No description provided for @energyTitle.
  ///
  /// In en, this message translates to:
  /// **'Energy'**
  String get energyTitle;

  /// No description provided for @houseSeeMore.
  ///
  /// In en, this message translates to:
  /// **'See more'**
  String get houseSeeMore;

  /// Section heading, all caps
  ///
  /// In en, this message translates to:
  /// **'TODAY'**
  String get energyTodayLabel;

  /// Section heading, all caps
  ///
  /// In en, this message translates to:
  /// **'TOMORROW'**
  String get energyTomorrowLabel;

  /// No description provided for @energySolarForecast.
  ///
  /// In en, this message translates to:
  /// **'Solar forecast'**
  String get energySolarForecast;

  /// No description provided for @houseSecurity.
  ///
  /// In en, this message translates to:
  /// **'Security'**
  String get houseSecurity;

  /// No description provided for @houseAllClosed.
  ///
  /// In en, this message translates to:
  /// **'All closed'**
  String get houseAllClosed;

  /// How many doors/locks are open
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 open} other{{count} open}}'**
  String houseOpenCount(int count);

  /// kind: lock (a lock), door (feminine noun in Portuguese) or gate (masculine). when is e.g. "yesterday at 19:40"
  ///
  /// In en, this message translates to:
  /// **'{kind, select, lock{Last unlocked {when}} door{Last opened {when}} other{Last opened {when}}}'**
  String houseLockLastOpened(String kind, String when);

  /// kind: lock, door (feminine in Portuguese) or gate (masculine)
  ///
  /// In en, this message translates to:
  /// **'{kind, select, lock{Unlocked since {time}} door{Open since {time}} other{Open since {time}}}'**
  String houseLockOpenSince(String kind, String time);

  /// kind: lock, door (feminine in Portuguese) or gate (masculine)
  ///
  /// In en, this message translates to:
  /// **'{kind, select, lock{Unlocked just now} door{Opened just now} other{Opened just now}}'**
  String houseLockOpenJustNow(String kind);

  /// No description provided for @houseFeelsLike.
  ///
  /// In en, this message translates to:
  /// **'Feels like {degrees}°'**
  String houseFeelsLike(String degrees);

  /// No description provided for @houseTodayMaxMin.
  ///
  /// In en, this message translates to:
  /// **'today high {max}°, low {min}°'**
  String houseTodayMaxMin(String max, String min);

  /// Card title: the weather outside
  ///
  /// In en, this message translates to:
  /// **'Outdoor'**
  String get houseOutdoor;

  /// How many robot vacuums are cleaning now
  ///
  /// In en, this message translates to:
  /// **'{count} cleaning'**
  String vacuumCountCleaning(int count);

  /// No description provided for @vacuumBothDocked.
  ///
  /// In en, this message translates to:
  /// **'Both docked'**
  String get vacuumBothDocked;

  /// No description provided for @vacuumAllDocked.
  ///
  /// In en, this message translates to:
  /// **'All docked'**
  String get vacuumAllDocked;

  /// No description provided for @vacuumNoneCleaning.
  ///
  /// In en, this message translates to:
  /// **'None cleaning'**
  String get vacuumNoneCleaning;

  /// No description provided for @vacuumTitle.
  ///
  /// In en, this message translates to:
  /// **'Robot vacuums'**
  String get vacuumTitle;

  /// No description provided for @vacuumErrorInRoom.
  ///
  /// In en, this message translates to:
  /// **'{error} in the {room}'**
  String vacuumErrorInRoom(String error, String room);

  /// No description provided for @vacuumBusyFoot.
  ///
  /// In en, this message translates to:
  /// **'Battery {battery}% · {area} m² · {minutes} min'**
  String vacuumBusyFoot(String battery, String area, String minutes);

  /// session is e.g. "24 m² in 31 min"
  ///
  /// In en, this message translates to:
  /// **'Last clean {session}'**
  String vacuumLastCleaningShort(String session);

  /// After a big percentage: "42% of the clean"
  ///
  /// In en, this message translates to:
  /// **'of the clean'**
  String get vacuumOfCleaning;

  /// After a big percentage
  ///
  /// In en, this message translates to:
  /// **'battery · charging'**
  String get vacuumBatteryCharging;

  /// After a big percentage
  ///
  /// In en, this message translates to:
  /// **'battery'**
  String get vacuumBatteryWord;

  /// No description provided for @acSectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Air conditioning'**
  String get acSectionTitle;

  /// No description provided for @acNone.
  ///
  /// In en, this message translates to:
  /// **'No air conditioning'**
  String get acNone;

  /// No description provided for @acAllOff.
  ///
  /// In en, this message translates to:
  /// **'All off'**
  String get acAllOff;

  /// No description provided for @acOnOfTotal.
  ///
  /// In en, this message translates to:
  /// **'{on} of {total} on'**
  String acOnOfTotal(int on, int total);

  /// No description provided for @houseSeeAll.
  ///
  /// In en, this message translates to:
  /// **'See all'**
  String get houseSeeAll;

  /// temp is a formatted temperature like "21,5°"
  ///
  /// In en, this message translates to:
  /// **'Now {temp}'**
  String acNowTemp(String temp);

  /// No description provided for @houseAllLocked.
  ///
  /// In en, this message translates to:
  /// **'All locked'**
  String get houseAllLocked;

  /// Doors and gates that are open
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 entrance open} other{{count} entrances open}}'**
  String houseAccessesOpen(int count);

  /// No description provided for @houseAlarmTriggered.
  ///
  /// In en, this message translates to:
  /// **'Alarm triggered'**
  String get houseAlarmTriggered;

  /// No description provided for @houseAlarmOff.
  ///
  /// In en, this message translates to:
  /// **'Alarm off'**
  String get houseAlarmOff;

  /// Alarm armed in home mode
  ///
  /// In en, this message translates to:
  /// **'Alarm home'**
  String get houseAlarmHome;

  /// Alarm armed in away mode
  ///
  /// In en, this message translates to:
  /// **'Alarm away'**
  String get houseAlarmAway;

  /// Hot water tank state
  ///
  /// In en, this message translates to:
  /// **'Heating'**
  String get houseWaterHeating;

  /// Hot water tank state (feminine in Portuguese)
  ///
  /// In en, this message translates to:
  /// **'Off'**
  String get houseWaterOff;

  /// Hot water tank state (feminine in Portuguese)
  ///
  /// In en, this message translates to:
  /// **'Ready'**
  String get houseWaterReady;

  /// No description provided for @houseHotWater.
  ///
  /// In en, this message translates to:
  /// **'Hot water'**
  String get houseHotWater;

  /// No description provided for @houseHotWaterTemperature.
  ///
  /// In en, this message translates to:
  /// **'Hot water · temperature'**
  String get houseHotWaterTemperature;

  /// No description provided for @houseWaterTarget.
  ///
  /// In en, this message translates to:
  /// **'Target {degrees} ºC'**
  String houseWaterTarget(String degrees);

  /// No description provided for @houseHeatPump.
  ///
  /// In en, this message translates to:
  /// **'Heat pump'**
  String get houseHeatPump;

  /// No description provided for @houseJustNow.
  ///
  /// In en, this message translates to:
  /// **'just now'**
  String get houseJustNow;

  /// No description provided for @houseMinutesAgo.
  ///
  /// In en, this message translates to:
  /// **'{minutes} min ago'**
  String houseMinutesAgo(int minutes);

  /// No description provided for @houseHoursAgo.
  ///
  /// In en, this message translates to:
  /// **'{hours} h ago'**
  String houseHoursAgo(int hours);

  /// No description provided for @houseDaysAgo.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 day ago} other{{count} days ago}}'**
  String houseDaysAgo(int count);

  /// No description provided for @houseMissedCalls.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 missed call} other{{count} missed calls}}'**
  String houseMissedCalls(int count);

  /// The building's entrance door (intercom camera)
  ///
  /// In en, this message translates to:
  /// **'Door'**
  String get houseBuildingDoor;

  /// Missed intercom calls, short
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 missed} other{{count} missed}}'**
  String houseMissedShort(int count);

  /// No description provided for @houseIntercom.
  ///
  /// In en, this message translates to:
  /// **'Intercom'**
  String get houseIntercom;

  /// Badge on a live camera image, all caps
  ///
  /// In en, this message translates to:
  /// **'LIVE'**
  String get cameraLive;

  /// No description provided for @cameraUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Camera unavailable'**
  String get cameraUnavailable;

  /// No description provided for @roomTemperatureHistory.
  ///
  /// In en, this message translates to:
  /// **'Temperature · {room}'**
  String roomTemperatureHistory(String room);

  /// No description provided for @roomNoTemperatureSensor.
  ///
  /// In en, this message translates to:
  /// **'No temperature sensor'**
  String get roomNoTemperatureSensor;

  /// No description provided for @roomHumidityHistory.
  ///
  /// In en, this message translates to:
  /// **'Humidity · {room}'**
  String roomHumidityHistory(String room);

  /// No description provided for @roomHumidityValue.
  ///
  /// In en, this message translates to:
  /// **'humidity {percent}%'**
  String roomHumidityValue(int percent);

  /// No description provided for @roomWindowHistory.
  ///
  /// In en, this message translates to:
  /// **'Window · {room}'**
  String roomWindowHistory(String room);

  /// Lights that are off (feminine plural in Portuguese)
  ///
  /// In en, this message translates to:
  /// **'Off'**
  String get roomLightsOff;

  /// No description provided for @roomBrightness.
  ///
  /// In en, this message translates to:
  /// **'Brightness'**
  String get roomBrightness;

  /// No description provided for @roomBlindsOpening.
  ///
  /// In en, this message translates to:
  /// **'Opening'**
  String get roomBlindsOpening;

  /// No description provided for @roomBlindsClosing.
  ///
  /// In en, this message translates to:
  /// **'Closing'**
  String get roomBlindsClosing;

  /// Blinds (masculine plural in Portuguese)
  ///
  /// In en, this message translates to:
  /// **'Closed'**
  String get roomBlindsClosed;

  /// Blinds (masculine plural in Portuguese)
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get roomBlindsOpen;

  /// No description provided for @roomBlindsOpenAt.
  ///
  /// In en, this message translates to:
  /// **'Open {percent}%'**
  String roomBlindsOpenAt(int percent);

  /// Button: move the blinds halfway
  ///
  /// In en, this message translates to:
  /// **'Half'**
  String get roomBlindsHalf;

  /// Slider label: how far the blinds are open
  ///
  /// In en, this message translates to:
  /// **'Opening'**
  String get roomBlindsAperture;

  /// Ventilation that is off (feminine in Portuguese)
  ///
  /// In en, this message translates to:
  /// **'Off'**
  String get roomVentOff;

  /// mode is the AC mode: heat, cool, fan or auto
  ///
  /// In en, this message translates to:
  /// **'{mode, select, heat{Now {temp} · heating} cool{Now {temp} · cooling} fan{Now {temp} · fan} other{Now {temp} · auto}}'**
  String acNowMode(String temp, String mode);

  /// No description provided for @acNowOff.
  ///
  /// In en, this message translates to:
  /// **'Now {temp} · off'**
  String acNowOff(String temp);

  /// No description provided for @acTargetTemperature.
  ///
  /// In en, this message translates to:
  /// **'Target temperature'**
  String get acTargetTemperature;

  /// No description provided for @acOffTurnOnToAdjust.
  ///
  /// In en, this message translates to:
  /// **'Off · turn on to adjust'**
  String get acOffTurnOnToAdjust;

  /// Section heading, all caps
  ///
  /// In en, this message translates to:
  /// **'MODE'**
  String get acModeLabel;

  /// Section heading, all caps
  ///
  /// In en, this message translates to:
  /// **'FAN'**
  String get acFanLabel;

  /// No description provided for @acAllUnits.
  ///
  /// In en, this message translates to:
  /// **'All air conditioners'**
  String get acAllUnits;

  /// No description provided for @acTurnOff.
  ///
  /// In en, this message translates to:
  /// **'Turn off'**
  String get acTurnOff;

  /// No description provided for @acTurnOn.
  ///
  /// In en, this message translates to:
  /// **'Turn on'**
  String get acTurnOn;

  /// No description provided for @acNowLower.
  ///
  /// In en, this message translates to:
  /// **'now {temp}'**
  String acNowLower(String temp);

  /// No description provided for @acHeating.
  ///
  /// In en, this message translates to:
  /// **'Heating'**
  String get acHeating;

  /// No description provided for @acCooling.
  ///
  /// In en, this message translates to:
  /// **'Cooling'**
  String get acCooling;

  /// No description provided for @acVentilating.
  ///
  /// In en, this message translates to:
  /// **'Fan'**
  String get acVentilating;

  /// No description provided for @acNoUnits.
  ///
  /// In en, this message translates to:
  /// **'No units'**
  String get acNoUnits;

  /// Average indoor temperature
  ///
  /// In en, this message translates to:
  /// **'House {temp}'**
  String acHouseTemp(String temp);

  /// No description provided for @acHouseTempNoHeating.
  ///
  /// In en, this message translates to:
  /// **'House {temp} · no heating'**
  String acHouseTempNoHeating(String temp);

  /// No description provided for @acOutside.
  ///
  /// In en, this message translates to:
  /// **'Outside {degrees}°'**
  String acOutside(String degrees);

  /// No description provided for @acTurnOffAll.
  ///
  /// In en, this message translates to:
  /// **'Turn all off'**
  String get acTurnOffAll;

  /// No description provided for @acNoneConfigured.
  ///
  /// In en, this message translates to:
  /// **'No air conditioning set up.'**
  String get acNoneConfigured;

  /// Card label, all caps
  ///
  /// In en, this message translates to:
  /// **'SOLAR TODAY'**
  String get energySolarTodayLabel;

  /// Card label, all caps
  ///
  /// In en, this message translates to:
  /// **'CONSUMPTION'**
  String get energyConsumptionLabel;

  /// Card label, all caps
  ///
  /// In en, this message translates to:
  /// **'SELF-CONSUMPTION'**
  String get energySelfUseLabel;

  /// No description provided for @energyCameFromSunOrBattery.
  ///
  /// In en, this message translates to:
  /// **'Came from the sun or the battery'**
  String get energyCameFromSunOrBattery;

  /// Card label, all caps
  ///
  /// In en, this message translates to:
  /// **'SAVINGS'**
  String get energySavingsLabel;

  /// No description provided for @energySavingsVsGrid.
  ///
  /// In en, this message translates to:
  /// **'Today, compared with grid only'**
  String get energySavingsVsGrid;

  /// No description provided for @energyNow.
  ///
  /// In en, this message translates to:
  /// **'Now'**
  String get energyNow;

  /// No description provided for @energyBatterySupplying.
  ///
  /// In en, this message translates to:
  /// **'Supplying {power}'**
  String energyBatterySupplying(String power);

  /// No description provided for @energyBatteryCharging.
  ///
  /// In en, this message translates to:
  /// **'Charging {power}'**
  String energyBatteryCharging(String power);

  /// Battery neither charging nor discharging
  ///
  /// In en, this message translates to:
  /// **'Idle'**
  String get energyBatteryIdle;

  /// Followed by a time
  ///
  /// In en, this message translates to:
  /// **'At the current rate it lasts until'**
  String get energyBatteryLastsUntil;

  /// No description provided for @energyBatteryRechargesAt.
  ///
  /// In en, this message translates to:
  /// **'Charges again (forecast)'**
  String get energyBatteryRechargesAt;

  /// No description provided for @energyBatteryRechargesWithSun.
  ///
  /// In en, this message translates to:
  /// **'≈ {time}, with the sun'**
  String energyBatteryRechargesWithSun(String time);

  /// No description provided for @energyCapacity.
  ///
  /// In en, this message translates to:
  /// **'Capacity'**
  String get energyCapacity;

  /// Nothing bought from or sold to the grid
  ///
  /// In en, this message translates to:
  /// **'No exchange'**
  String get energyGridIdle;

  /// No description provided for @energyGridImporting.
  ///
  /// In en, this message translates to:
  /// **'Importing {power}'**
  String energyGridImporting(String power);

  /// No description provided for @energyGridSelling.
  ///
  /// In en, this message translates to:
  /// **'Selling {power}'**
  String energyGridSelling(String power);

  /// No description provided for @energyImportedToday.
  ///
  /// In en, this message translates to:
  /// **'Imported today'**
  String get energyImportedToday;

  /// No description provided for @energySoldToday.
  ///
  /// In en, this message translates to:
  /// **'Sold today'**
  String get energySoldToday;

  /// No description provided for @energyTariffNow.
  ///
  /// In en, this message translates to:
  /// **'Tariff now'**
  String get energyTariffNow;

  /// No description provided for @energyPriceNow.
  ///
  /// In en, this message translates to:
  /// **'Price now'**
  String get energyPriceNow;

  /// Power drawn by everything not listed
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get energyOther;

  /// No description provided for @energyTodayByHour.
  ///
  /// In en, this message translates to:
  /// **'Today, hour by hour'**
  String get energyTodayByHour;

  /// No description provided for @energyForecast.
  ///
  /// In en, this message translates to:
  /// **'Forecast'**
  String get energyForecast;

  /// No description provided for @energySolarForecastTitle.
  ///
  /// In en, this message translates to:
  /// **'Solar forecast'**
  String get energySolarForecastTitle;

  /// No description provided for @energyBattery.
  ///
  /// In en, this message translates to:
  /// **'Battery'**
  String get energyBattery;

  /// No description provided for @energyConsumptionNow.
  ///
  /// In en, this message translates to:
  /// **'Consumption now'**
  String get energyConsumptionNow;

  /// No description provided for @energyLast7Days.
  ///
  /// In en, this message translates to:
  /// **'Last 7 days'**
  String get energyLast7Days;

  /// No description provided for @energyProduced.
  ///
  /// In en, this message translates to:
  /// **'Produced'**
  String get energyProduced;

  /// No description provided for @energyConsumed.
  ///
  /// In en, this message translates to:
  /// **'Consumed'**
  String get energyConsumed;

  /// No description provided for @energyExported.
  ///
  /// In en, this message translates to:
  /// **'Exported'**
  String get energyExported;

  /// No description provided for @energyWeekSummary.
  ///
  /// In en, this message translates to:
  /// **'Last 7 days: {produced} kWh produced, {consumed} kWh consumed, {exported} kWh exported.'**
  String energyWeekSummary(String produced, String consumed, String exported);

  /// No description provided for @energyWeekSummarySavings.
  ///
  /// In en, this message translates to:
  /// **'Last 7 days: {produced} kWh produced, {consumed} kWh consumed, {exported} kWh exported · estimated savings {savings}.'**
  String energyWeekSummarySavings(String produced, String consumed, String exported, String savings);

  /// No description provided for @energyNotConfigured.
  ///
  /// In en, this message translates to:
  /// **'The totals, forecast and history come from Home Assistant’s Energy dashboard, which isn’t set up.'**
  String get energyNotConfigured;

  /// No description provided for @energyModalToday.
  ///
  /// In en, this message translates to:
  /// **'Today, {date}'**
  String energyModalToday(String date);

  /// No description provided for @energyModalTodayUpdated.
  ///
  /// In en, this message translates to:
  /// **'Today, {date} · updated at {time}'**
  String energyModalTodayUpdated(String date, String time);

  /// No description provided for @energyForecastPeak.
  ///
  /// In en, this message translates to:
  /// **'Forecast peak {power} · {time}'**
  String energyForecastPeak(String power, String time);

  /// Corner label of the energy diagram, all caps
  ///
  /// In en, this message translates to:
  /// **'ENERGY'**
  String get energyFlowLabel;

  /// No description provided for @energyPowerGrid.
  ///
  /// In en, this message translates to:
  /// **'Power grid'**
  String get energyPowerGrid;

  /// No description provided for @energySolarProduction.
  ///
  /// In en, this message translates to:
  /// **'Solar production'**
  String get energySolarProduction;

  /// No description provided for @energyHouseBattery.
  ///
  /// In en, this message translates to:
  /// **'House battery'**
  String get energyHouseBattery;

  /// No description provided for @energyHouseConsumption.
  ///
  /// In en, this message translates to:
  /// **'House consumption'**
  String get energyHouseConsumption;

  /// A car (masculine in Portuguese)
  ///
  /// In en, this message translates to:
  /// **'Locked'**
  String get carLocked;

  /// A car (masculine in Portuguese)
  ///
  /// In en, this message translates to:
  /// **'Unlocked'**
  String get carUnlocked;

  /// No description provided for @carNoState.
  ///
  /// In en, this message translates to:
  /// **'No status'**
  String get carNoState;

  /// No description provided for @carCharging.
  ///
  /// In en, this message translates to:
  /// **'Charging'**
  String get carCharging;

  /// No description provided for @carBatteryLow.
  ///
  /// In en, this message translates to:
  /// **'Battery low'**
  String get carBatteryLow;

  /// No description provided for @carWaitingToCharge.
  ///
  /// In en, this message translates to:
  /// **'Waiting to charge'**
  String get carWaitingToCharge;

  /// No description provided for @carUnplugged.
  ///
  /// In en, this message translates to:
  /// **'Unplugged'**
  String get carUnplugged;

  /// No description provided for @carUpdatedAt.
  ///
  /// In en, this message translates to:
  /// **'Updated at {time}'**
  String carUpdatedAt(String time);

  /// No description provided for @carRefuelSoon.
  ///
  /// In en, this message translates to:
  /// **'refuel soon'**
  String get carRefuelSoon;

  /// Charge limit while charging
  ///
  /// In en, this message translates to:
  /// **'up to {percent}%'**
  String carChargeLimit(int percent);

  /// Advice when an electric car's battery is low
  ///
  /// In en, this message translates to:
  /// **'plug in'**
  String get carPlugIn;

  /// History chart title
  ///
  /// In en, this message translates to:
  /// **'{name} · fuel'**
  String carFuelHistory(String name);

  /// History chart title
  ///
  /// In en, this message translates to:
  /// **'{name} · battery'**
  String carBatteryHistory(String name);

  /// place is the camera's area or name
  ///
  /// In en, this message translates to:
  /// **'Camera · {place}'**
  String cameraSubtitle(String place);

  /// No description provided for @cameraLiveShort.
  ///
  /// In en, this message translates to:
  /// **'Live'**
  String get cameraLiveShort;

  /// Quick group preset: every speaker
  ///
  /// In en, this message translates to:
  /// **'Whole house'**
  String get speakersWholeHouse;

  /// Quick group preset: only this speaker
  ///
  /// In en, this message translates to:
  /// **'Only {name}'**
  String speakersOnly(String name);

  /// Shown only when count is 2 or more
  ///
  /// In en, this message translates to:
  /// **'{count} speakers playing in sync'**
  String speakersPlayingInSync(int count);

  /// No description provided for @speakersPlayingOnlyOn.
  ///
  /// In en, this message translates to:
  /// **'Playing only on {name}'**
  String speakersPlayingOnlyOn(String name);

  /// No description provided for @speakersTitle.
  ///
  /// In en, this message translates to:
  /// **'Speakers'**
  String get speakersTitle;

  /// No description provided for @speakersIntro.
  ///
  /// In en, this message translates to:
  /// **'Tap a speaker to add it to or remove it from the group. The music keeps playing.'**
  String get speakersIntro;

  /// No description provided for @speakersNoConnection.
  ///
  /// In en, this message translates to:
  /// **'No connection to Music Assistant.'**
  String get speakersNoConnection;

  /// Section caption, upper case
  ///
  /// In en, this message translates to:
  /// **'ALSO PLAYING'**
  String get speakersAlsoPlaying;

  /// No description provided for @speakersPlaying.
  ///
  /// In en, this message translates to:
  /// **'Playing'**
  String get speakersPlaying;

  /// Button: make this player the one the screen controls
  ///
  /// In en, this message translates to:
  /// **'Control'**
  String get speakersControl;

  /// Section caption, upper case
  ///
  /// In en, this message translates to:
  /// **'QUICK GROUPS'**
  String get speakersQuickGroups;

  /// Section caption, upper case
  ///
  /// In en, this message translates to:
  /// **'GROUP VOLUME'**
  String get speakersGroupVolume;

  /// Section caption, upper case
  ///
  /// In en, this message translates to:
  /// **'SPEAKERS IN THE HOUSE'**
  String get speakersHouseSpeakers;

  /// No description provided for @speakersMixedBrandsNote.
  ///
  /// In en, this message translates to:
  /// **'Speakers from different systems play together in a Music Assistant group. There may be a small delay between them.'**
  String get speakersMixedBrandsNote;

  /// Fallback name when a speaker has no model
  ///
  /// In en, this message translates to:
  /// **'Speaker'**
  String get speakersSpeaker;

  /// Speaker model or 'Speaker', then its state
  ///
  /// In en, this message translates to:
  /// **'{model} · off'**
  String speakersSubOff(String model);

  /// No description provided for @speakersSubPlaying.
  ///
  /// In en, this message translates to:
  /// **'{model} · playing {title}'**
  String speakersSubPlaying(String model, String title);

  /// No description provided for @speakersSubCantGroup.
  ///
  /// In en, this message translates to:
  /// **'{model} · can’t group with {name}'**
  String speakersSubCantGroup(String model, String name);

  /// No description provided for @speakersChipInGroup.
  ///
  /// In en, this message translates to:
  /// **'In group'**
  String get speakersChipInGroup;

  /// A speaker playing something else
  ///
  /// In en, this message translates to:
  /// **'Busy'**
  String get speakersChipBusy;

  /// A speaker available to join
  ///
  /// In en, this message translates to:
  /// **'Free'**
  String get speakersChipFree;

  /// No description provided for @musicRadio.
  ///
  /// In en, this message translates to:
  /// **'Radio'**
  String get musicRadio;

  /// Source name for files on a local or network disk
  ///
  /// In en, this message translates to:
  /// **'Local library'**
  String get musicLocalLibrary;

  /// Total length of a playlist or album
  ///
  /// In en, this message translates to:
  /// **'{hours} h {minutes} min'**
  String musicDurationHoursMinutes(int hours, int minutes);

  /// Total length of a playlist or album
  ///
  /// In en, this message translates to:
  /// **'{minutes} min'**
  String musicDurationMinutes(int minutes);

  /// Badge on a live radio station, upper case
  ///
  /// In en, this message translates to:
  /// **'LIVE'**
  String get musicLive;

  /// No description provided for @musicPlaylist.
  ///
  /// In en, this message translates to:
  /// **'Playlist'**
  String get musicPlaylist;

  /// No description provided for @musicPlaylistBy.
  ///
  /// In en, this message translates to:
  /// **'Playlist · {owner}'**
  String musicPlaylistBy(String owner);

  /// No description provided for @musicArtist.
  ///
  /// In en, this message translates to:
  /// **'Artist'**
  String get musicArtist;

  /// No description provided for @musicPodcast.
  ///
  /// In en, this message translates to:
  /// **'Podcast'**
  String get musicPodcast;

  /// No description provided for @musicPodcastBy.
  ///
  /// In en, this message translates to:
  /// **'Podcast · {owner}'**
  String musicPodcastBy(String owner);

  /// Toast when marking a favourite fails
  ///
  /// In en, this message translates to:
  /// **'Couldn’t save'**
  String get musicSaveFailed;

  /// Upper-case caption; target is the speaker or group name, already upper case
  ///
  /// In en, this message translates to:
  /// **'PLAYING ON {target}'**
  String musicPlayingOn(String target);

  /// No description provided for @musicQueue.
  ///
  /// In en, this message translates to:
  /// **'Queue'**
  String get musicQueue;

  /// Upper-case caption above the queue
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{UP NEXT · 1 track} other{UP NEXT · {count} tracks}}'**
  String musicUpNext(int count);

  /// No description provided for @musicClearQueue.
  ///
  /// In en, this message translates to:
  /// **'Clear queue'**
  String get musicClearQueue;

  /// No description provided for @musicQueueEmpty.
  ///
  /// In en, this message translates to:
  /// **'The queue is empty. Tap “Add to queue” on a playlist or album.'**
  String get musicQueueEmpty;

  /// Name of the built-in playlist of hearted tracks
  ///
  /// In en, this message translates to:
  /// **'Favourite songs'**
  String get musicFavoriteSongs;

  /// Owner shown on the favourite songs playlist
  ///
  /// In en, this message translates to:
  /// **'Family'**
  String get musicFamily;

  /// Upper-case caption above what is playing
  ///
  /// In en, this message translates to:
  /// **'LIVE RADIO'**
  String get musicContextLiveRadio;

  /// Upper-case caption above what is playing
  ///
  /// In en, this message translates to:
  /// **'PLAYING FROM PLAYLIST'**
  String get musicContextPlaylist;

  /// Upper-case caption above what is playing
  ///
  /// In en, this message translates to:
  /// **'PLAYING FROM ALBUM'**
  String get musicContextAlbum;

  /// Upper-case caption above what is playing
  ///
  /// In en, this message translates to:
  /// **'PLAYING FROM ARTIST'**
  String get musicContextArtist;

  /// Upper-case caption above what is playing
  ///
  /// In en, this message translates to:
  /// **'PLAYING FROM PODCAST'**
  String get musicContextPodcast;

  /// Upper-case caption above what is playing
  ///
  /// In en, this message translates to:
  /// **'NOW PLAYING'**
  String get musicContextPlaying;

  /// Upper-case caption above what is playing
  ///
  /// In en, this message translates to:
  /// **'ARTIST RADIO'**
  String get musicContextArtistRadio;

  /// Music tab
  ///
  /// In en, this message translates to:
  /// **'Listen now'**
  String get musicTabListenNow;

  /// Music tab, and the keyboard's search key
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get musicTabSearch;

  /// Music tab and page title
  ///
  /// In en, this message translates to:
  /// **'Library'**
  String get musicTabLibrary;

  /// No description provided for @musicMaUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Music Assistant unavailable'**
  String get musicMaUnavailable;

  /// No description provided for @musicMaConnecting.
  ///
  /// In en, this message translates to:
  /// **'Connecting to Music Assistant…'**
  String get musicMaConnecting;

  /// No description provided for @musicMaNotFound.
  ///
  /// In en, this message translates to:
  /// **'The Music Assistant add-on wasn’t found in Home Assistant.'**
  String get musicMaNotFound;

  /// Greeting on the music home page, before 13:00
  ///
  /// In en, this message translates to:
  /// **'Good morning, family'**
  String get musicGreetingMorning;

  /// Greeting on the music home page, 13:00–20:00
  ///
  /// In en, this message translates to:
  /// **'Good afternoon, family'**
  String get musicGreetingAfternoon;

  /// Greeting on the music home page, after 20:00
  ///
  /// In en, this message translates to:
  /// **'Good evening, family'**
  String get musicGreetingEvening;

  /// No description provided for @musicRecentlyPlayed.
  ///
  /// In en, this message translates to:
  /// **'Recently played'**
  String get musicRecentlyPlayed;

  /// Note beside 'Recently played'
  ///
  /// In en, this message translates to:
  /// **'In this house'**
  String get musicInThisHouse;

  /// No description provided for @musicYourPlaylists.
  ///
  /// In en, this message translates to:
  /// **'Your playlists'**
  String get musicYourPlaylists;

  /// No description provided for @musicRadios.
  ///
  /// In en, this message translates to:
  /// **'Radios'**
  String get musicRadios;

  /// Note beside the radios row
  ///
  /// In en, this message translates to:
  /// **'Live'**
  String get musicLiveNote;

  /// No description provided for @musicPodcasts.
  ///
  /// In en, this message translates to:
  /// **'Podcasts'**
  String get musicPodcasts;

  /// No description provided for @musicFavoriteArtists.
  ///
  /// In en, this message translates to:
  /// **'Favourite artists'**
  String get musicFavoriteArtists;

  /// Genre tile; also used as a search query
  ///
  /// In en, this message translates to:
  /// **'Portuguese'**
  String get musicGenrePortuguese;

  /// Genre tile; also used as a search query
  ///
  /// In en, this message translates to:
  /// **'Classical'**
  String get musicGenreClassical;

  /// Genre tile; also used as a search query
  ///
  /// In en, this message translates to:
  /// **'Relax'**
  String get musicGenreRelax;

  /// Genre tile; also used as a search query
  ///
  /// In en, this message translates to:
  /// **'Party'**
  String get musicGenreParty;

  /// Genre tile; also used as a search query
  ///
  /// In en, this message translates to:
  /// **'Workout'**
  String get musicGenreWorkout;

  /// Genre tile; also used as a search query
  ///
  /// In en, this message translates to:
  /// **'Sleep'**
  String get musicGenreSleep;

  /// Genre tile; also used as a search query
  ///
  /// In en, this message translates to:
  /// **'80s'**
  String get musicGenre80s;

  /// No description provided for @musicSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Artists, songs, albums, radios or podcasts'**
  String get musicSearchHint;

  /// Upper-case caption
  ///
  /// In en, this message translates to:
  /// **'RECENT SEARCHES'**
  String get musicRecentSearches;

  /// No description provided for @musicBrowseAll.
  ///
  /// In en, this message translates to:
  /// **'Browse all'**
  String get musicBrowseAll;

  /// Search results filter
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get musicFilterAll;

  /// No description provided for @musicSongs.
  ///
  /// In en, this message translates to:
  /// **'Songs'**
  String get musicSongs;

  /// No description provided for @musicArtists.
  ///
  /// In en, this message translates to:
  /// **'Artists'**
  String get musicArtists;

  /// No description provided for @musicAlbums.
  ///
  /// In en, this message translates to:
  /// **'Albums'**
  String get musicAlbums;

  /// No description provided for @musicPlaylists.
  ///
  /// In en, this message translates to:
  /// **'Playlists'**
  String get musicPlaylists;

  /// No description provided for @musicPodcastsAndRadios.
  ///
  /// In en, this message translates to:
  /// **'Podcasts and radios'**
  String get musicPodcastsAndRadios;

  /// No description provided for @musicNoResults.
  ///
  /// In en, this message translates to:
  /// **'No results for “{query}”'**
  String musicNoResults(String query);

  /// No description provided for @musicNoResultsDetail.
  ///
  /// In en, this message translates to:
  /// **'We searched every service connected to Music Assistant.'**
  String get musicNoResultsDetail;

  /// Upper-case caption
  ///
  /// In en, this message translates to:
  /// **'ARTIST'**
  String get musicCaptionArtist;

  /// Upper-case caption; also a track-list column header
  ///
  /// In en, this message translates to:
  /// **'ALBUM'**
  String get musicCaptionAlbum;

  /// Upper-case caption
  ///
  /// In en, this message translates to:
  /// **'PLAYLIST'**
  String get musicCaptionPlaylist;

  /// Upper-case caption
  ///
  /// In en, this message translates to:
  /// **'RADIO'**
  String get musicCaptionRadio;

  /// Upper-case caption
  ///
  /// In en, this message translates to:
  /// **'PODCAST'**
  String get musicCaptionPodcast;

  /// No description provided for @musicTopResult.
  ///
  /// In en, this message translates to:
  /// **'Top result'**
  String get musicTopResult;

  /// Library sort order
  ///
  /// In en, this message translates to:
  /// **'Recent'**
  String get musicSortRecent;

  /// Library sort order: recently added first
  ///
  /// In en, this message translates to:
  /// **'Added'**
  String get musicSortAdded;

  /// No description provided for @musicLibraryEmpty.
  ///
  /// In en, this message translates to:
  /// **'Nothing saved here yet.'**
  String get musicLibraryEmpty;

  /// No description provided for @musicFavoritesSummary.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Playlist · 1 song · Music Assistant} other{Playlist · {count} songs · Music Assistant}}'**
  String musicFavoritesSummary(int count);

  /// No description provided for @musicAlbum.
  ///
  /// In en, this message translates to:
  /// **'Album'**
  String get musicAlbum;

  /// No description provided for @musicEpisodesCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 episode} other{{count} episodes}}'**
  String musicEpisodesCount(int count);

  /// duration is already formatted, e.g. '1 h 12 min'
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 song, {duration}} other{{count} songs, {duration}}}'**
  String musicSongsAndDuration(int count, String duration);

  /// No description provided for @musicFavoritesDescription.
  ///
  /// In en, this message translates to:
  /// **'The songs marked with a heart.'**
  String get musicFavoritesDescription;

  /// No description provided for @musicAddedToQueue.
  ///
  /// In en, this message translates to:
  /// **'Added to queue'**
  String get musicAddedToQueue;

  /// target (speaker or group name) is shown in bold
  ///
  /// In en, this message translates to:
  /// **'Plays on {target}'**
  String musicPlaysOn(String target);

  /// Track-list column header
  ///
  /// In en, this message translates to:
  /// **'EPISODE'**
  String get musicColumnEpisode;

  /// Track-list column header
  ///
  /// In en, this message translates to:
  /// **'TITLE'**
  String get musicColumnTitle;

  /// Track-list column header
  ///
  /// In en, this message translates to:
  /// **'DURATION'**
  String get musicColumnDuration;

  /// No description provided for @musicNoTracks.
  ///
  /// In en, this message translates to:
  /// **'No tracks.'**
  String get musicNoTracks;

  /// No description provided for @musicFollowingArtist.
  ///
  /// In en, this message translates to:
  /// **'You follow this artist'**
  String get musicFollowingArtist;

  /// Button state: already following an artist
  ///
  /// In en, this message translates to:
  /// **'Following'**
  String get musicFollowing;

  /// Button: follow an artist
  ///
  /// In en, this message translates to:
  /// **'Follow'**
  String get musicFollow;

  /// No description provided for @musicArtistRadio.
  ///
  /// In en, this message translates to:
  /// **'Artist radio'**
  String get musicArtistRadio;

  /// An artist's most popular tracks
  ///
  /// In en, this message translates to:
  /// **'Popular'**
  String get musicPopular;

  /// No description provided for @musicDiscography.
  ///
  /// In en, this message translates to:
  /// **'Discography'**
  String get musicDiscography;

  /// No description provided for @musicLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn’t load.'**
  String get musicLoadFailed;

  /// Default favourite (a weather site)
  ///
  /// In en, this message translates to:
  /// **'Weather'**
  String get browserFavWeather;

  /// Default favourite (a news site)
  ///
  /// In en, this message translates to:
  /// **'News'**
  String get browserFavNews;

  /// No description provided for @browserUnavailable.
  ///
  /// In en, this message translates to:
  /// **'The browser isn’t available on this screen.'**
  String get browserUnavailable;

  /// On-screen keyboard action key
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get browserKeySearch;

  /// On-screen keyboard action key
  ///
  /// In en, this message translates to:
  /// **'Send'**
  String get browserKeySend;

  /// On-screen keyboard action key
  ///
  /// In en, this message translates to:
  /// **'Go'**
  String get browserKeyGo;

  /// Label under the minimised browser bubble; its first letter is the bubble's badge
  ///
  /// In en, this message translates to:
  /// **'Browser'**
  String get browserTitle;

  /// Accessibility label of the minimised browser bubble
  ///
  /// In en, this message translates to:
  /// **'Back to the browser · start page'**
  String get browserReturnToStart;

  /// Accessibility label of the minimised browser bubble; site is a host name
  ///
  /// In en, this message translates to:
  /// **'Back to the browser · {site}'**
  String browserReturnTo(String site);

  /// No description provided for @browserVolume.
  ///
  /// In en, this message translates to:
  /// **'Browser volume'**
  String get browserVolume;

  /// No description provided for @browserMuted.
  ///
  /// In en, this message translates to:
  /// **'Muted'**
  String get browserMuted;

  /// No description provided for @browserVolumeNote.
  ///
  /// In en, this message translates to:
  /// **'Only for sound from websites (videos, music). The screen volume stays the same, in Settings.'**
  String get browserVolumeNote;

  /// engine is a search engine name, e.g. Google
  ///
  /// In en, this message translates to:
  /// **'Search {engine} or type an address'**
  String browserAddressHint(String engine);

  /// No description provided for @browserStartPage.
  ///
  /// In en, this message translates to:
  /// **'Start page'**
  String get browserStartPage;

  /// Heading of the browser's start page
  ///
  /// In en, this message translates to:
  /// **'Where to?'**
  String get browserStartTitle;

  /// Upper-case caption
  ///
  /// In en, this message translates to:
  /// **'FAVOURITES'**
  String get browserFavorites;

  /// Upper-case caption
  ///
  /// In en, this message translates to:
  /// **'RECENTLY VISITED'**
  String get browserRecentlyVisited;

  /// When a site was visited; lower case, after a host name and ·
  ///
  /// In en, this message translates to:
  /// **'just now'**
  String get browserJustNow;

  /// No description provided for @browserMinutesAgo.
  ///
  /// In en, this message translates to:
  /// **'{minutes} min ago'**
  String browserMinutesAgo(int minutes);

  /// No description provided for @browserHoursAgo.
  ///
  /// In en, this message translates to:
  /// **'{hours} h ago'**
  String browserHoursAgo(int hours);

  /// When a site was visited; lower case
  ///
  /// In en, this message translates to:
  /// **'yesterday'**
  String get browserYesterday;

  /// Group of doorbell ringtones.
  ///
  /// In en, this message translates to:
  /// **'Classic'**
  String get doorbellGroupClassic;

  /// Group of the user's own doorbell ringtones.
  ///
  /// In en, this message translates to:
  /// **'My ringtones'**
  String get doorbellGroupCustom;

  /// Group of doorbell ringtones in the style of building intercoms.
  ///
  /// In en, this message translates to:
  /// **'Intercom'**
  String get doorbellGroupIntercom;

  /// Group of doorbell ringtones.
  ///
  /// In en, this message translates to:
  /// **'Modern'**
  String get doorbellGroupModern;

  /// Name of a doorbell ringtone.
  ///
  /// In en, this message translates to:
  /// **'Aurora'**
  String get doorbellToneAurora;

  /// No description provided for @doorbellToneAuroraDesc.
  ///
  /// In en, this message translates to:
  /// **'Slow chord, for the night'**
  String get doorbellToneAuroraDesc;

  /// Name of a doorbell ringtone.
  ///
  /// In en, this message translates to:
  /// **'Bubbles'**
  String get doorbellToneBolhas;

  /// No description provided for @doorbellToneBolhasDesc.
  ///
  /// In en, this message translates to:
  /// **'Rising bubbles, playful'**
  String get doorbellToneBolhasDesc;

  /// Name of a doorbell ringtone.
  ///
  /// In en, this message translates to:
  /// **'Carillon'**
  String get doorbellToneCarrilhao;

  /// No description provided for @doorbellToneCarrilhaoDesc.
  ///
  /// In en, this message translates to:
  /// **'Cascading bells'**
  String get doorbellToneCarrilhaoDesc;

  /// No description provided for @doorbellToneCustomDesc.
  ///
  /// In en, this message translates to:
  /// **'Your file · plays continuously'**
  String get doorbellToneCustomDesc;

  /// Name of a doorbell ringtone.
  ///
  /// In en, this message translates to:
  /// **'Digital'**
  String get doorbellToneDigital;

  /// No description provided for @doorbellToneDigitalDesc.
  ///
  /// In en, this message translates to:
  /// **'Double intercom beep'**
  String get doorbellToneDigitalDesc;

  /// Name of a doorbell ringtone.
  ///
  /// In en, this message translates to:
  /// **'Ding-dong'**
  String get doorbellToneDingdong;

  /// No description provided for @doorbellToneDingdongDesc.
  ///
  /// In en, this message translates to:
  /// **'Classic two-tone doorbell'**
  String get doorbellToneDingdongDesc;

  /// Name of a doorbell ringtone.
  ///
  /// In en, this message translates to:
  /// **'Two rings'**
  String get doorbellToneDoisToques;

  /// No description provided for @doorbellToneDoisToquesDesc.
  ///
  /// In en, this message translates to:
  /// **'Electronic ring, repeated'**
  String get doorbellToneDoisToquesDesc;

  /// Name of a doorbell ringtone.
  ///
  /// In en, this message translates to:
  /// **'Harp'**
  String get doorbellToneHarpa;

  /// No description provided for @doorbellToneHarpaDesc.
  ///
  /// In en, this message translates to:
  /// **'Delicate harp arpeggio'**
  String get doorbellToneHarpaDesc;

  /// Name of a doorbell ringtone.
  ///
  /// In en, this message translates to:
  /// **'Kalimba'**
  String get doorbellToneKalimba;

  /// No description provided for @doorbellToneKalimbaDesc.
  ///
  /// In en, this message translates to:
  /// **'Thumb piano, soft'**
  String get doorbellToneKalimbaDesc;

  /// Name of a doorbell ringtone.
  ///
  /// In en, this message translates to:
  /// **'Marimba'**
  String get doorbellToneMarimba;

  /// No description provided for @doorbellToneMarimbaDesc.
  ///
  /// In en, this message translates to:
  /// **'Wooden notes, cheerful'**
  String get doorbellToneMarimbaDesc;

  /// Name of a doorbell ringtone.
  ///
  /// In en, this message translates to:
  /// **'Melody'**
  String get doorbellToneMelodia;

  /// No description provided for @doorbellToneMelodiaDesc.
  ///
  /// In en, this message translates to:
  /// **'Polyphonic monitor melody'**
  String get doorbellToneMelodiaDesc;

  /// Name of a doorbell ringtone.
  ///
  /// In en, this message translates to:
  /// **'Concierge'**
  String get doorbellTonePortaria;

  /// No description provided for @doorbellTonePortariaDesc.
  ///
  /// In en, this message translates to:
  /// **'The trill of building intercom monitors'**
  String get doorbellTonePortariaDesc;

  /// Name of a doorbell ringtone.
  ///
  /// In en, this message translates to:
  /// **'Pulsar'**
  String get doorbellTonePulsar;

  /// No description provided for @doorbellTonePulsarDesc.
  ///
  /// In en, this message translates to:
  /// **'Synthesiser arpeggio'**
  String get doorbellTonePulsarDesc;

  /// Name of a doorbell ringtone.
  ///
  /// In en, this message translates to:
  /// **'Retro'**
  String get doorbellToneRetro;

  /// No description provided for @doorbellToneRetroDesc.
  ///
  /// In en, this message translates to:
  /// **'8-bit game'**
  String get doorbellToneRetroDesc;

  /// Name of a doorbell ringtone.
  ///
  /// In en, this message translates to:
  /// **'Gentle'**
  String get doorbellToneSuave;

  /// No description provided for @doorbellToneSuaveDesc.
  ///
  /// In en, this message translates to:
  /// **'Two calm tones'**
  String get doorbellToneSuaveDesc;

  /// Name of a doorbell ringtone.
  ///
  /// In en, this message translates to:
  /// **'Three tones'**
  String get doorbellToneTresTons;

  /// No description provided for @doorbellToneTresTonsDesc.
  ///
  /// In en, this message translates to:
  /// **'Rising chord, short'**
  String get doorbellToneTresTonsDesc;

  /// Name of a doorbell ringtone.
  ///
  /// In en, this message translates to:
  /// **'Triangle'**
  String get doorbellToneTriangulo;

  /// No description provided for @doorbellToneTrianguloDesc.
  ///
  /// In en, this message translates to:
  /// **'Three metallic strikes'**
  String get doorbellToneTrianguloDesc;

  /// Name of a doorbell ringtone.
  ///
  /// In en, this message translates to:
  /// **'Brrring'**
  String get doorbellToneTrrrim;

  /// No description provided for @doorbellToneTrrrimDesc.
  ///
  /// In en, this message translates to:
  /// **'Electric hammer bell'**
  String get doorbellToneTrrrimDesc;

  /// Name of a doorbell ringtone.
  ///
  /// In en, this message translates to:
  /// **'Glass'**
  String get doorbellToneVidro;

  /// No description provided for @doorbellToneVidroDesc.
  ///
  /// In en, this message translates to:
  /// **'Crystal bells, clean'**
  String get doorbellToneVidroDesc;

  /// Name of a doorbell ringtone.
  ///
  /// In en, this message translates to:
  /// **'Westminster'**
  String get doorbellToneWestminster;

  /// No description provided for @doorbellToneWestminsterDesc.
  ///
  /// In en, this message translates to:
  /// **'Four-note chime'**
  String get doorbellToneWestminsterDesc;

  /// Name of a doorbell ringtone.
  ///
  /// In en, this message translates to:
  /// **'Xylophone'**
  String get doorbellToneXilofone;

  /// No description provided for @doorbellToneXilofoneDesc.
  ///
  /// In en, this message translates to:
  /// **'Quick, cheerful scale'**
  String get doorbellToneXilofoneDesc;

  /// Today's forecast maximum temperature.
  ///
  /// In en, this message translates to:
  /// **'High {temp}°'**
  String headerMax(String temp);

  /// Today's forecast minimum temperature.
  ///
  /// In en, this message translates to:
  /// **'Low {temp}°'**
  String headerMin(String temp);

  /// {weekday} is an abbreviated lower-case weekday, {date} like "17 Oct".
  ///
  /// In en, this message translates to:
  /// **'Next holiday: {name}, {weekday} {date}'**
  String headerNextHoliday(String name, String weekday, String date);

  /// Accessibility label of the weather button.
  ///
  /// In en, this message translates to:
  /// **'See the weather forecast'**
  String get headerSeeForecast;

  /// No description provided for @headerWeek.
  ///
  /// In en, this message translates to:
  /// **'Week {week}'**
  String headerWeek(int week);

  /// No description provided for @historyAtTime.
  ///
  /// In en, this message translates to:
  /// **'at {time}'**
  String historyAtTime(String time);

  /// No description provided for @historyAverage.
  ///
  /// In en, this message translates to:
  /// **'Average'**
  String get historyAverage;

  /// {weekday} is an abbreviated lower-case weekday, {date} like "17 Oct".
  ///
  /// In en, this message translates to:
  /// **'{weekday}, {date} at {time}'**
  String historyDayAt(String weekday, String date, String time);

  /// No description provided for @historyDurationHm.
  ///
  /// In en, this message translates to:
  /// **'{hours} h {minutes} min'**
  String historyDurationHm(int hours, int minutes);

  /// No description provided for @historyDurationM.
  ///
  /// In en, this message translates to:
  /// **'{minutes} min'**
  String historyDurationM(int minutes);

  /// No description provided for @historyFooter.
  ///
  /// In en, this message translates to:
  /// **'History kept by Home Assistant (recorder). Slide your finger across the chart to see each moment.'**
  String get historyFooter;

  /// No description provided for @historyInPeriod.
  ///
  /// In en, this message translates to:
  /// **'in the period'**
  String get historyInPeriod;

  /// No description provided for @historyInTotal.
  ///
  /// In en, this message translates to:
  /// **'in total'**
  String get historyInTotal;

  /// No description provided for @historyLast24h.
  ///
  /// In en, this message translates to:
  /// **'Last 24 hours'**
  String get historyLast24h;

  /// No description provided for @historyLast30d.
  ///
  /// In en, this message translates to:
  /// **'Last 30 days'**
  String get historyLast30d;

  /// No description provided for @historyLast7d.
  ///
  /// In en, this message translates to:
  /// **'Last 7 days'**
  String get historyLast7d;

  /// No description provided for @historyLastChange.
  ///
  /// In en, this message translates to:
  /// **'Last change'**
  String get historyLastChange;

  /// No description provided for @historyMax.
  ///
  /// In en, this message translates to:
  /// **'Maximum'**
  String get historyMax;

  /// No description provided for @historyMin.
  ///
  /// In en, this message translates to:
  /// **'Minimum'**
  String get historyMin;

  /// No description provided for @historyNoChanges.
  ///
  /// In en, this message translates to:
  /// **'no changes'**
  String get historyNoChanges;

  /// No description provided for @historyNoData.
  ///
  /// In en, this message translates to:
  /// **'No data'**
  String get historyNoData;

  /// No description provided for @historyNone.
  ///
  /// In en, this message translates to:
  /// **'No history'**
  String get historyNone;

  /// No description provided for @historyNow.
  ///
  /// In en, this message translates to:
  /// **'Now'**
  String get historyNow;

  /// No description provided for @historyPercentOfTime.
  ///
  /// In en, this message translates to:
  /// **'{percent}% of the time'**
  String historyPercentOfTime(int percent);

  /// No description provided for @historyRange24h.
  ///
  /// In en, this message translates to:
  /// **'24 hours'**
  String get historyRange24h;

  /// No description provided for @historyRange30d.
  ///
  /// In en, this message translates to:
  /// **'30 days'**
  String get historyRange30d;

  /// No description provided for @historyRange7d.
  ///
  /// In en, this message translates to:
  /// **'7 days'**
  String get historyRange7d;

  /// How long an entity was in a state, e.g. "Time on", "Time open"; {state} is lower-cased.
  ///
  /// In en, this message translates to:
  /// **'Time {state}'**
  String historyTimeIn(String state);

  /// No description provided for @historyTimes.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 time} other{{count} times}}'**
  String historyTimes(int count);

  /// No description provided for @historyTodayAt.
  ///
  /// In en, this message translates to:
  /// **'Today at {time}'**
  String historyTodayAt(String time);

  /// No description provided for @intercomAnswer.
  ///
  /// In en, this message translates to:
  /// **'Answer'**
  String get intercomAnswer;

  /// The building's front door (the intercom's door station).
  ///
  /// In en, this message translates to:
  /// **'Building door'**
  String get intercomBuildingDoor;

  /// No description provided for @intercomCallAtBuildingDoor.
  ///
  /// In en, this message translates to:
  /// **'Call at the building door'**
  String get intercomCallAtBuildingDoor;

  /// No description provided for @intercomCallCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 call} other{{count} calls}}'**
  String intercomCallCount(int count);

  /// No description provided for @intercomConnecting.
  ///
  /// In en, this message translates to:
  /// **'Connecting…'**
  String get intercomConnecting;

  /// No description provided for @intercomDoorCalls.
  ///
  /// In en, this message translates to:
  /// **'Door calls'**
  String get intercomDoorCalls;

  /// No description provided for @intercomDoorNotOpened.
  ///
  /// In en, this message translates to:
  /// **'Door was not opened'**
  String get intercomDoorNotOpened;

  /// No description provided for @intercomDoorNotOpenedSub.
  ///
  /// In en, this message translates to:
  /// **'No device opened the door.'**
  String get intercomDoorNotOpenedSub;

  /// No description provided for @intercomDoorOpened.
  ///
  /// In en, this message translates to:
  /// **'Door open'**
  String get intercomDoorOpened;

  /// No description provided for @intercomDoorOpenedSub.
  ///
  /// In en, this message translates to:
  /// **'During or right after the call.'**
  String get intercomDoorOpenedSub;

  /// No description provided for @intercomDoorUnlocked.
  ///
  /// In en, this message translates to:
  /// **'Door unlocked'**
  String get intercomDoorUnlocked;

  /// No description provided for @intercomEmptySub.
  ///
  /// In en, this message translates to:
  /// **'Whenever someone rings the doorbell, we keep a picture of the door here, the time and what happened.'**
  String get intercomEmptySub;

  /// No description provided for @intercomEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No calls yet since this screen started logging them.'**
  String get intercomEmptyTitle;

  /// No description provided for @intercomEndOfList.
  ///
  /// In en, this message translates to:
  /// **'End of the list. This screen keeps the last 200 calls.'**
  String get intercomEndOfList;

  /// No description provided for @intercomHangUp.
  ///
  /// In en, this message translates to:
  /// **'Hang up'**
  String get intercomHangUp;

  /// No description provided for @intercomHistory.
  ///
  /// In en, this message translates to:
  /// **'History'**
  String get intercomHistory;

  /// No description provided for @intercomIgnore.
  ///
  /// In en, this message translates to:
  /// **'Ignore'**
  String get intercomIgnore;

  /// No description provided for @intercomIgnoreHint.
  ///
  /// In en, this message translates to:
  /// **'Ignore only closes this screen. The indoor station keeps ringing and can be answered there.'**
  String get intercomIgnoreHint;

  /// No description provided for @intercomInCall.
  ///
  /// In en, this message translates to:
  /// **'In a call'**
  String get intercomInCall;

  /// No description provided for @intercomLive.
  ///
  /// In en, this message translates to:
  /// **'Live'**
  String get intercomLive;

  /// No description provided for @intercomLoggedHere.
  ///
  /// In en, this message translates to:
  /// **'Intercom · logged by this screen'**
  String get intercomLoggedHere;

  /// No description provided for @intercomMicOff.
  ///
  /// In en, this message translates to:
  /// **'Mic off'**
  String get intercomMicOff;

  /// No description provided for @intercomMissedCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 not answered} other{{count} not answered}}'**
  String intercomMissedCount(int count);

  /// No description provided for @intercomMute.
  ///
  /// In en, this message translates to:
  /// **'Mute'**
  String get intercomMute;

  /// Small uppercase badge on a call not seen yet.
  ///
  /// In en, this message translates to:
  /// **'NEW'**
  String get intercomNewTag;

  /// No description provided for @intercomNewestFirst.
  ///
  /// In en, this message translates to:
  /// **'Newest first'**
  String get intercomNewestFirst;

  /// No description provided for @intercomNoPicture.
  ///
  /// In en, this message translates to:
  /// **'No picture'**
  String get intercomNoPicture;

  /// No description provided for @intercomNotConnected.
  ///
  /// In en, this message translates to:
  /// **'The intercom isn’t connected to this screen yet'**
  String get intercomNotConnected;

  /// No description provided for @intercomOpenDoor.
  ///
  /// In en, this message translates to:
  /// **'Open door'**
  String get intercomOpenDoor;

  /// No description provided for @intercomOutcomeHere.
  ///
  /// In en, this message translates to:
  /// **'Answered on this screen'**
  String get intercomOutcomeHere;

  /// No description provided for @intercomOutcomeHereSub.
  ///
  /// In en, this message translates to:
  /// **'The door was heard through this screen.'**
  String get intercomOutcomeHereSub;

  /// A doorbell call answered on the indoor station.
  ///
  /// In en, this message translates to:
  /// **'Answered on the intercom'**
  String get intercomOutcomeIndoor;

  /// No description provided for @intercomOutcomeIndoorSub.
  ///
  /// In en, this message translates to:
  /// **'They talked through the indoor station.'**
  String get intercomOutcomeIndoorSub;

  /// No description provided for @intercomOutcomeMissed.
  ///
  /// In en, this message translates to:
  /// **'Not answered'**
  String get intercomOutcomeMissed;

  /// No description provided for @intercomOutcomeMissedSub.
  ///
  /// In en, this message translates to:
  /// **'Nobody answered, neither here nor on the intercom.'**
  String get intercomOutcomeMissedSub;

  /// No description provided for @intercomOutcomeRinging.
  ///
  /// In en, this message translates to:
  /// **'Ringing now'**
  String get intercomOutcomeRinging;

  /// No description provided for @intercomOutcomeRingingSub.
  ///
  /// In en, this message translates to:
  /// **'You can still answer on the intercom.'**
  String get intercomOutcomeRingingSub;

  /// {outcome} is a full sentence ending in a full stop; {duration} like 1:05.
  ///
  /// In en, this message translates to:
  /// **'{outcome} Duration: {duration}.'**
  String intercomOutcomeWithDuration(String outcome, String duration);

  /// No description provided for @intercomPictureFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn’t capture the picture'**
  String get intercomPictureFailed;

  /// No description provided for @intercomPictureFailedSub.
  ///
  /// In en, this message translates to:
  /// **'The camera didn’t respond when they rang.'**
  String get intercomPictureFailedSub;

  /// No description provided for @intercomPosition.
  ///
  /// In en, this message translates to:
  /// **'{index} of {total}'**
  String intercomPosition(int index, int total);

  /// No description provided for @intercomRelocksIn.
  ///
  /// In en, this message translates to:
  /// **'Locks again in {seconds} s'**
  String intercomRelocksIn(int seconds);

  /// No description provided for @intercomRinging.
  ///
  /// In en, this message translates to:
  /// **'Ringing…'**
  String get intercomRinging;

  /// No description provided for @intercomSeeCamera.
  ///
  /// In en, this message translates to:
  /// **'View camera'**
  String get intercomSeeCamera;

  /// Badge: the door camera fell back to still snapshots instead of live video.
  ///
  /// In en, this message translates to:
  /// **'Images'**
  String get intercomSnapshots;

  /// No description provided for @intercomSomeoneRang.
  ///
  /// In en, this message translates to:
  /// **'Someone rang the doorbell'**
  String get intercomSomeoneRang;

  /// No description provided for @intercomSubBuildingDoor.
  ///
  /// In en, this message translates to:
  /// **'Intercom · Building door'**
  String get intercomSubBuildingDoor;

  /// No description provided for @intercomTalk.
  ///
  /// In en, this message translates to:
  /// **'Talk'**
  String get intercomTalk;

  /// No description provided for @intercomVideoUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Video unavailable'**
  String get intercomVideoUnavailable;

  /// No description provided for @navCalendar.
  ///
  /// In en, this message translates to:
  /// **'Calendar'**
  String get navCalendar;

  /// No description provided for @navHome.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get navHome;

  /// No description provided for @navHouse.
  ///
  /// In en, this message translates to:
  /// **'House'**
  String get navHouse;

  /// No description provided for @navLists.
  ///
  /// In en, this message translates to:
  /// **'Lists'**
  String get navLists;

  /// No description provided for @navMeals.
  ///
  /// In en, this message translates to:
  /// **'Meals'**
  String get navMeals;

  /// No description provided for @navMusic.
  ///
  /// In en, this message translates to:
  /// **'Music'**
  String get navMusic;

  /// No description provided for @navSettings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get navSettings;

  /// No description provided for @navTasks.
  ///
  /// In en, this message translates to:
  /// **'Tasks'**
  String get navTasks;

  /// No description provided for @settingsAddTone.
  ///
  /// In en, this message translates to:
  /// **'Add ringtone'**
  String get settingsAddTone;

  /// {group} is the lower-cased name of the "My ringtones" group.
  ///
  /// In en, this message translates to:
  /// **'Your own ringtones come with the app: put .wav files in the project’s assets/ringtones/custom folder. They appear in \"{group}\" with the next update of this screen.'**
  String settingsAddToneHow(String group);

  /// No description provided for @settingsAddToneNotHere.
  ///
  /// In en, this message translates to:
  /// **'Can’t be added from the screen'**
  String get settingsAddToneNotHere;

  /// No description provided for @settingsAddToneSub.
  ///
  /// In en, this message translates to:
  /// **'Your own .wav files. They become available like any other ringtone.'**
  String get settingsAddToneSub;

  /// No description provided for @settingsAppearance.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get settingsAppearance;

  /// The voice assistant's language (set in Home Assistant).
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get settingsAssistantLanguage;

  /// No description provided for @settingsBrightness.
  ///
  /// In en, this message translates to:
  /// **'Brightness'**
  String get settingsBrightness;

  /// No description provided for @settingsBrightnessFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn’t change the brightness'**
  String get settingsBrightnessFailed;

  /// No description provided for @settingsBrightnessSub.
  ///
  /// In en, this message translates to:
  /// **'The monitor’s brightness, over DDC/CI.'**
  String get settingsBrightnessSub;

  /// No description provided for @settingsBuildingDoorToneSub.
  ///
  /// In en, this message translates to:
  /// **'Rings until you answer or the call ends. The button to the right of each ringtone lets you hear it.'**
  String get settingsBuildingDoorToneSub;

  /// No description provided for @settingsConfigureEntities.
  ///
  /// In en, this message translates to:
  /// **'Set up entities'**
  String get settingsConfigureEntities;

  /// No description provided for @settingsConfigureEntitiesSub.
  ///
  /// In en, this message translates to:
  /// **'People, rooms, energy and cars are set up in the \"ByteHomeDash\" panel in Home Assistant.'**
  String get settingsConfigureEntitiesSub;

  /// No description provided for @settingsConnections.
  ///
  /// In en, this message translates to:
  /// **'Connections'**
  String get settingsConnections;

  /// No description provided for @settingsHaSub.
  ///
  /// In en, this message translates to:
  /// **'{host} · {count, plural, =1{1 entity} other{{count} entities}}'**
  String settingsHaSub(String host, int count);

  /// No description provided for @settingsIntercom.
  ///
  /// In en, this message translates to:
  /// **'Intercom'**
  String get settingsIntercom;

  /// No description provided for @settingsIntercomBuildingDoor.
  ///
  /// In en, this message translates to:
  /// **'Hikvision · Building door'**
  String get settingsIntercomBuildingDoor;

  /// No description provided for @settingsIntercomConnection.
  ///
  /// In en, this message translates to:
  /// **'Connection'**
  String get settingsIntercomConnection;

  /// No description provided for @settingsIntercomDoorCamera.
  ///
  /// In en, this message translates to:
  /// **'Hikvision · door camera'**
  String get settingsIntercomDoorCamera;

  /// No description provided for @settingsIntercomNotConfigured.
  ///
  /// In en, this message translates to:
  /// **'Hikvision · not set up on this screen'**
  String get settingsIntercomNotConfigured;

  /// No description provided for @settingsIntercomPageSub.
  ///
  /// In en, this message translates to:
  /// **'This screen’s ringtone when someone rings from the building intercom.'**
  String get settingsIntercomPageSub;

  /// No description provided for @settingsIntercomToneSub.
  ///
  /// In en, this message translates to:
  /// **'Building door: {tone}'**
  String settingsIntercomToneSub(String tone);

  /// No description provided for @settingsIntercomTones.
  ///
  /// In en, this message translates to:
  /// **'Ringtones and volume'**
  String get settingsIntercomTones;

  /// No description provided for @settingsMaAddonMissing.
  ///
  /// In en, this message translates to:
  /// **'Add-on not found in Home Assistant'**
  String get settingsMaAddonMissing;

  /// No description provided for @settingsMaSpeakersFound.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 speaker found} other{{count} speakers found}}'**
  String settingsMaSpeakersFound(int count);

  /// No description provided for @settingsMaViaHa.
  ///
  /// In en, this message translates to:
  /// **'Through Home Assistant'**
  String get settingsMaViaHa;

  /// No description provided for @settingsManage.
  ///
  /// In en, this message translates to:
  /// **'Manage'**
  String get settingsManage;

  /// No description provided for @settingsMicNotConnected.
  ///
  /// In en, this message translates to:
  /// **'The microphone isn’t connected to this screen yet.'**
  String get settingsMicNotConnected;

  /// No description provided for @settingsNetNoCable.
  ///
  /// In en, this message translates to:
  /// **'No cable or no address'**
  String get settingsNetNoCable;

  /// Wi-Fi signal strength, inside a "network · signal · address" line.
  ///
  /// In en, this message translates to:
  /// **'signal {percent}%'**
  String settingsNetSignal(int percent);

  /// No description provided for @settingsOwnTones.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{None of your own ringtones yet} =1{1 of your own ringtones} other{{count} of your own ringtones}}'**
  String settingsOwnTones(int count);

  /// No description provided for @settingsRebootFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn’t restart'**
  String get settingsRebootFailed;

  /// No description provided for @settingsRebootScreen.
  ///
  /// In en, this message translates to:
  /// **'Restart the screen'**
  String get settingsRebootScreen;

  /// No description provided for @settingsRebootScreenSub.
  ///
  /// In en, this message translates to:
  /// **'Restarts the device. Takes about 1 minute.'**
  String get settingsRebootScreenSub;

  /// No description provided for @settingsRebootScreenText.
  ///
  /// In en, this message translates to:
  /// **'The device restarts. The screen is unavailable for about 1 minute, intercom included.'**
  String get settingsRebootScreenText;

  /// No description provided for @settingsRebootScreenTitle.
  ///
  /// In en, this message translates to:
  /// **'Restart the screen?'**
  String get settingsRebootScreenTitle;

  /// No description provided for @settingsRebootingScreen.
  ///
  /// In en, this message translates to:
  /// **'Restarting the screen…'**
  String get settingsRebootingScreen;

  /// No description provided for @settingsRecognizedVoices.
  ///
  /// In en, this message translates to:
  /// **'Recognised voices'**
  String get settingsRecognizedVoices;

  /// No description provided for @settingsRecognizedVoicesSub.
  ///
  /// In en, this message translates to:
  /// **'Who the assistant recognises by voice.'**
  String get settingsRecognizedVoicesSub;

  /// No description provided for @settingsRestart.
  ///
  /// In en, this message translates to:
  /// **'Restart'**
  String get settingsRestart;

  /// No description provided for @settingsRestartApp.
  ///
  /// In en, this message translates to:
  /// **'Restart the app'**
  String get settingsRestartApp;

  /// No description provided for @settingsRestartAppSub.
  ///
  /// In en, this message translates to:
  /// **'Reloads the screen. Takes a few seconds.'**
  String get settingsRestartAppSub;

  /// No description provided for @settingsRestartAppText.
  ///
  /// In en, this message translates to:
  /// **'The screen goes blank for a few seconds and comes back on the Home page.'**
  String get settingsRestartAppText;

  /// No description provided for @settingsRestartAppTitle.
  ///
  /// In en, this message translates to:
  /// **'Restart the app?'**
  String get settingsRestartAppTitle;

  /// No description provided for @settingsRestartingApp.
  ///
  /// In en, this message translates to:
  /// **'Restarting the app…'**
  String get settingsRestartingApp;

  /// No description provided for @settingsScreenAndSound.
  ///
  /// In en, this message translates to:
  /// **'Screen and sound'**
  String get settingsScreenAndSound;

  /// No description provided for @settingsScreenOff.
  ///
  /// In en, this message translates to:
  /// **'Turn off the screen'**
  String get settingsScreenOff;

  /// No description provided for @settingsScreenOffButton.
  ///
  /// In en, this message translates to:
  /// **'Turn off'**
  String get settingsScreenOffButton;

  /// No description provided for @settingsScreenOffSub.
  ///
  /// In en, this message translates to:
  /// **'Goes dark right away. Touch it to wake it up.'**
  String get settingsScreenOffSub;

  /// No description provided for @settingsSetInHa.
  ///
  /// In en, this message translates to:
  /// **'Set in Home Assistant.'**
  String get settingsSetInHa;

  /// Connection status of a service or network link.
  ///
  /// In en, this message translates to:
  /// **'Connected'**
  String get settingsStatusConnected;

  /// No description provided for @settingsStatusConnecting.
  ///
  /// In en, this message translates to:
  /// **'Connecting'**
  String get settingsStatusConnecting;

  /// No description provided for @settingsStatusDisconnected.
  ///
  /// In en, this message translates to:
  /// **'Not connected'**
  String get settingsStatusDisconnected;

  /// No description provided for @settingsSystem.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get settingsSystem;

  /// No description provided for @settingsTapClockHint.
  ///
  /// In en, this message translates to:
  /// **'Tap the clock on any page to come back here.'**
  String get settingsTapClockHint;

  /// No description provided for @settingsThemeAlwaysDark.
  ///
  /// In en, this message translates to:
  /// **'Always dark'**
  String get settingsThemeAlwaysDark;

  /// No description provided for @settingsThemeAlwaysLight.
  ///
  /// In en, this message translates to:
  /// **'Always light'**
  String get settingsThemeAlwaysLight;

  /// No description provided for @settingsThemeAtSunsetSunrise.
  ///
  /// In en, this message translates to:
  /// **'At sunset and sunrise'**
  String get settingsThemeAtSunsetSunrise;

  /// No description provided for @settingsThemeBySun.
  ///
  /// In en, this message translates to:
  /// **'Follows the sun'**
  String get settingsThemeBySun;

  /// Dark theme.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get settingsThemeDark;

  /// No description provided for @settingsThemeDarkAtSunset.
  ///
  /// In en, this message translates to:
  /// **'Dark at sunset'**
  String get settingsThemeDarkAtSunset;

  /// Above a time, e.g. "Dark from 21:00".
  ///
  /// In en, this message translates to:
  /// **'Dark from'**
  String get settingsThemeDarkFrom;

  /// No description provided for @settingsThemeFixedTimes.
  ///
  /// In en, this message translates to:
  /// **'At fixed times'**
  String get settingsThemeFixedTimes;

  /// Light theme.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get settingsThemeLight;

  /// No description provided for @settingsThemeLightAtSunrise.
  ///
  /// In en, this message translates to:
  /// **'Light at sunrise'**
  String get settingsThemeLightAtSunrise;

  /// Above a time, e.g. "Light from 07:00".
  ///
  /// In en, this message translates to:
  /// **'Light from'**
  String get settingsThemeLightFrom;

  /// No description provided for @settingsThemeNowDark.
  ///
  /// In en, this message translates to:
  /// **'Dark now · light at {time}'**
  String settingsThemeNowDark(String time);

  /// No description provided for @settingsThemeNowLight.
  ///
  /// In en, this message translates to:
  /// **'Light now · dark at {time}'**
  String settingsThemeNowLight(String time);

  /// No description provided for @settingsThemeSunToday.
  ///
  /// In en, this message translates to:
  /// **'Today’s times, from the Home Assistant sun (sun.sun). They follow the seasons by themselves.'**
  String get settingsThemeSunToday;

  /// {command} is settingsThemeVoiceCommand and {entity} an entity id, both shown in bold.
  ///
  /// In en, this message translates to:
  /// **'You can also ask the assistant: {command}. In Home Assistant the theme is available as {entity}, for use in automations (for example, dark when a film starts).'**
  String settingsThemeTip(String command, String entity);

  /// An example voice command; {wakePhrase} is e.g. "Ok Nabu".
  ///
  /// In en, this message translates to:
  /// **'“{wakePhrase}, switch to dark mode”'**
  String settingsThemeVoiceCommand(String wakePhrase);

  /// No description provided for @settingsThemeWaitingForSun.
  ///
  /// In en, this message translates to:
  /// **'Waiting for the sun times from Home Assistant (sun.sun). Until then, it switches at {darkTime} and at {lightTime}.'**
  String settingsThemeWaitingForSun(String darkTime, String lightTime);

  /// No description provided for @settingsThemeWhen.
  ///
  /// In en, this message translates to:
  /// **'When to switch'**
  String get settingsThemeWhen;

  /// No description provided for @settingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// No description provided for @settingsToneCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 ringtone} other{{count} ringtones}}'**
  String settingsToneCount(int count);

  /// Small badge on the user's own ringtone.
  ///
  /// In en, this message translates to:
  /// **'MINE'**
  String get settingsToneMine;

  /// No description provided for @settingsTonePlaying.
  ///
  /// In en, this message translates to:
  /// **'“{name}” · volume {percent}%'**
  String settingsTonePlaying(String name, int percent);

  /// No description provided for @settingsToneVolume.
  ///
  /// In en, this message translates to:
  /// **'Ringtone volume'**
  String get settingsToneVolume;

  /// No description provided for @settingsToneVolumeSub.
  ///
  /// In en, this message translates to:
  /// **'Through the monitor’s speakers. Doesn’t change the music or intercom volume.'**
  String get settingsToneVolumeSub;

  /// No description provided for @settingsUnavailableOnScreen.
  ///
  /// In en, this message translates to:
  /// **'Not available on this screen.'**
  String get settingsUnavailableOnScreen;

  /// No description provided for @settingsVersion.
  ///
  /// In en, this message translates to:
  /// **'Version'**
  String get settingsVersion;

  /// No description provided for @settingsVersionSub.
  ///
  /// In en, this message translates to:
  /// **'Updated by the deploy on the device.'**
  String get settingsVersionSub;

  /// No description provided for @settingsVoiceAssistant.
  ///
  /// In en, this message translates to:
  /// **'Voice assistant'**
  String get settingsVoiceAssistant;

  /// No description provided for @settingsVolume.
  ///
  /// In en, this message translates to:
  /// **'Volume'**
  String get settingsVolume;

  /// No description provided for @settingsVolumeFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn’t change the volume'**
  String get settingsVolumeFailed;

  /// No description provided for @settingsVolumePercent.
  ///
  /// In en, this message translates to:
  /// **'Volume {percent}%'**
  String settingsVolumePercent(int percent);

  /// No description provided for @settingsVolumeSub.
  ///
  /// In en, this message translates to:
  /// **'This screen’s overall volume.'**
  String get settingsVolumeSub;

  /// No description provided for @settingsWakeWord.
  ///
  /// In en, this message translates to:
  /// **'Wake word'**
  String get settingsWakeWord;

  /// No description provided for @settingsWakeWordSub.
  ///
  /// In en, this message translates to:
  /// **'Say “{wakePhrase}” to talk to the assistant.'**
  String settingsWakeWordSub(String wakePhrase);

  /// No description provided for @settingsWebBrowser.
  ///
  /// In en, this message translates to:
  /// **'Web browser'**
  String get settingsWebBrowser;

  /// No description provided for @shellDoorbellWontRing.
  ///
  /// In en, this message translates to:
  /// **'The doorbell won’t ring on this screen'**
  String get shellDoorbellWontRing;

  /// No description provided for @shellNoHaConnection.
  ///
  /// In en, this message translates to:
  /// **'No connection to Home Assistant'**
  String get shellNoHaConnection;

  /// No description provided for @shellRetryingAuto.
  ///
  /// In en, this message translates to:
  /// **'Trying again automatically…'**
  String get shellRetryingAuto;

  /// No description provided for @shellScreenSettings.
  ///
  /// In en, this message translates to:
  /// **'Screen settings'**
  String get shellScreenSettings;

  /// Portuguese public holiday name
  ///
  /// In en, this message translates to:
  /// **'New Year’s Day'**
  String get calendarHolidayNewYear;

  /// No description provided for @calendarHolidayCarnival.
  ///
  /// In en, this message translates to:
  /// **'Carnival'**
  String get calendarHolidayCarnival;

  /// No description provided for @calendarHolidayGoodFriday.
  ///
  /// In en, this message translates to:
  /// **'Good Friday'**
  String get calendarHolidayGoodFriday;

  /// No description provided for @calendarHolidayEaster.
  ///
  /// In en, this message translates to:
  /// **'Easter'**
  String get calendarHolidayEaster;

  /// Portugal, 25 April
  ///
  /// In en, this message translates to:
  /// **'Freedom Day'**
  String get calendarHolidayFreedomDay;

  /// No description provided for @calendarHolidayLabourDay.
  ///
  /// In en, this message translates to:
  /// **'Labour Day'**
  String get calendarHolidayLabourDay;

  /// No description provided for @calendarHolidayPortugalDay.
  ///
  /// In en, this message translates to:
  /// **'Portugal Day'**
  String get calendarHolidayPortugalDay;

  /// No description provided for @calendarHolidayCorpusChristi.
  ///
  /// In en, this message translates to:
  /// **'Corpus Christi'**
  String get calendarHolidayCorpusChristi;

  /// No description provided for @calendarHolidaySaintAnthony.
  ///
  /// In en, this message translates to:
  /// **'Saint Anthony’s Day'**
  String get calendarHolidaySaintAnthony;

  /// No description provided for @calendarHolidayAssumption.
  ///
  /// In en, this message translates to:
  /// **'Assumption Day'**
  String get calendarHolidayAssumption;

  /// No description provided for @calendarHolidayRepublicDay.
  ///
  /// In en, this message translates to:
  /// **'Republic Day'**
  String get calendarHolidayRepublicDay;

  /// No description provided for @calendarHolidayAllSaints.
  ///
  /// In en, this message translates to:
  /// **'All Saints’ Day'**
  String get calendarHolidayAllSaints;

  /// No description provided for @calendarHolidayRestorationOfIndependence.
  ///
  /// In en, this message translates to:
  /// **'Restoration of Independence'**
  String get calendarHolidayRestorationOfIndependence;

  /// No description provided for @calendarHolidayImmaculateConception.
  ///
  /// In en, this message translates to:
  /// **'Immaculate Conception'**
  String get calendarHolidayImmaculateConception;

  /// No description provided for @calendarHolidayChristmas.
  ///
  /// In en, this message translates to:
  /// **'Christmas Day'**
  String get calendarHolidayChristmas;

  /// Toast when a just-created calendar event never showed up in HA
  ///
  /// In en, this message translates to:
  /// **'Home Assistant didn’t confirm the event \"{title}\"'**
  String eventNotConfirmed(String title);

  /// Event title suggestion
  ///
  /// In en, this message translates to:
  /// **'Dinner'**
  String get eventSuggestionDinner;

  /// Event title suggestion
  ///
  /// In en, this message translates to:
  /// **'Lunch'**
  String get eventSuggestionLunch;

  /// Event title suggestion (doctor etc.)
  ///
  /// In en, this message translates to:
  /// **'Appointment'**
  String get eventSuggestionAppointment;

  /// Event title suggestion
  ///
  /// In en, this message translates to:
  /// **'Birthday'**
  String get eventSuggestionBirthday;

  /// Event title suggestion
  ///
  /// In en, this message translates to:
  /// **'School'**
  String get eventSuggestionSchool;

  /// Event title suggestion
  ///
  /// In en, this message translates to:
  /// **'Gym'**
  String get eventSuggestionGym;

  /// Event title suggestion
  ///
  /// In en, this message translates to:
  /// **'Meeting'**
  String get eventSuggestionMeeting;

  /// Toast; date like "sat 17 Oct"
  ///
  /// In en, this message translates to:
  /// **'Event created: {title} · {date}, all day'**
  String eventCreatedAllDay(String title, String date);

  /// Toast; time like 09:00
  ///
  /// In en, this message translates to:
  /// **'Event created: {title} · {date}, {time}'**
  String eventCreatedAt(String title, String date, String time);

  /// Part of an event duration, followed by "3 h 15 min"
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 day} other{{count} days}}'**
  String eventDurationDays(int count);

  /// No description provided for @eventNewTitle.
  ///
  /// In en, this message translates to:
  /// **'New event'**
  String get eventNewTitle;

  /// Field label, uppercase
  ///
  /// In en, this message translates to:
  /// **'TITLE'**
  String get eventFieldTitle;

  /// No description provided for @eventTitleHint.
  ///
  /// In en, this message translates to:
  /// **'E.g. Dinner with friends'**
  String get eventTitleHint;

  /// Field label: whose calendar
  ///
  /// In en, this message translates to:
  /// **'FOR WHOM'**
  String get eventFieldForWhom;

  /// No description provided for @eventNoWritableCalendar.
  ///
  /// In en, this message translates to:
  /// **'No writable calendar set up.'**
  String get eventNoWritableCalendar;

  /// No description provided for @eventFieldDate.
  ///
  /// In en, this message translates to:
  /// **'DATE'**
  String get eventFieldDate;

  /// Uppercase label of a multi-day event’s end date
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{END · 1 DAY} other{END · {count} DAYS}}'**
  String eventFieldEndDays(int count);

  /// Uppercase label
  ///
  /// In en, this message translates to:
  /// **'END'**
  String get eventFieldEnd;

  /// Uppercase label
  ///
  /// In en, this message translates to:
  /// **'START'**
  String get eventFieldStart;

  /// No description provided for @eventSameDay.
  ///
  /// In en, this message translates to:
  /// **'Same day'**
  String get eventSameDay;

  /// No description provided for @eventFieldTime.
  ///
  /// In en, this message translates to:
  /// **'TIME'**
  String get eventFieldTime;

  /// No description provided for @eventAllDay.
  ///
  /// In en, this message translates to:
  /// **'All day'**
  String get eventAllDay;

  /// No description provided for @eventStartOn.
  ///
  /// In en, this message translates to:
  /// **'Start · {date}'**
  String eventStartOn(String date);

  /// No description provided for @eventStart.
  ///
  /// In en, this message translates to:
  /// **'Start'**
  String get eventStart;

  /// No description provided for @eventEndOn.
  ///
  /// In en, this message translates to:
  /// **'End · {date}'**
  String eventEndOn(String date);

  /// No description provided for @eventEnd.
  ///
  /// In en, this message translates to:
  /// **'End'**
  String get eventEnd;

  /// No description provided for @eventDuration.
  ///
  /// In en, this message translates to:
  /// **'Duration: {duration}'**
  String eventDuration(String duration);

  /// No description provided for @eventFieldPlace.
  ///
  /// In en, this message translates to:
  /// **'PLACE'**
  String get eventFieldPlace;

  /// No description provided for @eventPlaceHint.
  ///
  /// In en, this message translates to:
  /// **'E.g. Grandma’s house'**
  String get eventPlaceHint;

  /// No description provided for @eventFieldRepeat.
  ///
  /// In en, this message translates to:
  /// **'REPEAT'**
  String get eventFieldRepeat;

  /// No description provided for @eventRepeatNone.
  ///
  /// In en, this message translates to:
  /// **'Doesn’t repeat'**
  String get eventRepeatNone;

  /// No description provided for @eventRepeatDaily.
  ///
  /// In en, this message translates to:
  /// **'Every day'**
  String get eventRepeatDaily;

  /// No description provided for @eventRepeatWeekly.
  ///
  /// In en, this message translates to:
  /// **'Every week'**
  String get eventRepeatWeekly;

  /// No description provided for @eventRepeatMonthly.
  ///
  /// In en, this message translates to:
  /// **'Every month'**
  String get eventRepeatMonthly;

  /// No description provided for @eventFieldNotes.
  ///
  /// In en, this message translates to:
  /// **'NOTES'**
  String get eventFieldNotes;

  /// No description provided for @eventNotesHint.
  ///
  /// In en, this message translates to:
  /// **'Details, what to bring, contacts…'**
  String get eventNotesHint;

  /// No description provided for @eventSave.
  ///
  /// In en, this message translates to:
  /// **'Save event'**
  String get eventSave;

  /// No description provided for @eventNoCalendarToSave.
  ///
  /// In en, this message translates to:
  /// **'No calendar to save it to'**
  String get eventNoCalendarToSave;

  /// No description provided for @eventWillBeAddedTo.
  ///
  /// In en, this message translates to:
  /// **'Will be added to {name}’s calendar'**
  String eventWillBeAddedTo(String name);

  /// No description provided for @eventTitleRequired.
  ///
  /// In en, this message translates to:
  /// **'Type a title to save'**
  String get eventTitleRequired;

  /// Calendar view switch
  ///
  /// In en, this message translates to:
  /// **'Day'**
  String get calendarViewDay;

  /// Calendar view switch
  ///
  /// In en, this message translates to:
  /// **'Week'**
  String get calendarViewWeek;

  /// Calendar view switch
  ///
  /// In en, this message translates to:
  /// **'Month'**
  String get calendarViewMonth;

  /// Calendar view switch: list of upcoming days
  ///
  /// In en, this message translates to:
  /// **'Agenda'**
  String get calendarViewAgenda;

  /// Day view subtitle; week is the ISO week number
  ///
  /// In en, this message translates to:
  /// **'Today · {year} · Week {week}'**
  String calendarDaySubtitleToday(String year, String week);

  /// Day view subtitle; week is the ISO week number
  ///
  /// In en, this message translates to:
  /// **'{year} · Week {week}'**
  String calendarDaySubtitle(String year, String week);

  /// Week view subtitle; range like "13 Oct – 19 Oct"
  ///
  /// In en, this message translates to:
  /// **'Week {week} · {range}'**
  String calendarWeekSubtitle(String week, String range);

  /// No description provided for @calendarMonthHint.
  ///
  /// In en, this message translates to:
  /// **'Tap a day to see its details'**
  String get calendarMonthHint;

  /// No description provided for @calendarAgendaSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Next 3 weeks, from {weekday}, {date}'**
  String calendarAgendaSubtitle(String weekday, String date);

  /// Nothing scheduled on this day
  ///
  /// In en, this message translates to:
  /// **'Free day'**
  String get calendarDayFree;

  /// No description provided for @calendarNothingScheduled.
  ///
  /// In en, this message translates to:
  /// **'Nothing scheduled'**
  String get calendarNothingScheduled;

  /// No description provided for @calendarDayIsFree.
  ///
  /// In en, this message translates to:
  /// **'This day is free.'**
  String get calendarDayIsFree;

  /// Uppercase label in a narrow column, on two lines
  ///
  /// In en, this message translates to:
  /// **'ALL\nDAY'**
  String get calendarAllDayStacked;

  /// No description provided for @calendarNoAllDayEvents.
  ///
  /// In en, this message translates to:
  /// **'No all-day events'**
  String get calendarNoAllDayEvents;

  /// No description provided for @calendarDaySummary.
  ///
  /// In en, this message translates to:
  /// **'Day summary'**
  String get calendarDaySummary;

  /// No description provided for @calendarEventCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 event} other{{count} events}}'**
  String calendarEventCount(int count);

  /// No description provided for @calendarUpcomingHolidays.
  ///
  /// In en, this message translates to:
  /// **'Upcoming holidays'**
  String get calendarUpcomingHolidays;

  /// More events than fit in a month-view cell
  ///
  /// In en, this message translates to:
  /// **'+{count} more'**
  String calendarMore(int count);

  /// Agenda row time column for an all-day event
  ///
  /// In en, this message translates to:
  /// **'All day'**
  String get calendarAllDay;

  /// No description provided for @calendarDayFreeNothingScheduled.
  ///
  /// In en, this message translates to:
  /// **'Free day · nothing scheduled'**
  String get calendarDayFreeNothingScheduled;

  /// Forecast modal subtitle, daily tab
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Next day} other{Next {count} days}}'**
  String forecastSubtitleDays(int count);

  /// Forecast modal subtitle, daily tab; time the forecast was fetched
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Next day · updated at {time}} other{Next {count} days · updated at {time}}}'**
  String forecastSubtitleDaysUpdated(int count, String time);

  /// No description provided for @forecastSubtitleHours.
  ///
  /// In en, this message translates to:
  /// **'Next 48 hours'**
  String get forecastSubtitleHours;

  /// No description provided for @forecastSubtitleHoursUpdated.
  ///
  /// In en, this message translates to:
  /// **'Next 48 hours · updated at {time}'**
  String forecastSubtitleHoursUpdated(String time);

  /// No description provided for @forecastNoEntity.
  ///
  /// In en, this message translates to:
  /// **'No weather entity set up.'**
  String get forecastNoEntity;

  /// No description provided for @forecastLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn’t get the forecast.'**
  String get forecastLoadFailed;

  /// No description provided for @forecastLoading.
  ///
  /// In en, this message translates to:
  /// **'Loading the forecast…'**
  String get forecastLoading;

  /// No description provided for @forecastUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Forecast unavailable.'**
  String get forecastUnavailable;

  /// No description provided for @forecastTodayDotHint.
  ///
  /// In en, this message translates to:
  /// **'The dot on today’s bar marks the current temperature.'**
  String get forecastTodayDotHint;

  /// No description provided for @forecastHoursHint.
  ///
  /// In en, this message translates to:
  /// **'Tap the chart or an hour to see its details.'**
  String get forecastHoursHint;

  /// No description provided for @forecastTitle.
  ///
  /// In en, this message translates to:
  /// **'Weather forecast'**
  String get forecastTitle;

  /// Tab
  ///
  /// In en, this message translates to:
  /// **'Days'**
  String get forecastTabDays;

  /// Tab
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 day} other{{count} days}}'**
  String forecastTabDaysCount(int count);

  /// Tab
  ///
  /// In en, this message translates to:
  /// **'48 hours'**
  String get forecastTabHours;

  /// No description provided for @forecastNow.
  ///
  /// In en, this message translates to:
  /// **'Now'**
  String get forecastNow;

  /// date like "sat 17"
  ///
  /// In en, this message translates to:
  /// **'Now · {date}'**
  String forecastNowOn(String date);

  /// Chance of rain
  ///
  /// In en, this message translates to:
  /// **'Rain {pct}%'**
  String forecastRain(String pct);

  /// No description provided for @forecastWind.
  ///
  /// In en, this message translates to:
  /// **'Wind {speed} {unit}'**
  String forecastWind(String speed, String unit);

  /// Today’s high, temp like 21°
  ///
  /// In en, this message translates to:
  /// **'max {temp}'**
  String forecastMax(String temp);

  /// Today’s low, temp like 12°
  ///
  /// In en, this message translates to:
  /// **'min {temp}'**
  String forecastMin(String temp);

  /// No description provided for @forecastSunrise.
  ///
  /// In en, this message translates to:
  /// **'Sunrise {time}'**
  String forecastSunrise(String time);

  /// No description provided for @forecastSunset.
  ///
  /// In en, this message translates to:
  /// **'Sunset {time}'**
  String forecastSunset(String time);

  /// Uppercase day heading, day like "SATURDAY 17"
  ///
  /// In en, this message translates to:
  /// **'{day} · TODAY'**
  String forecastHeadToday(String day);

  /// Weather warnings (IPMA)
  ///
  /// In en, this message translates to:
  /// **'No warnings in effect'**
  String get weatherNoWarnings;

  /// when like "at 18:00", "tomorrow at 06:00", "sat at 06:00"
  ///
  /// In en, this message translates to:
  /// **'from {when}'**
  String weatherWarningFrom(String when);

  /// when like "at 18:00", "tomorrow at 06:00", "sat at 06:00"
  ///
  /// In en, this message translates to:
  /// **'until {when}'**
  String weatherWarningUntil(String when);

  /// No description provided for @weatherWarningActive.
  ///
  /// In en, this message translates to:
  /// **'Warning in effect'**
  String get weatherWarningActive;

  /// Uppercase card label
  ///
  /// In en, this message translates to:
  /// **'WARNING'**
  String get weatherWarningLabel;

  /// Warning level
  ///
  /// In en, this message translates to:
  /// **'Green'**
  String get weatherWarningGreen;

  /// Warning level
  ///
  /// In en, this message translates to:
  /// **'Yellow'**
  String get weatherWarningYellow;

  /// Warning level
  ///
  /// In en, this message translates to:
  /// **'Orange'**
  String get weatherWarningOrange;

  /// Warning level
  ///
  /// In en, this message translates to:
  /// **'Red'**
  String get weatherWarningRed;

  /// No description provided for @weatherUvAtHour.
  ///
  /// In en, this message translates to:
  /// **'At {time}'**
  String weatherUvAtHour(String time);

  /// UV index card; max is today’s peak UV index
  ///
  /// In en, this message translates to:
  /// **'At {time} · max. {max} at {maxTime}'**
  String weatherUvAtHourWithMax(String time, String max, String maxTime);

  /// UV index card; max is today’s peak UV index
  ///
  /// In en, this message translates to:
  /// **'Now · max. {max} at {maxTime}'**
  String weatherUvNowWithMax(String max, String maxTime);

  /// UV index card
  ///
  /// In en, this message translates to:
  /// **'Today’s forecast peak'**
  String get weatherUvTodayMax;

  /// UV index level
  ///
  /// In en, this message translates to:
  /// **'Low'**
  String get weatherUvLow;

  /// UV index and fire risk level
  ///
  /// In en, this message translates to:
  /// **'Moderate'**
  String get weatherLevelModerate;

  /// UV index and fire risk level
  ///
  /// In en, this message translates to:
  /// **'High'**
  String get weatherLevelHigh;

  /// UV index and fire risk level
  ///
  /// In en, this message translates to:
  /// **'Very high'**
  String get weatherLevelVeryHigh;

  /// UV index level
  ///
  /// In en, this message translates to:
  /// **'Extreme'**
  String get weatherUvExtreme;

  /// Uppercase card label
  ///
  /// In en, this message translates to:
  /// **'UV INDEX'**
  String get weatherUvLabel;

  /// UV index 0
  ///
  /// In en, this message translates to:
  /// **'No sun'**
  String get weatherUvNoSun;

  /// Uppercase card label
  ///
  /// In en, this message translates to:
  /// **'FIRE RISK'**
  String get weatherFireRiskLabel;

  /// Fire risk level
  ///
  /// In en, this message translates to:
  /// **'Low'**
  String get weatherFireLow;

  /// Fire risk level
  ///
  /// In en, this message translates to:
  /// **'Maximum'**
  String get weatherFireMaximum;

  /// No description provided for @weatherFireAdvice.
  ///
  /// In en, this message translates to:
  /// **'Avoid bonfires and burning'**
  String get weatherFireAdvice;

  /// IPMA is the Portuguese weather service
  ///
  /// In en, this message translates to:
  /// **'Today · IPMA forecast'**
  String get weatherFireTodayIpma;

  /// Lowercase, used inside a sentence
  ///
  /// In en, this message translates to:
  /// **'at {time}'**
  String weatherAtTime(String time);

  /// Lowercase, used inside a sentence
  ///
  /// In en, this message translates to:
  /// **'tomorrow at {time}'**
  String weatherTomorrowAtTime(String time);

  /// day is a short weekday like "sat"
  ///
  /// In en, this message translates to:
  /// **'{day} at {time}'**
  String weatherDayAtTime(String day, String time);

  /// Home page card title, opens the House page
  ///
  /// In en, this message translates to:
  /// **'House'**
  String get homeHouseTitle;

  /// Uppercase tag above an all-day event
  ///
  /// In en, this message translates to:
  /// **'HOLIDAY'**
  String get homeHolidayTag;

  /// Uppercase tag above an all-day event
  ///
  /// In en, this message translates to:
  /// **'ALL DAY'**
  String get homeAllDayTag;

  /// Current-time marker in the week strip
  ///
  /// In en, this message translates to:
  /// **'Now'**
  String get homeNow;

  /// Card title
  ///
  /// In en, this message translates to:
  /// **'Tasks'**
  String get homeTasksTitle;

  /// No description provided for @homeTasksNothingToday.
  ///
  /// In en, this message translates to:
  /// **'Nothing for today'**
  String get homeTasksNothingToday;

  /// Today’s tasks progress
  ///
  /// In en, this message translates to:
  /// **'{done} of {total} done'**
  String homeTasksDone(int done, int total);

  /// No description provided for @homeNoTasksToday.
  ///
  /// In en, this message translates to:
  /// **'No tasks for today'**
  String get homeNoTasksToday;

  /// Addressed to the whole family
  ///
  /// In en, this message translates to:
  /// **'Enjoy the free day.'**
  String get homeEnjoyFreeDay;

  /// Card title
  ///
  /// In en, this message translates to:
  /// **'Meals'**
  String get homeMealsTitle;

  /// Empty meal slot: tap to plan a meal
  ///
  /// In en, this message translates to:
  /// **'+ Plan'**
  String get homeMealPlan;

  /// Meal eaten out
  ///
  /// In en, this message translates to:
  /// **'Out · {dish}'**
  String homeMealOut(String dish);

  /// Meal ordered in
  ///
  /// In en, this message translates to:
  /// **'{dish} · Takeaway'**
  String homeMealDelivery(String dish);

  /// No description provided for @homeMealTomorrowUnplanned.
  ///
  /// In en, this message translates to:
  /// **'Tomorrow: not planned'**
  String get homeMealTomorrowUnplanned;

  /// No description provided for @homeMealTomorrow.
  ///
  /// In en, this message translates to:
  /// **'Tomorrow: {dish}'**
  String homeMealTomorrow(String dish);

  /// Card title when no list is chosen
  ///
  /// In en, this message translates to:
  /// **'Shopping'**
  String get homeShoppingTitle;

  /// No description provided for @homeNoList.
  ///
  /// In en, this message translates to:
  /// **'No list'**
  String get homeNoList;

  /// No description provided for @homeSeeAllCount.
  ///
  /// In en, this message translates to:
  /// **'See all ({count})'**
  String homeSeeAllCount(int count);

  /// No description provided for @homeOpenList.
  ///
  /// In en, this message translates to:
  /// **'Open list'**
  String get homeOpenList;

  /// Title of a recipe page that has none
  ///
  /// In en, this message translates to:
  /// **'Recipe'**
  String get kitchenRecipeDefaultTitle;

  /// Shown briefly when a voice command moved the recipe on
  ///
  /// In en, this message translates to:
  /// **'By voice · “next step”'**
  String get kitchenVoiceNextStep;

  /// No description provided for @kitchenVoiceRepeat.
  ///
  /// In en, this message translates to:
  /// **'By voice · “repeat”'**
  String get kitchenVoiceRepeat;

  /// No description provided for @kitchenVoiceBack.
  ///
  /// In en, this message translates to:
  /// **'By voice · “go back”'**
  String get kitchenVoiceBack;

  /// No description provided for @kitchenVoiceStep.
  ///
  /// In en, this message translates to:
  /// **'By voice · step {step}'**
  String kitchenVoiceStep(int step);

  /// No description provided for @kitchenStepN.
  ///
  /// In en, this message translates to:
  /// **'Step {step}'**
  String kitchenStepN(int step);

  /// A step timer chip, after "Step 3": the timer has ended
  ///
  /// In en, this message translates to:
  /// **'done!'**
  String get kitchenTimerEndedShort;

  /// time like 04:30
  ///
  /// In en, this message translates to:
  /// **'{time} · paused'**
  String kitchenTimerPaused(String time);

  /// No description provided for @kitchenExitTitle.
  ///
  /// In en, this message translates to:
  /// **'Leave the recipe?'**
  String get kitchenExitTitle;

  /// No description provided for @kitchenExitBodyWithTimer.
  ///
  /// In en, this message translates to:
  /// **'You’re on step {step} of {total}. The timer stops and the recipe closes. You can minimize it and come back later from the bubble.'**
  String kitchenExitBodyWithTimer(int step, int total);

  /// No description provided for @kitchenExitBody.
  ///
  /// In en, this message translates to:
  /// **'You’re on step {step} of {total}. The recipe closes. You can minimize it and come back later from the bubble.'**
  String kitchenExitBody(int step, int total);

  /// Nabu is the voice assistant’s name
  ///
  /// In en, this message translates to:
  /// **'Say “Ok Nabu, exit”, “minimize” or “continue”.'**
  String get kitchenExitVoiceHint;

  /// No description provided for @kitchenContinue.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get kitchenContinue;

  /// No description provided for @kitchenMinimize.
  ///
  /// In en, this message translates to:
  /// **'Minimize'**
  String get kitchenMinimize;

  /// No description provided for @kitchenExit.
  ///
  /// In en, this message translates to:
  /// **'Exit'**
  String get kitchenExit;

  /// Uppercase label above the recipe title
  ///
  /// In en, this message translates to:
  /// **'COOKING MODE'**
  String get kitchenModeLabel;

  /// ofTotal is kitchenOfTotal, drawn fainter
  ///
  /// In en, this message translates to:
  /// **'Step {step} {ofTotal}'**
  String kitchenProgress(int step, String ofTotal);

  /// Second half of "Step 3 of 12"
  ///
  /// In en, this message translates to:
  /// **'of {total}'**
  String kitchenOfTotal(int total);

  /// No description provided for @kitchenAllSteps.
  ///
  /// In en, this message translates to:
  /// **'All steps'**
  String get kitchenAllSteps;

  /// Tab
  ///
  /// In en, this message translates to:
  /// **'Step'**
  String get kitchenTabStep;

  /// Tab
  ///
  /// In en, this message translates to:
  /// **'Ingredients · {count}'**
  String kitchenTabIngredients(int count);

  /// No description provided for @kitchenTimerRunning.
  ///
  /// In en, this message translates to:
  /// **'Timer running'**
  String get kitchenTimerRunning;

  /// No description provided for @kitchenPause.
  ///
  /// In en, this message translates to:
  /// **'Pause'**
  String get kitchenPause;

  /// No description provided for @kitchenTimeUp.
  ///
  /// In en, this message translates to:
  /// **'Time’s up!'**
  String get kitchenTimeUp;

  /// No description provided for @kitchenStopAlarm.
  ///
  /// In en, this message translates to:
  /// **'Stop alarm'**
  String get kitchenStopAlarm;

  /// No description provided for @kitchenTimerMinutes.
  ///
  /// In en, this message translates to:
  /// **'Timer · {minutes} min'**
  String kitchenTimerMinutes(int minutes);

  /// Start the timer
  ///
  /// In en, this message translates to:
  /// **'Start'**
  String get kitchenStart;

  /// Ingredients ticked off
  ///
  /// In en, this message translates to:
  /// **'{ready} of {total} ready'**
  String kitchenIngredientsReady(int ready, int total);

  /// No description provided for @kitchenIngredientsTapHint.
  ///
  /// In en, this message translates to:
  /// **'Tap to cross off what you already have'**
  String get kitchenIngredientsTapHint;

  /// No description provided for @kitchenNoServings.
  ///
  /// In en, this message translates to:
  /// **'The recipe doesn’t say how many it serves'**
  String get kitchenNoServings;

  /// No description provided for @kitchenNoServingsReady.
  ///
  /// In en, this message translates to:
  /// **'The recipe doesn’t say how many it serves · {ready} of {total} ready'**
  String kitchenNoServingsReady(int ready, int total);

  /// No description provided for @kitchenIngredients.
  ///
  /// In en, this message translates to:
  /// **'Ingredients'**
  String get kitchenIngredients;

  /// Before a number of people: "For 4 people"
  ///
  /// In en, this message translates to:
  /// **'For'**
  String get kitchenServesFor;

  /// from/to like "4 people"
  ///
  /// In en, this message translates to:
  /// **'Quantities adjusted from {from} to {to}. Step times don’t change.'**
  String kitchenScaledNote(String from, String to);

  /// No description provided for @kitchenEnjoy.
  ///
  /// In en, this message translates to:
  /// **'Enjoy your meal!'**
  String get kitchenEnjoy;

  /// No description provided for @kitchenRecipeDone.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Recipe done · 1 step} other{Recipe done · {count} steps}}'**
  String kitchenRecipeDone(int count);

  /// No description provided for @kitchenReviewSteps.
  ///
  /// In en, this message translates to:
  /// **'Review the steps'**
  String get kitchenReviewSteps;

  /// No description provided for @kitchenExitMode.
  ///
  /// In en, this message translates to:
  /// **'Exit cooking mode'**
  String get kitchenExitMode;

  /// command is kitchenVoiceHintCommand, drawn bold
  ///
  /// In en, this message translates to:
  /// **'Say {command}, “repeat”, “go back” or “ingredients”. The screen stays on while you cook.'**
  String kitchenVoiceHint(String command);

  /// Example voice command; Nabu is the assistant’s name
  ///
  /// In en, this message translates to:
  /// **'“Ok Nabu, next step”'**
  String get kitchenVoiceHintCommand;

  /// Last step: finish the recipe
  ///
  /// In en, this message translates to:
  /// **'Finish'**
  String get kitchenFinish;

  /// No description provided for @kitchenPeople.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 person} other{{count} people}}'**
  String kitchenPeople(int count);

  /// Under the minimized recipe bubble
  ///
  /// In en, this message translates to:
  /// **'Step {step}/{total}'**
  String kitchenBubbleStep(int step, int total);

  /// Under the minimized recipe bubble: the timer has ended
  ///
  /// In en, this message translates to:
  /// **'Done!'**
  String get kitchenTimerEnded;

  /// Accessibility label
  ///
  /// In en, this message translates to:
  /// **'Back to the recipe {title}'**
  String kitchenBubbleSemantics(String title);

  /// Accessibility label
  ///
  /// In en, this message translates to:
  /// **'Back to the recipe {title}, timer {time}'**
  String kitchenBubbleSemanticsTimer(String title, String time);

  /// Accessibility label
  ///
  /// In en, this message translates to:
  /// **'Back to the recipe {title}, timer done'**
  String kitchenBubbleSemanticsTimerEnded(String title);

  /// Repeat label of a one-off household task
  ///
  /// In en, this message translates to:
  /// **'Only on this day'**
  String get choresOnlyThisDay;

  /// Task repeats daily
  ///
  /// In en, this message translates to:
  /// **'Every day'**
  String get choresEveryDay;

  /// Task repeats Monday to Friday
  ///
  /// In en, this message translates to:
  /// **'Weekdays'**
  String get choresWeekdays;

  /// A task's repeat label and its deadline (HH:MM)
  ///
  /// In en, this message translates to:
  /// **'{repeat} · by {time}'**
  String choresMetaDue(String repeat, String time);

  /// Page title
  ///
  /// In en, this message translates to:
  /// **'Tasks'**
  String get tasksTitle;

  /// Selected day in the Tasks header, e.g. 'Monday, 27 Oct'
  ///
  /// In en, this message translates to:
  /// **'{weekday}, {date}'**
  String tasksWeekdayDate(String weekday, String date);

  /// Header summary when the selected day has no tasks (after 'Today · ')
  ///
  /// In en, this message translates to:
  /// **'no tasks'**
  String get tasksSummaryNone;

  /// Header summary of the selected day's tasks
  ///
  /// In en, this message translates to:
  /// **'{done} of {total} done'**
  String tasksSummaryDone(int done, int total);

  /// No description provided for @tasksNew.
  ///
  /// In en, this message translates to:
  /// **'New task'**
  String get tasksNew;

  /// No description provided for @tasksEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit task'**
  String get tasksEdit;

  /// Save button for a new task
  ///
  /// In en, this message translates to:
  /// **'Create task'**
  String get tasksCreate;

  /// A person with no tasks on the day
  ///
  /// In en, this message translates to:
  /// **'Free'**
  String get tasksFree;

  /// Tasks done by one person on the day
  ///
  /// In en, this message translates to:
  /// **'{done} of {total}'**
  String tasksCountOf(int done, int total);

  /// No description provided for @tasksAllDone.
  ///
  /// In en, this message translates to:
  /// **'All done!'**
  String get tasksAllDone;

  /// No description provided for @tasksNoneTitle.
  ///
  /// In en, this message translates to:
  /// **'No tasks'**
  String get tasksNoneTitle;

  /// Empty column of the shared household member
  ///
  /// In en, this message translates to:
  /// **'Nothing for the family today'**
  String get tasksHouseholdFreeToday;

  /// No description provided for @tasksHouseholdFreeDay.
  ///
  /// In en, this message translates to:
  /// **'Nothing for the family on this day'**
  String get tasksHouseholdFreeDay;

  /// No description provided for @tasksMemberFreeToday.
  ///
  /// In en, this message translates to:
  /// **'{name} is free today'**
  String tasksMemberFreeToday(String name);

  /// No description provided for @tasksMemberFreeDay.
  ///
  /// In en, this message translates to:
  /// **'{name} is free on this day'**
  String tasksMemberFreeDay(String name);

  /// No description provided for @tasksEmptyDayTitle.
  ///
  /// In en, this message translates to:
  /// **'No tasks on this day'**
  String get tasksEmptyDayTitle;

  /// No description provided for @tasksEmptyDayBodyToday.
  ///
  /// In en, this message translates to:
  /// **'No one has tasks set for today.'**
  String get tasksEmptyDayBodyToday;

  /// date is a long lowercase date, e.g. 'monday, 27 october'
  ///
  /// In en, this message translates to:
  /// **'No one has tasks set for {date}.'**
  String tasksEmptyDayBody(String date);

  /// Field label (upper case)
  ///
  /// In en, this message translates to:
  /// **'TASK'**
  String get tasksFieldTask;

  /// No description provided for @tasksNameHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Tidy the bedroom'**
  String get tasksNameHint;

  /// Field label (upper case)
  ///
  /// In en, this message translates to:
  /// **'FOR WHOM'**
  String get tasksFieldWho;

  /// Field label (upper case)
  ///
  /// In en, this message translates to:
  /// **'REPEAT'**
  String get tasksFieldRepeat;

  /// No description provided for @tasksRepeatNone.
  ///
  /// In en, this message translates to:
  /// **'Doesn\'t repeat'**
  String get tasksRepeatNone;

  /// No description provided for @tasksRepeatDays.
  ///
  /// In en, this message translates to:
  /// **'Specific days'**
  String get tasksRepeatDays;

  /// Field label (upper case)
  ///
  /// In en, this message translates to:
  /// **'DEADLINE'**
  String get tasksFieldDue;

  /// Switch that gives a task a deadline
  ///
  /// In en, this message translates to:
  /// **'By a set time'**
  String get tasksDueToggle;

  /// Shown right before the deadline time, e.g. 'By 20:00'
  ///
  /// In en, this message translates to:
  /// **'By'**
  String get tasksDueBy;

  /// Suggested task name
  ///
  /// In en, this message translates to:
  /// **'Tidy the bedroom'**
  String get tasksSuggestTidyRoom;

  /// Suggested task name
  ///
  /// In en, this message translates to:
  /// **'Make the bed'**
  String get tasksSuggestMakeBed;

  /// Suggested task name
  ///
  /// In en, this message translates to:
  /// **'Dust'**
  String get tasksSuggestDust;

  /// Suggested task name
  ///
  /// In en, this message translates to:
  /// **'Hang out the washing'**
  String get tasksSuggestHangLaundry;

  /// Suggested task name
  ///
  /// In en, this message translates to:
  /// **'Wash the car'**
  String get tasksSuggestWashCar;

  /// Suggested task name
  ///
  /// In en, this message translates to:
  /// **'Empty the dishwasher'**
  String get tasksSuggestEmptyDishwasher;

  /// Suggested task name
  ///
  /// In en, this message translates to:
  /// **'Take out the rubbish'**
  String get tasksSuggestTakeOutRubbish;

  /// Suggested task name
  ///
  /// In en, this message translates to:
  /// **'Water the plants'**
  String get tasksSuggestWaterPlants;

  /// Page title
  ///
  /// In en, this message translates to:
  /// **'Meals'**
  String get mealsTitle;

  /// ISO week number and its first and last day
  ///
  /// In en, this message translates to:
  /// **'Week {week} · {from} – {to}'**
  String mealsWeekRange(int week, String from, String to);

  /// No description provided for @mealsBreakfast.
  ///
  /// In en, this message translates to:
  /// **'Breakfast'**
  String get mealsBreakfast;

  /// No description provided for @mealsLunch.
  ///
  /// In en, this message translates to:
  /// **'Lunch'**
  String get mealsLunch;

  /// No description provided for @mealsDinner.
  ///
  /// In en, this message translates to:
  /// **'Dinner'**
  String get mealsDinner;

  /// Where a meal happens
  ///
  /// In en, this message translates to:
  /// **'At home'**
  String get mealsPlaceHome;

  /// Where a meal happens
  ///
  /// In en, this message translates to:
  /// **'Eating out'**
  String get mealsPlaceOut;

  /// Where a meal happens: ordered in
  ///
  /// In en, this message translates to:
  /// **'Takeaway'**
  String get mealsPlaceDelivery;

  /// Toast after dragging a meal to another slot; meal is lowercase (e.g. 'dinner'), weekday e.g. 'Monday', day is the day of the month
  ///
  /// In en, this message translates to:
  /// **'{dish} copied to {meal} on {weekday} {day}'**
  String mealsCopiedTo(String dish, String meal, String weekday, int day);

  /// No description provided for @mealsUndo.
  ///
  /// In en, this message translates to:
  /// **'Undo'**
  String get mealsUndo;

  /// Empty slot while a meal is dragged over it
  ///
  /// In en, this message translates to:
  /// **'Copy here'**
  String get mealsCopyHere;

  /// Empty meal slot button
  ///
  /// In en, this message translates to:
  /// **'Plan'**
  String get mealsPlan;

  /// No description provided for @mealsRecipe.
  ///
  /// In en, this message translates to:
  /// **'Recipe'**
  String get mealsRecipe;

  /// Error shown when Cooking mode can't read the recipe
  ///
  /// In en, this message translates to:
  /// **'the recipe page has no steps'**
  String get mealsRecipeNoSteps;

  /// Field label (upper case)
  ///
  /// In en, this message translates to:
  /// **'DISH'**
  String get mealsFieldDish;

  /// No description provided for @mealsDishHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Vegetable soup'**
  String get mealsDishHint;

  /// No description provided for @mealsOpenSite.
  ///
  /// In en, this message translates to:
  /// **'Open the site'**
  String get mealsOpenSite;

  /// No description provided for @mealsOpening.
  ///
  /// In en, this message translates to:
  /// **'Opening…'**
  String get mealsOpening;

  /// No description provided for @mealsKitchenMode.
  ///
  /// In en, this message translates to:
  /// **'Cooking mode'**
  String get mealsKitchenMode;

  /// Web search query for a dish's recipe
  ///
  /// In en, this message translates to:
  /// **'{dish} recipe'**
  String mealsRecipeSearch(String dish);

  /// No description provided for @mealsSearchRecipe.
  ///
  /// In en, this message translates to:
  /// **'Search for a recipe online'**
  String get mealsSearchRecipe;

  /// Field label (upper case)
  ///
  /// In en, this message translates to:
  /// **'FAVOURITES'**
  String get mealsFieldFavorites;

  /// Field label (upper case)
  ///
  /// In en, this message translates to:
  /// **'WHERE'**
  String get mealsFieldWhere;

  /// Field label (upper case)
  ///
  /// In en, this message translates to:
  /// **'TIME'**
  String get mealsFieldTime;

  /// Field label (upper case)
  ///
  /// In en, this message translates to:
  /// **'NOTES'**
  String get mealsFieldNotes;

  /// No description provided for @mealsNoteHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. defrost in the morning'**
  String get mealsNoteHint;

  /// Suggested breakfast
  ///
  /// In en, this message translates to:
  /// **'Toast and fruit'**
  String get mealsDishToastFruit;

  /// Suggested breakfast
  ///
  /// In en, this message translates to:
  /// **'Oat pancakes'**
  String get mealsDishOatPancakes;

  /// Suggested breakfast
  ///
  /// In en, this message translates to:
  /// **'Yoghurt with granola'**
  String get mealsDishYogurtGranola;

  /// Suggested breakfast
  ///
  /// In en, this message translates to:
  /// **'Porridge'**
  String get mealsDishPorridge;

  /// Suggested breakfast
  ///
  /// In en, this message translates to:
  /// **'Scrambled eggs'**
  String get mealsDishScrambledEggs;

  /// Suggested lunch
  ///
  /// In en, this message translates to:
  /// **'Soup and a sandwich'**
  String get mealsDishSoupSandwich;

  /// Suggested lunch
  ///
  /// In en, this message translates to:
  /// **'Tuna salad'**
  String get mealsDishTunaSalad;

  /// Suggested lunch (Portuguese steak, egg and chips)
  ///
  /// In en, this message translates to:
  /// **'Steak with fried egg'**
  String get mealsDishBitoque;

  /// Suggested lunch
  ///
  /// In en, this message translates to:
  /// **'Pasta with vegetables'**
  String get mealsDishVegetablePasta;

  /// Suggested lunch
  ///
  /// In en, this message translates to:
  /// **'Grilled chicken'**
  String get mealsDishGrilledChicken;

  /// Suggested dinner (shredded salt cod with eggs and straw potatoes)
  ///
  /// In en, this message translates to:
  /// **'Cod à Brás'**
  String get mealsDishBacalhauBras;

  /// Suggested dinner
  ///
  /// In en, this message translates to:
  /// **'Duck rice'**
  String get mealsDishDuckRice;

  /// Suggested dinner
  ///
  /// In en, this message translates to:
  /// **'Spaghetti bolognese'**
  String get mealsDishBolognese;

  /// Suggested dinner
  ///
  /// In en, this message translates to:
  /// **'Roast chicken'**
  String get mealsDishRoastChicken;

  /// Suggested dinner
  ///
  /// In en, this message translates to:
  /// **'Vegetable soup'**
  String get mealsDishVegetableSoup;

  /// Suggested dinner
  ///
  /// In en, this message translates to:
  /// **'Grilled salmon'**
  String get mealsDishGrilledSalmon;

  /// Suggested dinner
  ///
  /// In en, this message translates to:
  /// **'Lasagne'**
  String get mealsDishLasagne;

  /// Suggested dinner
  ///
  /// In en, this message translates to:
  /// **'Pizza'**
  String get mealsDishPizza;

  /// Page title; also shown upper case as a section label
  ///
  /// In en, this message translates to:
  /// **'Lists'**
  String get listsTitle;

  /// No description provided for @listsNew.
  ///
  /// In en, this message translates to:
  /// **'New list'**
  String get listsNew;

  /// No description provided for @listsNoneInHa.
  ///
  /// In en, this message translates to:
  /// **'No lists in Home Assistant'**
  String get listsNoneInHa;

  /// A list with nothing left to do
  ///
  /// In en, this message translates to:
  /// **'All done'**
  String get listsAllDone;

  /// No description provided for @listsItemsPending.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 item to do} other{{count} items to do}}'**
  String listsItemsPending(int count);

  /// Pending items on a list, in the list picker
  ///
  /// In en, this message translates to:
  /// **'{count} to do'**
  String listsPendingCount(int count);

  /// No description provided for @listsClearDone.
  ///
  /// In en, this message translates to:
  /// **'Clear completed'**
  String get listsClearDone;

  /// No description provided for @listsAddItem.
  ///
  /// In en, this message translates to:
  /// **'Add item…'**
  String get listsAddItem;

  /// No description provided for @listsNothingPending.
  ///
  /// In en, this message translates to:
  /// **'Nothing to do on this list'**
  String get listsNothingPending;

  /// Header of the folded completed items
  ///
  /// In en, this message translates to:
  /// **'Completed ({count})'**
  String listsDoneCount(int count);

  /// Voice messages left for the family
  ///
  /// In en, this message translates to:
  /// **'Messages'**
  String get listsMessagesTitle;

  /// No description provided for @listsMessagesUnseen.
  ///
  /// In en, this message translates to:
  /// **'{count} unseen'**
  String listsMessagesUnseen(int count);

  /// No description provided for @listsMessagesNone.
  ///
  /// In en, this message translates to:
  /// **'No messages'**
  String get listsMessagesNone;

  /// No description provided for @listsMessagesAllSeen.
  ///
  /// In en, this message translates to:
  /// **'All seen'**
  String get listsMessagesAllSeen;

  /// Subtitle of Messages: they delete themselves after 7 days
  ///
  /// In en, this message translates to:
  /// **'deleted after 7 days'**
  String get listsMessagesExpiry;

  /// No description provided for @listsMessagesEmptyBody.
  ///
  /// In en, this message translates to:
  /// **'Messages left by voice show up here until someone sees them, and delete themselves after 7 days.'**
  String get listsMessagesEmptyBody;

  /// Badge on a message nobody has seen yet
  ///
  /// In en, this message translates to:
  /// **'Unseen'**
  String get listsMessagesUnseenBadge;

  /// No description provided for @listsMessagesMarkSeen.
  ///
  /// In en, this message translates to:
  /// **'Mark as seen'**
  String get listsMessagesMarkSeen;

  /// When a message deletes itself; count is days left
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Deleted tomorrow} other{Deleted in {count} days}}'**
  String listsMessagesDeletesIn(int count);

  /// No description provided for @listsCreated.
  ///
  /// In en, this message translates to:
  /// **'List created: {name}'**
  String listsCreated(String name);

  /// Field label (upper case)
  ///
  /// In en, this message translates to:
  /// **'NAME'**
  String get listsFieldName;

  /// No description provided for @listsNameHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Attic clear-out'**
  String get listsNameHint;

  /// Keyboard done key that creates the list
  ///
  /// In en, this message translates to:
  /// **'Create'**
  String get listsCreateShort;

  /// Field label (upper case)
  ///
  /// In en, this message translates to:
  /// **'ICON'**
  String get listsFieldIcon;

  /// No description provided for @listsCreate.
  ///
  /// In en, this message translates to:
  /// **'Create list'**
  String get listsCreate;

  /// Modal title for a new list item
  ///
  /// In en, this message translates to:
  /// **'New item'**
  String get itemNew;

  /// No description provided for @itemEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit item'**
  String get itemEdit;

  /// Field label (upper case)
  ///
  /// In en, this message translates to:
  /// **'ITEM'**
  String get itemFieldItem;

  /// Field label (upper case)
  ///
  /// In en, this message translates to:
  /// **'QUANTITY'**
  String get itemFieldQuantity;

  /// No description provided for @itemNoQuantity.
  ///
  /// In en, this message translates to:
  /// **'No quantity'**
  String get itemNoQuantity;

  /// Field label (upper case)
  ///
  /// In en, this message translates to:
  /// **'NOTE'**
  String get itemFieldNote;

  /// No description provided for @itemNoteHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. whole beans, brand, lactose-free…'**
  String get itemNoteHint;

  /// Suggested shopping item
  ///
  /// In en, this message translates to:
  /// **'Olive oil'**
  String get itemSuggestOliveOil;

  /// Suggested shopping item
  ///
  /// In en, this message translates to:
  /// **'Rice'**
  String get itemSuggestRice;

  /// Suggested shopping item
  ///
  /// In en, this message translates to:
  /// **'Butter'**
  String get itemSuggestButter;

  /// Suggested shopping item
  ///
  /// In en, this message translates to:
  /// **'Fruit'**
  String get itemSuggestFruit;

  /// Suggested shopping item
  ///
  /// In en, this message translates to:
  /// **'Water'**
  String get itemSuggestWater;

  /// Suggested shopping item
  ///
  /// In en, this message translates to:
  /// **'Toilet paper'**
  String get itemSuggestToiletPaper;

  /// Suggested shopping item
  ///
  /// In en, this message translates to:
  /// **'Cheese'**
  String get itemSuggestCheese;

  /// Suggested shopping item
  ///
  /// In en, this message translates to:
  /// **'Milk'**
  String get itemSuggestMilk;

  /// Suggested shopping item
  ///
  /// In en, this message translates to:
  /// **'Bread'**
  String get itemSuggestBread;

  /// Suggested shopping item
  ///
  /// In en, this message translates to:
  /// **'Eggs'**
  String get itemSuggestEggs;

  /// Suggested pharmacy item
  ///
  /// In en, this message translates to:
  /// **'Ibuprofen'**
  String get itemSuggestIbuprofen;

  /// Suggested pharmacy item
  ///
  /// In en, this message translates to:
  /// **'Paracetamol'**
  String get itemSuggestParacetamol;

  /// Suggested pharmacy item
  ///
  /// In en, this message translates to:
  /// **'Saline solution'**
  String get itemSuggestSaline;

  /// Suggested pharmacy item
  ///
  /// In en, this message translates to:
  /// **'Thermometer'**
  String get itemSuggestThermometer;

  /// Suggested pharmacy item (adhesive bandages)
  ///
  /// In en, this message translates to:
  /// **'Plasters'**
  String get itemSuggestPlasters;

  /// Suggested household item
  ///
  /// In en, this message translates to:
  /// **'Batteries'**
  String get itemSuggestBatteries;

  /// Suggested household item
  ///
  /// In en, this message translates to:
  /// **'Light bulbs'**
  String get itemSuggestLightBulbs;

  /// Suggested household item (sealant)
  ///
  /// In en, this message translates to:
  /// **'Silicone'**
  String get itemSuggestSilicone;

  /// Suggested household item
  ///
  /// In en, this message translates to:
  /// **'Screws'**
  String get itemSuggestScrews;

  /// Quantity unit 'piece', singular (short). Also written into the Home Assistant item description
  ///
  /// In en, this message translates to:
  /// **'pc'**
  String get todoUnitPieceOne;

  /// Quantity unit 'pieces', plural (short)
  ///
  /// In en, this message translates to:
  /// **'pcs'**
  String get todoUnitPieceMany;

  /// Quantity unit, singular
  ///
  /// In en, this message translates to:
  /// **'pack'**
  String get todoUnitPackOne;

  /// Quantity unit, plural
  ///
  /// In en, this message translates to:
  /// **'packs'**
  String get todoUnitPackMany;

  /// Quantity unit, singular
  ///
  /// In en, this message translates to:
  /// **'dozen'**
  String get todoUnitDozenOne;

  /// Quantity unit, plural
  ///
  /// In en, this message translates to:
  /// **'dozen'**
  String get todoUnitDozenMany;

  /// Toast when a list change timed out and was undone
  ///
  /// In en, this message translates to:
  /// **'Home Assistant didn\'t confirm the change to the list'**
  String get todoNotConfirmed;

  /// No description provided for @todoNoConnection.
  ///
  /// In en, this message translates to:
  /// **'Not connected to Home Assistant'**
  String get todoNoConnection;

  /// Name shown for a public-holidays calendar
  ///
  /// In en, this message translates to:
  /// **'Holidays'**
  String get familyHolidays;

  /// Toast when a device change timed out and was undone
  ///
  /// In en, this message translates to:
  /// **'Home Assistant didn\'t confirm the change'**
  String get entitiesNotConfirmed;

  /// Shown after a form field label, e.g. "Notes (optional)".
  ///
  /// In en, this message translates to:
  /// **'(optional)'**
  String get uiOptionalSuffix;

  /// Save button label while saving.
  ///
  /// In en, this message translates to:
  /// **'Saving…'**
  String get uiSaving;

  /// Error toast; reason is the error text.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t finish: {reason}'**
  String uiActionFailed(String reason);

  /// On-screen keyboard space bar label (lowercase, like phone keyboards).
  ///
  /// In en, this message translates to:
  /// **'space'**
  String get keyboardSpace;

  /// On-screen keyboard button: detach the keyboard into a small movable panel.
  ///
  /// In en, this message translates to:
  /// **'Float'**
  String get keyboardFloat;

  /// Icon choice for an energy-card device: generic plug.
  ///
  /// In en, this message translates to:
  /// **'Generic'**
  String get powerSensorIconGeneric;

  /// No description provided for @powerSensorIconWasher.
  ///
  /// In en, this message translates to:
  /// **'Washing machine'**
  String get powerSensorIconWasher;

  /// No description provided for @powerSensorIconFridge.
  ///
  /// In en, this message translates to:
  /// **'Fridge'**
  String get powerSensorIconFridge;

  /// No description provided for @powerSensorIconAirConditioning.
  ///
  /// In en, this message translates to:
  /// **'Air conditioning'**
  String get powerSensorIconAirConditioning;

  /// A heat-pump water heater (AQS = domestic hot water).
  ///
  /// In en, this message translates to:
  /// **'Heat pump (hot water)'**
  String get powerSensorIconHeatPump;

  /// No description provided for @powerSensorIconOven.
  ///
  /// In en, this message translates to:
  /// **'Oven'**
  String get powerSensorIconOven;

  /// Toast when a music change was undone because Music Assistant never confirmed it.
  ///
  /// In en, this message translates to:
  /// **'Music Assistant didn\'t confirm the change'**
  String get optimisticMusicNotConfirmed;

  /// No description provided for @miscMusicNoSpeakers.
  ///
  /// In en, this message translates to:
  /// **'No speakers'**
  String get miscMusicNoSpeakers;

  /// Music target label: the first speaker's name plus how many other speakers are grouped with it.
  ///
  /// In en, this message translates to:
  /// **'{name} + {count, plural, =1{1 speaker} other{{count} speakers}}'**
  String miscMusicSpeakersMore(String name, int count);

  /// No description provided for @miscMusicUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Music Assistant unavailable'**
  String get miscMusicUnavailable;

  /// No description provided for @miscMusicChooseSpeaker.
  ///
  /// In en, this message translates to:
  /// **'Choose a speaker'**
  String get miscMusicChooseSpeaker;

  /// No description provided for @miscMusicCannotGroup.
  ///
  /// In en, this message translates to:
  /// **'{speaker} can\'t play in a group with {target}'**
  String miscMusicCannotGroup(String speaker, String target);

  /// No description provided for @miscMusicNotConnected.
  ///
  /// In en, this message translates to:
  /// **'Music Assistant isn\'t connected'**
  String get miscMusicNotConnected;

  /// command is a technical Music Assistant command name.
  ///
  /// In en, this message translates to:
  /// **'No reply from Music Assistant ({command})'**
  String miscMusicNoReply(String command);

  /// Shown in the web preview, where creating a to-do list isn't possible.
  ///
  /// In en, this message translates to:
  /// **'Creating lists only works on the screen at home'**
  String get haCreateListsDeviceOnly;

  /// Theme option; also the option name in the Home Assistant theme select entity.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get themeLight;

  /// Theme option; also the option name in the Home Assistant theme select entity.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get themeDark;

  /// Name of this screen's theme select entity in Home Assistant.
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get themeMqttSelectName;

  /// Doorbell problem banner. The home intercom is the indoor station in the flat.
  ///
  /// In en, this message translates to:
  /// **'Not connected to the home intercom yet ({host}).'**
  String doorIndoorNotYetConnected(String host);

  /// No description provided for @doorIndoorLinkStopped.
  ///
  /// In en, this message translates to:
  /// **'The connection to the home intercom stopped; reconnecting.'**
  String get doorIndoorLinkStopped;

  /// No description provided for @doorIndoorStartFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t start the connection to the home intercom: {details}'**
  String doorIndoorStartFailed(String details);

  /// No description provided for @doorIndoorNoLibrary.
  ///
  /// In en, this message translates to:
  /// **'The intercom library is missing ({path}).'**
  String doorIndoorNoLibrary(String path);

  /// No description provided for @doorIndoorSdkFailed.
  ///
  /// In en, this message translates to:
  /// **'The intercom SDK didn\'t start (error {code}).'**
  String doorIndoorSdkFailed(String code);

  /// No description provided for @doorIndoorBadPassword.
  ///
  /// In en, this message translates to:
  /// **'Wrong username or password for the home intercom.'**
  String get doorIndoorBadPassword;

  /// No description provided for @doorIndoorLocked.
  ///
  /// In en, this message translates to:
  /// **'The home intercom blocked access (too many attempts); trying again in 10 min.'**
  String get doorIndoorLocked;

  /// No description provided for @doorIndoorStoppedResponding.
  ///
  /// In en, this message translates to:
  /// **'The home intercom stopped responding (error {code}); reconnecting.'**
  String doorIndoorStoppedResponding(String code);

  /// No description provided for @doorIndoorLoginFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t connect to the home intercom ({host}, error {code}).'**
  String doorIndoorLoginFailed(String host, String code);

  /// INDOOR_HOST is a configuration variable name; keep it.
  ///
  /// In en, this message translates to:
  /// **'The home intercom isn\'t set up on this screen (INDOOR_HOST).'**
  String get doorIndoorNotConfigured;

  /// No description provided for @doorSipConnecting.
  ///
  /// In en, this message translates to:
  /// **'Connecting to the main station (SIP)…'**
  String get doorSipConnecting;

  /// No description provided for @doorSipNoConnection.
  ///
  /// In en, this message translates to:
  /// **'No connection to the main station (SIP {server}).'**
  String doorSipNoConnection(String server);

  /// No description provided for @doorSipStartFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t start the SIP extension: {details}'**
  String doorSipStartFailed(String details);

  /// No description provided for @doorSipRegistrationRefused.
  ///
  /// In en, this message translates to:
  /// **'SIP registration refused (number/password). Check the extension and the admin password.'**
  String get doorSipRegistrationRefused;

  /// No description provided for @doorSipDeviceOnly.
  ///
  /// In en, this message translates to:
  /// **'The SIP extension only works on the device, not in the web preview.'**
  String get doorSipDeviceOnly;

  /// No description provided for @doorCameraReconnecting.
  ///
  /// In en, this message translates to:
  /// **'Reconnecting to the camera…'**
  String get doorCameraReconnecting;

  /// No description provided for @doorCameraConnecting.
  ///
  /// In en, this message translates to:
  /// **'Connecting to the building\'s door camera…'**
  String get doorCameraConnecting;

  /// No description provided for @doorOpenFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t open the door (HTTP {status})'**
  String doorOpenFailed(String status);

  /// No description provided for @doorTalkRefused.
  ///
  /// In en, this message translates to:
  /// **'The door didn\'t accept talking right now (HTTP {status})'**
  String doorTalkRefused(String status);

  /// No description provided for @settingsBrowserEngineDuckSub.
  ///
  /// In en, this message translates to:
  /// **'duckduckgo.com · doesn’t keep what you search'**
  String get settingsBrowserEngineDuckSub;

  /// No description provided for @settingsBrowserEngineEcosiaSub.
  ///
  /// In en, this message translates to:
  /// **'ecosia.org · plants trees with your searches'**
  String get settingsBrowserEngineEcosiaSub;

  /// Browser ⋮ menu item and the title of its sheet: plan this web page (a recipe) for a meal, keeping its link.
  ///
  /// In en, this message translates to:
  /// **'Add to a meal'**
  String get browserMenuAddToMeal;

  /// No description provided for @browserMenuAddToMealSub.
  ///
  /// In en, this message translates to:
  /// **'Keeps this page’s link'**
  String get browserMenuAddToMealSub;

  /// Under the disabled menu item while the browser shows its own start page.
  ///
  /// In en, this message translates to:
  /// **'Open a website’s page first'**
  String get browserMenuAddToMealNoSite;

  /// No description provided for @browserMenuSendToPhone.
  ///
  /// In en, this message translates to:
  /// **'Send to phone'**
  String get browserMenuSendToPhone;

  /// Browser ⋮ menu item: go to the home page chosen in Settings.
  ///
  /// In en, this message translates to:
  /// **'Home page'**
  String get browserMenuHome;

  /// Toast; meal is the lowercase meal name (breakfast, lunch, dinner).
  ///
  /// In en, this message translates to:
  /// **'Added to today’s {meal}, with the link'**
  String browserMealAddedToday(String meal);

  /// Toast; meal is the lowercase meal name.
  ///
  /// In en, this message translates to:
  /// **'Added to tomorrow’s {meal}, with the link'**
  String browserMealAddedTomorrow(String meal);

  /// Toast; day is the weekday name as the locale writes it (Thursday / quinta-feira), meal the lowercase meal name.
  ///
  /// In en, this message translates to:
  /// **'Added to {day}’s {meal}, with the link'**
  String browserMealAddedOn(String meal, String day);

  /// No description provided for @browserMealDish.
  ///
  /// In en, this message translates to:
  /// **'DISH'**
  String get browserMealDish;

  /// No description provided for @browserMealDishHint.
  ///
  /// In en, this message translates to:
  /// **'Name of the dish'**
  String get browserMealDishHint;

  /// No description provided for @browserMealKeepsLink.
  ///
  /// In en, this message translates to:
  /// **'Keeps the link: {site}'**
  String browserMealKeepsLink(String site);

  /// No description provided for @browserMealDay.
  ///
  /// In en, this message translates to:
  /// **'DAY'**
  String get browserMealDay;

  /// No description provided for @browserMealMeal.
  ///
  /// In en, this message translates to:
  /// **'MEAL'**
  String get browserMealMeal;

  /// Under a meal in the add-to-meal sheet when nothing is planned for it yet.
  ///
  /// In en, this message translates to:
  /// **'free'**
  String get browserMealSlotFree;

  /// meal is the lowercase meal name.
  ///
  /// In en, this message translates to:
  /// **'There’s already {dish} for this {meal}. Adding replaces it.'**
  String browserMealReplaces(String dish, String meal);

  /// No description provided for @browserMealReplace.
  ///
  /// In en, this message translates to:
  /// **'Replace'**
  String get browserMealReplace;

  /// No description provided for @settingsBrowserOpenSub.
  ///
  /// In en, this message translates to:
  /// **'Opens with the home page and mode chosen in the browser settings.'**
  String get settingsBrowserOpenSub;

  /// No description provided for @settingsBrowserSettings.
  ///
  /// In en, this message translates to:
  /// **'Browser settings'**
  String get settingsBrowserSettings;

  /// No description provided for @settingsBrowserSettingsSub.
  ///
  /// In en, this message translates to:
  /// **'Home page, search engine and how it opens.'**
  String get settingsBrowserSettingsSub;

  /// No description provided for @settingsBrowserManage.
  ///
  /// In en, this message translates to:
  /// **'Manage'**
  String get settingsBrowserManage;

  /// No description provided for @settingsBrowserTitle.
  ///
  /// In en, this message translates to:
  /// **'Web browser'**
  String get settingsBrowserTitle;

  /// No description provided for @settingsBrowserSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Choose the home page, the search engine and how the browser opens.'**
  String get settingsBrowserSubtitle;

  /// No description provided for @settingsBrowserOpen.
  ///
  /// In en, this message translates to:
  /// **'Open browser'**
  String get settingsBrowserOpen;

  /// No description provided for @settingsBrowserEngine.
  ///
  /// In en, this message translates to:
  /// **'Search engine'**
  String get settingsBrowserEngine;

  /// No description provided for @settingsBrowserEngineSub.
  ///
  /// In en, this message translates to:
  /// **'Used when what you type isn’t an address.'**
  String get settingsBrowserEngineSub;

  /// No description provided for @settingsBrowserMode.
  ///
  /// In en, this message translates to:
  /// **'Open by default'**
  String get settingsBrowserMode;

  /// No description provided for @settingsBrowserModeSub.
  ///
  /// In en, this message translates to:
  /// **'How the browser appears when it opens. You can always change it in the browser’s bar.'**
  String get settingsBrowserModeSub;

  /// No description provided for @settingsBrowserHome.
  ///
  /// In en, this message translates to:
  /// **'Home page'**
  String get settingsBrowserHome;

  /// No description provided for @settingsBrowserHomeSub.
  ///
  /// In en, this message translates to:
  /// **'What shows when it opens and on the home button.'**
  String get settingsBrowserHomeSub;

  /// No description provided for @settingsBrowserHomeStart.
  ///
  /// In en, this message translates to:
  /// **'Favourites and search'**
  String get settingsBrowserHomeStart;

  /// No description provided for @settingsBrowserHomeStartSub.
  ///
  /// In en, this message translates to:
  /// **'The browser’s start page'**
  String get settingsBrowserHomeStartSub;

  /// No description provided for @settingsBrowserHomeHaMissing.
  ///
  /// In en, this message translates to:
  /// **'Not connected to Home Assistant yet'**
  String get settingsBrowserHomeHaMissing;

  /// No description provided for @settingsBrowserHomeOther.
  ///
  /// In en, this message translates to:
  /// **'Another page'**
  String get settingsBrowserHomeOther;

  /// No description provided for @settingsBrowserHomeOtherSub.
  ///
  /// In en, this message translates to:
  /// **'Choose an address'**
  String get settingsBrowserHomeOtherSub;

  /// No description provided for @settingsBrowserHomeUrlHint.
  ///
  /// In en, this message translates to:
  /// **'Tap to type the address'**
  String get settingsBrowserHomeUrlHint;

  /// No description provided for @settingsBrowserModeWindow.
  ///
  /// In en, this message translates to:
  /// **'Floating window'**
  String get settingsBrowserModeWindow;

  /// No description provided for @settingsBrowserModeWindowSub.
  ///
  /// In en, this message translates to:
  /// **'The app stays behind it'**
  String get settingsBrowserModeWindowSub;

  /// No description provided for @settingsBrowserModeModal.
  ///
  /// In en, this message translates to:
  /// **'Modal'**
  String get settingsBrowserModeModal;

  /// No description provided for @settingsBrowserModeModalSub.
  ///
  /// In en, this message translates to:
  /// **'Centred, background dimmed'**
  String get settingsBrowserModeModalSub;

  /// No description provided for @settingsBrowserModeFull.
  ///
  /// In en, this message translates to:
  /// **'Full screen'**
  String get settingsBrowserModeFull;

  /// No description provided for @settingsBrowserModeFullSub.
  ///
  /// In en, this message translates to:
  /// **'Fills the whole screen'**
  String get settingsBrowserModeFullSub;

  /// No description provided for @settingsIntercomOff.
  ///
  /// In en, this message translates to:
  /// **'Intercom off'**
  String get settingsIntercomOff;

  /// Shown in Settings when the screen has no intercom configured.
  ///
  /// In en, this message translates to:
  /// **'To answer the door on this screen, set up the door station in this screen\'s settings (/etc/bytehomedash.env).'**
  String get settingsIntercomOffSub;

  /// No description provided for @settingsIntercomOffValue.
  ///
  /// In en, this message translates to:
  /// **'Off'**
  String get settingsIntercomOffValue;

  /// Button in Lists › Messages that opens the new-message modal
  ///
  /// In en, this message translates to:
  /// **'Write a message…'**
  String get listsMessagesWrite;

  /// Hint under the write button; {name} is the first household member, as an example
  ///
  /// In en, this message translates to:
  /// **'Or by voice: “Ok Nabu, leave a message for {name}: …”'**
  String listsMessagesByVoice(String name);

  /// Hint under the write button when no household members are set up
  ///
  /// In en, this message translates to:
  /// **'Or by voice: “Ok Nabu, leave a message for everyone: …”'**
  String get listsMessagesByVoiceEveryone;

  /// No description provided for @recadoNewTitle.
  ///
  /// In en, this message translates to:
  /// **'New message'**
  String get recadoNewTitle;

  /// No description provided for @recadoNewSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Shows on the screen until someone sees it · deleted after 7 days'**
  String get recadoNewSubtitle;

  /// Recipient chip: the message is for everyone
  ///
  /// In en, this message translates to:
  /// **'Everyone'**
  String get recadoNewEveryone;

  /// Field label, in capitals like the other field labels
  ///
  /// In en, this message translates to:
  /// **'MESSAGE'**
  String get recadoNewText;

  /// No description provided for @recadoNewHint.
  ///
  /// In en, this message translates to:
  /// **'E.g. Dinner is in the oven, just heat it up.'**
  String get recadoNewHint;

  /// Field label for who is leaving the message, in capitals
  ///
  /// In en, this message translates to:
  /// **'FROM'**
  String get recadoNewFrom;

  /// Sender chip: leave the message without saying who it's from
  ///
  /// In en, this message translates to:
  /// **'Don\'t say'**
  String get recadoNewAnonymous;

  /// Phone switch label before a recipient is chosen
  ///
  /// In en, this message translates to:
  /// **'Also send to their phone'**
  String get recadoNewPhone;

  /// No description provided for @recadoNewPhoneEveryone.
  ///
  /// In en, this message translates to:
  /// **'Also send to everyone\'s phones'**
  String get recadoNewPhoneEveryone;

  /// No description provided for @recadoNewPhoneOf.
  ///
  /// In en, this message translates to:
  /// **'Also send to {name}\'s phone'**
  String recadoNewPhoneOf(String name);

  /// No description provided for @recadoNewPhoneSub.
  ///
  /// In en, this message translates to:
  /// **'Through the Home Assistant app'**
  String get recadoNewPhoneSub;

  /// No description provided for @recadoNewSave.
  ///
  /// In en, this message translates to:
  /// **'Leave message'**
  String get recadoNewSave;

  /// Keyboard suggestion to start a message
  ///
  /// In en, this message translates to:
  /// **'Dinner is in the oven'**
  String get recadoNewSuggestDinner;

  /// Keyboard suggestion to start a message
  ///
  /// In en, this message translates to:
  /// **'Back at 7 pm'**
  String get recadoNewSuggestBack;

  /// Keyboard suggestion to start a message
  ///
  /// In en, this message translates to:
  /// **'Don\'t forget to'**
  String get recadoNewSuggestDontForget;
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>['en', 'pt'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'pt':
      return AppLocalizationsPt();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
