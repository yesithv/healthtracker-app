import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_de.dart';
import 'app_localizations_en.dart';
import 'app_localizations_es.dart';
import 'app_localizations_it.dart';
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
/// import 'generated/app_localizations.dart';
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
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

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
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('de'),
    Locale('en'),
    Locale('es'),
    Locale('it'),
    Locale('pt'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'My Vitals'**
  String get appTitle;

  /// No description provided for @dashboard.
  ///
  /// In en, this message translates to:
  /// **'Dashboard'**
  String get dashboard;

  /// No description provided for @history.
  ///
  /// In en, this message translates to:
  /// **'History'**
  String get history;

  /// No description provided for @record.
  ///
  /// In en, this message translates to:
  /// **'Record'**
  String get record;

  /// No description provided for @discover.
  ///
  /// In en, this message translates to:
  /// **'Discover'**
  String get discover;

  /// No description provided for @profile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profile;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @savePreferences.
  ///
  /// In en, this message translates to:
  /// **'Save Preferences'**
  String get savePreferences;

  /// No description provided for @selectLanguage.
  ///
  /// In en, this message translates to:
  /// **'Select your preferred language'**
  String get selectLanguage;

  /// No description provided for @personalInfo.
  ///
  /// In en, this message translates to:
  /// **'Personal Info'**
  String get personalInfo;

  /// No description provided for @measurementUnits.
  ///
  /// In en, this message translates to:
  /// **'Measurement Units'**
  String get measurementUnits;

  /// No description provided for @notifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notifications;

  /// No description provided for @privacySecurity.
  ///
  /// In en, this message translates to:
  /// **'Privacy & Security'**
  String get privacySecurity;

  /// No description provided for @helpSupport.
  ///
  /// In en, this message translates to:
  /// **'Help & Support'**
  String get helpSupport;

  /// No description provided for @logOut.
  ///
  /// In en, this message translates to:
  /// **'Log Out'**
  String get logOut;

  /// No description provided for @level.
  ///
  /// In en, this message translates to:
  /// **'Level {value}'**
  String level(int value);

  /// No description provided for @newUserInfo.
  ///
  /// In en, this message translates to:
  /// **'New User'**
  String get newUserInfo;

  /// No description provided for @xpForNextLevel.
  ///
  /// In en, this message translates to:
  /// **'{current} / {total} XP for next level'**
  String xpForNextLevel(int current, int total);

  /// No description provided for @levelProgress.
  ///
  /// In en, this message translates to:
  /// **'Level Progress'**
  String get levelProgress;

  /// No description provided for @vitalSigns.
  ///
  /// In en, this message translates to:
  /// **'Vital Signs'**
  String get vitalSigns;

  /// No description provided for @vitalsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Blood pressure & Heart rate'**
  String get vitalsSubtitle;

  /// No description provided for @noDataYet.
  ///
  /// In en, this message translates to:
  /// **'No data recorded yet.'**
  String get noDataYet;

  /// No description provided for @recordVitalsAction.
  ///
  /// In en, this message translates to:
  /// **'Record your pressure and rate ›'**
  String get recordVitalsAction;

  /// No description provided for @bodyComposition.
  ///
  /// In en, this message translates to:
  /// **'Body Composition'**
  String get bodyComposition;

  /// No description provided for @compositionSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Fat, muscle, water and bone mass.'**
  String get compositionSubtitle;

  /// No description provided for @completeBodyProfile.
  ///
  /// In en, this message translates to:
  /// **'Complete your body profile ›'**
  String get completeBodyProfile;

  /// No description provided for @anthropometricHistory.
  ///
  /// In en, this message translates to:
  /// **'Anthropometric History'**
  String get anthropometricHistory;

  /// No description provided for @anthroSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Measure your weight, height and physical progress.'**
  String get anthroSubtitle;

  /// No description provided for @recordFirstMeasure.
  ///
  /// In en, this message translates to:
  /// **'Record your first measurement ›'**
  String get recordFirstMeasure;

  /// No description provided for @lipidProfile.
  ///
  /// In en, this message translates to:
  /// **'Lipid Profile'**
  String get lipidProfile;

  /// No description provided for @lipidSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Monitor your cholesterol and triglycerides.'**
  String get lipidSubtitle;

  /// No description provided for @recordLabResults.
  ///
  /// In en, this message translates to:
  /// **'Record your lab results ›'**
  String get recordLabResults;

  /// No description provided for @medicalDisclaimerTitle.
  ///
  /// In en, this message translates to:
  /// **'Medical Disclaimer'**
  String get medicalDisclaimerTitle;

  /// No description provided for @medicalDisclaimerText.
  ///
  /// In en, this message translates to:
  /// **'This application is for informational and personal tracking purposes only. It is not a substitute for professional medical advice, diagnosis, or treatment. Always seek the advice of your physician or other qualified health provider with any questions.'**
  String get medicalDisclaimerText;

  /// No description provided for @selfCareProgress.
  ///
  /// In en, this message translates to:
  /// **'Self-care Progress'**
  String get selfCareProgress;

  /// No description provided for @myHealthAchievements.
  ///
  /// In en, this message translates to:
  /// **'My Health Achievements'**
  String get myHealthAchievements;

  /// No description provided for @badgeFirstStep.
  ///
  /// In en, this message translates to:
  /// **'First Step'**
  String get badgeFirstStep;

  /// No description provided for @badgeFirstStepDesc.
  ///
  /// In en, this message translates to:
  /// **'Beginning of the journey'**
  String get badgeFirstStepDesc;

  /// No description provided for @badgeStrongHeart.
  ///
  /// In en, this message translates to:
  /// **'Strong Heart'**
  String get badgeStrongHeart;

  /// No description provided for @badgeStrongHeartDesc.
  ///
  /// In en, this message translates to:
  /// **'Cardio Health'**
  String get badgeStrongHeartDesc;

  /// No description provided for @badgeVitalHabit.
  ///
  /// In en, this message translates to:
  /// **'Vital Habit'**
  String get badgeVitalHabit;

  /// No description provided for @badgeVitalHabitDesc.
  ///
  /// In en, this message translates to:
  /// **'7 days in a row'**
  String get badgeVitalHabitDesc;

  /// No description provided for @badgeAwareness.
  ///
  /// In en, this message translates to:
  /// **'Awareness'**
  String get badgeAwareness;

  /// No description provided for @badgeAwarenessDesc.
  ///
  /// In en, this message translates to:
  /// **'Big Picture'**
  String get badgeAwarenessDesc;

  /// No description provided for @badgeBalance.
  ///
  /// In en, this message translates to:
  /// **'Balance'**
  String get badgeBalance;

  /// No description provided for @badgeBalanceDesc.
  ///
  /// In en, this message translates to:
  /// **'Body goal'**
  String get badgeBalanceDesc;

  /// No description provided for @badgeGuardian.
  ///
  /// In en, this message translates to:
  /// **'Guardian'**
  String get badgeGuardian;

  /// No description provided for @badgeGuardianDesc.
  ///
  /// In en, this message translates to:
  /// **'Commitment'**
  String get badgeGuardianDesc;

  /// No description provided for @metricSystem.
  ///
  /// In en, this message translates to:
  /// **'Metric (kg, cm, °C)'**
  String get metricSystem;

  /// No description provided for @registerIndicators.
  ///
  /// In en, this message translates to:
  /// **'Register Indicators'**
  String get registerIndicators;

  /// No description provided for @anthropometry.
  ///
  /// In en, this message translates to:
  /// **'Anthropometry'**
  String get anthropometry;

  /// No description provided for @unitOfMeasureTitle.
  ///
  /// In en, this message translates to:
  /// **'Unit of Measure'**
  String get unitOfMeasureTitle;

  /// No description provided for @unitOfMeasureDescription.
  ///
  /// In en, this message translates to:
  /// **'How do you prefer to see your measurements? Select the system that best suits you for accurate health tracking.'**
  String get unitOfMeasureDescription;

  /// No description provided for @metricOption.
  ///
  /// In en, this message translates to:
  /// **'Metric (kg, cm)'**
  String get metricOption;

  /// No description provided for @metricSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Kilograms and centimeters'**
  String get metricSubtitle;

  /// No description provided for @imperialOption.
  ///
  /// In en, this message translates to:
  /// **'Imperial (lb, ft/in)'**
  String get imperialOption;

  /// No description provided for @imperialSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Pounds and feet/inches'**
  String get imperialSubtitle;

  /// No description provided for @continueAction.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get continueAction;

  /// No description provided for @languageTitle.
  ///
  /// In en, this message translates to:
  /// **'Language Selection'**
  String get languageTitle;

  /// No description provided for @languageDescription.
  ///
  /// In en, this message translates to:
  /// **'Select your preferred language to adapt the application to your needs. You can change it at any time from this screen.'**
  String get languageDescription;

  /// No description provided for @profileImageTitle.
  ///
  /// In en, this message translates to:
  /// **'Profile Image'**
  String get profileImageTitle;

  /// No description provided for @gallery.
  ///
  /// In en, this message translates to:
  /// **'Gallery'**
  String get gallery;

  /// No description provided for @camera.
  ///
  /// In en, this message translates to:
  /// **'Camera'**
  String get camera;

  /// No description provided for @deletePhoto.
  ///
  /// In en, this message translates to:
  /// **'Delete photo'**
  String get deletePhoto;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @personalInfoTitle.
  ///
  /// In en, this message translates to:
  /// **'Personal Information'**
  String get personalInfoTitle;

  /// No description provided for @personalInfoDescription.
  ///
  /// In en, this message translates to:
  /// **'Keep your details up to date to receive more accurate and personalized health recommendations.'**
  String get personalInfoDescription;

  /// No description provided for @fullName.
  ///
  /// In en, this message translates to:
  /// **'Full name'**
  String get fullName;

  /// No description provided for @birthDate.
  ///
  /// In en, this message translates to:
  /// **'Date of birth'**
  String get birthDate;

  /// No description provided for @emailOptional.
  ///
  /// In en, this message translates to:
  /// **'Email (Optional)'**
  String get emailOptional;

  /// No description provided for @phoneOptional.
  ///
  /// In en, this message translates to:
  /// **'Phone (Optional)'**
  String get phoneOptional;

  /// No description provided for @selectCountry.
  ///
  /// In en, this message translates to:
  /// **'Select your country'**
  String get selectCountry;

  /// No description provided for @searchCountry.
  ///
  /// In en, this message translates to:
  /// **'Search country'**
  String get searchCountry;

  /// No description provided for @gender.
  ///
  /// In en, this message translates to:
  /// **'Gender'**
  String get gender;

  /// No description provided for @male.
  ///
  /// In en, this message translates to:
  /// **'Male'**
  String get male;

  /// No description provided for @female.
  ///
  /// In en, this message translates to:
  /// **'Female'**
  String get female;

  /// No description provided for @other.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get other;

  /// No description provided for @activityLevel.
  ///
  /// In en, this message translates to:
  /// **'Activity Level'**
  String get activityLevel;

  /// No description provided for @activitySedentary.
  ///
  /// In en, this message translates to:
  /// **'Sedentary'**
  String get activitySedentary;

  /// No description provided for @activityLightlyActive.
  ///
  /// In en, this message translates to:
  /// **'Lightly Active'**
  String get activityLightlyActive;

  /// No description provided for @activityModeratelyActive.
  ///
  /// In en, this message translates to:
  /// **'Moderately Active'**
  String get activityModeratelyActive;

  /// No description provided for @activityVeryActive.
  ///
  /// In en, this message translates to:
  /// **'Very Active'**
  String get activityVeryActive;

  /// No description provided for @activityExtraActive.
  ///
  /// In en, this message translates to:
  /// **'Extra Active'**
  String get activityExtraActive;

  /// No description provided for @selectDate.
  ///
  /// In en, this message translates to:
  /// **'Select date'**
  String get selectDate;

  /// No description provided for @recordAnthropometricTitle.
  ///
  /// In en, this message translates to:
  /// **'ANTHROPOMETRIC MEASURES'**
  String get recordAnthropometricTitle;

  /// No description provided for @dateTimeOfMeasurement.
  ///
  /// In en, this message translates to:
  /// **'DATE AND TIME OF MEASUREMENT'**
  String get dateTimeOfMeasurement;

  /// No description provided for @dateLabel.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get dateLabel;

  /// No description provided for @timeLabel.
  ///
  /// In en, this message translates to:
  /// **'Time'**
  String get timeLabel;

  /// No description provided for @bodyMeasurements.
  ///
  /// In en, this message translates to:
  /// **'BODY MEASUREMENTS'**
  String get bodyMeasurements;

  /// No description provided for @weightLabel.
  ///
  /// In en, this message translates to:
  /// **'Weight'**
  String get weightLabel;

  /// No description provided for @heightLabel.
  ///
  /// In en, this message translates to:
  /// **'Height'**
  String get heightLabel;

  /// No description provided for @bmiTitle.
  ///
  /// In en, this message translates to:
  /// **'Body Mass Index (BMI)'**
  String get bmiTitle;

  /// No description provided for @manual.
  ///
  /// In en, this message translates to:
  /// **'Manual'**
  String get manual;

  /// No description provided for @bmiLow.
  ///
  /// In en, this message translates to:
  /// **'LOW'**
  String get bmiLow;

  /// No description provided for @bmiNormal.
  ///
  /// In en, this message translates to:
  /// **'NORMAL'**
  String get bmiNormal;

  /// No description provided for @bmiOverweight.
  ///
  /// In en, this message translates to:
  /// **'OVERWEIGHT'**
  String get bmiOverweight;

  /// No description provided for @bmiObesity.
  ///
  /// In en, this message translates to:
  /// **'OBESITY'**
  String get bmiObesity;

  /// No description provided for @commentOptional.
  ///
  /// In en, this message translates to:
  /// **'COMMENT (OPTIONAL)'**
  String get commentOptional;

  /// No description provided for @commentHint.
  ///
  /// In en, this message translates to:
  /// **'Any observations about this measurement?'**
  String get commentHint;

  /// No description provided for @saveAndEarnXp.
  ///
  /// In en, this message translates to:
  /// **'Save and earn +10 XP'**
  String get saveAndEarnXp;

  /// No description provided for @historyGoodJob.
  ///
  /// In en, this message translates to:
  /// **'Good job!'**
  String get historyGoodJob;

  /// No description provided for @historyGoalProgress.
  ///
  /// In en, this message translates to:
  /// **'You have recorded a new measurement this month, staying on your wellness track.'**
  String get historyGoalProgress;

  /// No description provided for @historyWeightLoss.
  ///
  /// In en, this message translates to:
  /// **'You lost {weight}kg this month, getting closer to your wellness goal.'**
  String historyWeightLoss(String weight);

  /// No description provided for @historyBmiTrend.
  ///
  /// In en, this message translates to:
  /// **'BMI TREND'**
  String get historyBmiTrend;

  /// No description provided for @historyLast6Months.
  ///
  /// In en, this message translates to:
  /// **'Last 6 months'**
  String get historyLast6Months;

  /// No description provided for @historyTargetZone.
  ///
  /// In en, this message translates to:
  /// **'Target Zone'**
  String get historyTargetZone;

  /// No description provided for @historyBmiUnit.
  ///
  /// In en, this message translates to:
  /// **'BMI'**
  String get historyBmiUnit;

  /// No description provided for @historyExportPdf.
  ///
  /// In en, this message translates to:
  /// **'Export to PDF'**
  String get historyExportPdf;

  /// No description provided for @historyExportCsv.
  ///
  /// In en, this message translates to:
  /// **'Excel (CSV)'**
  String get historyExportCsv;

  /// No description provided for @historyMeasurements.
  ///
  /// In en, this message translates to:
  /// **'MEASUREMENT HISTORY'**
  String get historyMeasurements;

  /// No description provided for @historyNoMeasurements.
  ///
  /// In en, this message translates to:
  /// **'No measurements yet. Record your first one to start your history.'**
  String get historyNoMeasurements;

  /// No description provided for @historyColDate.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get historyColDate;

  /// No description provided for @historyColWeight.
  ///
  /// In en, this message translates to:
  /// **'Weight (kg)'**
  String get historyColWeight;

  /// No description provided for @historyColBmi.
  ///
  /// In en, this message translates to:
  /// **'BMI'**
  String get historyColBmi;

  /// No description provided for @historyColCategory.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get historyColCategory;

  /// No description provided for @historyUnknown.
  ///
  /// In en, this message translates to:
  /// **'Unknown'**
  String get historyUnknown;

  /// No description provided for @historyPdfTitle.
  ///
  /// In en, this message translates to:
  /// **'Anthropometric History'**
  String get historyPdfTitle;

  /// No description provided for @historyShareCsvSubject.
  ///
  /// In en, this message translates to:
  /// **'Measurement History CSV'**
  String get historyShareCsvSubject;

  /// No description provided for @historyBmiLabel.
  ///
  /// In en, this message translates to:
  /// **'BMI'**
  String get historyBmiLabel;

  /// History chart card title, per the selected metric
  ///
  /// In en, this message translates to:
  /// **'{metric} TREND'**
  String historyTrendOf(String metric);

  /// Empty state when the derived metric lacks enough data
  ///
  /// In en, this message translates to:
  /// **'Log {measure} to see this indicator.'**
  String historyMetricNeedsData(String measure);

  /// No description provided for @whtrName.
  ///
  /// In en, this message translates to:
  /// **'Waist-to-height'**
  String get whtrName;

  /// No description provided for @whtrShort.
  ///
  /// In en, this message translates to:
  /// **'WHtR'**
  String get whtrShort;

  /// No description provided for @whtrLow.
  ///
  /// In en, this message translates to:
  /// **'LOW'**
  String get whtrLow;

  /// No description provided for @whtrNormal.
  ///
  /// In en, this message translates to:
  /// **'NORMAL'**
  String get whtrNormal;

  /// No description provided for @whtrIncreased.
  ///
  /// In en, this message translates to:
  /// **'INCREASED'**
  String get whtrIncreased;

  /// No description provided for @whtrHigh.
  ///
  /// In en, this message translates to:
  /// **'HIGH'**
  String get whtrHigh;

  /// No description provided for @whrName.
  ///
  /// In en, this message translates to:
  /// **'Waist-to-hip'**
  String get whrName;

  /// No description provided for @whrShort.
  ///
  /// In en, this message translates to:
  /// **'WHR'**
  String get whrShort;

  /// No description provided for @whrNormal.
  ///
  /// In en, this message translates to:
  /// **'NORMAL'**
  String get whrNormal;

  /// No description provided for @whrIncreased.
  ///
  /// In en, this message translates to:
  /// **'INCREASED'**
  String get whrIncreased;

  /// No description provided for @measureWaist.
  ///
  /// In en, this message translates to:
  /// **'your waist'**
  String get measureWaist;

  /// No description provided for @measureWaistAndHip.
  ///
  /// In en, this message translates to:
  /// **'waist and hip'**
  String get measureWaistAndHip;

  /// No description provided for @unitCm.
  ///
  /// In en, this message translates to:
  /// **'cm'**
  String get unitCm;

  /// No description provided for @recordVitalSignsTitle.
  ///
  /// In en, this message translates to:
  /// **'VITAL SIGNS'**
  String get recordVitalSignsTitle;

  /// No description provided for @bloodPressureTitle.
  ///
  /// In en, this message translates to:
  /// **'BLOOD PRESSURE (MMHG)'**
  String get bloodPressureTitle;

  /// No description provided for @systolicLabel.
  ///
  /// In en, this message translates to:
  /// **'SYSTOLIC'**
  String get systolicLabel;

  /// No description provided for @diastolicLabel.
  ///
  /// In en, this message translates to:
  /// **'DIASTOLIC'**
  String get diastolicLabel;

  /// No description provided for @heartRateTitle.
  ///
  /// In en, this message translates to:
  /// **'HEART RATE (BPM)'**
  String get heartRateTitle;

  /// No description provided for @vitalMetricBpShort.
  ///
  /// In en, this message translates to:
  /// **'Blood Pressure'**
  String get vitalMetricBpShort;

  /// No description provided for @vitalMetricHrShort.
  ///
  /// In en, this message translates to:
  /// **'Heart Rate'**
  String get vitalMetricHrShort;

  /// No description provided for @heartRateSeriesLabel.
  ///
  /// In en, this message translates to:
  /// **'Heart Rate'**
  String get heartRateSeriesLabel;

  /// No description provided for @symptomMarkerLegend.
  ///
  /// In en, this message translates to:
  /// **'Symptom noted'**
  String get symptomMarkerLegend;

  /// No description provided for @contextAndSymptoms.
  ///
  /// In en, this message translates to:
  /// **'CONTEXT & SYMPTOMS'**
  String get contextAndSymptoms;

  /// No description provided for @activityState.
  ///
  /// In en, this message translates to:
  /// **'ACTIVITY STATE'**
  String get activityState;

  /// No description provided for @activityRest.
  ///
  /// In en, this message translates to:
  /// **'Rest'**
  String get activityRest;

  /// No description provided for @activityExercise.
  ///
  /// In en, this message translates to:
  /// **'Exercise'**
  String get activityExercise;

  /// No description provided for @activityPostOp.
  ///
  /// In en, this message translates to:
  /// **'Post-op'**
  String get activityPostOp;

  /// No description provided for @howDoYouFeel.
  ///
  /// In en, this message translates to:
  /// **'HOW DO YOU FEEL?'**
  String get howDoYouFeel;

  /// No description provided for @symptomNormal.
  ///
  /// In en, this message translates to:
  /// **'Normal'**
  String get symptomNormal;

  /// No description provided for @symptomDizziness.
  ///
  /// In en, this message translates to:
  /// **'Dizziness'**
  String get symptomDizziness;

  /// No description provided for @symptomPain.
  ///
  /// In en, this message translates to:
  /// **'Pain'**
  String get symptomPain;

  /// No description provided for @symptomFatigue.
  ///
  /// In en, this message translates to:
  /// **'Fatigue'**
  String get symptomFatigue;

  /// No description provided for @bpLow.
  ///
  /// In en, this message translates to:
  /// **'LOW'**
  String get bpLow;

  /// No description provided for @bpNormal.
  ///
  /// In en, this message translates to:
  /// **'NORMAL'**
  String get bpNormal;

  /// No description provided for @bpElevated.
  ///
  /// In en, this message translates to:
  /// **'ELEVATED'**
  String get bpElevated;

  /// No description provided for @bpHigh.
  ///
  /// In en, this message translates to:
  /// **'HIGH'**
  String get bpHigh;

  /// No description provided for @hrLow.
  ///
  /// In en, this message translates to:
  /// **'LOW'**
  String get hrLow;

  /// No description provided for @hrNormal.
  ///
  /// In en, this message translates to:
  /// **'NORMAL'**
  String get hrNormal;

  /// No description provided for @hrHigh.
  ///
  /// In en, this message translates to:
  /// **'HIGH'**
  String get hrHigh;

  /// No description provided for @vitalsSavedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Vital signs saved successfully.'**
  String get vitalsSavedSuccess;

  /// No description provided for @lipidProfileTitle.
  ///
  /// In en, this message translates to:
  /// **'LIPID PROFILE'**
  String get lipidProfileTitle;

  /// No description provided for @lipidInfoBanner.
  ///
  /// In en, this message translates to:
  /// **'Enter the values from your latest lab test. All fields are optional, but filling them all in gives a more complete picture of your cardiovascular health.'**
  String get lipidInfoBanner;

  /// No description provided for @lipidLabInfo.
  ///
  /// In en, this message translates to:
  /// **'LABORATORY INFORMATION'**
  String get lipidLabInfo;

  /// No description provided for @lipidLabName.
  ///
  /// In en, this message translates to:
  /// **'Laboratory Name'**
  String get lipidLabName;

  /// No description provided for @lipidLabNameHint.
  ///
  /// In en, this message translates to:
  /// **'E.g. City Clinical Lab'**
  String get lipidLabNameHint;

  /// No description provided for @lipidResultsTitle.
  ///
  /// In en, this message translates to:
  /// **'ANALYSIS RESULTS (mg/dL)'**
  String get lipidResultsTitle;

  /// No description provided for @lipidTotalCholesterol.
  ///
  /// In en, this message translates to:
  /// **'Total Cholesterol'**
  String get lipidTotalCholesterol;

  /// No description provided for @lipidTcRef.
  ///
  /// In en, this message translates to:
  /// **'Ref: < 200 mg/dL'**
  String get lipidTcRef;

  /// No description provided for @lipidLdl.
  ///
  /// In en, this message translates to:
  /// **'LDL (\"Bad\" Cholesterol)'**
  String get lipidLdl;

  /// No description provided for @lipidLdlRef.
  ///
  /// In en, this message translates to:
  /// **'Ref: < 100 mg/dL'**
  String get lipidLdlRef;

  /// No description provided for @lipidHdl.
  ///
  /// In en, this message translates to:
  /// **'HDL (\"Good\" Cholesterol)'**
  String get lipidHdl;

  /// No description provided for @lipidHdlRef.
  ///
  /// In en, this message translates to:
  /// **'Ref: ≥ 60 mg/dL'**
  String get lipidHdlRef;

  /// No description provided for @lipidVldl.
  ///
  /// In en, this message translates to:
  /// **'VLDL'**
  String get lipidVldl;

  /// No description provided for @lipidVldlRef.
  ///
  /// In en, this message translates to:
  /// **'Ref: 2 – 30 mg/dL'**
  String get lipidVldlRef;

  /// No description provided for @lipidTriglycerides.
  ///
  /// In en, this message translates to:
  /// **'Triglycerides'**
  String get lipidTriglycerides;

  /// No description provided for @lipidTrigsRef.
  ///
  /// In en, this message translates to:
  /// **'Ref: < 150 mg/dL'**
  String get lipidTrigsRef;

  /// No description provided for @lipidStatusOptimal.
  ///
  /// In en, this message translates to:
  /// **'OPTIMAL'**
  String get lipidStatusOptimal;

  /// No description provided for @lipidStatusNearOptimal.
  ///
  /// In en, this message translates to:
  /// **'ACCEPTABLE'**
  String get lipidStatusNearOptimal;

  /// No description provided for @lipidStatusBorderline.
  ///
  /// In en, this message translates to:
  /// **'BORDERLINE'**
  String get lipidStatusBorderline;

  /// No description provided for @lipidStatusHigh.
  ///
  /// In en, this message translates to:
  /// **'HIGH'**
  String get lipidStatusHigh;

  /// No description provided for @lipidStatusLow.
  ///
  /// In en, this message translates to:
  /// **'LOW'**
  String get lipidStatusLow;

  /// No description provided for @lipidStatusProtective.
  ///
  /// In en, this message translates to:
  /// **'PROTECTIVE'**
  String get lipidStatusProtective;

  /// No description provided for @lipidStatusAcceptable.
  ///
  /// In en, this message translates to:
  /// **'ACCEPTABLE'**
  String get lipidStatusAcceptable;

  /// No description provided for @lipidOverallRisk.
  ///
  /// In en, this message translates to:
  /// **'OVERALL ASSESSMENT'**
  String get lipidOverallRisk;

  /// No description provided for @lipidOverallDesc.
  ///
  /// In en, this message translates to:
  /// **'Based on the values entered. Always consult your doctor.'**
  String get lipidOverallDesc;

  /// No description provided for @lipidAtLeastOneValue.
  ///
  /// In en, this message translates to:
  /// **'Enter at least one value to save the record.'**
  String get lipidAtLeastOneValue;

  /// No description provided for @lipidSavedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Lipid profile saved successfully.'**
  String get lipidSavedSuccess;

  /// No description provided for @compositionTitle.
  ///
  /// In en, this message translates to:
  /// **'BODY PROFILE'**
  String get compositionTitle;

  /// No description provided for @compositionInfoBanner.
  ///
  /// In en, this message translates to:
  /// **'Enter the values from your body composition analyzer (e.g. bioimpedance scale). All fields are optional — record whatever your device provides.'**
  String get compositionInfoBanner;

  /// No description provided for @compositionDevice.
  ///
  /// In en, this message translates to:
  /// **'MEASUREMENT DEVICE'**
  String get compositionDevice;

  /// No description provided for @compositionDeviceHint.
  ///
  /// In en, this message translates to:
  /// **'E.g. OMRON HBF-514C scale'**
  String get compositionDeviceHint;

  /// No description provided for @compositionBodyFat.
  ///
  /// In en, this message translates to:
  /// **'BODY FAT PERCENTAGE (%)'**
  String get compositionBodyFat;

  /// No description provided for @compositionMuscleMass.
  ///
  /// In en, this message translates to:
  /// **'MUSCLE MASS (KG)'**
  String get compositionMuscleMass;

  /// No description provided for @compositionVisceralAndAge.
  ///
  /// In en, this message translates to:
  /// **'VISCERAL FAT & METABOLIC AGE'**
  String get compositionVisceralAndAge;

  /// No description provided for @compositionVisceralFat.
  ///
  /// In en, this message translates to:
  /// **'VISCERAL FAT'**
  String get compositionVisceralFat;

  /// No description provided for @compositionLevel.
  ///
  /// In en, this message translates to:
  /// **'Level'**
  String get compositionLevel;

  /// No description provided for @compositionMetabolicAge.
  ///
  /// In en, this message translates to:
  /// **'METABOLIC AGE'**
  String get compositionMetabolicAge;

  /// No description provided for @compositionYears.
  ///
  /// In en, this message translates to:
  /// **'Years'**
  String get compositionYears;

  /// No description provided for @compositionOptionalSection.
  ///
  /// In en, this message translates to:
  /// **'OPTIONAL (BODY WATER & BONE MASS)'**
  String get compositionOptionalSection;

  /// No description provided for @compositionBodyWater.
  ///
  /// In en, this message translates to:
  /// **'Body Water'**
  String get compositionBodyWater;

  /// No description provided for @compositionBodyWaterRef.
  ///
  /// In en, this message translates to:
  /// **'Ref: 50–65 %'**
  String get compositionBodyWaterRef;

  /// No description provided for @compositionBoneMass.
  ///
  /// In en, this message translates to:
  /// **'Bone Mass'**
  String get compositionBoneMass;

  /// No description provided for @compositionBoneMassRef.
  ///
  /// In en, this message translates to:
  /// **'Ref: 2–4 kg'**
  String get compositionBoneMassRef;

  /// No description provided for @compositionBmr.
  ///
  /// In en, this message translates to:
  /// **'BASAL METABOLIC RATE (KCAL)'**
  String get compositionBmr;

  /// No description provided for @compositionBmrSubtitle.
  ///
  /// In en, this message translates to:
  /// **'ESTIMATE BASED ON YOUR CURRENT BODY COMPOSITION'**
  String get compositionBmrSubtitle;

  /// No description provided for @fatVeryLow.
  ///
  /// In en, this message translates to:
  /// **'VERY LOW'**
  String get fatVeryLow;

  /// No description provided for @fatLow.
  ///
  /// In en, this message translates to:
  /// **'LOW'**
  String get fatLow;

  /// No description provided for @fatNormal.
  ///
  /// In en, this message translates to:
  /// **'NORMAL'**
  String get fatNormal;

  /// No description provided for @fatElevated.
  ///
  /// In en, this message translates to:
  /// **'ELEVATED'**
  String get fatElevated;

  /// No description provided for @fatHigh.
  ///
  /// In en, this message translates to:
  /// **'HIGH'**
  String get fatHigh;

  /// No description provided for @infoBannerAnthro.
  ///
  /// In en, this message translates to:
  /// **'Try to take the measurement every time under the same conditions, for example: every morning after waking up, going to the bathroom, and before breakfast.'**
  String get infoBannerAnthro;

  /// No description provided for @infoBannerVitals.
  ///
  /// In en, this message translates to:
  /// **'Try to take your vital signs after resting for half an hour.'**
  String get infoBannerVitals;

  /// No description provided for @compositionSavedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Body profile saved successfully.'**
  String get compositionSavedSuccess;

  /// No description provided for @discoverGreeting.
  ///
  /// In en, this message translates to:
  /// **'Good morning, {name}'**
  String discoverGreeting(String name);

  /// No description provided for @discoverSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search for tips...'**
  String get discoverSearchHint;

  /// No description provided for @discoverDailyTip.
  ///
  /// In en, this message translates to:
  /// **'DAILY HEALTH TIP'**
  String get discoverDailyTip;

  /// No description provided for @discoverReadMore.
  ///
  /// In en, this message translates to:
  /// **'Read more'**
  String get discoverReadMore;

  /// No description provided for @discoverRecommended.
  ///
  /// In en, this message translates to:
  /// **'Recommended for you'**
  String get discoverRecommended;

  /// No description provided for @discoverCategoryAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get discoverCategoryAll;

  /// No description provided for @discoverCategoryHeart.
  ///
  /// In en, this message translates to:
  /// **'Heart Health'**
  String get discoverCategoryHeart;

  /// No description provided for @discoverCategoryNutrition.
  ///
  /// In en, this message translates to:
  /// **'Nutrition'**
  String get discoverCategoryNutrition;

  /// No description provided for @discoverCategoryEmotional.
  ///
  /// In en, this message translates to:
  /// **'Emotional Health'**
  String get discoverCategoryEmotional;

  /// No description provided for @discoverCategorySports.
  ///
  /// In en, this message translates to:
  /// **'Sports'**
  String get discoverCategorySports;

  /// No description provided for @discoverCategorySleep.
  ///
  /// In en, this message translates to:
  /// **'Sleep'**
  String get discoverCategorySleep;

  /// No description provided for @discoverMinRead.
  ///
  /// In en, this message translates to:
  /// **'MIN READ'**
  String get discoverMinRead;

  /// No description provided for @discoverFeatured.
  ///
  /// In en, this message translates to:
  /// **'Featured'**
  String get discoverFeatured;

  /// No description provided for @discoverRoutines.
  ///
  /// In en, this message translates to:
  /// **'Routines'**
  String get discoverRoutines;

  /// No description provided for @discoverArticles.
  ///
  /// In en, this message translates to:
  /// **'Articles'**
  String get discoverArticles;

  /// No description provided for @discoverChallenges.
  ///
  /// In en, this message translates to:
  /// **'Challenges'**
  String get discoverChallenges;

  /// No description provided for @discoverSeeAll.
  ///
  /// In en, this message translates to:
  /// **'See all'**
  String get discoverSeeAll;

  /// No description provided for @discoverMinShort.
  ///
  /// In en, this message translates to:
  /// **'min'**
  String get discoverMinShort;

  /// No description provided for @discoverStart.
  ///
  /// In en, this message translates to:
  /// **'Start'**
  String get discoverStart;

  /// No description provided for @discoverJoin.
  ///
  /// In en, this message translates to:
  /// **'Join'**
  String get discoverJoin;

  /// No description provided for @discoverLevelBeginner.
  ///
  /// In en, this message translates to:
  /// **'Beginner'**
  String get discoverLevelBeginner;

  /// No description provided for @discoverLevelIntermediate.
  ///
  /// In en, this message translates to:
  /// **'Intermediate'**
  String get discoverLevelIntermediate;

  /// No description provided for @discoverLevelAdvanced.
  ///
  /// In en, this message translates to:
  /// **'Advanced'**
  String get discoverLevelAdvanced;

  /// No description provided for @discoverStatusActive.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get discoverStatusActive;

  /// No description provided for @discoverStatusScheduled.
  ///
  /// In en, this message translates to:
  /// **'Scheduled'**
  String get discoverStatusScheduled;

  /// No description provided for @discoverStatusFinished.
  ///
  /// In en, this message translates to:
  /// **'Finished'**
  String get discoverStatusFinished;

  /// No description provided for @discoverEmpty.
  ///
  /// In en, this message translates to:
  /// **'No content available yet.'**
  String get discoverEmpty;

  /// No description provided for @discoverExercises.
  ///
  /// In en, this message translates to:
  /// **'{count} exercises'**
  String discoverExercises(String count);

  /// No description provided for @discoverParticipants.
  ///
  /// In en, this message translates to:
  /// **'{count} participants'**
  String discoverParticipants(String count);

  /// No description provided for @discoverDaysShort.
  ///
  /// In en, this message translates to:
  /// **'{count} days'**
  String discoverDaysShort(String count);

  /// No description provided for @privacySecurityDescription.
  ///
  /// In en, this message translates to:
  /// **'Manage how your medical and personal information is protected.'**
  String get privacySecurityDescription;

  /// No description provided for @biometricLockTitle.
  ///
  /// In en, this message translates to:
  /// **'Biometric Lock'**
  String get biometricLockTitle;

  /// No description provided for @biometricLockSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Requires Fingerprint or FaceID on app startup'**
  String get biometricLockSubtitle;

  /// No description provided for @biometricReasoning.
  ///
  /// In en, this message translates to:
  /// **'Your medical records are highly sensitive information. Enabling biometric lock ensures only you can access your health data, protecting your privacy.'**
  String get biometricReasoning;

  /// No description provided for @unlockAppToContinue.
  ///
  /// In en, this message translates to:
  /// **'Unlock to continue'**
  String get unlockAppToContinue;

  /// No description provided for @biometricNotAvailable.
  ///
  /// In en, this message translates to:
  /// **'Biometrics not available on this device.'**
  String get biometricNotAvailable;

  /// No description provided for @healthGoalsTitle.
  ///
  /// In en, this message translates to:
  /// **'Health Goals'**
  String get healthGoalsTitle;

  /// No description provided for @goalsScreenDescription.
  ///
  /// In en, this message translates to:
  /// **'Set your target values and track your progress.'**
  String get goalsScreenDescription;

  /// No description provided for @healthGoalsDescription.
  ///
  /// In en, this message translates to:
  /// **'Set your medical objectives to track your progress.'**
  String get healthGoalsDescription;

  /// No description provided for @medicalGoalsToggle.
  ///
  /// In en, this message translates to:
  /// **'Enable Medical Goals'**
  String get medicalGoalsToggle;

  /// No description provided for @medicalGoalsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Enable to set weight and body composition goals'**
  String get medicalGoalsSubtitle;

  /// No description provided for @targetWeight.
  ///
  /// In en, this message translates to:
  /// **'Target Weight'**
  String get targetWeight;

  /// No description provided for @targetBodyFat.
  ///
  /// In en, this message translates to:
  /// **'Target Body Fat'**
  String get targetBodyFat;

  /// No description provided for @targetMuscleMass.
  ///
  /// In en, this message translates to:
  /// **'Target Muscle Mass'**
  String get targetMuscleMass;

  /// No description provided for @targetVisceralFat.
  ///
  /// In en, this message translates to:
  /// **'Target Visceral Fat'**
  String get targetVisceralFat;

  /// No description provided for @goalsSavedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Goals saved successfully.'**
  String get goalsSavedSuccess;

  /// No description provided for @helpSupportPageTitle.
  ///
  /// In en, this message translates to:
  /// **'Help & Support'**
  String get helpSupportPageTitle;

  /// No description provided for @helpSupportPageDescription.
  ///
  /// In en, this message translates to:
  /// **'Everything you need to know about My Vitals.'**
  String get helpSupportPageDescription;

  /// No description provided for @helpFaqTitle.
  ///
  /// In en, this message translates to:
  /// **'Frequently Asked Questions'**
  String get helpFaqTitle;

  /// No description provided for @helpFaqDescription.
  ///
  /// In en, this message translates to:
  /// **'Quick answers to the most common questions.'**
  String get helpFaqDescription;

  /// No description provided for @helpGlossaryTitle.
  ///
  /// In en, this message translates to:
  /// **'Medical Glossary'**
  String get helpGlossaryTitle;

  /// No description provided for @helpGlossaryDescription.
  ///
  /// In en, this message translates to:
  /// **'Understand every health indicator.'**
  String get helpGlossaryDescription;

  /// No description provided for @helpLegalTitle.
  ///
  /// In en, this message translates to:
  /// **'Legal Notice'**
  String get helpLegalTitle;

  /// No description provided for @helpLegalDescription.
  ///
  /// In en, this message translates to:
  /// **'Terms of use and data privacy.'**
  String get helpLegalDescription;

  /// No description provided for @helpContactTitle.
  ///
  /// In en, this message translates to:
  /// **'Contact & Feedback'**
  String get helpContactTitle;

  /// No description provided for @helpContactDescription.
  ///
  /// In en, this message translates to:
  /// **'Write to us, we improve together.'**
  String get helpContactDescription;

  /// No description provided for @helpSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search...'**
  String get helpSearchHint;

  /// No description provided for @helpNoResults.
  ///
  /// In en, this message translates to:
  /// **'No results for your search.'**
  String get helpNoResults;

  /// No description provided for @helpFaqCatGeneral.
  ///
  /// In en, this message translates to:
  /// **'General'**
  String get helpFaqCatGeneral;

  /// No description provided for @helpFaqCatData.
  ///
  /// In en, this message translates to:
  /// **'My Data'**
  String get helpFaqCatData;

  /// No description provided for @helpFaqCatBiometrics.
  ///
  /// In en, this message translates to:
  /// **'Biometrics'**
  String get helpFaqCatBiometrics;

  /// No description provided for @helpFaqCatExport.
  ///
  /// In en, this message translates to:
  /// **'Export'**
  String get helpFaqCatExport;

  /// No description provided for @helpFaqQ1.
  ///
  /// In en, this message translates to:
  /// **'What is My Vitals?'**
  String get helpFaqQ1;

  /// No description provided for @helpFaqA1.
  ///
  /// In en, this message translates to:
  /// **'My Vitals is a personal health tracking app that lets you record and monitor your wellness indicators: anthropometric measurements, vital signs, lipid profile, and body composition.'**
  String get helpFaqA1;

  /// No description provided for @helpFaqQ2.
  ///
  /// In en, this message translates to:
  /// **'Is my data saved to the cloud?'**
  String get helpFaqQ2;

  /// No description provided for @helpFaqA2.
  ///
  /// In en, this message translates to:
  /// **'No. All your data is stored exclusively on your device. My Vitals does not send any information to external servers, ensuring complete privacy.'**
  String get helpFaqA2;

  /// No description provided for @helpFaqQ3.
  ///
  /// In en, this message translates to:
  /// **'Can I use the app without internet?'**
  String get helpFaqQ3;

  /// No description provided for @helpFaqA3.
  ///
  /// In en, this message translates to:
  /// **'Yes. My Vitals works completely offline. You only need connectivity for app updates.'**
  String get helpFaqA3;

  /// No description provided for @helpFaqQ4.
  ///
  /// In en, this message translates to:
  /// **'How do I enable biometric lock?'**
  String get helpFaqQ4;

  /// No description provided for @helpFaqA4.
  ///
  /// In en, this message translates to:
  /// **'Go to Profile › Privacy & Security and enable the Biometric Lock toggle. Your device must have fingerprint or FaceID configured.'**
  String get helpFaqA4;

  /// No description provided for @helpFaqQ5.
  ///
  /// In en, this message translates to:
  /// **'How do I export my history?'**
  String get helpFaqQ5;

  /// No description provided for @helpFaqA5.
  ///
  /// In en, this message translates to:
  /// **'In each history screen (Anthropometric, Vital Signs, etc.) you will find \'Export PDF\' and \'Excel (CSV)\' buttons at the top.'**
  String get helpFaqA5;

  /// No description provided for @helpFaqQ6.
  ///
  /// In en, this message translates to:
  /// **'Can I change the measurement units?'**
  String get helpFaqQ6;

  /// No description provided for @helpFaqA6.
  ///
  /// In en, this message translates to:
  /// **'Yes. Go to Profile › Measurement Units and choose between Metric (kg, cm) or Imperial (lb, ft/in) system.'**
  String get helpFaqA6;

  /// No description provided for @helpFaqQ7.
  ///
  /// In en, this message translates to:
  /// **'What happens if I delete the app?'**
  String get helpFaqQ7;

  /// No description provided for @helpFaqA7.
  ///
  /// In en, this message translates to:
  /// **'Uninstalling the app will permanently delete all locally stored data. We recommend exporting your history to PDF or CSV before uninstalling.'**
  String get helpFaqA7;

  /// No description provided for @helpFaqQ8.
  ///
  /// In en, this message translates to:
  /// **'Does this app replace my doctor?'**
  String get helpFaqQ8;

  /// No description provided for @helpFaqA8.
  ///
  /// In en, this message translates to:
  /// **'No. My Vitals is a personal tracking tool to help you keep an organized record. Always consult a healthcare professional for medical interpretation and diagnosis.'**
  String get helpFaqA8;

  /// No description provided for @helpGlossarySearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search term...'**
  String get helpGlossarySearchHint;

  /// No description provided for @helpGlossaryGroupAnthropo.
  ///
  /// In en, this message translates to:
  /// **'Anthropometric Measurements'**
  String get helpGlossaryGroupAnthropo;

  /// No description provided for @helpGlossaryGroupVitals.
  ///
  /// In en, this message translates to:
  /// **'Vital Signs'**
  String get helpGlossaryGroupVitals;

  /// No description provided for @helpGlossaryGroupLipid.
  ///
  /// In en, this message translates to:
  /// **'Lipid Profile'**
  String get helpGlossaryGroupLipid;

  /// No description provided for @helpGlossaryGroupBody.
  ///
  /// In en, this message translates to:
  /// **'Body Composition'**
  String get helpGlossaryGroupBody;

  /// No description provided for @helpGlossaryNormalRange.
  ///
  /// In en, this message translates to:
  /// **'Normal range'**
  String get helpGlossaryNormalRange;

  /// No description provided for @helpLegalPurposeTitle.
  ///
  /// In en, this message translates to:
  /// **'Purpose of the application'**
  String get helpLegalPurposeTitle;

  /// No description provided for @helpLegalPurposeBody.
  ///
  /// In en, this message translates to:
  /// **'My Vitals is a personal health tracking application designed to help users record and visualize their wellness indicators. It is not a certified medical device.'**
  String get helpLegalPurposeBody;

  /// No description provided for @helpLegalNotMedicalTitle.
  ///
  /// In en, this message translates to:
  /// **'Not a medical device'**
  String get helpLegalNotMedicalTitle;

  /// No description provided for @helpLegalNotMedicalBody.
  ///
  /// In en, this message translates to:
  /// **'The information displayed in this application is for reference purposes only. It does not replace the diagnosis, advice, or treatment of a health professional. If you have any medical symptoms or concerns, consult your doctor.'**
  String get helpLegalNotMedicalBody;

  /// No description provided for @helpLegalResponsibilityTitle.
  ///
  /// In en, this message translates to:
  /// **'User responsibility'**
  String get helpLegalResponsibilityTitle;

  /// No description provided for @helpLegalResponsibilityBody.
  ///
  /// In en, this message translates to:
  /// **'The user is responsible for the accuracy of the data entered. My Vitals is not responsible for health decisions made based on information recorded in the app.'**
  String get helpLegalResponsibilityBody;

  /// No description provided for @helpLegalPrivacyTitle.
  ///
  /// In en, this message translates to:
  /// **'Privacy and data'**
  String get helpLegalPrivacyTitle;

  /// No description provided for @helpLegalPrivacyBody.
  ///
  /// In en, this message translates to:
  /// **'All data is stored locally on the user\'s device. My Vitals does not collect, transmit, or share personal information with third parties. There are no user accounts or data servers.'**
  String get helpLegalPrivacyBody;

  /// No description provided for @helpLegalContactTitle.
  ///
  /// In en, this message translates to:
  /// **'Developer contact'**
  String get helpLegalContactTitle;

  /// No description provided for @helpLegalContactBody.
  ///
  /// In en, this message translates to:
  /// **'For legal or privacy inquiries, you can contact the developer at: yesithvalencia@gmail.com'**
  String get helpLegalContactBody;

  /// No description provided for @helpContactReportBug.
  ///
  /// In en, this message translates to:
  /// **'Report a bug'**
  String get helpContactReportBug;

  /// No description provided for @helpContactReportBugDesc.
  ///
  /// In en, this message translates to:
  /// **'Found something that\'s not working? Tell us.'**
  String get helpContactReportBugDesc;

  /// No description provided for @helpContactSuggest.
  ///
  /// In en, this message translates to:
  /// **'Send a suggestion'**
  String get helpContactSuggest;

  /// No description provided for @helpContactSuggestDesc.
  ///
  /// In en, this message translates to:
  /// **'Have an idea to improve the app? We want to hear it.'**
  String get helpContactSuggestDesc;

  /// No description provided for @helpContactSendEmail.
  ///
  /// In en, this message translates to:
  /// **'Send email'**
  String get helpContactSendEmail;

  /// No description provided for @helpContactAppVersion.
  ///
  /// In en, this message translates to:
  /// **'App version'**
  String get helpContactAppVersion;

  /// No description provided for @helpContactWhatsNew.
  ///
  /// In en, this message translates to:
  /// **'What\'s new'**
  String get helpContactWhatsNew;

  /// No description provided for @helpContactV110.
  ///
  /// In en, this message translates to:
  /// **'v1.1.0 — Current'**
  String get helpContactV110;

  /// No description provided for @helpContactV110Changes.
  ///
  /// In en, this message translates to:
  /// **'• Biometric lock (fingerprint / FaceID)\n• Personalized health goals\n• Italian language support\n• Improved activity level selector'**
  String get helpContactV110Changes;

  /// No description provided for @helpContactV100.
  ///
  /// In en, this message translates to:
  /// **'v1.0.0 — Initial release'**
  String get helpContactV100;

  /// No description provided for @helpContactV100Changes.
  ///
  /// In en, this message translates to:
  /// **'• Anthropometric measurements tracking\n• Vital signs and lipid profile\n• Body composition\n• PDF and CSV export\n• Multilanguage support (es, en, de, pt)'**
  String get helpContactV100Changes;

  /// No description provided for @myDataBackup.
  ///
  /// In en, this message translates to:
  /// **'My Data'**
  String get myDataBackup;

  /// No description provided for @backupTitle.
  ///
  /// In en, this message translates to:
  /// **'Backup & Restore'**
  String get backupTitle;

  /// No description provided for @backupDescription.
  ///
  /// In en, this message translates to:
  /// **'Export or restore all your data and preferences.'**
  String get backupDescription;

  /// No description provided for @backupPrivacyTitle.
  ///
  /// In en, this message translates to:
  /// **'Your data is yours. And yours only.'**
  String get backupPrivacyTitle;

  /// No description provided for @backupPrivacyBody.
  ///
  /// In en, this message translates to:
  /// **'All of our health features are built with privacy at the core. Your data never leaves your device — My Vitals does not use cloud servers, external accounts, or third-party services. Everything is stored locally in an encrypted database, accessible only to you.'**
  String get backupPrivacyBody;

  /// No description provided for @backupPrivacyHighlight.
  ///
  /// In en, this message translates to:
  /// **'If you enable biometric lock, your health data is further protected by your fingerprint or Face ID — no one else can access your information, not even us.'**
  String get backupPrivacyHighlight;

  /// No description provided for @backupExportTitle.
  ///
  /// In en, this message translates to:
  /// **'Export my data'**
  String get backupExportTitle;

  /// No description provided for @backupExportSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Generate a secure file with all your history and settings'**
  String get backupExportSubtitle;

  /// No description provided for @backupExportButton.
  ///
  /// In en, this message translates to:
  /// **'Export Backup'**
  String get backupExportButton;

  /// No description provided for @backupImportTitle.
  ///
  /// In en, this message translates to:
  /// **'Restore my data'**
  String get backupImportTitle;

  /// No description provided for @backupImportSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Import a previous My Vitals backup'**
  String get backupImportSubtitle;

  /// No description provided for @backupImportButton.
  ///
  /// In en, this message translates to:
  /// **'Import Backup'**
  String get backupImportButton;

  /// No description provided for @backupWhatIncluded.
  ///
  /// In en, this message translates to:
  /// **'What\'s included in the backup?'**
  String get backupWhatIncluded;

  /// No description provided for @backupSuccess.
  ///
  /// In en, this message translates to:
  /// **'Backup exported successfully!'**
  String get backupSuccess;

  /// No description provided for @backupImportSuccess.
  ///
  /// In en, this message translates to:
  /// **'Data restored successfully!'**
  String get backupImportSuccess;

  /// No description provided for @backupImportError.
  ///
  /// In en, this message translates to:
  /// **'Import error. Verify that the file is valid.'**
  String get backupImportError;

  /// No description provided for @backupImportConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Restore data?'**
  String get backupImportConfirmTitle;

  /// No description provided for @backupImportConfirmBody.
  ///
  /// In en, this message translates to:
  /// **'This will replace your current records with the ones from the backup. Do you want to continue?'**
  String get backupImportConfirmBody;

  /// No description provided for @backupIncludesVitalSigns.
  ///
  /// In en, this message translates to:
  /// **'Vital Signs History'**
  String get backupIncludesVitalSigns;

  /// No description provided for @backupIncludesAnthropo.
  ///
  /// In en, this message translates to:
  /// **'Anthropometric History'**
  String get backupIncludesAnthropo;

  /// No description provided for @backupIncludesLipid.
  ///
  /// In en, this message translates to:
  /// **'Lipid Profile'**
  String get backupIncludesLipid;

  /// No description provided for @backupIncludesBodyComp.
  ///
  /// In en, this message translates to:
  /// **'Body Composition'**
  String get backupIncludesBodyComp;

  /// No description provided for @backupIncludesPersonalInfo.
  ///
  /// In en, this message translates to:
  /// **'Personal Information'**
  String get backupIncludesPersonalInfo;

  /// No description provided for @backupIncludesGoals.
  ///
  /// In en, this message translates to:
  /// **'Health Goals'**
  String get backupIncludesGoals;

  /// No description provided for @backupIncludesPhoto.
  ///
  /// In en, this message translates to:
  /// **'Profile Photo'**
  String get backupIncludesPhoto;

  /// No description provided for @backupIncludesPreferences.
  ///
  /// In en, this message translates to:
  /// **'Preferences (language, units, theme, reminders, device)'**
  String get backupIncludesPreferences;

  /// No description provided for @exportSuccess.
  ///
  /// In en, this message translates to:
  /// **'Exported successfully'**
  String get exportSuccess;

  /// No description provided for @exportError.
  ///
  /// In en, this message translates to:
  /// **'Could not export. Please try again.'**
  String get exportError;

  /// No description provided for @backupCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get backupCancel;

  /// No description provided for @onboardingWelcomeTitle.
  ///
  /// In en, this message translates to:
  /// **'Welcome to My Vitals'**
  String get onboardingWelcomeTitle;

  /// No description provided for @onboardingWelcomeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Your personal health companion'**
  String get onboardingWelcomeSubtitle;

  /// No description provided for @onboardingWelcomeFeature1.
  ///
  /// In en, this message translates to:
  /// **'Record your vital signs and body measurements'**
  String get onboardingWelcomeFeature1;

  /// No description provided for @onboardingWelcomeFeature2.
  ///
  /// In en, this message translates to:
  /// **'Visualize your progress with charts and stats'**
  String get onboardingWelcomeFeature2;

  /// No description provided for @onboardingWelcomeFeature3.
  ///
  /// In en, this message translates to:
  /// **'Sync your history securely across your devices'**
  String get onboardingWelcomeFeature3;

  /// No description provided for @onboardingNext.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get onboardingNext;

  /// No description provided for @onboardingFinish.
  ///
  /// In en, this message translates to:
  /// **'Get Started!'**
  String get onboardingFinish;

  /// No description provided for @welcomeGetStarted.
  ///
  /// In en, this message translates to:
  /// **'Get Started'**
  String get welcomeGetStarted;

  /// No description provided for @welcomeLogIn.
  ///
  /// In en, this message translates to:
  /// **'Log In'**
  String get welcomeLogIn;

  /// No description provided for @welcomeAlreadyHaveAccount.
  ///
  /// In en, this message translates to:
  /// **'Already have an account?'**
  String get welcomeAlreadyHaveAccount;

  /// No description provided for @onboardingStep.
  ///
  /// In en, this message translates to:
  /// **'Step {current} of {total}'**
  String onboardingStep(int current, int total);

  /// No description provided for @onboardingAvatarTitle.
  ///
  /// In en, this message translates to:
  /// **'Your profile picture'**
  String get onboardingAvatarTitle;

  /// No description provided for @onboardingAvatarSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Put a face to your health journey (optional)'**
  String get onboardingAvatarSubtitle;

  /// No description provided for @remindersTitle.
  ///
  /// In en, this message translates to:
  /// **'Reminders & Alerts'**
  String get remindersTitle;

  /// No description provided for @remindersDescription.
  ///
  /// In en, this message translates to:
  /// **'Set daily alerts to remember your routine medical checkups.'**
  String get remindersDescription;

  /// No description provided for @remindersNote.
  ///
  /// In en, this message translates to:
  /// **'* Notifications will arrive on your device daily at the scheduled time.'**
  String get remindersNote;

  /// No description provided for @reminderVitals.
  ///
  /// In en, this message translates to:
  /// **'Record Vital Signs'**
  String get reminderVitals;

  /// No description provided for @reminderMeds.
  ///
  /// In en, this message translates to:
  /// **'Take Medication'**
  String get reminderMeds;

  /// No description provided for @reminderWorkout.
  ///
  /// In en, this message translates to:
  /// **'Physical Activity'**
  String get reminderWorkout;

  /// No description provided for @reminderWater.
  ///
  /// In en, this message translates to:
  /// **'Drink Water'**
  String get reminderWater;

  /// No description provided for @reminderTitle.
  ///
  /// In en, this message translates to:
  /// **'Medical Reminder'**
  String get reminderTitle;

  /// No description provided for @filterLast7Days.
  ///
  /// In en, this message translates to:
  /// **'Last 7 days'**
  String get filterLast7Days;

  /// No description provided for @filterLast30Days.
  ///
  /// In en, this message translates to:
  /// **'Last 30 days'**
  String get filterLast30Days;

  /// No description provided for @filterLast6Months.
  ///
  /// In en, this message translates to:
  /// **'Last 6 months'**
  String get filterLast6Months;

  /// No description provided for @filterAllTime.
  ///
  /// In en, this message translates to:
  /// **'All time'**
  String get filterAllTime;

  /// No description provided for @goalRemainingWeight.
  ///
  /// In en, this message translates to:
  /// **'{weight}kg remaining for target'**
  String goalRemainingWeight(String weight);

  /// No description provided for @goalAchieved.
  ///
  /// In en, this message translates to:
  /// **'Goal achieved!'**
  String get goalAchieved;

  /// No description provided for @noGoalDefined.
  ///
  /// In en, this message translates to:
  /// **'No goal defined'**
  String get noGoalDefined;

  /// No description provided for @validationRequiredFields.
  ///
  /// In en, this message translates to:
  /// **'Required fields'**
  String get validationRequiredFields;

  /// No description provided for @validationCompleteBeforeContinue.
  ///
  /// In en, this message translates to:
  /// **'Please complete these fields before continuing:'**
  String get validationCompleteBeforeContinue;

  /// No description provided for @validationSelectLanguage.
  ///
  /// In en, this message translates to:
  /// **'Select a language'**
  String get validationSelectLanguage;

  /// No description provided for @validationEnterName.
  ///
  /// In en, this message translates to:
  /// **'Enter your full name'**
  String get validationEnterName;

  /// No description provided for @validationSelectBirthDate.
  ///
  /// In en, this message translates to:
  /// **'Select your date of birth'**
  String get validationSelectBirthDate;

  /// No description provided for @validationSelectGender.
  ///
  /// In en, this message translates to:
  /// **'Select your gender'**
  String get validationSelectGender;

  /// No description provided for @dashboardCompositionFat.
  ///
  /// In en, this message translates to:
  /// **'FAT'**
  String get dashboardCompositionFat;

  /// No description provided for @dashboardCompositionMuscle.
  ///
  /// In en, this message translates to:
  /// **'MUSCLE'**
  String get dashboardCompositionMuscle;

  /// No description provided for @dashboardCompositionVisceral.
  ///
  /// In en, this message translates to:
  /// **'VISCERAL'**
  String get dashboardCompositionVisceral;

  /// No description provided for @dashboardCompositionBmr.
  ///
  /// In en, this message translates to:
  /// **'BMR'**
  String get dashboardCompositionBmr;

  /// No description provided for @dashboardLastMeasured.
  ///
  /// In en, this message translates to:
  /// **'Last measured'**
  String get dashboardLastMeasured;

  /// No description provided for @dashboardCompositionLevel.
  ///
  /// In en, this message translates to:
  /// **'Lv. {level}'**
  String dashboardCompositionLevel(int level);

  /// No description provided for @vitalsPdfTitle.
  ///
  /// In en, this message translates to:
  /// **'Vital Signs History'**
  String get vitalsPdfTitle;

  /// No description provided for @vitalsShareCsvSubject.
  ///
  /// In en, this message translates to:
  /// **'Vital Signs CSV'**
  String get vitalsShareCsvSubject;

  /// No description provided for @lipidPdfTitle.
  ///
  /// In en, this message translates to:
  /// **'Lipid Profile History'**
  String get lipidPdfTitle;

  /// No description provided for @lipidShareCsvSubject.
  ///
  /// In en, this message translates to:
  /// **'Lab Results CSV'**
  String get lipidShareCsvSubject;

  /// No description provided for @compositionPdfTitle.
  ///
  /// In en, this message translates to:
  /// **'Body Composition History'**
  String get compositionPdfTitle;

  /// No description provided for @compositionShareCsvSubject.
  ///
  /// In en, this message translates to:
  /// **'Body Composition CSV'**
  String get compositionShareCsvSubject;

  /// No description provided for @reminderDefaultTitle.
  ///
  /// In en, this message translates to:
  /// **'Medical Reminder'**
  String get reminderDefaultTitle;

  /// No description provided for @exportColComment.
  ///
  /// In en, this message translates to:
  /// **'Comment'**
  String get exportColComment;

  /// No description provided for @exportColHeight.
  ///
  /// In en, this message translates to:
  /// **'Height (m)'**
  String get exportColHeight;

  /// No description provided for @exportColSysDia.
  ///
  /// In en, this message translates to:
  /// **'Sys/Dia'**
  String get exportColSysDia;

  /// No description provided for @exportColHrShort.
  ///
  /// In en, this message translates to:
  /// **'HR'**
  String get exportColHrShort;

  /// No description provided for @exportColStatus.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get exportColStatus;

  /// No description provided for @exportColSystolic.
  ///
  /// In en, this message translates to:
  /// **'Systolic'**
  String get exportColSystolic;

  /// No description provided for @exportColDiastolic.
  ///
  /// In en, this message translates to:
  /// **'Diastolic'**
  String get exportColDiastolic;

  /// No description provided for @exportColHeartRate.
  ///
  /// In en, this message translates to:
  /// **'Heart Rate'**
  String get exportColHeartRate;

  /// No description provided for @exportColActivityState.
  ///
  /// In en, this message translates to:
  /// **'Activity State'**
  String get exportColActivityState;

  /// No description provided for @exportColSymptom.
  ///
  /// In en, this message translates to:
  /// **'Symptom'**
  String get exportColSymptom;

  /// No description provided for @exportColTotalCholShort.
  ///
  /// In en, this message translates to:
  /// **'Total Chol.'**
  String get exportColTotalCholShort;

  /// No description provided for @exportColTrigsShort.
  ///
  /// In en, this message translates to:
  /// **'Trigs'**
  String get exportColTrigsShort;

  /// No description provided for @exportColTotalCholesterol.
  ///
  /// In en, this message translates to:
  /// **'Total Cholesterol'**
  String get exportColTotalCholesterol;

  /// No description provided for @exportColTriglycerides.
  ///
  /// In en, this message translates to:
  /// **'Triglycerides'**
  String get exportColTriglycerides;

  /// No description provided for @exportColLabName.
  ///
  /// In en, this message translates to:
  /// **'Lab Name'**
  String get exportColLabName;

  /// No description provided for @exportColBodyFat.
  ///
  /// In en, this message translates to:
  /// **'Body Fat'**
  String get exportColBodyFat;

  /// No description provided for @exportColMuscleMass.
  ///
  /// In en, this message translates to:
  /// **'Muscle Mass'**
  String get exportColMuscleMass;

  /// No description provided for @exportColVisceralFat.
  ///
  /// In en, this message translates to:
  /// **'Visceral Fat'**
  String get exportColVisceralFat;

  /// No description provided for @exportColMetabolicAge.
  ///
  /// In en, this message translates to:
  /// **'Metabolic Age'**
  String get exportColMetabolicAge;

  /// No description provided for @exportColBodyWater.
  ///
  /// In en, this message translates to:
  /// **'Body Water'**
  String get exportColBodyWater;

  /// No description provided for @exportColBoneMass.
  ///
  /// In en, this message translates to:
  /// **'Bone Mass'**
  String get exportColBoneMass;

  /// No description provided for @exportColBmr.
  ///
  /// In en, this message translates to:
  /// **'BMR'**
  String get exportColBmr;

  /// No description provided for @glossaryImcName.
  ///
  /// In en, this message translates to:
  /// **'BMI (Body Mass Index)'**
  String get glossaryImcName;

  /// No description provided for @glossaryImcDefinition.
  ///
  /// In en, this message translates to:
  /// **'A measure relating weight and height to assess whether a person\'s weight is healthy. Calculated by dividing weight (kg) by height squared (m²).'**
  String get glossaryImcDefinition;

  /// No description provided for @glossaryImcRange.
  ///
  /// In en, this message translates to:
  /// **'18.5 – 24.9 kg/m²'**
  String get glossaryImcRange;

  /// No description provided for @glossaryPesoName.
  ///
  /// In en, this message translates to:
  /// **'Body Weight'**
  String get glossaryPesoName;

  /// No description provided for @glossaryPesoDefinition.
  ///
  /// In en, this message translates to:
  /// **'Total mass of the body expressed in kilograms or pounds. Includes muscles, bones, organs, fat, and water.'**
  String get glossaryPesoDefinition;

  /// No description provided for @glossaryPesoRange.
  ///
  /// In en, this message translates to:
  /// **'Depends on height and build'**
  String get glossaryPesoRange;

  /// No description provided for @glossaryTallaName.
  ///
  /// In en, this message translates to:
  /// **'Height (Stature)'**
  String get glossaryTallaName;

  /// No description provided for @glossaryTallaDefinition.
  ///
  /// In en, this message translates to:
  /// **'Measurement of a person\'s height from feet to the top of the head, expressed in centimeters or meters.'**
  String get glossaryTallaDefinition;

  /// No description provided for @glossarySistolicaName.
  ///
  /// In en, this message translates to:
  /// **'Systolic Pressure'**
  String get glossarySistolicaName;

  /// No description provided for @glossarySistolicaDefinition.
  ///
  /// In en, this message translates to:
  /// **'The maximum pressure exerted by blood on the arteries when the heart contracts (beats). It is the upper number in a blood pressure reading.'**
  String get glossarySistolicaDefinition;

  /// No description provided for @glossarySistolicaRange.
  ///
  /// In en, this message translates to:
  /// **'< 120 mmHg'**
  String get glossarySistolicaRange;

  /// No description provided for @glossaryDiastolicaName.
  ///
  /// In en, this message translates to:
  /// **'Diastolic Pressure'**
  String get glossaryDiastolicaName;

  /// No description provided for @glossaryDiastolicaDefinition.
  ///
  /// In en, this message translates to:
  /// **'The minimum pressure exerted by blood on the arteries between heartbeats, when the heart is at rest. It is the lower number in a blood pressure reading.'**
  String get glossaryDiastolicaDefinition;

  /// No description provided for @glossaryDiastolicaRange.
  ///
  /// In en, this message translates to:
  /// **'< 80 mmHg'**
  String get glossaryDiastolicaRange;

  /// No description provided for @glossaryFcName.
  ///
  /// In en, this message translates to:
  /// **'Heart Rate'**
  String get glossaryFcName;

  /// No description provided for @glossaryFcDefinition.
  ///
  /// In en, this message translates to:
  /// **'Number of times the heart beats per minute (bpm). At rest, a healthy heart beats regularly within a specific range.'**
  String get glossaryFcDefinition;

  /// No description provided for @glossaryFcRange.
  ///
  /// In en, this message translates to:
  /// **'60 – 100 bpm at rest'**
  String get glossaryFcRange;

  /// No description provided for @glossaryColesterolTotalName.
  ///
  /// In en, this message translates to:
  /// **'Total Cholesterol'**
  String get glossaryColesterolTotalName;

  /// No description provided for @glossaryColesterolTotalDefinition.
  ///
  /// In en, this message translates to:
  /// **'Sum of all cholesterol in the blood, including LDL, HDL, and other lipids. It is a general marker of cardiovascular risk.'**
  String get glossaryColesterolTotalDefinition;

  /// No description provided for @glossaryColesterolTotalRange.
  ///
  /// In en, this message translates to:
  /// **'< 200 mg/dL'**
  String get glossaryColesterolTotalRange;

  /// No description provided for @glossaryLdlName.
  ///
  /// In en, this message translates to:
  /// **'LDL (\"Bad\" Cholesterol)'**
  String get glossaryLdlName;

  /// No description provided for @glossaryLdlDefinition.
  ///
  /// In en, this message translates to:
  /// **'Low-density lipoprotein. It carries cholesterol into the arteries and can accumulate in their walls, increasing cardiovascular disease risk.'**
  String get glossaryLdlDefinition;

  /// No description provided for @glossaryLdlRange.
  ///
  /// In en, this message translates to:
  /// **'< 100 mg/dL'**
  String get glossaryLdlRange;

  /// No description provided for @glossaryHdlName.
  ///
  /// In en, this message translates to:
  /// **'HDL (\"Good\" Cholesterol)'**
  String get glossaryHdlName;

  /// No description provided for @glossaryHdlDefinition.
  ///
  /// In en, this message translates to:
  /// **'High-density lipoprotein. It collects excess cholesterol from the arteries and carries it to the liver for elimination. High levels are protective.'**
  String get glossaryHdlDefinition;

  /// No description provided for @glossaryHdlRange.
  ///
  /// In en, this message translates to:
  /// **'≥ 60 mg/dL'**
  String get glossaryHdlRange;

  /// No description provided for @glossaryVldlName.
  ///
  /// In en, this message translates to:
  /// **'VLDL'**
  String get glossaryVldlName;

  /// No description provided for @glossaryVldlDefinition.
  ///
  /// In en, this message translates to:
  /// **'Very low-density lipoprotein. It transports triglycerides from the liver to tissues. Elevated levels are associated with higher cardiovascular risk.'**
  String get glossaryVldlDefinition;

  /// No description provided for @glossaryVldlRange.
  ///
  /// In en, this message translates to:
  /// **'2 – 30 mg/dL'**
  String get glossaryVldlRange;

  /// No description provided for @glossaryTrigliceridosName.
  ///
  /// In en, this message translates to:
  /// **'Triglycerides'**
  String get glossaryTrigliceridosName;

  /// No description provided for @glossaryTrigliceridosDefinition.
  ///
  /// In en, this message translates to:
  /// **'A type of fat (lipid) in the blood. The body uses them as an energy source, but high levels increase the risk of heart and pancreatic disease.'**
  String get glossaryTrigliceridosDefinition;

  /// No description provided for @glossaryTrigliceridosRange.
  ///
  /// In en, this message translates to:
  /// **'< 150 mg/dL'**
  String get glossaryTrigliceridosRange;

  /// No description provided for @glossaryGrasaName.
  ///
  /// In en, this message translates to:
  /// **'Body Fat Percentage'**
  String get glossaryGrasaName;

  /// No description provided for @glossaryGrasaDefinition.
  ///
  /// In en, this message translates to:
  /// **'Proportion of fat mass relative to total body weight. Includes essential fat (needed for vital functions) and storage fat.'**
  String get glossaryGrasaDefinition;

  /// No description provided for @glossaryGrasaRange.
  ///
  /// In en, this message translates to:
  /// **'Men: 8–19% / Women: 21–33%'**
  String get glossaryGrasaRange;

  /// No description provided for @glossaryMusculoName.
  ///
  /// In en, this message translates to:
  /// **'Muscle Mass'**
  String get glossaryMusculoName;

  /// No description provided for @glossaryMusculoDefinition.
  ///
  /// In en, this message translates to:
  /// **'Total weight of muscle tissue in the body, expressed in kilograms. A higher muscle percentage is associated with a more active metabolism.'**
  String get glossaryMusculoDefinition;

  /// No description provided for @glossaryGrasaVisceralName.
  ///
  /// In en, this message translates to:
  /// **'Visceral Fat'**
  String get glossaryGrasaVisceralName;

  /// No description provided for @glossaryGrasaVisceralDefinition.
  ///
  /// In en, this message translates to:
  /// **'Fat accumulated around the internal organs of the abdomen (liver, intestines, pancreas). High levels are associated with higher metabolic and cardiovascular risk.'**
  String get glossaryGrasaVisceralDefinition;

  /// No description provided for @glossaryGrasaVisceralRange.
  ///
  /// In en, this message translates to:
  /// **'Level 1–9 (healthy)'**
  String get glossaryGrasaVisceralRange;

  /// No description provided for @glossaryEdadMetabolicaName.
  ///
  /// In en, this message translates to:
  /// **'Metabolic Age'**
  String get glossaryEdadMetabolicaName;

  /// No description provided for @glossaryEdadMetabolicaDefinition.
  ///
  /// In en, this message translates to:
  /// **'Estimated age of basal metabolism compared to the population average. A metabolic age lower than chronological age indicates an efficient metabolism.'**
  String get glossaryEdadMetabolicaDefinition;

  /// No description provided for @glossaryBmrName.
  ///
  /// In en, this message translates to:
  /// **'BMR / Basal Metabolism (kcal)'**
  String get glossaryBmrName;

  /// No description provided for @glossaryBmrDefinition.
  ///
  /// In en, this message translates to:
  /// **'Minimum amount of energy (calories) the body needs at complete rest to maintain vital functions: breathing, circulation, temperature, etc.'**
  String get glossaryBmrDefinition;

  /// No description provided for @glossaryAguaName.
  ///
  /// In en, this message translates to:
  /// **'Body Water'**
  String get glossaryAguaName;

  /// No description provided for @glossaryAguaDefinition.
  ///
  /// In en, this message translates to:
  /// **'Percentage of body weight that corresponds to water. Water is essential for all cellular functions, temperature regulation, and nutrient transport.'**
  String get glossaryAguaDefinition;

  /// No description provided for @glossaryAguaRange.
  ///
  /// In en, this message translates to:
  /// **'50 – 65%'**
  String get glossaryAguaRange;

  /// No description provided for @glossaryHuesoName.
  ///
  /// In en, this message translates to:
  /// **'Bone Mass'**
  String get glossaryHuesoName;

  /// No description provided for @glossaryHuesoDefinition.
  ///
  /// In en, this message translates to:
  /// **'Estimated weight of bone tissue in the body. Maintaining adequate bone mass is essential to prevent osteoporosis.'**
  String get glossaryHuesoDefinition;

  /// No description provided for @glossaryHuesoRange.
  ///
  /// In en, this message translates to:
  /// **'2 – 4 kg (average adult)'**
  String get glossaryHuesoRange;

  /// No description provided for @deleteRecordTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete record?'**
  String get deleteRecordTitle;

  /// No description provided for @deleteRecordBody.
  ///
  /// In en, this message translates to:
  /// **'This action can\'t be undone.'**
  String get deleteRecordBody;

  /// No description provided for @deleteRecordConfirm.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get deleteRecordConfirm;

  /// No description provided for @recordDeleted.
  ///
  /// In en, this message translates to:
  /// **'Record deleted'**
  String get recordDeleted;

  /// No description provided for @anthropoSavedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Measurement saved successfully.'**
  String get anthropoSavedSuccess;

  /// No description provided for @historyShowMore.
  ///
  /// In en, this message translates to:
  /// **'Show {count} more'**
  String historyShowMore(int count);

  /// No description provided for @introSignIn.
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get introSignIn;

  /// No description provided for @introRegister.
  ///
  /// In en, this message translates to:
  /// **'Create account'**
  String get introRegister;

  /// No description provided for @emailLabel.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get emailLabel;

  /// No description provided for @validationEnterEmail.
  ///
  /// In en, this message translates to:
  /// **'Enter your email'**
  String get validationEnterEmail;

  /// No description provided for @validationEmailFormat.
  ///
  /// In en, this message translates to:
  /// **'Check the email: the @ or the domain is missing'**
  String get validationEmailFormat;

  /// No description provided for @validationOutOfRange.
  ///
  /// In en, this message translates to:
  /// **'Enter a value between {min} and {max}'**
  String validationOutOfRange(Object max, Object min);

  /// No description provided for @commonRegisterFailed.
  ///
  /// In en, this message translates to:
  /// **'We couldn\'t create your account. Check your connection and try again.'**
  String get commonRegisterFailed;

  /// No description provided for @logOutConfirm.
  ///
  /// In en, this message translates to:
  /// **'Sign out on this device? Your records stay on the device and will sync again when you sign back in.'**
  String get logOutConfirm;

  /// No description provided for @pendingAccountTitle.
  ///
  /// In en, this message translates to:
  /// **'Account pending'**
  String get pendingAccountTitle;

  /// No description provided for @pendingAccountBody.
  ///
  /// In en, this message translates to:
  /// **'Your data is saved on this device. We will create your account as soon as there is a connection.'**
  String get pendingAccountBody;

  /// No description provided for @pendingAccountCreateNow.
  ///
  /// In en, this message translates to:
  /// **'Create my account now'**
  String get pendingAccountCreateNow;

  /// No description provided for @pendingAccountCreating.
  ///
  /// In en, this message translates to:
  /// **'Creating your account…'**
  String get pendingAccountCreating;

  /// No description provided for @pendingAccountCreated.
  ///
  /// In en, this message translates to:
  /// **'Account created. Uploading your records.'**
  String get pendingAccountCreated;

  /// No description provided for @pendingAccountStillOffline.
  ///
  /// In en, this message translates to:
  /// **'Still no connection. Your data is safe on this device.'**
  String get pendingAccountStillOffline;

  /// No description provided for @identifyTitle.
  ///
  /// In en, this message translates to:
  /// **'Let us bring your history'**
  String get identifyTitle;

  /// No description provided for @identifyBody.
  ///
  /// In en, this message translates to:
  /// **'Enter your ID number (or email). If you are already a patient we will load your data; if not, we will create your account.'**
  String get identifyBody;

  /// No description provided for @identifyFieldLabel.
  ///
  /// In en, this message translates to:
  /// **'ID number or email'**
  String get identifyFieldLabel;

  /// No description provided for @identifyFieldHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. 1032456789'**
  String get identifyFieldHint;

  /// No description provided for @identifyFoundTitle.
  ///
  /// In en, this message translates to:
  /// **'We found a medical history linked to this ID.'**
  String get identifyFoundTitle;

  /// No description provided for @identifyFoundBody.
  ///
  /// In en, this message translates to:
  /// **'We can bring it over and activate your account so you see your data from day one.'**
  String get identifyFoundBody;

  /// No description provided for @identifyBringHistory.
  ///
  /// In en, this message translates to:
  /// **'Bring my history and continue'**
  String get identifyBringHistory;

  /// No description provided for @identifyBringingHistory.
  ///
  /// In en, this message translates to:
  /// **'Bringing your history…'**
  String get identifyBringingHistory;

  /// No description provided for @identifyNotMe.
  ///
  /// In en, this message translates to:
  /// **'That\'s not me — sign me up as new'**
  String get identifyNotMe;

  /// No description provided for @verifyAppBarTitle.
  ///
  /// In en, this message translates to:
  /// **'Verification'**
  String get verifyAppBarTitle;

  /// No description provided for @verifyTitle.
  ///
  /// In en, this message translates to:
  /// **'We found your account'**
  String get verifyTitle;

  /// No description provided for @verifyBody.
  ///
  /// In en, this message translates to:
  /// **'Verify your identity to continue with\n{identifier}.'**
  String verifyBody(String identifier);

  /// No description provided for @verifyPasswordLabel.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get verifyPasswordLabel;

  /// No description provided for @verifyTestNotice.
  ///
  /// In en, this message translates to:
  /// **'Test phase: the password is 1234. (An OTP code will go here in production.)'**
  String get verifyTestNotice;

  /// No description provided for @verifySubmit.
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get verifySubmit;

  /// No description provided for @unexpectedError.
  ///
  /// In en, this message translates to:
  /// **'Unexpected error: {details}'**
  String unexpectedError(String details);

  /// No description provided for @accountSyncTitle.
  ///
  /// In en, this message translates to:
  /// **'Account and sync'**
  String get accountSyncTitle;

  /// No description provided for @accountSyncDescription.
  ///
  /// In en, this message translates to:
  /// **'Sign in and sync your records with the server.'**
  String get accountSyncDescription;

  /// No description provided for @accountYourAccount.
  ///
  /// In en, this message translates to:
  /// **'Your account'**
  String get accountYourAccount;

  /// No description provided for @accountPendingBody.
  ///
  /// In en, this message translates to:
  /// **'Your data is on this device. The account still has to be created on the server.'**
  String get accountPendingBody;

  /// No description provided for @accountLoggedOutBody.
  ///
  /// In en, this message translates to:
  /// **'Sign in if you are already a patient, or register to get started.'**
  String get accountLoggedOutBody;

  /// No description provided for @accountFallbackName.
  ///
  /// In en, this message translates to:
  /// **'Patient'**
  String get accountFallbackName;

  /// No description provided for @accountFromLegacy.
  ///
  /// In en, this message translates to:
  /// **'Account migrated from the legacy system'**
  String get accountFromLegacy;

  /// No description provided for @accountCreatedInApp.
  ///
  /// In en, this message translates to:
  /// **'Account created in the app'**
  String get accountCreatedInApp;

  /// No description provided for @accountSignOut.
  ///
  /// In en, this message translates to:
  /// **'Sign out'**
  String get accountSignOut;

  /// No description provided for @accountSyncSection.
  ///
  /// In en, this message translates to:
  /// **'Sync'**
  String get accountSyncSection;

  /// No description provided for @accountSyncBody.
  ///
  /// In en, this message translates to:
  /// **'Upload your local records to the server.'**
  String get accountSyncBody;

  /// No description provided for @accountSyncing.
  ///
  /// In en, this message translates to:
  /// **'Syncing…'**
  String get accountSyncing;

  /// No description provided for @accountSyncNow.
  ///
  /// In en, this message translates to:
  /// **'Sync now'**
  String get accountSyncNow;

  /// No description provided for @accountHaveAccount.
  ///
  /// In en, this message translates to:
  /// **'I already have an account (migrated patient)'**
  String get accountHaveAccount;

  /// No description provided for @accountImNew.
  ///
  /// In en, this message translates to:
  /// **'I am new (sign me up)'**
  String get accountImNew;

  /// No description provided for @accountCreateAccount.
  ///
  /// In en, this message translates to:
  /// **'Create account'**
  String get accountCreateAccount;

  /// No description provided for @accountNewHere.
  ///
  /// In en, this message translates to:
  /// **'I\'m new (sign up)'**
  String get accountNewHere;

  /// No description provided for @accountDocumentOptional.
  ///
  /// In en, this message translates to:
  /// **'Document (optional)'**
  String get accountDocumentOptional;

  /// No description provided for @accountNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get accountNameLabel;

  /// No description provided for @accountEmailLabel.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get accountEmailLabel;

  /// No description provided for @deviceScreenTitle.
  ///
  /// In en, this message translates to:
  /// **'My measuring device'**
  String get deviceScreenTitle;

  /// No description provided for @deviceScreenDescription.
  ///
  /// In en, this message translates to:
  /// **'Choose the scale you use so we can interpret your measurements.'**
  String get deviceScreenDescription;

  /// No description provided for @deviceNoneTitle.
  ///
  /// In en, this message translates to:
  /// **'I don’t use one'**
  String get deviceNoneTitle;

  /// No description provided for @deviceNoneSubtitle.
  ///
  /// In en, this message translates to:
  /// **'I will only record manual measurements (weight, waist, height).'**
  String get deviceNoneSubtitle;

  /// No description provided for @deviceNoneSaved.
  ///
  /// In en, this message translates to:
  /// **'Saved: you don’t use bioimpedance.'**
  String get deviceNoneSaved;

  /// No description provided for @deviceCatalogError.
  ///
  /// In en, this message translates to:
  /// **'Could not refresh the catalogue. Showing the saved options.'**
  String get deviceCatalogError;

  /// No description provided for @deviceAvailableScales.
  ///
  /// In en, this message translates to:
  /// **'AVAILABLE SCALES'**
  String get deviceAvailableScales;

  /// No description provided for @deviceWhyItMatters.
  ///
  /// In en, this message translates to:
  /// **'Every bioimpedance scale interprets fat, muscle and visceral fat with its own ranges. Tell us which one you use so we can show whether your values are low, normal or high. You can change it whenever you like.'**
  String get deviceWhyItMatters;

  /// No description provided for @circumferencesSection.
  ///
  /// In en, this message translates to:
  /// **'BODY CIRCUMFERENCES (OPTIONAL)'**
  String get circumferencesSection;

  /// No description provided for @circWaist.
  ///
  /// In en, this message translates to:
  /// **'Waist'**
  String get circWaist;

  /// No description provided for @circHip.
  ///
  /// In en, this message translates to:
  /// **'Hip'**
  String get circHip;

  /// No description provided for @circLowerAbdomen.
  ///
  /// In en, this message translates to:
  /// **'Lower abdomen'**
  String get circLowerAbdomen;

  /// No description provided for @circArm.
  ///
  /// In en, this message translates to:
  /// **'Arm'**
  String get circArm;

  /// No description provided for @circLeg.
  ///
  /// In en, this message translates to:
  /// **'Leg'**
  String get circLeg;

  /// No description provided for @circChestBust.
  ///
  /// In en, this message translates to:
  /// **'Chest/Bust'**
  String get circChestBust;

  /// No description provided for @circAbdomenShort.
  ///
  /// In en, this message translates to:
  /// **'Abd.'**
  String get circAbdomenShort;

  /// No description provided for @lipidLabQuestion.
  ///
  /// In en, this message translates to:
  /// **'Which lab ran your test?'**
  String get lipidLabQuestion;

  /// No description provided for @lipidLabLoading.
  ///
  /// In en, this message translates to:
  /// **'Loading labs…'**
  String get lipidLabLoading;

  /// No description provided for @lipidLabNotSpecified.
  ///
  /// In en, this message translates to:
  /// **'Not specified / I don’t know'**
  String get lipidLabNotSpecified;

  /// No description provided for @lipidLabOther.
  ///
  /// In en, this message translates to:
  /// **'Other (specify)'**
  String get lipidLabOther;

  /// No description provided for @compositionSkeletalMuscle.
  ///
  /// In en, this message translates to:
  /// **'Skeletal muscle'**
  String get compositionSkeletalMuscle;

  /// No description provided for @compositionSkeletalMuscleRef.
  ///
  /// In en, this message translates to:
  /// **'As reported by your scale (%)'**
  String get compositionSkeletalMuscleRef;

  /// No description provided for @profileAppTheme.
  ///
  /// In en, this message translates to:
  /// **'App theme'**
  String get profileAppTheme;

  /// No description provided for @profileRankObserver.
  ///
  /// In en, this message translates to:
  /// **'Vital Observer'**
  String get profileRankObserver;

  /// No description provided for @themeBankLabel.
  ///
  /// In en, this message translates to:
  /// **'THEME LIBRARY'**
  String get themeBankLabel;

  /// No description provided for @themePickTitle.
  ///
  /// In en, this message translates to:
  /// **'Choose the look'**
  String get themePickTitle;

  /// No description provided for @themePickBody.
  ///
  /// In en, this message translates to:
  /// **'Changes colours and typography. Navigation, icons and the meaning of every colour stay exactly the same.'**
  String get themePickBody;

  /// No description provided for @themeSettingsBody.
  ///
  /// In en, this message translates to:
  /// **'The change applies instantly and is remembered. Navigation, icons and the meaning of every colour stay exactly the same.'**
  String get themeSettingsBody;

  /// No description provided for @themeContinueWith.
  ///
  /// In en, this message translates to:
  /// **'Continue with {theme}'**
  String themeContinueWith(String theme);

  /// No description provided for @deviceSelectedSaved.
  ///
  /// In en, this message translates to:
  /// **'{device} selected.'**
  String deviceSelectedSaved(String device);

  /// No description provided for @deviceWillSyncLater.
  ///
  /// In en, this message translates to:
  /// **'{message} It will sync once you are online.'**
  String deviceWillSyncLater(String message);

  /// No description provided for @introDemo.
  ///
  /// In en, this message translates to:
  /// **'Explore the demo'**
  String get introDemo;

  /// No description provided for @demoNoticeTitle.
  ///
  /// In en, this message translates to:
  /// **'You are in the demo'**
  String get demoNoticeTitle;

  /// No description provided for @demoNoticeBody.
  ///
  /// In en, this message translates to:
  /// **'Everything you see belongs to a fictional patient. Feel free to add or edit measurements: nothing is saved, and it all disappears when you leave the demo.'**
  String get demoNoticeBody;

  /// No description provided for @demoNoticeAction.
  ///
  /// In en, this message translates to:
  /// **'Got it'**
  String get demoNoticeAction;

  /// No description provided for @demoBannerLabel.
  ///
  /// In en, this message translates to:
  /// **'Demo data'**
  String get demoBannerLabel;

  /// No description provided for @demoExit.
  ///
  /// In en, this message translates to:
  /// **'Leave the demo'**
  String get demoExit;

  /// No description provided for @profileRankTier2.
  ///
  /// In en, this message translates to:
  /// **'Steady Caregiver'**
  String get profileRankTier2;

  /// No description provided for @profileRankTier3.
  ///
  /// In en, this message translates to:
  /// **'Wellness Veteran'**
  String get profileRankTier3;

  /// No description provided for @mhxDocTitle.
  ///
  /// In en, this message translates to:
  /// **'Personal Health Summary'**
  String get mhxDocTitle;

  /// No description provided for @mhxDocSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Consolidated report of self-reported measurements'**
  String get mhxDocSubtitle;

  /// No description provided for @mhxPatient.
  ///
  /// In en, this message translates to:
  /// **'Patient'**
  String get mhxPatient;

  /// No description provided for @mhxBirthDate.
  ///
  /// In en, this message translates to:
  /// **'Date of birth'**
  String get mhxBirthDate;

  /// No description provided for @mhxPeriodCovered.
  ///
  /// In en, this message translates to:
  /// **'Period covered'**
  String get mhxPeriodCovered;

  /// No description provided for @mhxGeneratedOn.
  ///
  /// In en, this message translates to:
  /// **'Generated on'**
  String get mhxGeneratedOn;

  /// No description provided for @mhxSource.
  ///
  /// In en, this message translates to:
  /// **'Source'**
  String get mhxSource;

  /// No description provided for @mhxGeneratedBy.
  ///
  /// In en, this message translates to:
  /// **'Generated by'**
  String get mhxGeneratedBy;

  /// No description provided for @mhxReportRef.
  ///
  /// In en, this message translates to:
  /// **'Report no.'**
  String get mhxReportRef;

  /// No description provided for @mhxSelfReported.
  ///
  /// In en, this message translates to:
  /// **'self-reported data'**
  String get mhxSelfReported;

  /// No description provided for @mhxDisclaimerTitle.
  ///
  /// In en, this message translates to:
  /// **'Informational summary - not a medical diagnosis'**
  String get mhxDisclaimerTitle;

  /// No description provided for @mhxDisclaimerBody.
  ///
  /// In en, this message translates to:
  /// **'This document was generated automatically from measurements recorded by the user. It is not a medical diagnosis or an official clinical record, and does not replace assessment by a healthcare professional.'**
  String get mhxDisclaimerBody;

  /// No description provided for @mhxSummaryTitle.
  ///
  /// In en, this message translates to:
  /// **'Summary of latest values'**
  String get mhxSummaryTitle;

  /// No description provided for @mhxColIndicator.
  ///
  /// In en, this message translates to:
  /// **'Indicator'**
  String get mhxColIndicator;

  /// No description provided for @mhxColLatest.
  ///
  /// In en, this message translates to:
  /// **'Latest value'**
  String get mhxColLatest;

  /// No description provided for @mhxColReference.
  ///
  /// In en, this message translates to:
  /// **'Reference'**
  String get mhxColReference;

  /// No description provided for @mhxColStatus.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get mhxColStatus;

  /// No description provided for @mhxColNotes.
  ///
  /// In en, this message translates to:
  /// **'Notes'**
  String get mhxColNotes;

  /// No description provided for @mhxBloodPressure.
  ///
  /// In en, this message translates to:
  /// **'Blood pressure'**
  String get mhxBloodPressure;

  /// No description provided for @mhxHeartRate.
  ///
  /// In en, this message translates to:
  /// **'Heart rate'**
  String get mhxHeartRate;

  /// No description provided for @mhxWeight.
  ///
  /// In en, this message translates to:
  /// **'Weight'**
  String get mhxWeight;

  /// No description provided for @mhxBmi.
  ///
  /// In en, this message translates to:
  /// **'BMI'**
  String get mhxBmi;

  /// No description provided for @mhxBodyFat.
  ///
  /// In en, this message translates to:
  /// **'Body fat'**
  String get mhxBodyFat;

  /// No description provided for @mhxVisceralFat.
  ///
  /// In en, this message translates to:
  /// **'Visceral fat'**
  String get mhxVisceralFat;

  /// No description provided for @mhxTotalCholesterol.
  ///
  /// In en, this message translates to:
  /// **'Total cholesterol'**
  String get mhxTotalCholesterol;

  /// No description provided for @mhxLdl.
  ///
  /// In en, this message translates to:
  /// **'LDL'**
  String get mhxLdl;

  /// No description provided for @mhxHdl.
  ///
  /// In en, this message translates to:
  /// **'HDL'**
  String get mhxHdl;

  /// No description provided for @mhxTriglycerides.
  ///
  /// In en, this message translates to:
  /// **'Triglycerides'**
  String get mhxTriglycerides;

  /// No description provided for @mhxSystolic.
  ///
  /// In en, this message translates to:
  /// **'Systolic'**
  String get mhxSystolic;

  /// No description provided for @mhxDiastolic.
  ///
  /// In en, this message translates to:
  /// **'Diastolic'**
  String get mhxDiastolic;

  /// No description provided for @mhxStatsMeasurements.
  ///
  /// In en, this message translates to:
  /// **'Measurements'**
  String get mhxStatsMeasurements;

  /// No description provided for @mhxStatsAverage.
  ///
  /// In en, this message translates to:
  /// **'Average'**
  String get mhxStatsAverage;

  /// No description provided for @mhxStatsRange.
  ///
  /// In en, this message translates to:
  /// **'Range'**
  String get mhxStatsRange;

  /// No description provided for @mhxStatsLatest.
  ///
  /// In en, this message translates to:
  /// **'Latest'**
  String get mhxStatsLatest;

  /// No description provided for @mhxFooterDisclaimer.
  ///
  /// In en, this message translates to:
  /// **'Data source: measurements entered by the patient through the MY VITALS app using personal devices that may not be clinically calibrated; their accuracy is not verified by a professional or an accredited laboratory. The reference ranges shown are indicative and may not apply to your individual situation; a value flagged outside the range is not a diagnosis. Do not make treatment decisions based on this document without professional supervision. It contains personal health data: the user is responsible for its safekeeping and sharing.'**
  String get mhxFooterDisclaimer;

  /// No description provided for @mhxButton.
  ///
  /// In en, this message translates to:
  /// **'Export complete medical history'**
  String get mhxButton;

  /// No description provided for @mhxHubHint.
  ///
  /// In en, this message translates to:
  /// **'One PDF with your four indicators to show your doctor.'**
  String get mhxHubHint;

  /// No description provided for @mhxChoosePeriod.
  ///
  /// In en, this message translates to:
  /// **'Choose the period'**
  String get mhxChoosePeriod;

  /// No description provided for @mhxPeriod6Months.
  ///
  /// In en, this message translates to:
  /// **'Last 6 months'**
  String get mhxPeriod6Months;

  /// No description provided for @mhxPeriod1Year.
  ///
  /// In en, this message translates to:
  /// **'Last year'**
  String get mhxPeriod1Year;

  /// No description provided for @mhxPeriodAll.
  ///
  /// In en, this message translates to:
  /// **'All history'**
  String get mhxPeriodAll;

  /// No description provided for @mhxGenerate.
  ///
  /// In en, this message translates to:
  /// **'Generate PDF'**
  String get mhxGenerate;

  /// No description provided for @mhxNoData.
  ///
  /// In en, this message translates to:
  /// **'There are no measurements to export yet.'**
  String get mhxNoData;

  /// No description provided for @mhxAgeYears.
  ///
  /// In en, this message translates to:
  /// **'{years} yr'**
  String mhxAgeYears(int years);

  /// No description provided for @mhxPageOf.
  ///
  /// In en, this message translates to:
  /// **'Page {current} of {total}'**
  String mhxPageOf(int current, int total);

  /// No description provided for @medicationsTitle.
  ///
  /// In en, this message translates to:
  /// **'Medications'**
  String get medicationsTitle;

  /// No description provided for @medicationsMenuTitle.
  ///
  /// In en, this message translates to:
  /// **'Medications'**
  String get medicationsMenuTitle;

  /// No description provided for @medicationAdd.
  ///
  /// In en, this message translates to:
  /// **'Add medication'**
  String get medicationAdd;

  /// No description provided for @medicationTaken.
  ///
  /// In en, this message translates to:
  /// **'Taken'**
  String get medicationTaken;

  /// No description provided for @medicationSkipped.
  ///
  /// In en, this message translates to:
  /// **'Skipped'**
  String get medicationSkipped;

  /// No description provided for @medicationRefill.
  ///
  /// In en, this message translates to:
  /// **'Refill'**
  String get medicationRefill;

  /// No description provided for @medicationDoseNotifTitle.
  ///
  /// In en, this message translates to:
  /// **'Time for {name}'**
  String medicationDoseNotifTitle(String name);

  /// No description provided for @medicationDoseNotifBody.
  ///
  /// In en, this message translates to:
  /// **'It\'s time to take your medication.'**
  String get medicationDoseNotifBody;

  /// No description provided for @medicationRefillNotifTitle.
  ///
  /// In en, this message translates to:
  /// **'Refill {name}'**
  String medicationRefillNotifTitle(String name);

  /// No description provided for @medicationRefillNotifBody.
  ///
  /// In en, this message translates to:
  /// **'Your stock is running low.'**
  String get medicationRefillNotifBody;

  /// No description provided for @medicationUnitsLeft.
  ///
  /// In en, this message translates to:
  /// **'{count} units left'**
  String medicationUnitsLeft(int count);

  /// No description provided for @medicationOutOfStock.
  ///
  /// In en, this message translates to:
  /// **'Out of stock'**
  String get medicationOutOfStock;

  /// No description provided for @medFormNameCapsule.
  ///
  /// In en, this message translates to:
  /// **'Capsule'**
  String get medFormNameCapsule;

  /// No description provided for @medFormNameTablet.
  ///
  /// In en, this message translates to:
  /// **'Tablet'**
  String get medFormNameTablet;

  /// No description provided for @medFormNameLiquid.
  ///
  /// In en, this message translates to:
  /// **'Liquid'**
  String get medFormNameLiquid;

  /// No description provided for @medFormNameInjection.
  ///
  /// In en, this message translates to:
  /// **'Injection'**
  String get medFormNameInjection;

  /// No description provided for @medFormNameDrops.
  ///
  /// In en, this message translates to:
  /// **'Drops'**
  String get medFormNameDrops;

  /// No description provided for @medFormNameOther.
  ///
  /// In en, this message translates to:
  /// **'Unit'**
  String get medFormNameOther;

  /// No description provided for @medUnitCapsule.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{capsule} other{capsules}}'**
  String medUnitCapsule(int count);

  /// No description provided for @medUnitTablet.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{tablet} other{tablets}}'**
  String medUnitTablet(int count);

  /// No description provided for @medUnitLiquid.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{ml} other{ml}}'**
  String medUnitLiquid(int count);

  /// No description provided for @medUnitInjection.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{injection} other{injections}}'**
  String medUnitInjection(int count);

  /// No description provided for @medUnitDrops.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{drop} other{drops}}'**
  String medUnitDrops(int count);

  /// No description provided for @medUnitOther.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{unit} other{units}}'**
  String medUnitOther(int count);

  /// No description provided for @medScheduleDaily.
  ///
  /// In en, this message translates to:
  /// **'Every day'**
  String get medScheduleDaily;

  /// No description provided for @medScheduleEveryNDays.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{Every day} other{Every {count} days}}'**
  String medScheduleEveryNDays(int count);

  /// No description provided for @medMenuDescription.
  ///
  /// In en, this message translates to:
  /// **'Manage your doses, your inventory and your adherence in one place.'**
  String get medMenuDescription;

  /// No description provided for @medMenuTodaySubtitle.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No doses pending} one{1 dose pending} other{{count} doses pending}}'**
  String medMenuTodaySubtitle(int count);

  /// No description provided for @medMenuInventorySubtitle.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{All stocked up} one{1 running low} other{{count} running low}}'**
  String medMenuInventorySubtitle(int count);

  /// No description provided for @medMenuAdherenceSubtitle.
  ///
  /// In en, this message translates to:
  /// **'{pct}% this month · {streak} day streak'**
  String medMenuAdherenceSubtitle(int pct, int streak);

  /// No description provided for @medTodayTitle.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get medTodayTitle;

  /// No description provided for @medTodayDescription.
  ///
  /// In en, this message translates to:
  /// **'Log today\'s doses and review what\'s done.'**
  String get medTodayDescription;

  /// No description provided for @medSectionToTakeToday.
  ///
  /// In en, this message translates to:
  /// **'TO TAKE TODAY'**
  String get medSectionToTakeToday;

  /// No description provided for @medSectionLogged.
  ///
  /// In en, this message translates to:
  /// **'LOGGED'**
  String get medSectionLogged;

  /// No description provided for @medSectionYourMeds.
  ///
  /// In en, this message translates to:
  /// **'YOUR MEDICATIONS'**
  String get medSectionYourMeds;

  /// No description provided for @medDosesProgress.
  ///
  /// In en, this message translates to:
  /// **'{done} of {total}'**
  String medDosesProgress(int done, int total);

  /// No description provided for @medNoPendingToday.
  ///
  /// In en, this message translates to:
  /// **'No doses left for today.'**
  String get medNoPendingToday;

  /// No description provided for @medInventoryTitle.
  ///
  /// In en, this message translates to:
  /// **'Inventory'**
  String get medInventoryTitle;

  /// No description provided for @medInventoryDescription.
  ///
  /// In en, this message translates to:
  /// **'How many units you have left and when to refill.'**
  String get medInventoryDescription;

  /// No description provided for @medSectionInventory.
  ///
  /// In en, this message translates to:
  /// **'INVENTORY'**
  String get medSectionInventory;

  /// No description provided for @medStockLeftUnits.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{1 unit left} other{{count} units left}}'**
  String medStockLeftUnits(int count);

  /// No description provided for @medRunsOutOn.
  ///
  /// In en, this message translates to:
  /// **'runs out {date}'**
  String medRunsOutOn(String date);

  /// No description provided for @medStockDonutOf.
  ///
  /// In en, this message translates to:
  /// **'of {total}'**
  String medStockDonutOf(int total);

  /// No description provided for @medAdherenceTitle.
  ///
  /// In en, this message translates to:
  /// **'Adherence'**
  String get medAdherenceTitle;

  /// No description provided for @medAdherenceDescription.
  ///
  /// In en, this message translates to:
  /// **'Your consistency with the treatment over the month.'**
  String get medAdherenceDescription;

  /// No description provided for @medComplianceMonth.
  ///
  /// In en, this message translates to:
  /// **'adherence · {month}'**
  String medComplianceMonth(String month);

  /// No description provided for @medStreakDays.
  ///
  /// In en, this message translates to:
  /// **'day streak'**
  String get medStreakDays;

  /// No description provided for @medLegendTaken.
  ///
  /// In en, this message translates to:
  /// **'Taken'**
  String get medLegendTaken;

  /// No description provided for @medLegendSkipped.
  ///
  /// In en, this message translates to:
  /// **'Missed'**
  String get medLegendSkipped;

  /// No description provided for @medLegendNoData.
  ///
  /// In en, this message translates to:
  /// **'No data'**
  String get medLegendNoData;

  /// No description provided for @medSectionSchedule.
  ///
  /// In en, this message translates to:
  /// **'SCHEDULE'**
  String get medSectionSchedule;

  /// No description provided for @medSectionAdherence.
  ///
  /// In en, this message translates to:
  /// **'ADHERENCE'**
  String get medSectionAdherence;

  /// No description provided for @medSectionInformation.
  ///
  /// In en, this message translates to:
  /// **'INFORMATION'**
  String get medSectionInformation;

  /// No description provided for @medRemainingUnits.
  ///
  /// In en, this message translates to:
  /// **'{count} units'**
  String medRemainingUnits(int count);

  /// No description provided for @medBuyBefore.
  ///
  /// In en, this message translates to:
  /// **'Buy before {date}'**
  String medBuyBefore(String date);

  /// No description provided for @medPackAndThreshold.
  ///
  /// In en, this message translates to:
  /// **'Box of {pack} · alert at: {threshold}'**
  String medPackAndThreshold(int pack, int threshold);

  /// No description provided for @medThisMonth.
  ///
  /// In en, this message translates to:
  /// **'this month'**
  String get medThisMonth;

  /// No description provided for @medEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get medEdit;

  /// No description provided for @medDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get medDelete;

  /// No description provided for @medDeleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete medication?'**
  String get medDeleteTitle;

  /// No description provided for @medDeleteBody.
  ///
  /// In en, this message translates to:
  /// **'This deletes the medication and all its history. This can\'t be undone.'**
  String get medDeleteBody;

  /// No description provided for @medInfoSoon.
  ///
  /// In en, this message translates to:
  /// **'Soon'**
  String get medInfoSoon;

  /// No description provided for @medInfoSoonBody.
  ///
  /// In en, this message translates to:
  /// **'Interactions, pregnancy and breastfeeding.'**
  String get medInfoSoonBody;

  /// No description provided for @medRegisterDose.
  ///
  /// In en, this message translates to:
  /// **'Log dose'**
  String get medRegisterDose;

  /// No description provided for @medDoseAtTime.
  ///
  /// In en, this message translates to:
  /// **'{amount} at {time}'**
  String medDoseAtTime(String amount, String time);

  /// No description provided for @medSkip.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get medSkip;

  /// No description provided for @medMultipleTitle.
  ///
  /// In en, this message translates to:
  /// **'{count} doses at {time}'**
  String medMultipleTitle(int count, String time);

  /// No description provided for @medMultipleSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Check each one or log them all at once.'**
  String get medMultipleSubtitle;

  /// No description provided for @medSkipRest.
  ///
  /// In en, this message translates to:
  /// **'Skip rest'**
  String get medSkipRest;

  /// No description provided for @medRegisterNSelected.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{Log doses} one{Log 1 dose} other{Log {count} doses}}'**
  String medRegisterNSelected(int count);

  /// No description provided for @medNotifTitle.
  ///
  /// In en, this message translates to:
  /// **'Turn on reminders'**
  String get medNotifTitle;

  /// No description provided for @medNotifBody.
  ///
  /// In en, this message translates to:
  /// **'We\'ll remind you at each dose time and when your stock is running low. You can change this anytime.'**
  String get medNotifBody;

  /// No description provided for @medNotifWebWarning.
  ///
  /// In en, this message translates to:
  /// **'Notifications aren\'t available on the web version. Use the iOS or Android app.'**
  String get medNotifWebWarning;

  /// No description provided for @medAllowNotifications.
  ///
  /// In en, this message translates to:
  /// **'Allow notifications'**
  String get medAllowNotifications;

  /// No description provided for @medNotNow.
  ///
  /// In en, this message translates to:
  /// **'Not now'**
  String get medNotNow;

  /// No description provided for @medWizardStepOf.
  ///
  /// In en, this message translates to:
  /// **'STEP {step} OF {total}'**
  String medWizardStepOf(int step, int total);

  /// No description provided for @medBack.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get medBack;

  /// No description provided for @medStepIdentity.
  ///
  /// In en, this message translates to:
  /// **'Identity'**
  String get medStepIdentity;

  /// No description provided for @medStepDose.
  ///
  /// In en, this message translates to:
  /// **'Dose'**
  String get medStepDose;

  /// No description provided for @medStepFrequency.
  ///
  /// In en, this message translates to:
  /// **'Frequency'**
  String get medStepFrequency;

  /// No description provided for @medStepDates.
  ///
  /// In en, this message translates to:
  /// **'Dates'**
  String get medStepDates;

  /// No description provided for @medStepInventory.
  ///
  /// In en, this message translates to:
  /// **'Inventory'**
  String get medStepInventory;

  /// No description provided for @medFieldName.
  ///
  /// In en, this message translates to:
  /// **'NAME'**
  String get medFieldName;

  /// No description provided for @medFieldForm.
  ///
  /// In en, this message translates to:
  /// **'FORM'**
  String get medFieldForm;

  /// No description provided for @medFieldStrength.
  ///
  /// In en, this message translates to:
  /// **'STRENGTH'**
  String get medFieldStrength;

  /// No description provided for @medFieldColorIcon.
  ///
  /// In en, this message translates to:
  /// **'COLOR & ICON'**
  String get medFieldColorIcon;

  /// No description provided for @medShapeCapsule.
  ///
  /// In en, this message translates to:
  /// **'Capsule'**
  String get medShapeCapsule;

  /// No description provided for @medShapeRound.
  ///
  /// In en, this message translates to:
  /// **'Round'**
  String get medShapeRound;

  /// No description provided for @medFieldReason.
  ///
  /// In en, this message translates to:
  /// **'WHAT FOR (OPTIONAL)'**
  String get medFieldReason;

  /// No description provided for @medFieldQtyPerDose.
  ///
  /// In en, this message translates to:
  /// **'AMOUNT PER DOSE'**
  String get medFieldQtyPerDose;

  /// No description provided for @medWithFood.
  ///
  /// In en, this message translates to:
  /// **'Take with food'**
  String get medWithFood;

  /// No description provided for @medWithFoodSub.
  ///
  /// In en, this message translates to:
  /// **'Hint in the reminder'**
  String get medWithFoodSub;

  /// No description provided for @medSpecialInstruction.
  ///
  /// In en, this message translates to:
  /// **'Special instruction'**
  String get medSpecialInstruction;

  /// No description provided for @medSpecialInstructionSub.
  ///
  /// In en, this message translates to:
  /// **'E.g. dissolve in water'**
  String get medSpecialInstructionSub;

  /// No description provided for @medFreqDaily.
  ///
  /// In en, this message translates to:
  /// **'Daily'**
  String get medFreqDaily;

  /// No description provided for @medFreqSpecificDays.
  ///
  /// In en, this message translates to:
  /// **'Specific days'**
  String get medFreqSpecificDays;

  /// No description provided for @medFreqEveryNDays.
  ///
  /// In en, this message translates to:
  /// **'Every N days'**
  String get medFreqEveryNDays;

  /// No description provided for @medFieldWeekdays.
  ///
  /// In en, this message translates to:
  /// **'DAYS OF THE WEEK'**
  String get medFieldWeekdays;

  /// No description provided for @medFieldDoseTimes.
  ///
  /// In en, this message translates to:
  /// **'DOSE TIMES'**
  String get medFieldDoseTimes;

  /// No description provided for @medAddTime.
  ///
  /// In en, this message translates to:
  /// **'Add time'**
  String get medAddTime;

  /// No description provided for @medIntervalLabel.
  ///
  /// In en, this message translates to:
  /// **'Every how many days'**
  String get medIntervalLabel;

  /// No description provided for @medFieldStart.
  ///
  /// In en, this message translates to:
  /// **'START'**
  String get medFieldStart;

  /// No description provided for @medWithEndDate.
  ///
  /// In en, this message translates to:
  /// **'With end date'**
  String get medWithEndDate;

  /// No description provided for @medWithEndDateSub.
  ///
  /// In en, this message translates to:
  /// **'End the treatment on a date'**
  String get medWithEndDateSub;

  /// No description provided for @medFieldEnd.
  ///
  /// In en, this message translates to:
  /// **'END'**
  String get medFieldEnd;

  /// No description provided for @medTrackInventory.
  ///
  /// In en, this message translates to:
  /// **'Track inventory'**
  String get medTrackInventory;

  /// No description provided for @medTrackInventorySub.
  ///
  /// In en, this message translates to:
  /// **'Deduct stock on each dose'**
  String get medTrackInventorySub;

  /// No description provided for @medCurrentUnits.
  ///
  /// In en, this message translates to:
  /// **'Current units'**
  String get medCurrentUnits;

  /// No description provided for @medAlertWhenRemaining.
  ///
  /// In en, this message translates to:
  /// **'Alert me when I have'**
  String get medAlertWhenRemaining;

  /// No description provided for @medLeadTimeDays.
  ///
  /// In en, this message translates to:
  /// **'Lead time (days)'**
  String get medLeadTimeDays;

  /// No description provided for @medPackSize.
  ///
  /// In en, this message translates to:
  /// **'Box size'**
  String get medPackSize;

  /// No description provided for @medRefillAlerts.
  ///
  /// In en, this message translates to:
  /// **'Refill alerts'**
  String get medRefillAlerts;

  /// No description provided for @medRefillAlertsSub.
  ///
  /// In en, this message translates to:
  /// **'With an estimated deadline'**
  String get medRefillAlertsSub;

  /// No description provided for @medSaveMedication.
  ///
  /// In en, this message translates to:
  /// **'Save medication'**
  String get medSaveMedication;

  /// No description provided for @medContinue.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get medContinue;

  /// No description provided for @medErrorNameRequired.
  ///
  /// In en, this message translates to:
  /// **'Enter a name'**
  String get medErrorNameRequired;

  /// No description provided for @medErrorSelectDays.
  ///
  /// In en, this message translates to:
  /// **'Pick at least one day'**
  String get medErrorSelectDays;

  /// No description provided for @medErrorAddTime.
  ///
  /// In en, this message translates to:
  /// **'Add at least one time'**
  String get medErrorAddTime;

  /// No description provided for @medUnitsSuffix.
  ///
  /// In en, this message translates to:
  /// **'units'**
  String get medUnitsSuffix;

  /// No description provided for @medRefillTitle.
  ///
  /// In en, this message translates to:
  /// **'Refill inventory'**
  String get medRefillTitle;

  /// No description provided for @medRunsOutInDays.
  ///
  /// In en, this message translates to:
  /// **'Runs out in ~{days, plural, one{1 day} other{{days} days}}'**
  String medRunsOutInDays(int days);

  /// No description provided for @medAddABox.
  ///
  /// In en, this message translates to:
  /// **'Add a box'**
  String get medAddABox;

  /// No description provided for @medAddABoxSub.
  ///
  /// In en, this message translates to:
  /// **'Adds to the current stock'**
  String get medAddABoxSub;

  /// No description provided for @medWillRemain.
  ///
  /// In en, this message translates to:
  /// **'{units} units left · lasts ~{days} days'**
  String medWillRemain(int units, int days);

  /// No description provided for @medRemindOneDay.
  ///
  /// In en, this message translates to:
  /// **'Remind me in 1 day'**
  String get medRemindOneDay;

  /// No description provided for @medBought.
  ///
  /// In en, this message translates to:
  /// **'I bought it'**
  String get medBought;

  /// No description provided for @medEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No medications yet'**
  String get medEmptyTitle;

  /// No description provided for @medEmptyBody.
  ///
  /// In en, this message translates to:
  /// **'Add your first medication and we\'ll remind you of every dose and warn you before it runs out.'**
  String get medEmptyBody;

  /// No description provided for @medDashTodayLabel.
  ///
  /// In en, this message translates to:
  /// **'TODAY\'S DOSES'**
  String get medDashTodayLabel;

  /// No description provided for @medDashSeeModule.
  ///
  /// In en, this message translates to:
  /// **'See module ›'**
  String get medDashSeeModule;

  /// No description provided for @medDashNextDose.
  ///
  /// In en, this message translates to:
  /// **'Next dose'**
  String get medDashNextDose;

  /// No description provided for @medDashNoDoses.
  ///
  /// In en, this message translates to:
  /// **'No upcoming doses'**
  String get medDashNoDoses;

  /// No description provided for @medLowStockBannerTitle.
  ///
  /// In en, this message translates to:
  /// **'{name} has {count} units left'**
  String medLowStockBannerTitle(String name, int count);

  /// No description provided for @medDashMedsTitle.
  ///
  /// In en, this message translates to:
  /// **'Medications'**
  String get medDashMedsTitle;

  /// No description provided for @medDashApptsTitle.
  ///
  /// In en, this message translates to:
  /// **'Medical appointments'**
  String get medDashApptsTitle;

  /// No description provided for @medDashApptsSoon.
  ///
  /// In en, this message translates to:
  /// **'Coming soon'**
  String get medDashApptsSoon;

  /// No description provided for @medDashTodayProgress.
  ///
  /// In en, this message translates to:
  /// **'{done}/{total} today'**
  String medDashTodayProgress(int done, int total);

  /// No description provided for @medDashStreakShort.
  ///
  /// In en, this message translates to:
  /// **'{days} d'**
  String medDashStreakShort(int days);

  /// No description provided for @medDashAllDone.
  ///
  /// In en, this message translates to:
  /// **'All caught up'**
  String get medDashAllDone;

  /// No description provided for @medDashAddMed.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get medDashAddMed;

  /// No description provided for @medDashLowShort.
  ///
  /// In en, this message translates to:
  /// **'{count} left'**
  String medDashLowShort(int count);

  /// No description provided for @appointmentsTitle.
  ///
  /// In en, this message translates to:
  /// **'My appointments'**
  String get appointmentsTitle;

  /// No description provided for @appointmentsDescription.
  ///
  /// In en, this message translates to:
  /// **'Keep track of the appointments you have and the ones you still need to book.'**
  String get appointmentsDescription;

  /// No description provided for @appointmentsAddCta.
  ///
  /// In en, this message translates to:
  /// **'Add appointment'**
  String get appointmentsAddCta;

  /// No description provided for @appointmentsSectionToBook.
  ///
  /// In en, this message translates to:
  /// **'To book'**
  String get appointmentsSectionToBook;

  /// No description provided for @appointmentsSectionScheduled.
  ///
  /// In en, this message translates to:
  /// **'Scheduled'**
  String get appointmentsSectionScheduled;

  /// No description provided for @appointmentsSectionHistory.
  ///
  /// In en, this message translates to:
  /// **'History'**
  String get appointmentsSectionHistory;

  /// No description provided for @appointmentsEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No appointments yet'**
  String get appointmentsEmptyTitle;

  /// No description provided for @appointmentsEmptyBody.
  ///
  /// In en, this message translates to:
  /// **'Add the appointments you need to book or have already scheduled.'**
  String get appointmentsEmptyBody;

  /// No description provided for @appointmentsOverdueChip.
  ///
  /// In en, this message translates to:
  /// **'Overdue'**
  String get appointmentsOverdueChip;

  /// No description provided for @appointmentDueOn.
  ///
  /// In en, this message translates to:
  /// **'Book before {date}'**
  String appointmentDueOn(String date);

  /// No description provided for @appointmentNoDate.
  ///
  /// In en, this message translates to:
  /// **'No date'**
  String get appointmentNoDate;

  /// No description provided for @appointmentScheduledOn.
  ///
  /// In en, this message translates to:
  /// **'{date} at {time}'**
  String appointmentScheduledOn(String date, String time);

  /// No description provided for @appointmentStatusAttended.
  ///
  /// In en, this message translates to:
  /// **'Attended'**
  String get appointmentStatusAttended;

  /// No description provided for @appointmentStatusMissed.
  ///
  /// In en, this message translates to:
  /// **'Missed'**
  String get appointmentStatusMissed;

  /// No description provided for @appointmentStatusCancelled.
  ///
  /// In en, this message translates to:
  /// **'Cancelled'**
  String get appointmentStatusCancelled;

  /// No description provided for @appointmentActionBook.
  ///
  /// In en, this message translates to:
  /// **'I booked it'**
  String get appointmentActionBook;

  /// No description provided for @appointmentActionPostpone.
  ///
  /// In en, this message translates to:
  /// **'Postpone'**
  String get appointmentActionPostpone;

  /// No description provided for @appointmentActionAttended.
  ///
  /// In en, this message translates to:
  /// **'I attended'**
  String get appointmentActionAttended;

  /// No description provided for @appointmentActionMissed.
  ///
  /// In en, this message translates to:
  /// **'I missed it'**
  String get appointmentActionMissed;

  /// No description provided for @appointmentActionDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get appointmentActionDelete;

  /// No description provided for @appointmentDeleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete this appointment?'**
  String get appointmentDeleteTitle;

  /// No description provided for @appointmentAddTitle.
  ///
  /// In en, this message translates to:
  /// **'New appointment'**
  String get appointmentAddTitle;

  /// No description provided for @appointmentModeToBook.
  ///
  /// In en, this message translates to:
  /// **'I need to book it'**
  String get appointmentModeToBook;

  /// No description provided for @appointmentModeScheduled.
  ///
  /// In en, this message translates to:
  /// **'I have a date'**
  String get appointmentModeScheduled;

  /// No description provided for @appointmentFieldTitle.
  ///
  /// In en, this message translates to:
  /// **'Title'**
  String get appointmentFieldTitle;

  /// No description provided for @appointmentFieldTitleHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Endocrinology check-up'**
  String get appointmentFieldTitleHint;

  /// No description provided for @appointmentFieldSpecialty.
  ///
  /// In en, this message translates to:
  /// **'Specialty'**
  String get appointmentFieldSpecialty;

  /// No description provided for @appointmentFieldSpecialtyHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Endocrinology'**
  String get appointmentFieldSpecialtyHint;

  /// No description provided for @appointmentFieldDate.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get appointmentFieldDate;

  /// No description provided for @appointmentFieldTargetDate.
  ///
  /// In en, this message translates to:
  /// **'Target date to book'**
  String get appointmentFieldTargetDate;

  /// No description provided for @appointmentFieldProvider.
  ///
  /// In en, this message translates to:
  /// **'Doctor or place'**
  String get appointmentFieldProvider;

  /// No description provided for @appointmentFieldNotes.
  ///
  /// In en, this message translates to:
  /// **'Notes'**
  String get appointmentFieldNotes;

  /// No description provided for @appointmentPickDate.
  ///
  /// In en, this message translates to:
  /// **'Pick date'**
  String get appointmentPickDate;

  /// No description provided for @appointmentPickTime.
  ///
  /// In en, this message translates to:
  /// **'Pick time'**
  String get appointmentPickTime;

  /// No description provided for @appointmentTitleRequired.
  ///
  /// In en, this message translates to:
  /// **'Enter a title for the appointment'**
  String get appointmentTitleRequired;

  /// No description provided for @appointmentDateRequired.
  ///
  /// In en, this message translates to:
  /// **'Pick a date'**
  String get appointmentDateRequired;

  /// No description provided for @appointmentSave.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get appointmentSave;

  /// No description provided for @apptDashAdd.
  ///
  /// In en, this message translates to:
  /// **'Add appointment'**
  String get apptDashAdd;

  /// No description provided for @apptDashNextTitle.
  ///
  /// In en, this message translates to:
  /// **'Next appointment'**
  String get apptDashNextTitle;

  /// No description provided for @apptDashToBookTitle.
  ///
  /// In en, this message translates to:
  /// **'To book'**
  String get apptDashToBookTitle;

  /// No description provided for @apptDashOverdue.
  ///
  /// In en, this message translates to:
  /// **'Overdue'**
  String get apptDashOverdue;

  /// No description provided for @apptDashAllClear.
  ///
  /// In en, this message translates to:
  /// **'All up to date'**
  String get apptDashAllClear;

  /// No description provided for @apptScheduledNotifTitle.
  ///
  /// In en, this message translates to:
  /// **'Appointment: {title}'**
  String apptScheduledNotifTitle(String title);

  /// No description provided for @apptScheduledNotifBody.
  ///
  /// In en, this message translates to:
  /// **'You have an upcoming appointment.'**
  String get apptScheduledNotifBody;

  /// No description provided for @apptToBookNotifTitle.
  ///
  /// In en, this message translates to:
  /// **'Time to book: {title}'**
  String apptToBookNotifTitle(String title);

  /// No description provided for @apptToBookNotifBody.
  ///
  /// In en, this message translates to:
  /// **'Time to book this appointment.'**
  String get apptToBookNotifBody;

  /// No description provided for @apptOverdueNotifTitle.
  ///
  /// In en, this message translates to:
  /// **'Pending appointment: {title}'**
  String apptOverdueNotifTitle(String title);

  /// No description provided for @apptOverdueNotifBody.
  ///
  /// In en, this message translates to:
  /// **'You have an overdue appointment.'**
  String get apptOverdueNotifBody;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['de', 'en', 'es', 'it', 'pt'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'de':
      return AppLocalizationsDe();
    case 'en':
      return AppLocalizationsEn();
    case 'es':
      return AppLocalizationsEs();
    case 'it':
      return AppLocalizationsIt();
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
