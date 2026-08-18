// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for German (`de`).
class AppLocalizationsDe extends AppLocalizations {
  AppLocalizationsDe([String locale = 'de']) : super(locale);

  @override
  String get appTitle => 'Meine Vitals';

  @override
  String get dashboard => 'Startseite';

  @override
  String get history => 'Verlauf';

  @override
  String get record => 'Aufzeichnen';

  @override
  String get discover => 'Entdecken';

  @override
  String get profile => 'Profil';

  @override
  String get language => 'Sprache';

  @override
  String get savePreferences => 'Präferenzen speichern';

  @override
  String get selectLanguage => 'Wählen Sie Ihre bevorzugte Sprache';

  @override
  String get personalInfo => 'Persönliche Daten';

  @override
  String get measurementUnits => 'Maßeinheiten';

  @override
  String get notifications => 'Benachrichtigungen';

  @override
  String get privacySecurity => 'Datenschutz & Sicherheit';

  @override
  String get helpSupport => 'Hilfe & Support';

  @override
  String get logOut => 'Abmelden';

  @override
  String level(int value) {
    return 'Level $value';
  }

  @override
  String get newUserInfo => 'Neuer Benutzer';

  @override
  String xpForNextLevel(int current, int total) {
    return '$current / $total XP bis zum nächsten Level';
  }

  @override
  String get levelProgress => 'Level-Fortschritt';

  @override
  String get vitalSigns => 'Vitalwerte';

  @override
  String get vitalsSubtitle => 'Blutdruck & Herzfrequenz';

  @override
  String get noDataYet => 'Noch keine Daten registriert.';

  @override
  String get recordVitalsAction => 'Druck und Frequenz erfassen ›';

  @override
  String get bodyComposition => 'Körperzusammensetzung';

  @override
  String get compositionSubtitle => 'Fett, Muskeln, Wasser und Knochenmasse.';

  @override
  String get completeBodyProfile => 'Körperprofil vervollständigen ›';

  @override
  String get anthropometricHistory => 'Anthropometrische Historie';

  @override
  String get anthroSubtitle => 'Gewicht, Größe und Fortschritt messen.';

  @override
  String get recordFirstMeasure => 'Erste Messung erfassen ›';

  @override
  String get lipidProfile => 'Lipidprofil';

  @override
  String get lipidSubtitle => 'Cholesterin und Triglyzeride überwachen.';

  @override
  String get recordLabResults => 'Laborergebnisse erfassen ›';

  @override
  String get medicalDisclaimerTitle => 'Medizinischer Haftungsausschluss';

  @override
  String get medicalDisclaimerText =>
      'Diese Anwendung dient nur zu Informationszwecken. Sie ist kein Ersatz für professionelle medizinische Beratung.';

  @override
  String get selfCareProgress => 'Selbstpflege-Fortschritt';

  @override
  String get myHealthAchievements => 'Meine Gesundheitserfolge';

  @override
  String get badgeFirstStep => 'Erster Schritt';

  @override
  String get badgeFirstStepDesc => 'Beginn des Weges';

  @override
  String get badgeStrongHeart => 'Starkes Herz';

  @override
  String get badgeStrongHeartDesc => 'Cardio-Gesundheit';

  @override
  String get badgeVitalHabit => 'Vitale Gewohnheit';

  @override
  String get badgeVitalHabitDesc => '7 Tage in Folge';

  @override
  String get badgeAwareness => 'Bewusstsein';

  @override
  String get badgeAwarenessDesc => 'Überblick';

  @override
  String get badgeBalance => 'Gleichgewicht';

  @override
  String get badgeBalanceDesc => 'Körperziel';

  @override
  String get badgeGuardian => 'Wächter';

  @override
  String get badgeGuardianDesc => 'Engagement';

  @override
  String get metricSystem => 'Metrisch (kg, cm, °C)';

  @override
  String get registerIndicators => 'Indikatoren registrieren';

  @override
  String get anthropometry => 'Anthropometrie';

  @override
  String get unitOfMeasureTitle => 'Maßeinheit';

  @override
  String get unitOfMeasureDescription =>
      'Wie möchten Sie Ihre Messungen sehen? Wählen Sie das System, das am besten zu Ihnen passt, für eine präzise Gesundheitsverfolgung.';

  @override
  String get metricOption => 'Metrisch (kg, cm)';

  @override
  String get metricSubtitle => 'Kilogramm und Zentimeter';

  @override
  String get imperialOption => 'Imperial (lb, ft/in)';

  @override
  String get imperialSubtitle => 'Pfund und Fuß/Zoll';

  @override
  String get continueAction => 'Weiter';

  @override
  String get languageTitle => 'Sprachauswahl';

  @override
  String get languageDescription =>
      'Wählen Sie Ihre bevorzugte Sprache, um die Anwendung an Ihre Bedürfnisse anzupassen. Sie können sie jederzeit auf dieser Seite ändern.';

  @override
  String get profileImageTitle => 'Profilbild';

  @override
  String get gallery => 'Galerie';

  @override
  String get camera => 'Kamera';

  @override
  String get deletePhoto => 'Foto löschen';

  @override
  String get cancel => 'Abbrechen';

  @override
  String get personalInfoTitle => 'Persönliche Informationen';

  @override
  String get personalInfoDescription =>
      'Halten Sie Ihre Daten auf dem neuesten Stand, um präzisere und personalisierte Gesundheitsempfehlungen zu erhalten.';

  @override
  String get fullName => 'Vollständiger Name';

  @override
  String get birthDate => 'Geburtsdatum';

  @override
  String get emailOptional => 'E-Mail (Optional)';

  @override
  String get phoneOptional => 'Telefon (Optional)';

  @override
  String get selectCountry => 'Wähle dein Land';

  @override
  String get searchCountry => 'Land suchen';

  @override
  String get gender => 'Geschlecht';

  @override
  String get male => 'Männlich';

  @override
  String get female => 'Weiblich';

  @override
  String get other => 'Andere';

  @override
  String get activityLevel => 'Aktivitätslevel';

  @override
  String get activitySedentary => 'Sitzend';

  @override
  String get activityLightlyActive => 'Leicht aktiv';

  @override
  String get activityModeratelyActive => 'Mäßig aktiv';

  @override
  String get activityVeryActive => 'Sehr aktiv';

  @override
  String get activityExtraActive => 'Extra aktiv';

  @override
  String get selectDate => 'Datum auswählen';

  @override
  String get recordAnthropometricTitle => 'ANTHROPOMETRISCHE MESSUNGEN';

  @override
  String get dateTimeOfMeasurement => 'DATUM UND UHRZEIT DER MESSUNG';

  @override
  String get dateLabel => 'Datum';

  @override
  String get timeLabel => 'Uhrzeit';

  @override
  String get bodyMeasurements => 'KÖRPERMESSUNGEN';

  @override
  String get weightLabel => 'Gewicht';

  @override
  String get heightLabel => 'Größe';

  @override
  String get bmiTitle => 'Body-Mass-Index (BMI)';

  @override
  String get manual => 'Manuell';

  @override
  String get bmiLow => 'NIEDRIG';

  @override
  String get bmiNormal => 'NORMAL';

  @override
  String get bmiOverweight => 'ÜBERGEWICHT';

  @override
  String get bmiObesity => 'FETTLEIBIGKEIT';

  @override
  String get commentOptional => 'KOMMENTAR (OPTIONAL)';

  @override
  String get commentHint => 'Irgendwelche Beobachtungen zu dieser Messung?';

  @override
  String get saveAndEarnXp => 'Speichern und +10 XP verdienen';

  @override
  String get historyGoodJob => 'Gute Arbeit!';

  @override
  String get historyGoalProgress =>
      'Sie haben diesen Monat eine neue Messung aufgezeichnet und bleiben auf Ihrem Wellness-Weg.';

  @override
  String historyWeightLoss(String weight) {
    return 'Sie haben diesen Monat ${weight}kg abgenommen und kommen Ihrem Wellness-Ziel näher.';
  }

  @override
  String get historyBmiTrend => 'BMI-TREND';

  @override
  String get historyLast6Months => 'Letzte 6 Monate';

  @override
  String get historyTargetZone => 'Zielzone';

  @override
  String get historyBmiUnit => 'BMI';

  @override
  String get historyExportPdf => 'Als PDF exportieren';

  @override
  String get historyExportCsv => 'Excel (CSV)';

  @override
  String get historyMeasurements => 'MESSVERLAUF';

  @override
  String get historyNoMeasurements =>
      'Noch keine Messungen. Zeichnen Sie Ihre erste auf, um Ihren Verlauf zu starten.';

  @override
  String get historyColDate => 'Datum';

