// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'My Vitals';

  @override
  String get dashboard => 'Dashboard';

  @override
  String get history => 'History';

  @override
  String get record => 'Record';

  @override
  String get discover => 'Discover';

  @override
  String get profile => 'Profile';

  @override
  String get language => 'Language';

  @override
  String get savePreferences => 'Save Preferences';

  @override
  String get selectLanguage => 'Select your preferred language';

  @override
  String get personalInfo => 'Personal Info';

  @override
  String get measurementUnits => 'Measurement Units';

  @override
  String get notifications => 'Notifications';

  @override
  String get privacySecurity => 'Privacy & Security';

  @override
  String get helpSupport => 'Help & Support';

  @override
  String get logOut => 'Log Out';

  @override
  String level(int value) {
    return 'Level $value';
  }

  @override
  String get newUserInfo => 'New User';

  @override
  String xpForNextLevel(int current, int total) {
    return '$current / $total XP for next level';
  }

  @override
  String get levelProgress => 'Level Progress';

  @override
  String get vitalSigns => 'Vital Signs';

  @override
  String get vitalsSubtitle => 'Blood pressure & Heart rate';

  @override
  String get noDataYet => 'No data recorded yet.';

  @override
  String get recordVitalsAction => 'Record your pressure and rate ›';

  @override
  String get bodyComposition => 'Body Composition';

  @override
  String get compositionSubtitle => 'Fat, muscle, water and bone mass.';

  @override
  String get completeBodyProfile => 'Complete your body profile ›';

  @override
  String get anthropometricHistory => 'Anthropometric History';

  @override
  String get anthroSubtitle =>
      'Measure your weight, height and physical progress.';

  @override
  String get recordFirstMeasure => 'Record your first measurement ›';

  @override
  String get lipidProfile => 'Lipid Profile';

  @override
  String get lipidSubtitle => 'Monitor your cholesterol and triglycerides.';

  @override
  String get recordLabResults => 'Record your lab results ›';

  @override
  String get medicalDisclaimerTitle => 'Medical Disclaimer';

  @override
  String get medicalDisclaimerText =>
      'This application is for informational and personal tracking purposes only. It is not a substitute for professional medical advice, diagnosis, or treatment. Always seek the advice of your physician or other qualified health provider with any questions.';

  @override
  String get selfCareProgress => 'Self-care Progress';

  @override
  String get myHealthAchievements => 'My Health Achievements';

  @override
  String get badgeFirstStep => 'First Step';

  @override
  String get badgeFirstStepDesc => 'Beginning of the journey';

  @override
  String get badgeStrongHeart => 'Strong Heart';

  @override
  String get badgeStrongHeartDesc => 'Cardio Health';

  @override
  String get badgeVitalHabit => 'Vital Habit';

  @override
  String get badgeVitalHabitDesc => '7 days in a row';

  @override
  String get badgeAwareness => 'Awareness';

  @override
  String get badgeAwarenessDesc => 'Big Picture';

  @override
  String get badgeBalance => 'Balance';

  @override
  String get badgeBalanceDesc => 'Body goal';

  @override
  String get badgeGuardian => 'Guardian';

  @override
  String get badgeGuardianDesc => 'Commitment';

  @override
  String get metricSystem => 'Metric (kg, cm, °C)';

  @override
  String get registerIndicators => 'Register Indicators';

  @override
  String get anthropometry => 'Anthropometry';

  @override
  String get unitOfMeasureTitle => 'Unit of Measure';

  @override
  String get unitOfMeasureDescription =>
      'How do you prefer to see your measurements? Select the system that best suits you for accurate health tracking.';

  @override
  String get metricOption => 'Metric (kg, cm)';

  @override
  String get metricSubtitle => 'Kilograms and centimeters';

  @override
  String get imperialOption => 'Imperial (lb, ft/in)';

  @override
  String get imperialSubtitle => 'Pounds and feet/inches';

  @override
  String get continueAction => 'Continue';

  @override
  String get languageTitle => 'Language Selection';

  @override
  String get languageDescription =>
      'Select your preferred language to adapt the application to your needs. You can change it at any time from this screen.';

  @override
  String get profileImageTitle => 'Profile Image';

  @override
  String get gallery => 'Gallery';

  @override
  String get camera => 'Camera';

  @override
  String get deletePhoto => 'Delete photo';

  @override
  String get cancel => 'Cancel';

  @override
  String get personalInfoTitle => 'Personal Information';

  @override
  String get personalInfoDescription =>
      'Keep your details up to date to receive more accurate and personalized health recommendations.';

  @override
  String get fullName => 'Full name';

  @override
  String get birthDate => 'Date of birth';

  @override
  String get emailOptional => 'Email (Optional)';

  @override
  String get phoneOptional => 'Phone (Optional)';

  @override
  String get selectCountry => 'Select your country';

  @override
  String get searchCountry => 'Search country';

  @override
  String get gender => 'Gender';

  @override
  String get male => 'Male';

  @override
  String get female => 'Female';

  @override
  String get other => 'Other';

  @override
  String get activityLevel => 'Activity Level';

  @override
  String get activitySedentary => 'Sedentary';

  @override
  String get activityLightlyActive => 'Lightly Active';

  @override
  String get activityModeratelyActive => 'Moderately Active';

  @override
  String get activityVeryActive => 'Very Active';

  @override
  String get activityExtraActive => 'Extra Active';

  @override
  String get selectDate => 'Select date';

  @override
  String get recordAnthropometricTitle => 'ANTHROPOMETRIC MEASURES';

  @override
  String get dateTimeOfMeasurement => 'DATE AND TIME OF MEASUREMENT';

  @override
  String get dateLabel => 'Date';

  @override
  String get timeLabel => 'Time';

  @override
  String get bodyMeasurements => 'BODY MEASUREMENTS';

  @override
  String get weightLabel => 'Weight';

  @override
  String get heightLabel => 'Height';

  @override
  String get bmiTitle => 'Body Mass Index (BMI)';

  @override
  String get manual => 'Manual';

  @override
  String get bmiLow => 'LOW';

  @override
  String get bmiNormal => 'NORMAL';

  @override
  String get bmiOverweight => 'OVERWEIGHT';

  @override
  String get bmiObesity => 'OBESITY';

  @override
  String get commentOptional => 'COMMENT (OPTIONAL)';

  @override
  String get commentHint => 'Any observations about this measurement?';

  @override
  String get saveAndEarnXp => 'Save and earn +10 XP';

  @override
  String get historyGoodJob => 'Good job!';

  @override
  String get historyGoalProgress =>
      'You have recorded a new measurement this month, staying on your wellness track.';

  @override
  String historyWeightLoss(String weight) {
    return 'You lost ${weight}kg this month, getting closer to your wellness goal.';
  }

  @override
  String get historyBmiTrend => 'BMI TREND';

  @override
  String get historyLast6Months => 'Last 6 months';

  @override
  String get historyTargetZone => 'Target Zone';

  @override
  String get historyBmiUnit => 'BMI';

  @override
  String get historyExportPdf => 'Export to PDF';

  @override
  String get historyExportCsv => 'Excel (CSV)';

  @override
  String get historyMeasurements => 'MEASUREMENT HISTORY';

  @override
  String get historyNoMeasurements =>
      'No measurements yet. Record your first one to start your history.';

  @override
  String get historyColDate => 'Date';

  @override
  String get historyColWeight => 'Weight (kg)';

  @override
  String get historyColBmi => 'BMI';

  @override
  String get historyColCategory => 'Category';

  @override
  String get historyUnknown => 'Unknown';

  @override
  String get historyPdfTitle => 'Anthropometric History';

  @override
  String get historyShareCsvSubject => 'Measurement History CSV';

  @override
  String get historyBmiLabel => 'BMI';

  @override
  String get recordVitalSignsTitle => 'VITAL SIGNS';

  @override
  String get bloodPressureTitle => 'BLOOD PRESSURE (MMHG)';

  @override
  String get systolicLabel => 'SYSTOLIC';

  @override
  String get diastolicLabel => 'DIASTOLIC';

  @override
  String get heartRateTitle => 'HEART RATE (BPM)';

  @override
  String get contextAndSymptoms => 'CONTEXT & SYMPTOMS';

  @override
  String get activityState => 'ACTIVITY STATE';

  @override
  String get activityRest => 'Rest';

  @override
  String get activityExercise => 'Exercise';

  @override
  String get activityPostOp => 'Post-op';

  @override
  String get howDoYouFeel => 'HOW DO YOU FEEL?';

  @override
  String get symptomNormal => 'Normal';

  @override
  String get symptomDizziness => 'Dizziness';

  @override
  String get symptomPain => 'Pain';

  @override
  String get symptomFatigue => 'Fatigue';

  @override
  String get bpLow => 'LOW';

  @override
  String get bpNormal => 'NORMAL';

  @override
  String get bpElevated => 'ELEVATED';

  @override
  String get bpHigh => 'HIGH';

  @override
  String get hrLow => 'LOW';

  @override
  String get hrNormal => 'NORMAL';

  @override
  String get hrHigh => 'HIGH';

  @override
  String get vitalsSavedSuccess => 'Vital signs saved successfully.';

  @override
  String get lipidProfileTitle => 'LIPID PROFILE';

  @override
  String get lipidInfoBanner =>
      'Enter the values from your latest lab test. All fields are optional, but filling them all in gives a more complete picture of your cardiovascular health.';

  @override
  String get lipidLabInfo => 'LABORATORY INFORMATION';

  @override
  String get lipidLabName => 'Laboratory Name';

  @override
  String get lipidLabNameHint => 'E.g. City Clinical Lab';

  @override
  String get lipidResultsTitle => 'ANALYSIS RESULTS (mg/dL)';

  @override
  String get lipidTotalCholesterol => 'Total Cholesterol';

  @override
  String get lipidTcRef => 'Ref: < 200 mg/dL';

  @override
  String get lipidLdl => 'LDL (\"Bad\" Cholesterol)';

  @override
  String get lipidLdlRef => 'Ref: < 100 mg/dL';

  @override
  String get lipidHdl => 'HDL (\"Good\" Cholesterol)';

  @override
  String get lipidHdlRef => 'Ref: ≥ 60 mg/dL';

  @override
  String get lipidVldl => 'VLDL';

  @override
  String get lipidVldlRef => 'Ref: 2 – 30 mg/dL';

  @override
  String get lipidTriglycerides => 'Triglycerides';

  @override
  String get lipidTrigsRef => 'Ref: < 150 mg/dL';

  @override
  String get lipidStatusOptimal => 'OPTIMAL';

  @override
  String get lipidStatusNearOptimal => 'ACCEPTABLE';

  @override
  String get lipidStatusBorderline => 'BORDERLINE';

  @override
  String get lipidStatusHigh => 'HIGH';

  @override
  String get lipidStatusLow => 'LOW';

  @override
  String get lipidStatusProtective => 'PROTECTIVE';

  @override
  String get lipidStatusAcceptable => 'ACCEPTABLE';

  @override
  String get lipidOverallRisk => 'OVERALL ASSESSMENT';

  @override
  String get lipidOverallDesc =>
      'Based on the values entered. Always consult your doctor.';

  @override
  String get lipidAtLeastOneValue =>
      'Enter at least one value to save the record.';

  @override
  String get lipidSavedSuccess => 'Lipid profile saved successfully.';

  @override
  String get compositionTitle => 'BODY PROFILE';

  @override
  String get compositionInfoBanner =>
      'Enter the values from your body composition analyzer (e.g. bioimpedance scale). All fields are optional — record whatever your device provides.';

  @override
  String get compositionDevice => 'MEASUREMENT DEVICE';

  @override
  String get compositionDeviceHint => 'E.g. OMRON HBF-514C scale';

  @override
  String get compositionBodyFat => 'BODY FAT PERCENTAGE (%)';

  @override
  String get compositionMuscleMass => 'MUSCLE MASS (KG)';

  @override
  String get compositionVisceralAndAge => 'VISCERAL FAT & METABOLIC AGE';

  @override
  String get compositionVisceralFat => 'VISCERAL FAT';

  @override
  String get compositionLevel => 'Level';

  @override
  String get compositionMetabolicAge => 'METABOLIC AGE';

  @override
  String get compositionYears => 'Years';

  @override
  String get compositionOptionalSection => 'OPTIONAL (BODY WATER & BONE MASS)';

  @override
  String get compositionBodyWater => 'Body Water';

  @override
  String get compositionBodyWaterRef => 'Ref: 50–65 %';

  @override
  String get compositionBoneMass => 'Bone Mass';

  @override
  String get compositionBoneMassRef => 'Ref: 2–4 kg';

  @override
  String get compositionBmr => 'BASAL METABOLIC RATE (KCAL)';

  @override
  String get compositionBmrSubtitle =>
      'ESTIMATE BASED ON YOUR CURRENT BODY COMPOSITION';

  @override
  String get fatVeryLow => 'VERY LOW';

  @override
  String get fatLow => 'LOW';

  @override
  String get fatNormal => 'NORMAL';

  @override
  String get fatElevated => 'ELEVATED';

  @override
  String get fatHigh => 'HIGH';

  @override
  String get infoBannerAnthro =>
      'Try to take the measurement every time under the same conditions, for example: every morning after waking up, going to the bathroom, and before breakfast.';

  @override
  String get infoBannerVitals =>
      'Try to take your vital signs after resting for half an hour.';

  @override
  String get compositionSavedSuccess => 'Body profile saved successfully.';

  @override
  String discoverGreeting(String name) {
    return 'Good morning, $name';
  }

  @override
  String get discoverSearchHint => 'Search for tips...';

  @override
  String get discoverDailyTip => 'DAILY HEALTH TIP';

  @override
  String get discoverReadMore => 'Read more';

  @override
  String get discoverRecommended => 'Recommended for you';

  @override
  String get discoverCategoryAll => 'All';

  @override
  String get discoverCategoryHeart => 'Heart Health';

  @override
  String get discoverCategoryNutrition => 'Nutrition';

  @override
  String get discoverCategoryEmotional => 'Emotional Health';

  @override
  String get discoverCategorySports => 'Sports';

  @override
  String get discoverCategorySleep => 'Sleep';

  @override
  String get discoverMinRead => 'MIN READ';

  @override
  String get discoverFeatured => 'Featured';

  @override
  String get discoverRoutines => 'Routines';

  @override
  String get discoverArticles => 'Articles';

  @override
  String get discoverChallenges => 'Challenges';

  @override
  String get discoverSeeAll => 'See all';

  @override
  String get discoverMinShort => 'min';

  @override
  String get discoverStart => 'Start';

  @override
  String get discoverJoin => 'Join';

  @override
  String get discoverLevelBeginner => 'Beginner';

  @override
  String get discoverLevelIntermediate => 'Intermediate';

  @override
  String get discoverLevelAdvanced => 'Advanced';

  @override
  String get discoverStatusActive => 'Active';

  @override
  String get discoverStatusScheduled => 'Scheduled';

  @override
  String get discoverStatusFinished => 'Finished';

  @override
  String get discoverEmpty => 'No content available yet.';

  @override
  String discoverExercises(String count) {
    return '$count exercises';
  }

  @override
  String discoverParticipants(String count) {
    return '$count participants';
  }

  @override
  String discoverDaysShort(String count) {
    return '$count days';
  }

  @override
  String get privacySecurityDescription =>
      'Manage how your medical and personal information is protected.';

  @override
  String get biometricLockTitle => 'Biometric Lock';

  @override
  String get biometricLockSubtitle =>
      'Requires Fingerprint or FaceID on app startup';

  @override
  String get biometricReasoning =>
      'Your medical records are highly sensitive information. Enabling biometric lock ensures only you can access your health data, protecting your privacy.';

  @override
  String get unlockAppToContinue => 'Unlock to continue';

  @override
  String get biometricNotAvailable =>
      'Biometrics not available on this device.';

  @override
  String get healthGoalsTitle => 'Health Goals';

  @override
  String get healthGoalsDescription =>
      'Set your medical objectives to track your progress.';

  @override
  String get medicalGoalsToggle => 'Enable Medical Goals';

  @override
  String get medicalGoalsSubtitle =>
      'Enable to set weight and body composition goals';

  @override
  String get targetWeight => 'Target Weight';

  @override
  String get targetBodyFat => 'Target Body Fat';

  @override
  String get targetMuscleMass => 'Target Muscle Mass';

  @override
  String get targetVisceralFat => 'Target Visceral Fat';

  @override
  String get goalsSavedSuccess => 'Goals saved successfully.';

  @override
  String get helpSupportPageTitle => 'Help & Support';

  @override
  String get helpSupportPageDescription =>
      'Everything you need to know about My Vitals.';

  @override
  String get helpFaqTitle => 'Frequently Asked Questions';

  @override
  String get helpFaqDescription =>
      'Quick answers to the most common questions.';

  @override
  String get helpGlossaryTitle => 'Medical Glossary';

  @override
  String get helpGlossaryDescription => 'Understand every health indicator.';

  @override
  String get helpLegalTitle => 'Legal Notice';

  @override
  String get helpLegalDescription => 'Terms of use and data privacy.';

  @override
  String get helpContactTitle => 'Contact & Feedback';

  @override
  String get helpContactDescription => 'Write to us, we improve together.';

  @override
  String get helpSearchHint => 'Search...';

  @override
  String get helpNoResults => 'No results for your search.';

  @override
  String get helpFaqCatGeneral => 'General';

  @override
  String get helpFaqCatData => 'My Data';

  @override
  String get helpFaqCatBiometrics => 'Biometrics';

  @override
  String get helpFaqCatExport => 'Export';

  @override
  String get helpFaqQ1 => 'What is My Vitals?';

  @override
  String get helpFaqA1 =>
      'My Vitals is a personal health tracking app that lets you record and monitor your wellness indicators: anthropometric measurements, vital signs, lipid profile, and body composition.';

  @override
  String get helpFaqQ2 => 'Is my data saved to the cloud?';

  @override
  String get helpFaqA2 =>
      'No. All your data is stored exclusively on your device. My Vitals does not send any information to external servers, ensuring complete privacy.';

  @override
  String get helpFaqQ3 => 'Can I use the app without internet?';

  @override
  String get helpFaqA3 =>
      'Yes. My Vitals works completely offline. You only need connectivity for app updates.';

  @override
  String get helpFaqQ4 => 'How do I enable biometric lock?';

  @override
  String get helpFaqA4 =>
      'Go to Profile › Privacy & Security and enable the Biometric Lock toggle. Your device must have fingerprint or FaceID configured.';

  @override
  String get helpFaqQ5 => 'How do I export my history?';

  @override
  String get helpFaqA5 =>
      'In each history screen (Anthropometric, Vital Signs, etc.) you will find \'Export PDF\' and \'Excel (CSV)\' buttons at the top.';

  @override
  String get helpFaqQ6 => 'Can I change the measurement units?';

  @override
  String get helpFaqA6 =>
      'Yes. Go to Profile › Measurement Units and choose between Metric (kg, cm) or Imperial (lb, ft/in) system.';

  @override
  String get helpFaqQ7 => 'What happens if I delete the app?';

  @override
  String get helpFaqA7 =>
      'Uninstalling the app will permanently delete all locally stored data. We recommend exporting your history to PDF or CSV before uninstalling.';

  @override
  String get helpFaqQ8 => 'Does this app replace my doctor?';

  @override
  String get helpFaqA8 =>
      'No. My Vitals is a personal tracking tool to help you keep an organized record. Always consult a healthcare professional for medical interpretation and diagnosis.';

  @override
  String get helpGlossarySearchHint => 'Search term...';

  @override
  String get helpGlossaryGroupAnthropo => 'Anthropometric Measurements';

  @override
  String get helpGlossaryGroupVitals => 'Vital Signs';

  @override
  String get helpGlossaryGroupLipid => 'Lipid Profile';

  @override
  String get helpGlossaryGroupBody => 'Body Composition';

  @override
  String get helpGlossaryNormalRange => 'Normal range';

  @override
  String get helpLegalPurposeTitle => 'Purpose of the application';

  @override
  String get helpLegalPurposeBody =>
      'My Vitals is a personal health tracking application designed to help users record and visualize their wellness indicators. It is not a certified medical device.';

  @override
  String get helpLegalNotMedicalTitle => 'Not a medical device';

  @override
  String get helpLegalNotMedicalBody =>
      'The information displayed in this application is for reference purposes only. It does not replace the diagnosis, advice, or treatment of a health professional. If you have any medical symptoms or concerns, consult your doctor.';

  @override
  String get helpLegalResponsibilityTitle => 'User responsibility';

  @override
  String get helpLegalResponsibilityBody =>
      'The user is responsible for the accuracy of the data entered. My Vitals is not responsible for health decisions made based on information recorded in the app.';

  @override
  String get helpLegalPrivacyTitle => 'Privacy and data';

  @override
  String get helpLegalPrivacyBody =>
      'All data is stored locally on the user\'s device. My Vitals does not collect, transmit, or share personal information with third parties. There are no user accounts or data servers.';

  @override
  String get helpLegalContactTitle => 'Developer contact';

  @override
  String get helpLegalContactBody =>
      'For legal or privacy inquiries, you can contact the developer at: yesithvalencia@gmail.com';

  @override
  String get helpContactReportBug => 'Report a bug';

  @override
  String get helpContactReportBugDesc =>
      'Found something that\'s not working? Tell us.';

  @override
  String get helpContactSuggest => 'Send a suggestion';

  @override
  String get helpContactSuggestDesc =>
      'Have an idea to improve the app? We want to hear it.';

  @override
  String get helpContactSendEmail => 'Send email';

  @override
  String get helpContactAppVersion => 'App version';

  @override
  String get helpContactWhatsNew => 'What\'s new';

  @override
  String get helpContactV110 => 'v1.1.0 — Current';

  @override
  String get helpContactV110Changes =>
      '• Biometric lock (fingerprint / FaceID)\n• Personalized health goals\n• Italian language support\n• Improved activity level selector';

  @override
  String get helpContactV100 => 'v1.0.0 — Initial release';

  @override
  String get helpContactV100Changes =>
      '• Anthropometric measurements tracking\n• Vital signs and lipid profile\n• Body composition\n• PDF and CSV export\n• Multilanguage support (es, en, de, pt)';

  @override
  String get myDataBackup => 'My Data';

  @override
  String get backupTitle => 'Backup & Restore';

  @override
  String get backupDescription =>
      'Export or restore all your data and preferences.';

  @override
  String get backupPrivacyTitle => 'Your data is yours. And yours only.';

  @override
  String get backupPrivacyBody =>
      'All of our health features are built with privacy at the core. Your data never leaves your device — My Vitals does not use cloud servers, external accounts, or third-party services. Everything is stored locally in an encrypted database, accessible only to you.';

  @override
  String get backupPrivacyHighlight =>
      'If you enable biometric lock, your health data is further protected by your fingerprint or Face ID — no one else can access your information, not even us.';

  @override
  String get backupExportTitle => 'Export my data';

  @override
  String get backupExportSubtitle =>
      'Generate a secure file with all your history and settings';

  @override
  String get backupExportButton => 'Export Backup';

  @override
  String get backupImportTitle => 'Restore my data';

  @override
  String get backupImportSubtitle => 'Import a previous My Vitals backup';

  @override
  String get backupImportButton => 'Import Backup';

  @override
  String get backupWhatIncluded => 'What\'s included in the backup?';

  @override
  String get backupSuccess => 'Backup exported successfully!';

  @override
  String get backupImportSuccess => 'Data restored successfully!';

  @override
  String get backupImportError =>
      'Import error. Verify that the file is valid.';

  @override
  String get backupImportConfirmTitle => 'Restore data?';

  @override
  String get backupImportConfirmBody =>
      'This will replace your current records with the ones from the backup. Do you want to continue?';

  @override
  String get backupIncludesVitalSigns => 'Vital Signs History';

  @override
  String get backupIncludesAnthropo => 'Anthropometric History';

  @override
  String get backupIncludesLipid => 'Lipid Profile';

  @override
  String get backupIncludesBodyComp => 'Body Composition';

  @override
  String get backupIncludesPersonalInfo => 'Personal Information';

  @override
  String get backupIncludesGoals => 'Health Goals';

  @override
  String get backupIncludesPhoto => 'Profile Photo';

  @override
  String get backupIncludesPreferences =>
      'Preferences (language, units, theme, reminders, device)';

  @override
  String get exportSuccess => 'Exported successfully';

  @override
  String get exportError => 'Could not export. Please try again.';

  @override
  String get backupCancel => 'Cancel';

  @override
  String get onboardingWelcomeTitle => 'Welcome to My Vitals';

  @override
  String get onboardingWelcomeSubtitle => 'Your personal health companion';

  @override
  String get onboardingWelcomeFeature1 =>
      'Record your vital signs and body measurements';

  @override
  String get onboardingWelcomeFeature2 =>
      'Visualize your progress with charts and stats';

  @override
  String get onboardingWelcomeFeature3 =>
      '100% private, everything stays on your device';

  @override
  String get onboardingNext => 'Next';

  @override
  String get onboardingFinish => 'Get Started!';

  @override
  String onboardingStep(int current, int total) {
    return 'Step $current of $total';
  }

  @override
  String get onboardingAvatarTitle => 'Your profile picture';

  @override
  String get onboardingAvatarSubtitle =>
      'Put a face to your health journey (optional)';

  @override
  String get remindersTitle => 'Reminders & Alerts';

  @override
  String get remindersDescription =>
      'Set daily alerts to remember your routine medical checkups.';

  @override
  String get remindersNote =>
      '* Notifications will arrive on your device daily at the scheduled time.';

  @override
  String get reminderVitals => 'Record Vital Signs';

  @override
  String get reminderMeds => 'Take Medication';

  @override
  String get reminderWorkout => 'Physical Activity';

  @override
  String get reminderWater => 'Drink Water';

  @override
  String get reminderTitle => 'Medical Reminder';

  @override
  String get filterLast7Days => 'Last 7 days';

  @override
  String get filterLast30Days => 'Last 30 days';

  @override
  String get filterLast6Months => 'Last 6 months';

  @override
  String get filterAllTime => 'All time';

  @override
  String goalRemainingWeight(String weight) {
    return '${weight}kg remaining for target';
  }

  @override
  String get goalAchieved => 'Goal achieved!';

  @override
  String get noGoalDefined => 'No goal defined';

  @override
  String get validationRequiredFields => 'Required fields';

  @override
  String get validationCompleteBeforeContinue =>
      'Please complete these fields before continuing:';

  @override
  String get validationSelectLanguage => 'Select a language';

  @override
  String get validationEnterName => 'Enter your full name';

  @override
  String get validationSelectBirthDate => 'Select your date of birth';

  @override
  String get validationSelectGender => 'Select your gender';

  @override
  String get dashboardCompositionFat => 'FAT';

  @override
  String get dashboardCompositionMuscle => 'MUSCLE';

  @override
  String get dashboardCompositionVisceral => 'VISCERAL';

  @override
  String get dashboardCompositionBmr => 'BMR';

  @override
  String dashboardCompositionLevel(int level) {
    return 'Lv. $level';
  }

  @override
  String get vitalsPdfTitle => 'Vital Signs History';

  @override
  String get vitalsShareCsvSubject => 'Vital Signs CSV';

  @override
  String get lipidPdfTitle => 'Lipid Profile History';

  @override
  String get lipidShareCsvSubject => 'Lab Results CSV';

  @override
  String get compositionPdfTitle => 'Body Composition History';

  @override
  String get compositionShareCsvSubject => 'Body Composition CSV';

  @override
  String get reminderDefaultTitle => 'Medical Reminder';

  @override
  String get exportColComment => 'Comment';

  @override
  String get exportColHeight => 'Height (m)';

  @override
  String get exportColSysDia => 'Sys/Dia';

  @override
  String get exportColHrShort => 'HR';

  @override
  String get exportColStatus => 'Status';

  @override
  String get exportColSystolic => 'Systolic';

  @override
  String get exportColDiastolic => 'Diastolic';

  @override
  String get exportColHeartRate => 'Heart Rate';

  @override
  String get exportColActivityState => 'Activity State';

  @override
  String get exportColSymptom => 'Symptom';

  @override
  String get exportColTotalCholShort => 'Total Chol.';

  @override
  String get exportColTrigsShort => 'Trigs';

  @override
  String get exportColTotalCholesterol => 'Total Cholesterol';

  @override
  String get exportColTriglycerides => 'Triglycerides';

  @override
  String get exportColLabName => 'Lab Name';

  @override
  String get exportColBodyFat => 'Body Fat';

  @override
  String get exportColMuscleMass => 'Muscle Mass';

  @override
  String get exportColVisceralFat => 'Visceral Fat';

  @override
  String get exportColMetabolicAge => 'Metabolic Age';

  @override
  String get exportColBodyWater => 'Body Water';

  @override
  String get exportColBoneMass => 'Bone Mass';

  @override
  String get exportColBmr => 'BMR';

  @override
  String get glossaryImcName => 'BMI (Body Mass Index)';

  @override
  String get glossaryImcDefinition =>
      'A measure relating weight and height to assess whether a person\'s weight is healthy. Calculated by dividing weight (kg) by height squared (m²).';

  @override
  String get glossaryImcRange => '18.5 – 24.9 kg/m²';

  @override
  String get glossaryPesoName => 'Body Weight';

  @override
  String get glossaryPesoDefinition =>
      'Total mass of the body expressed in kilograms or pounds. Includes muscles, bones, organs, fat, and water.';

  @override
  String get glossaryPesoRange => 'Depends on height and build';

  @override
  String get glossaryTallaName => 'Height (Stature)';

  @override
  String get glossaryTallaDefinition =>
      'Measurement of a person\'s height from feet to the top of the head, expressed in centimeters or meters.';

  @override
  String get glossarySistolicaName => 'Systolic Pressure';

  @override
  String get glossarySistolicaDefinition =>
      'The maximum pressure exerted by blood on the arteries when the heart contracts (beats). It is the upper number in a blood pressure reading.';

  @override
  String get glossarySistolicaRange => '< 120 mmHg';

  @override
  String get glossaryDiastolicaName => 'Diastolic Pressure';

  @override
  String get glossaryDiastolicaDefinition =>
      'The minimum pressure exerted by blood on the arteries between heartbeats, when the heart is at rest. It is the lower number in a blood pressure reading.';

  @override
  String get glossaryDiastolicaRange => '< 80 mmHg';

  @override
  String get glossaryFcName => 'Heart Rate';

  @override
  String get glossaryFcDefinition =>
      'Number of times the heart beats per minute (bpm). At rest, a healthy heart beats regularly within a specific range.';

  @override
  String get glossaryFcRange => '60 – 100 bpm at rest';

  @override
  String get glossaryColesterolTotalName => 'Total Cholesterol';

  @override
  String get glossaryColesterolTotalDefinition =>
      'Sum of all cholesterol in the blood, including LDL, HDL, and other lipids. It is a general marker of cardiovascular risk.';

  @override
  String get glossaryColesterolTotalRange => '< 200 mg/dL';

  @override
  String get glossaryLdlName => 'LDL (\"Bad\" Cholesterol)';

  @override
  String get glossaryLdlDefinition =>
      'Low-density lipoprotein. It carries cholesterol into the arteries and can accumulate in their walls, increasing cardiovascular disease risk.';

  @override
  String get glossaryLdlRange => '< 100 mg/dL';

  @override
  String get glossaryHdlName => 'HDL (\"Good\" Cholesterol)';

  @override
  String get glossaryHdlDefinition =>
      'High-density lipoprotein. It collects excess cholesterol from the arteries and carries it to the liver for elimination. High levels are protective.';

  @override
  String get glossaryHdlRange => '≥ 60 mg/dL';

  @override
  String get glossaryVldlName => 'VLDL';

  @override
  String get glossaryVldlDefinition =>
      'Very low-density lipoprotein. It transports triglycerides from the liver to tissues. Elevated levels are associated with higher cardiovascular risk.';

  @override
  String get glossaryVldlRange => '2 – 30 mg/dL';

  @override
  String get glossaryTrigliceridosName => 'Triglycerides';

  @override
  String get glossaryTrigliceridosDefinition =>
      'A type of fat (lipid) in the blood. The body uses them as an energy source, but high levels increase the risk of heart and pancreatic disease.';

  @override
  String get glossaryTrigliceridosRange => '< 150 mg/dL';

  @override
  String get glossaryGrasaName => 'Body Fat Percentage';

  @override
  String get glossaryGrasaDefinition =>
      'Proportion of fat mass relative to total body weight. Includes essential fat (needed for vital functions) and storage fat.';

  @override
  String get glossaryGrasaRange => 'Men: 8–19% / Women: 21–33%';

  @override
  String get glossaryMusculoName => 'Muscle Mass';

  @override
  String get glossaryMusculoDefinition =>
      'Total weight of muscle tissue in the body, expressed in kilograms. A higher muscle percentage is associated with a more active metabolism.';

  @override
  String get glossaryGrasaVisceralName => 'Visceral Fat';

  @override
  String get glossaryGrasaVisceralDefinition =>
      'Fat accumulated around the internal organs of the abdomen (liver, intestines, pancreas). High levels are associated with higher metabolic and cardiovascular risk.';

  @override
  String get glossaryGrasaVisceralRange => 'Level 1–9 (healthy)';

  @override
  String get glossaryEdadMetabolicaName => 'Metabolic Age';

  @override
  String get glossaryEdadMetabolicaDefinition =>
      'Estimated age of basal metabolism compared to the population average. A metabolic age lower than chronological age indicates an efficient metabolism.';

  @override
  String get glossaryBmrName => 'BMR / Basal Metabolism (kcal)';

  @override
  String get glossaryBmrDefinition =>
      'Minimum amount of energy (calories) the body needs at complete rest to maintain vital functions: breathing, circulation, temperature, etc.';

  @override
  String get glossaryAguaName => 'Body Water';

  @override
  String get glossaryAguaDefinition =>
      'Percentage of body weight that corresponds to water. Water is essential for all cellular functions, temperature regulation, and nutrient transport.';

  @override
  String get glossaryAguaRange => '50 – 65%';

  @override
  String get glossaryHuesoName => 'Bone Mass';

  @override
  String get glossaryHuesoDefinition =>
      'Estimated weight of bone tissue in the body. Maintaining adequate bone mass is essential to prevent osteoporosis.';

  @override
  String get glossaryHuesoRange => '2 – 4 kg (average adult)';

  @override
  String get deleteRecordTitle => 'Delete record?';

  @override
  String get deleteRecordBody => 'This action can\'t be undone.';

  @override
  String get deleteRecordConfirm => 'Delete';

  @override
  String get recordDeleted => 'Record deleted';

  @override
  String get anthropoSavedSuccess => 'Measurement saved successfully.';

  @override
  String historyShowMore(int count) {
    return 'Show $count more';
  }

  @override
  String get introSignIn => 'Sign in';

  @override
  String get introRegister => 'Create account';

  @override
  String get emailLabel => 'Email';

  @override
  String get validationEnterEmail => 'Enter your email';

  @override
  String get validationEmailFormat =>
      'Check the email: the @ or the domain is missing';

  @override
  String validationOutOfRange(Object max, Object min) {
    return 'Enter a value between $min and $max';
  }

  @override
  String get commonRegisterFailed =>
      'We couldn\'t create your account. Check your connection and try again.';

  @override
  String get logOutConfirm =>
      'Sign out on this device? Your records stay on the device and will sync again when you sign back in.';

  @override
  String get pendingAccountTitle => 'Account pending';

  @override
  String get pendingAccountBody =>
      'Your data is saved on this device. We will create your account as soon as there is a connection.';

  @override
  String get pendingAccountCreateNow => 'Create my account now';

  @override
  String get pendingAccountCreating => 'Creating your account…';

  @override
  String get pendingAccountCreated =>
      'Account created. Uploading your records.';

  @override
  String get pendingAccountStillOffline =>
      'Still no connection. Your data is safe on this device.';

  @override
  String get identifyTitle => 'Let us bring your history';

  @override
  String get identifyBody =>
      'Enter your ID number (or email). If you are already a patient we will load your data; if not, we will create your account.';

  @override
  String get identifyFieldLabel => 'ID number or email';

  @override
  String get identifyFieldHint => 'e.g. 1032456789';

  @override
  String get identifyFoundTitle =>
      'We found a medical history linked to this ID.';

  @override
  String get identifyFoundBody =>
      'We can bring it over and activate your account so you see your data from day one.';

  @override
  String get identifyBringHistory => 'Bring my history and continue';

  @override
  String get identifyBringingHistory => 'Bringing your history…';

  @override
  String get identifyNotMe => 'That\'s not me — sign me up as new';

  @override
  String get verifyAppBarTitle => 'Verification';

  @override
  String get verifyTitle => 'We found your account';

  @override
  String verifyBody(String identifier) {
    return 'Verify your identity to continue with\n$identifier.';
  }

  @override
  String get verifyPasswordLabel => 'Password';

  @override
  String get verifyTestNotice =>
      'Test phase: the password is 1234. (An OTP code will go here in production.)';

  @override
  String get verifySubmit => 'Sign in';

  @override
  String unexpectedError(String details) {
    return 'Unexpected error: $details';
  }

  @override
  String get accountSyncTitle => 'Account and sync';

  @override
  String get accountSyncDescription =>
      'Sign in and sync your records with the server.';

  @override
  String get deviceScreenDescription =>
      'Choose the scale you use so we can interpret your measurements.';

  @override
  String get goalsScreenDescription =>
      'Set your target values and track your progress.';

  @override
  String get accountYourAccount => 'Your account';

  @override
  String get accountPendingBody =>
      'Your data is on this device. The account still has to be created on the server.';

  @override
  String get accountLoggedOutBody =>
      'Sign in if you are already a patient, or register to get started.';

  @override
  String get accountFallbackName => 'Patient';

  @override
  String get accountFromLegacy => 'Account migrated from the legacy system';

  @override
  String get accountCreatedInApp => 'Account created in the app';

  @override
  String get accountSignOut => 'Sign out';

  @override
  String get accountSyncSection => 'Sync';

  @override
  String get accountSyncBody => 'Upload your local records to the server.';

  @override
  String get accountSyncing => 'Syncing…';

  @override
  String get accountSyncNow => 'Sync now';

  @override
  String get accountHaveAccount =>
      'I already have an account (migrated patient)';

  @override
  String get accountImNew => 'I am new (sign me up)';

  @override
  String get accountCreateAccount => 'Create account';

  @override
  String get accountNewHere => 'I\'m new (sign up)';

  @override
  String get accountDocumentOptional => 'Document (optional)';

  @override
  String get accountNameLabel => 'Name';

  @override
  String get accountEmailLabel => 'Email';

  @override
  String get deviceScreenTitle => 'My measuring device';

  @override
  String get deviceNoneTitle => 'I don’t use one';

  @override
  String get deviceNoneSubtitle =>
      'I will only record manual measurements (weight, waist, height).';

  @override
  String get deviceNoneSaved => 'Saved: you don’t use bioimpedance.';

  @override
  String get deviceCatalogError =>
      'Could not refresh the catalogue. Showing the saved options.';

  @override
  String get deviceAvailableScales => 'AVAILABLE SCALES';

  @override
  String get deviceWhyItMatters =>
      'Every bioimpedance scale interprets fat, muscle and visceral fat with its own ranges. Tell us which one you use so we can show whether your values are low, normal or high. You can change it whenever you like.';

  @override
  String get circumferencesSection => 'BODY CIRCUMFERENCES (OPTIONAL)';

  @override
  String get circWaist => 'Waist';

  @override
  String get circHip => 'Hip';

  @override
  String get circLowerAbdomen => 'Lower abdomen';

  @override
  String get circArm => 'Arm';

  @override
  String get circLeg => 'Leg';

  @override
  String get circChestBust => 'Chest/Bust';

  @override
  String get circAbdomenShort => 'Abd.';

  @override
  String get lipidLabQuestion => 'Which lab ran your test?';

  @override
  String get lipidLabLoading => 'Loading labs…';

  @override
  String get lipidLabNotSpecified => 'Not specified / I don’t know';

  @override
  String get lipidLabOther => 'Other (specify)';

  @override
  String get compositionSkeletalMuscle => 'Skeletal muscle';

  @override
  String get compositionSkeletalMuscleRef => 'As reported by your scale (%)';

  @override
  String get profileAppTheme => 'App theme';

  @override
  String get profileRankObserver => 'Vital Observer';

  @override
  String get themeBankLabel => 'THEME LIBRARY';

  @override
  String get themePickTitle => 'Choose the look';

  @override
  String get themePickBody =>
      'Changes colours and typography. Navigation, icons and the meaning of every colour stay exactly the same.';

  @override
  String get themeSettingsBody =>
      'The change applies instantly and is remembered. Navigation, icons and the meaning of every colour stay exactly the same.';

  @override
  String themeContinueWith(String theme) {
    return 'Continue with $theme';
  }

  @override
  String deviceSelectedSaved(String device) {
    return '$device selected.';
  }

  @override
  String deviceWillSyncLater(String message) {
    return '$message It will sync once you are online.';
  }

  @override
  String get introDemo => 'Explore the demo';

  @override
  String get demoNoticeTitle => 'You are in the demo';

  @override
  String get demoNoticeBody =>
      'Everything you see belongs to a fictional patient. Feel free to add or edit measurements: nothing is saved, and it all disappears when you leave the demo.';

  @override
  String get demoNoticeAction => 'Got it';

  @override
  String get demoBannerLabel => 'Demo data';

  @override
  String get demoExit => 'Leave the demo';

  @override
  String get profileRankTier2 => 'Steady Caregiver';

  @override
  String get profileRankTier3 => 'Wellness Veteran';

  @override
  String get mhxDocTitle => 'Personal Health Summary';
  @override
  String get mhxDocSubtitle => 'Consolidated report of self-reported measurements';
  @override
  String get mhxPatient => 'Patient';
  @override
  String get mhxBirthDate => 'Date of birth';
  @override
  String get mhxPeriodCovered => 'Period covered';
  @override
  String get mhxGeneratedOn => 'Generated on';
  @override
  String get mhxSource => 'Source';

  @override
  String get mhxGeneratedBy => 'Generated by';

  @override
  String get mhxReportRef => 'Report no.';
  @override
  String get mhxSelfReported => 'self-reported data';
  @override
  String get mhxDisclaimerTitle => 'Informational summary - not a medical diagnosis';
  @override
  String get mhxDisclaimerBody => 'This document was generated automatically from measurements recorded by the user. It is not a medical diagnosis or an official clinical record, and does not replace assessment by a healthcare professional.';
  @override
  String get mhxSummaryTitle => 'Summary of latest values';
  @override
  String get mhxColIndicator => 'Indicator';
  @override
  String get mhxColLatest => 'Latest value';
  @override
  String get mhxColReference => 'Reference';
  @override
  String get mhxColStatus => 'Status';
  @override
  String get mhxColNotes => 'Notes';
  @override
  String get mhxBloodPressure => 'Blood pressure';
  @override
  String get mhxHeartRate => 'Heart rate';
  @override
  String get mhxWeight => 'Weight';
  @override
  String get mhxBmi => 'BMI';
  @override
  String get mhxBodyFat => 'Body fat';
  @override
  String get mhxVisceralFat => 'Visceral fat';
  @override
  String get mhxTotalCholesterol => 'Total cholesterol';
  @override
  String get mhxLdl => 'LDL';
  @override
  String get mhxHdl => 'HDL';
  @override
  String get mhxTriglycerides => 'Triglycerides';
  @override
  String get mhxSystolic => 'Systolic';
  @override
  String get mhxDiastolic => 'Diastolic';
  @override
  String get mhxStatsMeasurements => 'Measurements';
  @override
  String get mhxStatsAverage => 'Average';
  @override
  String get mhxStatsRange => 'Range';
  @override
  String get mhxStatsLatest => 'Latest';
  @override
  String get mhxFooterDisclaimer => 'Data source: measurements entered by the patient through the MY VITALS app using personal devices that may not be clinically calibrated; their accuracy is not verified by a professional or an accredited laboratory. The reference ranges shown are indicative and may not apply to your individual situation; a value flagged outside the range is not a diagnosis. Do not make treatment decisions based on this document without professional supervision. It contains personal health data: the user is responsible for its safekeeping and sharing.';
  @override
  String get mhxButton => 'Export complete medical history';
  @override
  String get mhxHubHint => 'One PDF with your four indicators to show your doctor.';
  @override
  String get mhxChoosePeriod => 'Choose the period';
  @override
  String get mhxPeriod6Months => 'Last 6 months';
  @override
  String get mhxPeriod1Year => 'Last year';
  @override
  String get mhxPeriodAll => 'All history';
  @override
  String get mhxGenerate => 'Generate PDF';
  @override
  String get mhxNoData => 'There are no measurements to export yet.';
  @override
  String mhxAgeYears(int years) {
    return '$years yr';
  }
  @override
  String mhxPageOf(int current, int total) {
    return 'Page $current of $total';
  }
}