  @override
  String get historyColWeight => 'Gewicht (kg)';

  @override
  String get historyColBmi => 'BMI';

  @override
  String get historyColCategory => 'Kategorie';

  @override
  String get historyUnknown => 'Unbekannt';

  @override
  String get historyPdfTitle => 'Anthropometrische Historie';

  @override
  String get historyShareCsvSubject => 'Messverlauf CSV';

  @override
  String get historyBmiLabel => 'BMI';

  @override
  String historyTrendOf(String metric) {
    return '$metric TREND';
  }

  @override
  String historyMetricNeedsData(String measure) {
    return 'Log $measure to see this indicator.';
  }

  @override
  String get whtrName => 'Waist-to-height';

  @override
  String get whtrShort => 'WHtR';

  @override
  String get whtrLow => 'LOW';

  @override
  String get whtrNormal => 'NORMAL';

  @override
  String get whtrIncreased => 'INCREASED';

  @override
  String get whtrHigh => 'HIGH';

  @override
  String get whrName => 'Waist-to-hip';

  @override
  String get whrShort => 'WHR';

  @override
  String get whrNormal => 'NORMAL';

  @override
  String get whrIncreased => 'INCREASED';

  @override
  String get measureWaist => 'your waist';

  @override
  String get measureWaistAndHip => 'waist and hip';

  @override
  String get unitCm => 'cm';

  @override
  String get recordVitalSignsTitle => 'VITALWERTE';

  @override
  String get bloodPressureTitle => 'BLUTDRUCK (MMHG)';

  @override
  String get systolicLabel => 'SYSTOLISCH';

  @override
  String get diastolicLabel => 'DIASTOLISCH';

  @override
  String get heartRateTitle => 'HERZFREQUENZ (BPM)';

  @override
  String get vitalMetricBpShort => 'Blutdruck';

  @override
  String get vitalMetricHrShort => 'Herzfrequenz';

  @override
  String get heartRateSeriesLabel => 'Herzfrequenz';

  @override
  String get symptomMarkerLegend => 'Symptom vermerkt';

  @override
  String get contextAndSymptoms => 'KONTEXT & SYMPTOME';

  @override
  String get activityState => 'AKTIVITÄTSZUSTAND';

  @override
  String get activityRest => 'Ruhe';

  @override
  String get activityExercise => 'Sport';

  @override
  String get activityPostOp => 'Post-op';

  @override
  String get howDoYouFeel => 'WIE FÜHLEN SIE SICH?';

  @override
  String get symptomNormal => 'Normal';

  @override
  String get symptomDizziness => 'Schwindel';

  @override
  String get symptomPain => 'Schmerz';

  @override
  String get symptomFatigue => 'Müdigkeit';

  @override
  String get bpLow => 'NIEDRIG';

  @override
  String get bpNormal => 'NORMAL';

  @override
  String get bpElevated => 'ERHÖHT';

  @override
  String get bpHigh => 'HOCH';

  @override
  String get hrLow => 'NIEDRIG';

  @override
  String get hrNormal => 'NORMAL';

  @override
  String get hrHigh => 'HOCH';

  @override
  String get vitalsSavedSuccess => 'Vitalwerte erfolgreich gespeichert.';

  @override
  String get lipidProfileTitle => 'LIPIDPROFIL';

  @override
  String get lipidInfoBanner =>
      'Gib die Werte deines letzten Labortests ein. Alle Felder sind optional, aber vollständige Angaben ermöglichen eine bessere Beurteilung.';

  @override
  String get lipidLabInfo => 'LABORINFORMATIONEN';

  @override
  String get lipidLabName => 'Laborname';

  @override
  String get lipidLabNameHint => 'Z.B. Stadtlabor München';

  @override
  String get lipidResultsTitle => 'ANALYSEERGEBNISSE (mg/dL)';

  @override
  String get lipidTotalCholesterol => 'Gesamtcholesterin';

  @override
  String get lipidTcRef => 'Ref: < 200 mg/dL';

  @override
  String get lipidLdl => 'LDL (\"Schlechtes\" Cholesterin)';

  @override
  String get lipidLdlRef => 'Ref: < 100 mg/dL';

  @override
  String get lipidHdl => 'HDL (\"Gutes\" Cholesterin)';

  @override
  String get lipidHdlRef => 'Ref: ≥ 60 mg/dL';

  @override
  String get lipidVldl => 'VLDL';

  @override
  String get lipidVldlRef => 'Ref: 2 – 30 mg/dL';

  @override
  String get lipidTriglycerides => 'Triglyzeride';

  @override
  String get lipidTrigsRef => 'Ref: < 150 mg/dL';

  @override
  String get lipidStatusOptimal => 'OPTIMAL';

  @override
  String get lipidStatusNearOptimal => 'AKZEPTABEL';

  @override
  String get lipidStatusBorderline => 'GRENZWERTIG';

  @override
  String get lipidStatusHigh => 'HOCH';

  @override
  String get lipidStatusLow => 'NIEDRIG';

  @override
  String get lipidStatusProtective => 'SCHUTZEND';

  @override
  String get lipidStatusAcceptable => 'AKZEPTABEL';

  @override
  String get lipidOverallRisk => 'GESAMTBEURTEILUNG';

  @override
  String get lipidOverallDesc =>
      'Basierend auf den eingegebenen Werten. Konsultiere immer deinen Arzt.';

  @override
  String get lipidAtLeastOneValue =>
      'Gib mindestens einen Wert ein, um den Datensatz zu speichern.';

  @override
  String get lipidSavedSuccess => 'Lipidprofil erfolgreich gespeichert.';

  @override
  String get compositionTitle => 'KÖRPERPROFIL';

  @override
  String get compositionInfoBanner =>
      'Gib die Werte deines Körperanalysegeräts ein (z. B. Bioimpedanzwaage). Alle Felder sind optional – erfasse, was dein Gerät liefert.';

  @override
  String get compositionDevice => 'MESSGERÄT';

  @override
  String get compositionDeviceHint => 'z. B. OMRON HBF-514C Waage';

  @override
  String get compositionBodyFat => 'KÖRPERFETTANTEIL (%)';

  @override
  String get compositionMuscleMass => 'MUSKELMASSE (KG)';

  @override
  String get compositionVisceralAndAge => 'VISZERALFETT & STOFFWECHSELALTER';

  @override
  String get compositionVisceralFat => 'VISZERALFETT';

  @override
  String get compositionLevel => 'Stufe';

  @override
  String get compositionMetabolicAge => 'STOFFWECHSELALTER';

  @override
  String get compositionYears => 'Jahre';

  @override
  String get compositionOptionalSection =>
      'OPTIONAL (KÖRPERWASSER & KNOCHENMASSE)';

  @override
  String get compositionBodyWater => 'Körperwasser';

  @override
  String get compositionBodyWaterRef => 'Ref: 50–65 %';

  @override
  String get compositionBoneMass => 'Knochenmasse';

  @override
  String get compositionBoneMassRef => 'Ref: 2–4 kg';

  @override
  String get compositionBmr => 'GRUNDUMSATZ (KCAL)';

  @override
  String get compositionBmrSubtitle =>
      'SCHÄTZUNG AUF BASIS DEINER AKTUELLEN KÖRPERZUSAMMENSETZUNG';

  @override
  String get fatVeryLow => 'SEHR NIEDRIG';

  @override
  String get fatLow => 'NIEDRIG';

  @override
  String get fatNormal => 'NORMAL';

  @override
  String get fatElevated => 'ERHÖHT';

  @override
  String get fatHigh => 'HOCH';

  @override
  String get infoBannerAnthro =>
      'Versuchen Sie, die Messung immer unter den gleichen Bedingungen durchzuführen, zum Beispiel: jeden Morgen nach dem Aufwachen, dem Toilettengang und vor dem Frühstück.';

  @override
  String get infoBannerVitals =>
      'Versuchen Sie, Ihre Vitalwerte nach einer halben Stunde Ruhezeit zu messen.';

  @override
  String get compositionSavedSuccess => 'Körperprofil erfolgreich gespeichert.';

  @override
  String discoverGreeting(String name) {
    return 'Guten Morgen, $name';
  }

  @override
  String get discoverSearchHint => 'Nach Tipps suchen...';

  @override
  String get discoverDailyTip => 'TÄGLICHER GESUNDHEITSTIPP';

  @override
  String get discoverReadMore => 'Weiterlesen';

  @override
  String get discoverRecommended => 'Für Sie empfohlen';

  @override
  String get discoverCategoryAll => 'Alle';

  @override
  String get discoverCategoryHeart => 'Herzgesundheit';

  @override
  String get discoverCategoryNutrition => 'Ernährung';

  @override
  String get discoverCategoryEmotional => 'Emotionale Gesundheit';

  @override
  String get discoverCategorySports => 'Sport';

  @override
  String get discoverCategorySleep => 'Schlaf';

  @override
  String get discoverMinRead => 'MIN LESEZEIT';

  @override
  String get discoverFeatured => 'Empfohlen';

  @override
  String get discoverRoutines => 'Routinen';

  @override
  String get discoverArticles => 'Artikel';

  @override
  String get discoverChallenges => 'Challenges';

  @override
  String get discoverSeeAll => 'Alle ansehen';

  @override
  String get discoverMinShort => 'Min';

  @override
  String get discoverStart => 'Starten';

  @override
  String get discoverJoin => 'Mitmachen';

  @override
  String get discoverLevelBeginner => 'Anfänger';

  @override
  String get discoverLevelIntermediate => 'Mittel';

  @override
  String get discoverLevelAdvanced => 'Fortgeschritten';

  @override
  String get discoverStatusActive => 'Aktiv';

  @override
  String get discoverStatusScheduled => 'Geplant';

  @override
  String get discoverStatusFinished => 'Beendet';

  @override
  String get discoverEmpty => 'Noch keine Inhalte verfügbar.';

  @override
  String discoverExercises(String count) {
    return '$count Übungen';
  }

  @override
  String discoverParticipants(String count) {
    return '$count Teilnehmer';
  }

  @override
  String discoverDaysShort(String count) {
    return '$count Tage';
  }

  @override
  String get privacySecurityDescription =>
      'Verwalten Sie, wie Ihre medizinischen und persönlichen Informationen geschützt werden.';

  @override
  String get biometricLockTitle => 'Biometrische Sperre';

  @override
  String get biometricLockSubtitle =>
      'Erfordert Fingerabdruck oder FaceID beim App-Start';

  @override
  String get biometricReasoning =>
      'Ihre medizinischen Daten sind vertraulich. Die Aktivierung der biometrischen Sperre stellt sicher, dass nur Sie auf Ihre Gesundheitsdaten zugreifen können, und schützt Ihre Privatsphäre.';

  @override
  String get unlockAppToContinue => 'Zum Fortfahren entsperren';

  @override
  String get biometricNotAvailable =>
      'Biometrie auf diesem Gerät nicht verfügbar.';

  @override
  String get healthGoalsTitle => 'Gesundheitsziele';

  @override
  String get goalsScreenDescription =>
      'Lege deine Zielwerte fest und verfolge deinen Fortschritt.';

  @override
  String get healthGoalsDescription =>
      'Legen Sie Ihre medizinischen Ziele fest, um Ihren Fortschritt zu verfolgen.';

  @override
  String get medicalGoalsToggle => 'Medizinische Ziele aktivieren';

  @override
  String get medicalGoalsSubtitle =>
      'Aktivieren Sie diese Option, um Gewichts- und Körperziele festzulegen';

  @override
  String get targetWeight => 'Zielgewicht';

  @override
  String get targetBodyFat => 'Ziel-Körperfett';

  @override
  String get targetMuscleMass => 'Ziel-Muskelmasse';

  @override
  String get targetVisceralFat => 'Ziel-Viszeralfett';

  @override
  String get goalsSavedSuccess => 'Ziele erfolgreich gespeichert.';

  @override
  String get helpSupportPageTitle => 'Hilfe & Support';

  @override
  String get helpSupportPageDescription =>
      'Alles was du über My Vitals wissen musst.';

  @override
  String get helpFaqTitle => 'Häufig gestellte Fragen';

  @override
  String get helpFaqDescription =>
      'Schnelle Antworten auf die häufigsten Fragen.';

  @override
  String get helpGlossaryTitle => 'Medizinisches Glossar';

  @override
  String get helpGlossaryDescription => 'Verstehe jeden Gesundheitsindikator.';

  @override
  String get helpLegalTitle => 'Rechtlicher Hinweis';

  @override
  String get helpLegalDescription => 'Nutzungsbedingungen und Datenschutz.';

  @override
  String get helpContactTitle => 'Kontakt & Feedback';

  @override
  String get helpContactDescription =>
      'Schreib uns, wir verbessern uns gemeinsam.';

  @override
  String get helpSearchHint => 'Suche...';

  @override
  String get helpNoResults => 'Keine Ergebnisse für deine Suche.';

  @override
  String get helpFaqCatGeneral => 'Allgemein';

  @override
  String get helpFaqCatData => 'Meine Daten';

  @override
  String get helpFaqCatBiometrics => 'Biometrie';

  @override
  String get helpFaqCatExport => 'Exportieren';

  @override
  String get helpFaqQ1 => 'Was ist My Vitals?';

  @override
  String get helpFaqA1 =>
      'My Vitals ist eine persönliche Gesundheits-Tracking-App, mit der du deine Wohlbefindensindikatoren aufzeichnen und überwachen kannst: anthropometrische Messungen, Vitalzeichen, Lipidprofil und Körperzusammensetzung.';

  @override
  String get helpFaqQ2 => 'Werden meine Daten in der Cloud gespeichert?';

  @override
  String get helpFaqA2 =>
      'Nein. Alle deine Daten werden ausschließlich auf deinem Gerät gespeichert. My Vitals sendet keine Informationen an externe Server und gewährleistet so vollständige Privatsphäre.';

  @override
  String get helpFaqQ3 => 'Kann ich die App ohne Internet nutzen?';

  @override
  String get helpFaqA3 =>
      'Ja. My Vitals funktioniert vollständig offline. Du brauchst nur für App-Updates eine Verbindung.';

  @override
  String get helpFaqQ4 => 'Wie aktiviere ich die biometrische Sperre?';

  @override
  String get helpFaqA4 =>
      'Gehe zu Profil › Datenschutz & Sicherheit und aktiviere den Biometrische Sperre-Schalter. Dein Gerät muss Fingerabdruck oder FaceID konfiguriert haben.';

  @override
  String get helpFaqQ5 => 'Wie exportiere ich meinen Verlauf?';

  @override
  String get helpFaqA5 =>
      'In jedem Verlaufsbildschirm (Anthropometrisch, Vitalzeichen usw.) findest du oben die Schaltflächen \'PDF exportieren\' und \'Excel (CSV)\'.';

  @override
  String get helpFaqQ6 => 'Kann ich die Maßeinheiten ändern?';

  @override
  String get helpFaqA6 =>
      'Ja. Gehe zu Profil › Maßeinheiten und wähle zwischen dem metrischen (kg, cm) oder imperialen (lb, ft/in) System.';

  @override
  String get helpFaqQ7 => 'Was passiert, wenn ich die App lösche?';

  @override
  String get helpFaqA7 =>
      'Beim Deinstallieren der App werden alle lokal gespeicherten Daten dauerhaft gelöscht. Wir empfehlen, deinen Verlauf vor der Deinstallation als PDF oder CSV zu exportieren.';

  @override
  String get helpFaqQ8 => 'Ersetzt diese App meinen Arzt?';

  @override
  String get helpFaqA8 =>
      'Nein. My Vitals ist ein persönliches Tracking-Tool, das dir hilft, einen organisierten Datensatz zu führen. Konsultiere immer einen Gesundheitsfachmann für medizinische Interpretation und Diagnose.';

  @override
  String get helpGlossarySearchHint => 'Begriff suchen...';

  @override
  String get helpGlossaryGroupAnthropo => 'Anthropometrische Messungen';

  @override
  String get helpGlossaryGroupVitals => 'Vitalzeichen';

  @override
  String get helpGlossaryGroupLipid => 'Lipidprofil';

  @override
  String get helpGlossaryGroupBody => 'Körperzusammensetzung';

  @override
  String get helpGlossaryNormalRange => 'Normaler Bereich';

  @override
  String get helpLegalPurposeTitle => 'Zweck der Anwendung';

  @override
  String get helpLegalPurposeBody =>
      'My Vitals ist eine persönliche Gesundheits-Tracking-Anwendung, die Nutzern hilft, ihre Wohlbefindensindikatoren aufzuzeichnen und zu visualisieren. Es ist kein zertifiziertes Medizinprodukt.';

  @override
  String get helpLegalNotMedicalTitle => 'Kein Medizinprodukt';

  @override
  String get helpLegalNotMedicalBody =>
      'Die in dieser Anwendung angezeigten Informationen dienen nur als Referenz. Sie ersetzen nicht die Diagnose, den Rat oder die Behandlung eines Gesundheitsfachmanns. Konsultiere bei medizinischen Symptomen deinen Arzt.';

  @override
  String get helpLegalResponsibilityTitle => 'Verantwortung des Nutzers';

  @override
  String get helpLegalResponsibilityBody =>
      'Der Nutzer ist für die Richtigkeit der eingegebenen Daten verantwortlich. My Vitals haftet nicht für Gesundheitsentscheidungen, die auf der Grundlage von in der App aufgezeichneten Informationen getroffen wurden.';

  @override
  String get helpLegalPrivacyTitle => 'Datenschutz und Daten';

  @override
  String get helpLegalPrivacyBody =>
      'Alle Daten werden lokal auf dem Gerät des Nutzers gespeichert. My Vitals erfasst, übermittelt oder teilt keine persönlichen Informationen mit Dritten. Es gibt keine Benutzerkonten oder Datenserver.';

  @override
  String get helpLegalContactTitle => 'Entwicklerkontakt';

  @override
  String get helpLegalContactBody =>
      'Für rechtliche Anfragen oder Datenschutzfragen können Sie den Entwickler kontaktieren unter: yesithvalencia@gmail.com';

  @override
  String get helpContactReportBug => 'Fehler melden';

  @override
  String get helpContactReportBugDesc =>
      'Etwas funktioniert nicht richtig? Sag es uns.';

  @override
  String get helpContactSuggest => 'Vorschlag senden';

  @override
  String get helpContactSuggestDesc =>
      'Hast du eine Idee zur Verbesserung der App? Wir möchten sie hören.';

  @override
  String get helpContactSendEmail => 'E-Mail senden';

  @override
  String get helpContactAppVersion => 'App-Version';

  @override
  String get helpContactWhatsNew => 'Neuigkeiten';

  @override
  String get helpContactV110 => 'v1.1.0 — Aktuell';

  @override
  String get helpContactV110Changes =>
      '• Biometrische Sperre (Fingerabdruck / FaceID)\n• Personalisierte Gesundheitsziele\n• Unterstützung für italienische Sprache\n• Verbesserter Aktivitätslevel-Auswahl';

  @override
  String get helpContactV100 => 'v1.0.0 — Erstveröffentlichung';

  @override
  String get helpContactV100Changes =>
      '• Anthropometrisches Messungs-Tracking\n• Vitalzeichen und Lipidprofil\n• Körperzusammensetzung\n• PDF- und CSV-Export\n• Mehrsprachige Unterstützung (es, en, de, pt)';

  @override
  String get myDataBackup => 'Meine Daten';

  @override
  String get backupTitle => 'Sicherung & Wiederherstellung';

  @override
  String get backupDescription =>
      'Exportieren oder stellen Sie alle Ihre Daten und Einstellungen wieder her.';

  @override
  String get backupPrivacyTitle => 'Ihre Daten gehören Ihnen. Und nur Ihnen.';

  @override
  String get backupPrivacyBody =>
      'Alle unsere Gesundheitsfunktionen wurden mit dem Schwerpunkt auf Datenschutz entwickelt, um Ihre Daten sicher aufzubewahren.\n\nIhre Gesundheitsdaten sind auf Ihrem Gerät verschlüsselt und nur mit Ihrem Code, Touch ID oder Face ID zugänglich. Wir nutzen keine Cloud-Server und teilen Ihre Daten niemals mit Dritten.';

  @override
  String get backupPrivacyHighlight =>
      'Ihre Gesundheitsdaten werden lokal verschlüsselt und nicht einmal wir können auf Ihre Informationen zugreifen.';

  @override
  String get backupExportTitle => 'Meine Daten exportieren';

  @override
  String get backupExportSubtitle =>
      'Generieren Sie eine sichere Datei mit Ihrem gesamten Verlauf und Ihren Einstellungen';

  @override
  String get backupExportButton => 'Sicherung exportieren';

  @override
  String get backupImportTitle => 'Meine Daten wiederherstellen';

  @override
  String get backupImportSubtitle =>
      'Importieren Sie eine vorherige My Vitals-Sicherung';

  @override
  String get backupImportButton => 'Sicherung importieren';

  @override
  String get backupWhatIncluded => 'Was ist im Backup enthalten?';

  @override
  String get backupSuccess => 'Sicherung erfolgreich exportiert!';

  @override
  String get backupImportSuccess => 'Daten erfolgreich wiederhergestellt!';

  @override
  String get backupImportError =>
      'Importfehler. Stellen Sie sicher, dass die Datei gültig ist.';

  @override
  String get backupImportConfirmTitle => 'Daten wiederherstellen?';

  @override
  String get backupImportConfirmBody =>
      'Dadurch werden Ihre aktuellen Datensätze durch die aus der Sicherung ersetzt. Möchten Sie fortfahren?';

  @override
  String get backupIncludesVitalSigns => 'Vitalwerte-Verlauf';

  @override
  String get backupIncludesAnthropo => 'Anthropometrie-Verlauf';

  @override
  String get backupIncludesLipid => 'Lipidprofil';

  @override
  String get backupIncludesBodyComp => 'Körperzusammensetzung';

  @override
  String get backupIncludesPersonalInfo => 'Persönliche Daten';

  @override
  String get backupIncludesGoals => 'Gesundheitsziele';

  @override
  String get backupIncludesPhoto => 'Profilfoto';

  @override
  String get backupIncludesPreferences =>
      'Einstellungen (Sprache, Einheiten, Design, Erinnerungen, Gerät)';

  @override
  String get exportSuccess => 'Erfolgreich exportiert';

  @override
  String get exportError => 'Export fehlgeschlagen. Bitte erneut versuchen.';

  @override
  String get backupCancel => 'Abbrechen';

  @override
  String get onboardingWelcomeTitle => 'Willkommen bei My Vitals';

  @override
  String get onboardingWelcomeSubtitle =>
      'Dein persönlicher Gesundheitsbegleiter';

  @override
  String get onboardingWelcomeFeature1 =>
      'Erfasse deine Vitalzeichen und Körpermaße';

  @override
  String get onboardingWelcomeFeature2 =>
      'Visualisiere deinen Fortschritt mit Diagrammen';

  @override
  String get onboardingWelcomeFeature3 =>
      'Synchronisiere deinen Verlauf sicher auf deinen Geräten';

  @override
  String get onboardingNext => 'Weiter';

  @override
  String get onboardingFinish => 'Loslegen!';

  @override
  String get welcomeGetStarted => 'Loslegen';

  @override
  String get welcomeLogIn => 'Anmelden';

  @override
  String get welcomeAlreadyHaveAccount => 'Schon ein Konto?';

  @override
  String onboardingStep(int current, int total) {
    return 'Schritt $current von $total';
  }

  @override
  String get onboardingAvatarTitle => 'Dein Profilbild';

  @override
  String get onboardingAvatarSubtitle =>
      'Gib deiner Gesundheitsreise ein Gesicht (optional)';

  @override
  String get remindersTitle => 'Erinnerungen & Alarme';

  @override
  String get remindersDescription =>
      'Richten Sie tägliche Alarme ein, um an Ihre routinemäßigen medizinischen Kontrollen zu erinnern.';

  @override
  String get remindersNote =>
      '* Benachrichtigungen kommen täglich zur geplanten Zeit auf Ihr Gerät.';

  @override
  String get reminderVitals => 'Vitalfunktionen aufzeichnen';

  @override
  String get reminderMeds => 'Medikamente einnehmen';

  @override
  String get reminderWorkout => 'Körperliche Aktivität';

  @override
  String get reminderWater => 'Wasser trinken';

  @override
  String get reminderTitle => 'Medizinische Erinnerung';

  @override
  String get filterLast7Days => 'Letzte 7 Tage';

  @override
  String get filterLast30Days => 'Letzte 30 Tage';

  @override
  String get filterLast6Months => 'Letzte 6 Monate';

  @override
  String get filterAllTime => 'Gesamte Zeit';

  @override
  String goalRemainingWeight(String weight) {
    return '${weight}kg bis zum Ziel';
  }

  @override
  String get goalAchieved => 'Ziel erreicht!';

  @override
  String get noGoalDefined => 'Kein Ziel definiert';

  @override
  String get validationRequiredFields => 'Pflichtfelder';

  @override
  String get validationCompleteBeforeContinue =>
      'Bitte fülle diese Felder aus, bevor du fortfährst:';

  @override
  String get validationSelectLanguage => 'Wähle eine Sprache';

  @override
  String get validationEnterName => 'Gib deinen vollständigen Namen ein';

  @override
  String get validationSelectBirthDate => 'Wähle dein Geburtsdatum';

  @override
  String get validationSelectGender => 'Wähle dein Geschlecht';

  @override
  String get dashboardCompositionFat => 'FETT';

  @override
  String get dashboardCompositionMuscle => 'MUSKEL';

  @override
  String get dashboardCompositionVisceral => 'VISZERAL';

  @override
  String get dashboardCompositionBmr => 'GU';

  @override
  String get dashboardLastMeasured => 'Zuletzt gemessen';

  @override
  String dashboardCompositionLevel(int level) {
    return 'St. $level';
  }

  @override
  String get vitalsPdfTitle => 'Vitalzeichen-Verlauf';

  @override
  String get vitalsShareCsvSubject => 'Vitalzeichen-CSV';

  @override
  String get lipidPdfTitle => 'Lipidprofil-Verlauf';

  @override
  String get lipidShareCsvSubject => 'Labor-CSV';

  @override
  String get compositionPdfTitle => 'Körperzusammensetzung-Verlauf';

  @override
  String get compositionShareCsvSubject => 'Körperzusammensetzung-CSV';

  @override
  String get reminderDefaultTitle => 'Medizinische Erinnerung';

  @override
  String get exportColComment => 'Kommentar';

  @override
  String get exportColHeight => 'Größe (m)';

  @override
  String get exportColSysDia => 'Sys/Dia';

  @override
  String get exportColHrShort => 'HF';

  @override
  String get exportColStatus => 'Status';

  @override
  String get exportColSystolic => 'Systolisch';

  @override
  String get exportColDiastolic => 'Diastolisch';

  @override
  String get exportColHeartRate => 'Herzfrequenz';

  @override
  String get exportColActivityState => 'Aktivitätszustand';

  @override
  String get exportColSymptom => 'Symptom';

  @override
  String get exportColTotalCholShort => 'Ges.-Chol.';

  @override
  String get exportColTrigsShort => 'Trig.';

  @override
  String get exportColTotalCholesterol => 'Gesamtcholesterin';

  @override
  String get exportColTriglycerides => 'Triglyceride';

  @override
  String get exportColLabName => 'Labor';

  @override
  String get exportColBodyFat => 'Körperfett';

  @override
  String get exportColMuscleMass => 'Muskelmasse';

  @override
  String get exportColVisceralFat => 'Viszeralfett';

  @override
  String get exportColMetabolicAge => 'Stoffwechselalter';

  @override
  String get exportColBodyWater => 'Körperwasser';

  @override
  String get exportColBoneMass => 'Knochenmasse';

  @override
  String get exportColBmr => 'GU';

  @override
  String get glossaryImcName => 'BMI (Body-Mass-Index)';

  @override
  String get glossaryImcDefinition =>
      'Ein Maß, das Gewicht und Körpergröße in Beziehung setzt, um zu beurteilen, ob das Gewicht einer Person gesund ist. Berechnet durch Division des Gewichts (kg) durch das Quadrat der Körpergröße (m²).';

  @override
  String get glossaryImcRange => '18,5 – 24,9 kg/m²';

  @override
  String get glossaryPesoName => 'Körpergewicht';

  @override
  String get glossaryPesoDefinition =>
      'Gesamtmasse des Körpers in Kilogramm oder Pfund, einschließlich Muskeln, Knochen, Organe, Fett und Wasser.';

  @override
  String get glossaryPesoRange => 'Abhängig von Körpergröße und Statur';

  @override
  String get glossaryTallaName => 'Körpergröße';

  @override
  String get glossaryTallaDefinition =>
      'Maß der Körpergröße einer Person von den Füßen bis zum Scheitelpunkt, ausgedrückt in Zentimetern oder Metern.';

  @override
  String get glossarySistolicaName => 'Systolischer Druck';

  @override
  String get glossarySistolicaDefinition =>
      'Der maximale Druck, den das Blut auf die Arterien ausübt, wenn das Herz sich zusammenzieht (schlägt). Es ist die obere Zahl bei einer Blutdruckmessung.';

  @override
  String get glossarySistolicaRange => '< 120 mmHg';

  @override
  String get glossaryDiastolicaName => 'Diastolischer Druck';

  @override
  String get glossaryDiastolicaDefinition =>
      'Der minimale Druck, den das Blut auf die Arterien zwischen den Herzschlägen ausübt, wenn das Herz in Ruhe ist. Es ist die untere Zahl bei einer Blutdruckmessung.';

  @override
  String get glossaryDiastolicaRange => '< 80 mmHg';

  @override
  String get glossaryFcName => 'Herzfrequenz';

  @override
  String get glossaryFcDefinition =>
      'Anzahl der Herzschläge pro Minute (bpm). In Ruhe schlägt ein gesundes Herz regelmäßig innerhalb eines bestimmten Bereichs.';

  @override
  String get glossaryFcRange => '60 – 100 Schläge/min in Ruhe';

  @override
  String get glossaryColesterolTotalName => 'Gesamtcholesterin';

  @override
  String get glossaryColesterolTotalDefinition =>
      'Summe aller Cholesterinwerte im Blut, einschließlich LDL, HDL und anderen Lipiden. Allgemeiner Marker für kardiovaskuläres Risiko.';

  @override
  String get glossaryColesterolTotalRange => '< 200 mg/dL';

  @override
  String get glossaryLdlName => 'LDL (\"Schlechtes\" Cholesterin)';

  @override
  String get glossaryLdlDefinition =>
      'Lipoprotein niedriger Dichte. Transportiert Cholesterin in die Arterien und kann sich in deren Wänden ansammeln, was das Herzerkrankungsrisiko erhöht.';

  @override
  String get glossaryLdlRange => '< 100 mg/dL';

  @override
  String get glossaryHdlName => 'HDL (\"Gutes\" Cholesterin)';

  @override
  String get glossaryHdlDefinition =>
      'Lipoprotein hoher Dichte. Sammelt überschüssiges Cholesterin aus den Arterien und transportiert es zur Leber. Hohe Werte sind schützend.';

  @override
  String get glossaryHdlRange => '≥ 60 mg/dL';

  @override
  String get glossaryVldlName => 'VLDL';

  @override
  String get glossaryVldlDefinition =>
      'Lipoprotein sehr niedriger Dichte. Transportiert Triglyceride von der Leber zu den Geweben. Erhöhte Werte sind mit höherem kardiovaskulärem Risiko verbunden.';

  @override
  String get glossaryVldlRange => '2 – 30 mg/dL';

  @override
  String get glossaryTrigliceridosName => 'Triglyceride';

  @override
  String get glossaryTrigliceridosDefinition =>
      'Eine Art Fett (Lipid) im Blut. Der Körper nutzt sie als Energiequelle, aber hohe Werte erhöhen das Risiko von Herz- und Bauchspeicheldrüsenerkrankungen.';

  @override
  String get glossaryTrigliceridosRange => '< 150 mg/dL';

  @override
  String get glossaryGrasaName => 'Körperfettanteil';

  @override
  String get glossaryGrasaDefinition =>
      'Anteil der Fettmasse am Gesamtkörpergewicht. Umfasst essenzielles Fett (für lebenswichtige Funktionen) und Reservefett.';

  @override
  String get glossaryGrasaRange => 'Männer: 8–19% / Frauen: 21–33%';

  @override
  String get glossaryMusculoName => 'Muskelmasse';

  @override
  String get glossaryMusculoDefinition =>
      'Gesamtgewicht des Muskelgewebes im Körper in Kilogramm. Ein höherer Muskelanteil ist mit einem aktiveren Stoffwechsel verbunden.';

  @override
  String get glossaryGrasaVisceralName => 'Viszeralfett';

  @override
  String get glossaryGrasaVisceralDefinition =>
      'Fett, das sich um die inneren Bauchorgane (Leber, Darm, Bauchspeicheldrüse) ansammelt. Hohe Werte sind mit höherem metabolischem und kardiovaskulärem Risiko verbunden.';

  @override
  String get glossaryGrasaVisceralRange => 'Niveau 1–9 (gesund)';

  @override
  String get glossaryEdadMetabolicaName => 'Metabolisches Alter';

  @override
  String get glossaryEdadMetabolicaDefinition =>
      'Geschätztes Alter des Grundumsatzes im Vergleich zum Bevölkerungsdurchschnitt. Ein metabolisches Alter unter dem chronologischen Alter zeigt einen effizienten Stoffwechsel.';

  @override
  String get glossaryBmrName => 'Grundumsatz / BMR (kcal)';

  @override
  String get glossaryBmrDefinition =>
      'Mindestmenge an Energie (Kalorien), die der Körper in vollständiger Ruhe zur Aufrechterhaltung der Lebensfunktionen benötigt: Atmung, Kreislauf, Temperatur usw.';

  @override
  String get glossaryAguaName => 'Körperwasser';

  @override
  String get glossaryAguaDefinition =>
      'Anteil des Körpergewichts, der Wasser entspricht. Wasser ist für alle Zellfunktionen, Temperaturregulierung und Nährstofftransport unerlässlich.';

  @override
  String get glossaryAguaRange => '50 – 65%';

  @override
  String get glossaryHuesoName => 'Knochenmasse';

  @override
  String get glossaryHuesoDefinition =>
      'Geschätztes Gewicht des Knochengewebes im Körper. Die Aufrechterhaltung einer ausreichenden Knochenmasse ist wichtig, um Osteoporose vorzubeugen.';

  @override
  String get glossaryHuesoRange => '2 – 4 kg (Durchschnittserwachsener)';

  @override
  String get deleteRecordTitle => 'Eintrag löschen?';

  @override
  String get deleteRecordBody =>
      'Diese Aktion kann nicht rückgängig gemacht werden.';

  @override
  String get deleteRecordConfirm => 'Löschen';

  @override
  String get recordDeleted => 'Eintrag gelöscht';

  @override
  String get anthropoSavedSuccess => 'Messung erfolgreich gespeichert.';

  @override
  String historyShowMore(int count) {
    return '$count weitere anzeigen';
  }

  @override
  String get introSignIn => 'Anmelden';

  @override
  String get introRegister => 'Konto erstellen';

  @override
  String get emailLabel => 'E-Mail';

  @override
  String get validationEnterEmail => 'Gib deine E-Mail-Adresse ein';

  @override
  String get validationEmailFormat =>
      'Prüfe die E-Mail-Adresse: @ oder Domain fehlt';

  @override
  String validationOutOfRange(Object max, Object min) {
    return 'Gib einen Wert zwischen $min und $max ein';
  }

  @override
  String get commonRegisterFailed =>
      'Wir konnten dein Konto nicht erstellen. Prüfe die Verbindung und versuche es erneut.';

  @override
  String get logOutConfirm =>
      'Auf diesem Gerät abmelden? Deine Einträge bleiben auf dem Gerät und werden bei der nächsten Anmeldung wieder synchronisiert.';

  @override
  String get pendingAccountTitle => 'Konto ausstehend';

  @override
  String get pendingAccountBody =>
      'Deine Daten sind auf diesem Gerät gespeichert. Wir erstellen dein Konto, sobald eine Verbindung besteht.';

  @override
  String get pendingAccountCreateNow => 'Mein Konto jetzt erstellen';

  @override
  String get pendingAccountCreating => 'Dein Konto wird erstellt…';

  @override
  String get pendingAccountCreated =>
      'Konto erstellt. Deine Einträge werden hochgeladen.';

  @override
  String get pendingAccountStillOffline =>
      'Noch keine Verbindung. Deine Daten bleiben sicher auf diesem Gerät.';

  @override
  String get identifyTitle => 'Holen wir deine Historie';

  @override
  String get identifyBody =>
      'Gib deine Ausweisnummer (oder E-Mail) ein. Wenn du bereits Patient bist, laden wir deine Daten; sonst legen wir dein Konto an.';

  @override
  String get identifyFieldLabel => 'Ausweisnummer oder E-Mail';

  @override
  String get identifyFieldHint => 'z. B. 1032456789';

  @override
  String get identifyFoundTitle =>
      'Wir haben eine Krankengeschichte zu dieser Ausweisnummer gefunden.';

  @override
  String get identifyFoundBody =>
      'Wir können sie übernehmen und dein Konto aktivieren, damit du deine Daten vom ersten Tag an siehst.';

  @override
  String get identifyBringHistory => 'Historie übernehmen und fortfahren';

  @override
  String get identifyBringingHistory => 'Historie wird übernommen …';

  @override
  String get identifyNotMe => 'Das bin nicht ich – neu registrieren';

  @override
  String get verifyAppBarTitle => 'Verifizierung';

  @override
  String get verifyTitle => 'Wir haben dein Konto gefunden';

  @override
  String verifyBody(String identifier) {
    return 'Bestätige deine Identität, um mit\n$identifier fortzufahren.';
  }

  @override
  String get verifyPasswordLabel => 'Passwort';

  @override
  String get verifyTestNotice =>
      'Testphase: Das Passwort lautet 1234. (In der Produktion steht hier der OTP-Code.)';

  @override
  String get verifySubmit => 'Anmelden';

  @override
  String unexpectedError(String details) {
    return 'Unerwarteter Fehler: $details';
  }

  @override
  String get accountSyncTitle => 'Konto und Synchronisierung';

  @override
  String get accountSyncDescription =>
      'Melde dich an und synchronisiere deine Einträge mit dem Server.';

  @override
  String get accountYourAccount => 'Dein Konto';

  @override
  String get accountPendingBody =>
      'Deine Daten liegen auf diesem Gerät. Das Konto muss noch auf dem Server angelegt werden.';

  @override
  String get accountLoggedOutBody =>
      'Melde dich an, wenn du bereits Patient bist, oder registriere dich.';

  @override
  String get accountFallbackName => 'Patient';

  @override
  String get accountFromLegacy => 'Aus dem Altsystem übernommenes Konto';

  @override
  String get accountCreatedInApp => 'In der App erstelltes Konto';

  @override
  String get accountSignOut => 'Abmelden';

  @override
  String get accountSyncSection => 'Synchronisierung';

  @override
  String get accountSyncBody => 'Lade deine lokalen Einträge auf den Server.';

  @override
  String get accountSyncing => 'Wird synchronisiert …';

  @override
  String get accountSyncNow => 'Jetzt synchronisieren';

  @override
  String get accountHaveAccount =>
      'Ich habe bereits ein Konto (übernommener Patient)';

  @override
  String get accountImNew => 'Ich bin neu (registrieren)';

  @override
  String get accountCreateAccount => 'Konto erstellen';

  @override
  String get accountNewHere => 'Ich bin neu (registrieren)';

  @override
  String get accountDocumentOptional => 'Dokument (optional)';

  @override
  String get accountNameLabel => 'Name';

  @override
  String get accountEmailLabel => 'E-Mail';

  @override
  String get deviceScreenTitle => 'Mein Messgerät';

  @override
  String get deviceScreenDescription =>
      'Wähle die Waage, die du nutzt, damit wir deine Messungen einordnen können.';

  @override
  String get deviceNoneTitle => 'Ich benutze keine';

  @override
  String get deviceNoneSubtitle =>
      'Ich erfasse nur manuelle Messwerte (Gewicht, Taille, Größe).';

  @override
  String get deviceNoneSaved => 'Gespeichert: Du nutzt keine Bioimpedanz.';

  @override
  String get deviceCatalogError =>
      'Katalog konnte nicht aktualisiert werden. Es werden die gespeicherten Optionen angezeigt.';

  @override
  String get deviceAvailableScales => 'VERFÜGBARE WAAGEN';

  @override
  String get deviceWhyItMatters =>
      'Jede Bioimpedanzwaage interpretiert Fett, Muskeln und viszerales Fett mit eigenen Bereichen. Sag uns, welche du nutzt, damit wir zeigen können, ob deine Werte niedrig, normal oder hoch sind. Du kannst das jederzeit ändern.';

  @override
  String get circumferencesSection => 'KÖRPERUMFÄNGE (OPTIONAL)';

  @override
  String get circWaist => 'Taille';

  @override
  String get circHip => 'Hüfte';

  @override
  String get circLowerAbdomen => 'Unterbauch';

  @override
  String get circArm => 'Arm';

  @override
  String get circLeg => 'Bein';

  @override
  String get circChestBust => 'Brust/Büste';

  @override
  String get circAbdomenShort => 'Bauch';

  @override
  String get lipidLabQuestion => 'In welchem Labor wurde der Test gemacht?';

  @override
  String get lipidLabLoading => 'Labore werden geladen …';

  @override
  String get lipidLabNotSpecified => 'Nicht angegeben / weiß nicht';

  @override
  String get lipidLabOther => 'Andere (angeben)';

  @override
  String get compositionSkeletalMuscle => 'Skelettmuskulatur';

  @override
  String get compositionSkeletalMuscleRef =>
      'Wie von deiner Waage angegeben (%)';

  @override
  String get profileAppTheme => 'App-Design';

  @override
  String get profileRankObserver => 'Vitaler Beobachter';

  @override
  String get themeBankLabel => 'DESIGN-BIBLIOTHEK';

  @override
  String get themePickTitle => 'Wähle das Aussehen';

  @override
  String get themePickBody =>
      'Ändert Farben und Typografie. Navigation, Symbole und die Bedeutung jeder Farbe bleiben unverändert.';

  @override
  String get themeSettingsBody =>
      'Die Änderung wirkt sofort und wird gemerkt. Navigation, Symbole und die Bedeutung jeder Farbe bleiben unverändert.';

  @override
  String themeContinueWith(String theme) {
    return 'Weiter mit $theme';
  }

  @override
  String deviceSelectedSaved(String device) {
    return '$device ausgewählt.';
  }

  @override
  String deviceWillSyncLater(String message) {
    return '$message Wird synchronisiert, sobald du online bist.';
  }

  @override
  String get introDemo => 'Demo ansehen';

  @override
  String get demoNoticeTitle => 'Du bist in der Demo';

  @override
  String get demoNoticeBody =>
      'Alles, was du siehst, gehört zu einer erfundenen Patientenakte. Du kannst Messwerte erfassen und bearbeiten: nichts wird gespeichert, und beim Verlassen der Demo verschwindet alles.';

  @override
  String get demoNoticeAction => 'Verstanden';

  @override
  String get demoBannerLabel => 'Demodaten';

  @override
  String get demoExit => 'Demo verlassen';

  @override
  String get profileRankTier2 => 'Beständiger Begleiter';

  @override
  String get profileRankTier3 => 'Wellness-Veteran';

  @override
  String get mhxDocTitle => 'Persönliche Gesundheitsübersicht';

  @override
  String get mhxDocSubtitle =>
      'Konsolidierter Bericht selbst erfasster Messwerte';

  @override
  String get mhxPatient => 'Patient';

  @override
  String get mhxBirthDate => 'Geburtsdatum';

  @override
  String get mhxPeriodCovered => 'Erfasster Zeitraum';

  @override
  String get mhxGeneratedOn => 'Erstellt am';

  @override
  String get mhxSource => 'Quelle';

  @override
  String get mhxGeneratedBy => 'Erstellt von';

  @override
  String get mhxReportRef => 'Bericht-Nr.';

  @override
  String get mhxSelfReported => 'selbst erfasste Daten';

  @override
  String get mhxDisclaimerTitle =>
      'Zusammenfassung zur Information - keine medizinische Diagnose';

  @override
  String get mhxDisclaimerBody =>
      'Dieses Dokument wurde automatisch aus vom Nutzer erfassten Messwerten erstellt. Es ist keine medizinische Diagnose und keine offizielle Krankenakte und ersetzt nicht die Beurteilung durch eine medizinische Fachkraft.';

  @override
  String get mhxSummaryTitle => 'Zusammenfassung der letzten Werte';

  @override
  String get mhxColIndicator => 'Indikator';

  @override
  String get mhxColLatest => 'Letzter Wert';

  @override
  String get mhxColReference => 'Referenz';

  @override
  String get mhxColStatus => 'Status';

  @override
  String get mhxColNotes => 'Anmerkungen';

  @override
  String get mhxBloodPressure => 'Blutdruck';

  @override
  String get mhxHeartRate => 'Herzfrequenz';

  @override
  String get mhxWeight => 'Gewicht';

  @override
  String get mhxBmi => 'BMI';

  @override
  String get mhxBodyFat => 'Körperfett';

  @override
  String get mhxVisceralFat => 'Viszeralfett';

  @override
  String get mhxTotalCholesterol => 'Gesamtcholesterin';

  @override
  String get mhxLdl => 'LDL';

  @override
  String get mhxHdl => 'HDL';

  @override
  String get mhxTriglycerides => 'Triglyceride';

  @override
  String get mhxSystolic => 'Systolisch';

  @override
  String get mhxDiastolic => 'Diastolisch';

  @override
  String get mhxStatsMeasurements => 'Messungen';

  @override
  String get mhxStatsAverage => 'Durchschnitt';

  @override
  String get mhxStatsRange => 'Bereich';

  @override
  String get mhxStatsLatest => 'Aktuell';

  @override
  String get mhxFooterDisclaimer =>
      'Datenquelle: vom Patienten über die App MY VITALS mit persönlichen Geräten erfasste Messwerte, die möglicherweise nicht klinisch kalibriert sind; ihre Genauigkeit ist nicht von einer Fachkraft oder einem akkreditierten Labor geprüft. Die angegebenen Referenzbereiche sind Richtwerte und gelten möglicherweise nicht für Ihre individuelle Situation; ein als außerhalb des Bereichs markierter Wert ist keine Diagnose. Treffen Sie ohne fachliche Aufsicht keine Behandlungsentscheidungen auf Grundlage dieses Dokuments. Es enthält persönliche Gesundheitsdaten: Der Nutzer ist für deren Aufbewahrung und Weitergabe verantwortlich.';

  @override
  String get mhxButton => 'Vollständige Krankengeschichte exportieren';

  @override
  String get mhxHubHint =>
      'Ein PDF mit deinen vier Indikatoren für den Arztbesuch.';

  @override
  String get mhxChoosePeriod => 'Zeitraum wählen';

  @override
  String get mhxPeriod6Months => 'Letzte 6 Monate';

  @override
  String get mhxPeriod1Year => 'Letztes Jahr';

  @override
  String get mhxPeriodAll => 'Gesamter Verlauf';

  @override
  String get mhxGenerate => 'PDF erstellen';

  @override
  String get mhxNoData => 'Es gibt noch keine Messwerte zum Exportieren.';

  @override
  String mhxAgeYears(int years) {
    return '$years J.';
  }

  @override
  String mhxPageOf(int current, int total) {
    return 'Seite $current von $total';
  }

  @override
  String get medicationsTitle => 'Medikamente';

  @override
  String get medicationsMenuTitle => 'Medikamente';

  @override
  String get medicationAdd => 'Medikament hinzufügen';

  @override
  String get medicationTaken => 'Eingenommen';

  @override
  String get medicationSkipped => 'Übersprungen';

  @override
  String get medicationRefill => 'Nachfüllen';

  @override
  String medicationDoseNotifTitle(String name) {
    return 'Zeit für $name';
  }

  @override
  String get medicationDoseNotifBody => 'Es ist Zeit für deine Einnahme.';

  @override
  String medicationRefillNotifTitle(String name) {
    return '$name nachfüllen';
  }

  @override
  String get medicationRefillNotifBody => 'Dein Vorrat geht zur Neige.';

  @override
  String medicationUnitsLeft(int count) {
    return 'Noch $count Einheiten';
  }

  @override
  String get medicationOutOfStock => 'Nicht vorrätig';

  @override
  String get medFormNameCapsule => 'Kapsel';

  @override
  String get medFormNameTablet => 'Tablette';

  @override
  String get medFormNameLiquid => 'Flüssigkeit';

  @override
  String get medFormNameInjection => 'Injektion';

  @override
  String get medFormNameDrops => 'Tropfen';

  @override
  String get medFormNameOther => 'Einheit';

  @override
  String medUnitCapsule(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Kapseln',
      one: 'Kapsel',
    );
    return '$_temp0';
  }

  @override
  String medUnitTablet(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Tabletten',
      one: 'Tablette',
    );
    return '$_temp0';
  }

  @override
  String medUnitLiquid(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'ml',
      one: 'ml',
    );
    return '$_temp0';
  }

  @override
  String medUnitInjection(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Injektionen',
      one: 'Injektion',
    );
    return '$_temp0';
  }

  @override
  String medUnitDrops(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Tropfen',
      one: 'Tropfen',
    );
    return '$_temp0';
  }

  @override
  String medUnitOther(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Einheiten',
      one: 'Einheit',
    );
    return '$_temp0';
  }

  @override
  String get medScheduleDaily => 'Jeden Tag';

  @override
  String medScheduleEveryNDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Alle $count Tage',
      one: 'Jeden Tag',
    );
    return '$_temp0';
  }

  @override
  String get medMenuDescription =>
      'Verwalte deine Einnahmen, deinen Bestand und deine Adhärenz an einem Ort.';

  @override
  String medMenuTodaySubtitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Einnahmen offen',
      one: '1 Einnahme offen',
      zero: 'Keine Einnahmen offen',
    );
    return '$_temp0';
  }

  @override
  String medMenuInventorySubtitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count gehen zur Neige',
      one: '1 geht zur Neige',
      zero: 'Alles vorrätig',
    );
    return '$_temp0';
  }

  @override
  String medMenuAdherenceSubtitle(int pct, int streak) {
    return '$pct% diesen Monat · $streak Tage in Folge';
  }

  @override
  String get medTodayTitle => 'Heute';

  @override
  String get medTodayDescription =>
      'Erfasse die heutigen Einnahmen und prüfe das Erledigte.';

  @override
  String get medSectionToTakeToday => 'HEUTE EINZUNEHMEN';

  @override
  String get medSectionLogged => 'ERFASST';

  @override
  String get medSectionYourMeds => 'DEINE MEDIKAMENTE';

  @override
  String medDosesProgress(int done, int total) {
    return '$done von $total';
  }

  @override
  String get medNoPendingToday => 'Keine Einnahmen mehr für heute.';

  @override
  String get medInventoryTitle => 'Bestand';

  @override
  String get medInventoryDescription =>
      'Wie viele Einheiten übrig sind und wann nachzufüllen ist.';

  @override
  String get medSectionInventory => 'BESTAND';

  @override
  String medStockLeftUnits(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Einheiten übrig',
      one: '1 Einheit übrig',
    );
    return '$_temp0';
  }

  @override
  String medRunsOutOn(String date) {
    return 'leer am $date';
  }

  @override
  String medStockDonutOf(int total) {
    return 'von $total';
  }

  @override
  String get medAdherenceTitle => 'Adhärenz';

  @override
  String get medAdherenceDescription =>
      'Deine Beständigkeit bei der Behandlung im Monatsverlauf.';

  @override
  String medComplianceMonth(String month) {
    return 'Adhärenz · $month';
  }

  @override
  String get medStreakDays => 'Tage in Folge';

  @override
  String get medLegendTaken => 'Eingenommen';

  @override
  String get medLegendSkipped => 'Verpasst';

  @override
  String get medLegendNoData => 'Keine Daten';

  @override
  String get medSectionSchedule => 'PLAN';

  @override
  String get medSectionAdherence => 'ADHÄRENZ';

  @override
  String get medSectionInformation => 'INFORMATION';

  @override
  String medRemainingUnits(int count) {
    return '$count Einheiten';
  }

  @override
  String medBuyBefore(String date) {
    return 'Kaufe vor dem $date';
  }

  @override
  String medPackAndThreshold(int pack, int threshold) {
    return 'Packung mit $pack · Warnung bei: $threshold';
  }

  @override
  String get medThisMonth => 'diesen Monat';

  @override
  String get medEdit => 'Bearbeiten';

  @override
  String get medDelete => 'Löschen';

  @override
  String get medDeleteTitle => 'Medikament löschen?';

  @override
  String get medDeleteBody =>
      'Das Medikament und sein gesamter Verlauf werden gelöscht. Dies kann nicht rückgängig gemacht werden.';

  @override
  String get medInfoSoon => 'Bald';

  @override
  String get medInfoSoonBody =>
      'Wechselwirkungen, Schwangerschaft und Stillzeit.';

  @override
  String get medRegisterDose => 'Einnahme erfassen';

  @override
  String medDoseAtTime(String amount, String time) {
    return '$amount um $time';
  }

  @override
  String get medSkip => 'Überspringen';

  @override
  String medMultipleTitle(int count, String time) {
    return '$count Einnahmen um $time';
  }

  @override
  String get medMultipleSubtitle =>
      'Markiere einzeln oder erfasse alle auf einmal.';

  @override
  String get medSkipRest => 'Rest überspringen';

  @override
  String medRegisterNSelected(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Einnahmen erfassen',
      one: '1 Einnahme erfassen',
      zero: 'Einnahmen erfassen',
    );
    return '$_temp0';
  }

  @override
  String get medNotifTitle => 'Erinnerungen aktivieren';

  @override
  String get medNotifBody =>
      'Wir erinnern dich zu jeder Einnahmezeit und wenn dein Bestand zur Neige geht. Du kannst das jederzeit ändern.';

  @override
  String get medNotifWebWarning =>
      'Benachrichtigungen sind in der Web-Version nicht verfügbar. Nutze die App für iOS oder Android.';

  @override
  String get medAllowNotifications => 'Benachrichtigungen erlauben';

  @override
  String get medNotNow => 'Jetzt nicht';

  @override
  String medWizardStepOf(int step, int total) {
    return 'SCHRITT $step VON $total';
  }

  @override
  String get medBack => 'Zurück';

  @override
  String get medStepIdentity => 'Identität';

  @override
  String get medStepDose => 'Dosis';

  @override
  String get medStepFrequency => 'Häufigkeit';

  @override
  String get medStepDates => 'Daten';

  @override
  String get medStepInventory => 'Bestand';

  @override
  String get medFieldName => 'NAME';

  @override
  String get medFieldForm => 'FORM';

  @override
  String get medFieldStrength => 'STÄRKE';

  @override
  String get medFieldColorIcon => 'FARBE & SYMBOL';

  @override
  String get medShapeCapsule => 'Kapsel';

  @override
  String get medShapeRound => 'Rund';

  @override
  String get medFieldReason => 'WOFÜR (OPTIONAL)';

  @override
  String get medFieldQtyPerDose => 'MENGE PRO EINNAHME';

  @override
  String get medWithFood => 'Mit dem Essen einnehmen';

  @override
  String get medWithFoodSub => 'Hinweis in der Erinnerung';

  @override
  String get medSpecialInstruction => 'Besondere Anweisung';

  @override
  String get medSpecialInstructionSub => 'Z. B. in Wasser auflösen';

  @override
  String get medFreqDaily => 'Täglich';

  @override
  String get medFreqSpecificDays => 'Bestimmte Tage';

  @override
  String get medFreqEveryNDays => 'Alle N Tage';

  @override
  String get medFieldWeekdays => 'WOCHENTAGE';

  @override
  String get medFieldDoseTimes => 'EINNAHMEZEITEN';

  @override
  String get medAddTime => 'Zeit hinzufügen';

  @override
  String get medIntervalLabel => 'Alle wie viele Tage';

  @override
  String get medFieldStart => 'BEGINN';

  @override
  String get medWithEndDate => 'Mit Enddatum';

  @override
  String get medWithEndDateSub => 'Beende die Behandlung an einem Datum';

  @override
  String get medFieldEnd => 'ENDE';

  @override
  String get medTrackInventory => 'Bestand verwalten';

  @override
  String get medTrackInventorySub => 'Zieht bei jeder Einnahme vom Bestand ab';

  @override
  String get medCurrentUnits => 'Aktuelle Einheiten';

  @override
  String get medAlertWhenRemaining => 'Warnen, wenn übrig';

  @override
  String get medLeadTimeDays => 'Vorlauf (Tage)';

  @override
  String get medPackSize => 'Packungsgröße';

  @override
  String get medRefillAlerts => 'Nachfüll-Warnungen';

  @override
  String get medRefillAlertsSub => 'Mit geschätztem Stichtag';

  @override
  String get medSaveMedication => 'Medikament speichern';

  @override
  String get medContinue => 'Weiter';

  @override
  String get medErrorNameRequired => 'Gib einen Namen ein';

  @override
  String get medErrorSelectDays => 'Wähle mindestens einen Tag';

  @override
  String get medErrorAddTime => 'Füge mindestens eine Zeit hinzu';

  @override
  String get medUnitsSuffix => 'Einh.';

  @override
  String get medRefillTitle => 'Bestand nachfüllen';

  @override
  String medRunsOutInDays(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days Tagen',
      one: '1 Tag',
    );
    return 'Leer in ~$_temp0';
  }

  @override
  String get medAddABox => 'Eine Packung hinzufügen';

  @override
  String get medAddABoxSub => 'Wird zum aktuellen Bestand addiert';

  @override
  String medWillRemain(int units, int days) {
    return '$units Einheiten übrig · reicht ~$days Tage';
  }

  @override
  String get medRemindOneDay => 'In 1 Tag erinnern';

  @override
  String get medBought => 'Ich habe es gekauft';

  @override
  String get medEmptyTitle => 'Noch keine Medikamente';

  @override
  String get medEmptyBody =>
      'Füge dein erstes Medikament hinzu und wir erinnern dich an jede Einnahme und warnen dich, bevor es ausgeht.';

  @override
  String get medDashTodayLabel => 'HEUTIGE EINNAHMEN';

  @override
  String get medDashSeeModule => 'Modul ansehen ›';

  @override
  String get medDashNextDose => 'Nächste Einnahme';

  @override
  String get medDashNoDoses => 'Keine anstehenden Einnahmen';

  @override
  String medLowStockBannerTitle(String name, int count) {
    return '$name hat noch $count Einheiten';
  }

  @override
  String get medDashMedsTitle => 'Medikamente';

  @override
  String get medDashApptsTitle => 'Arzttermine';

  @override
  String get medDashApptsSoon => 'Demnächst';

  @override
  String medDashTodayProgress(int done, int total) {
    return '$done/$total heute';
  }

  @override
  String medDashStreakShort(int days) {
    return '$days T';
  }

  @override
  String get medDashAllDone => 'Alles erledigt';

  @override
  String get medDashAddMed => 'Hinzufügen';

  @override
  String medDashLowShort(int count) {
    return 'Noch $count';
  }
}
