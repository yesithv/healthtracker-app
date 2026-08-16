// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Italian (`it`).
class AppLocalizationsIt extends AppLocalizations {
  AppLocalizationsIt([String locale = 'it']) : super(locale);

  @override
  String get appTitle => 'I miei parametri';

  @override
  String get dashboard => 'Pannello';

  @override
  String get history => 'Cronologia';

  @override
  String get record => 'Registra';

  @override
  String get discover => 'Scopri';

  @override
  String get profile => 'Profilo';

  @override
  String get language => 'Lingua';

  @override
  String get savePreferences => 'Salva Preferenze';

  @override
  String get selectLanguage => 'Seleziona la tua lingua preferita';

  @override
  String get personalInfo => 'Info Personali';

  @override
  String get measurementUnits => 'Unità di Misura';

  @override
  String get notifications => 'Notifiche';

  @override
  String get privacySecurity => 'Privacy e Sicurezza';

  @override
  String get helpSupport => 'Aiuto e Supporto';

  @override
  String get logOut => 'Esci';

  @override
  String level(int value) {
    return 'Livello $value';
  }

  @override
  String get newUserInfo => 'Nuovo Utente';

  @override
  String xpForNextLevel(int current, int total) {
    return '$current / $total XP per il prossimo livello';
  }

  @override
  String get levelProgress => 'Progresso Livello';

  @override
  String get vitalSigns => 'Segni Vitali';

  @override
  String get vitalsSubtitle => 'Pressione sanguigna e frequenza cardiaca';

  @override
  String get noDataYet => 'Nessun dato registrato ancora.';

  @override
  String get recordVitalsAction => 'Registra pressione e frequenza ›';

  @override
  String get bodyComposition => 'Composizione Corporea';

  @override
  String get compositionSubtitle => 'Grasso, muscoli, acqua e massa ossea.';

  @override
  String get completeBodyProfile => 'Completa il tuo profilo corporeo ›';

  @override
  String get anthropometricHistory => 'Cronologia Antropometrica';

  @override
  String get anthroSubtitle => 'Misura peso, altezza e progresso fisico.';

  @override
  String get recordFirstMeasure => 'Registra la tua prima misurazione ›';

  @override
  String get lipidProfile => 'Profilo Lipidico';

  @override
  String get lipidSubtitle => 'Monitora colesterolo e trigliceridi.';

  @override
  String get recordLabResults => 'Registra i risultati del laboratorio ›';

  @override
  String get medicalDisclaimerTitle => 'Avvertenza Medica';

  @override
  String get medicalDisclaimerText =>
      'Questa applicazione è a solo scopo informativo e di tracciamento personale. Non sostituisce la consulenza, la diagnosi o il trattamento medico professionale. Chiedi sempre il parere del tuo medico o di un altro fornitore di salute qualificato per qualsiasi domanda.';

  @override
  String get selfCareProgress => 'Progresso della Cura Personale';

  @override
  String get myHealthAchievements => 'I Miei Obiettivi di Salute';

  @override
  String get badgeFirstStep => 'Primo Passo';

  @override
  String get badgeFirstStepDesc => 'L\'inizio del viaggio';

  @override
  String get badgeStrongHeart => 'Cuore Forte';

  @override
  String get badgeStrongHeartDesc => 'Salute Cardio';

  @override
  String get badgeVitalHabit => 'Abitudine Vitale';

  @override
  String get badgeVitalHabitDesc => '7 giorni di fila';

  @override
  String get badgeAwareness => 'Consapevolezza';

  @override
  String get badgeAwarenessDesc => 'Quadro Generale';

  @override
  String get badgeBalance => 'Equilibrio';

  @override
  String get badgeBalanceDesc => 'Obiettivo corporeo';

  @override
  String get badgeGuardian => 'Guardiano';

  @override
  String get badgeGuardianDesc => 'Impegno';

  @override
  String get metricSystem => 'Metrico (kg, cm, °C)';

  @override
  String get registerIndicators => 'Registra Indicatori';

  @override
  String get anthropometry => 'Antropometria';

  @override
  String get unitOfMeasureTitle => 'Unità di Misura';

  @override
  String get unitOfMeasureDescription =>
      'Come preferisci visualizzare le tue misurazioni? Seleziona il sistema più adatto a te per un tracciamento accurato.';

  @override
  String get metricOption => 'Metrico (kg, cm)';

  @override
  String get metricSubtitle => 'Chilogrammi e centimetri';

  @override
  String get imperialOption => 'Imperiale (lb, ft/in)';

  @override
  String get imperialSubtitle => 'Libbre e piedi/pollici';

  @override
  String get continueAction => 'Continua';

  @override
  String get languageTitle => 'Selezione Lingua';

  @override
  String get languageDescription =>
      'Seleziona la tua lingua preferita per adattare l\'applicazione alle tue esigenze. Puoi cambiarla in qualsiasi momento da questa schermata.';

  @override
  String get profileImageTitle => 'Immagine del Profilo';

  @override
  String get gallery => 'Galleria';

  @override
  String get camera => 'Fotocamera';

  @override
  String get deletePhoto => 'Elimina foto';

  @override
  String get cancel => 'Annulla';

  @override
  String get personalInfoTitle => 'Informazioni Personali';

  @override
  String get personalInfoDescription =>
      'Mantieni aggiornati i tuoi dati per ricevere raccomandazioni di salute più accurate e personalizzate.';

  @override
  String get fullName => 'Nome completo';

  @override
  String get birthDate => 'Data di nascita';

  @override
  String get emailOptional => 'Email (Opzionale)';

  @override
  String get phoneOptional => 'Telefono (Opzionale)';

  @override
  String get selectCountry => 'Seleziona il tuo paese';

  @override
  String get searchCountry => 'Cerca paese';

  @override
  String get gender => 'Genere';

  @override
  String get male => 'Uomo';

  @override
  String get female => 'Donna';

  @override
  String get other => 'Altro';

  @override
  String get activityLevel => 'Livello di Attività';

  @override
  String get activitySedentary => 'Sedentario';

  @override
  String get activityLightlyActive => 'Leggermente Attivo';

  @override
  String get activityModeratelyActive => 'Moderatamente Attivo';

  @override
  String get activityVeryActive => 'Molto Attivo';

  @override
  String get activityExtraActive => 'Extra Attivo';

  @override
  String get selectDate => 'Seleziona data';

  @override
  String get recordAnthropometricTitle => 'MISURE ANTROPOMETRICHE';

  @override
  String get dateTimeOfMeasurement => 'DATA E ORA DELLA MISURAZIONE';

  @override
  String get dateLabel => 'Data';

  @override
  String get timeLabel => 'Ora';

  @override
  String get bodyMeasurements => 'MISURE CORPOREE';

  @override
  String get weightLabel => 'Peso';

  @override
  String get heightLabel => 'Altezza';

  @override
  String get bmiTitle => 'Indice di Massa Corporea (IMC)';

  @override
  String get manual => 'Manuale';

  @override
  String get bmiLow => 'BASSO';

  @override
  String get bmiNormal => 'NORMALE';

  @override
  String get bmiOverweight => 'SOVRAPPESO';

  @override
  String get bmiObesity => 'OBESITÀ';

  @override
  String get commentOptional => 'COMMENTO (OPZIONALE)';

  @override
  String get commentHint => 'Eventuali osservazioni su questa misurazione?';

  @override
  String get saveAndEarnXp => 'Salva e ottieni +10 XP';

  @override
  String get historyGoodJob => 'Ottimo lavoro!';

  @override
  String get historyGoalProgress =>
      'Hai registrato una nuova misurazione questo mese, rimanendo sul tuo percorso di benessere.';

  @override
  String historyWeightLoss(String weight) {
    return 'Hai perso ${weight}kg questo mese, avvicinandoti al tuo obiettivo di benessere.';
  }

  @override
  String get historyBmiTrend => 'TENDENZA IMC';

  @override
  String get historyLast6Months => 'Ultimi 6 mesi';

  @override
  String get historyTargetZone => 'Zona Obiettivo';

  @override
  String get historyBmiUnit => 'IMC';

  @override
  String historyTrendOf(String metric) {
    return 'ANDAMENTO $metric';
  }

  @override
  String historyMetricNeedsData(String measure) {
    return 'Registra $measure per vedere questo indicatore.';
  }

  @override
  String get whtrName => 'Vita-altezza';

  @override
  String get whtrShort => 'WHtR';

  @override
  String get whtrLow => 'BASSO';

  @override
  String get whtrNormal => 'NORMALE';

  @override
  String get whtrIncreased => 'AUMENTATO';

  @override
  String get whtrHigh => 'ALTO';

  @override
  String get whrName => 'Vita-fianchi';

  @override
  String get whrShort => 'WHR';

  @override
  String get whrNormal => 'NORMALE';

  @override
  String get whrIncreased => 'AUMENTATO';

  @override
  String get measureWaist => 'la vita';

  @override
  String get measureWaistAndHip => 'vita e fianchi';

  @override
  String get unitCm => 'cm';

  @override
  String get historyExportPdf => 'Esporta in PDF';

  @override
  String get historyExportCsv => 'Excel (CSV)';

  @override
  String get historyMeasurements => 'CRONOLOGIA MISURAZIONI';

  @override
  String get historyNoMeasurements =>
      'Ancora nessuna misurazione. Registra la prima per iniziare la tua cronologia.';

  @override
  String get historyColDate => 'Data';

  @override
  String get historyColWeight => 'Peso (kg)';

  @override
  String get historyColBmi => 'IMC';

  @override
  String get historyColCategory => 'Categoria';

  @override
  String get historyUnknown => 'Sconosciuto';

  @override
  String get historyPdfTitle => 'Cronologia Antropometrica';

  @override
  String get historyShareCsvSubject => 'Cronologia Misurazioni CSV';

  @override
  String get historyBmiLabel => 'IMC';

  @override
  String get recordVitalSignsTitle => 'SEGNI VITALI';

  @override
  String get bloodPressureTitle => 'PRESSIONE SANGUIGNA (MMHG)';

  @override
  String get systolicLabel => 'SISTOLICA';

  @override
  String get diastolicLabel => 'DIASTOLICA';

  @override
  String get heartRateTitle => 'FREQUENZA CARDIACA (BPM)';

  @override
  String get vitalMetricBpShort => 'Pressione Arteriosa';

  @override
  String get vitalMetricHrShort => 'Frequenza Cardiaca';

  @override
  String get heartRateSeriesLabel => 'Frequenza Cardiaca';

  @override
  String get symptomMarkerLegend => 'Con sintomo';

  @override
  String get contextAndSymptoms => 'CONTESTO E SINTOMI';

  @override
  String get activityState => 'STATO DI ATTIVITÀ';

  @override
  String get activityRest => 'Riposo';

  @override
  String get activityExercise => 'Esercizio';

  @override
  String get activityPostOp => 'Post-op';

  @override
  String get howDoYouFeel => 'COME TI SENTI?';

  @override
  String get symptomNormal => 'Normale';

  @override
  String get symptomDizziness => 'Vertigini';

  @override
  String get symptomPain => 'Dolore';

  @override
  String get symptomFatigue => 'Affaticamento';

  @override
  String get bpLow => 'BASSA';

  @override
  String get bpNormal => 'NORMALE';

  @override
  String get bpElevated => 'ELEVATA';

  @override
  String get bpHigh => 'ALTA';

  @override
  String get hrLow => 'BASSA';

  @override
  String get hrNormal => 'NORMALE';

  @override
  String get hrHigh => 'ALTA';

  @override
  String get vitalsSavedSuccess => 'Segni vitali salvati con successo.';

  @override
  String get lipidProfileTitle => 'PROFILO LIPIDICO';

  @override
  String get lipidInfoBanner =>
      'Inserisci i valori delle tue ultime analisi. Tutti i campi sono opzionali, ma compilarli tutti fornisce un quadro più completo della tua salute cardiovascolare.';

  @override
  String get lipidLabInfo => 'INFORMAZIONI LABORATORIO';

  @override
  String get lipidLabName => 'Nome del Laboratorio';

  @override
  String get lipidLabNameHint => 'Es. Laboratorio Clinico Centrale';

  @override
  String get lipidResultsTitle => 'RISULTATI ANALISI (mg/dL)';

  @override
  String get lipidTotalCholesterol => 'Colesterolo Totale';

  @override
  String get lipidTcRef => 'Rif: < 200 mg/dL';

  @override
  String get lipidLdl => 'LDL (Colesterolo \"Cattivo\")';

  @override
  String get lipidLdlRef => 'Rif: < 100 mg/dL';

  @override
  String get lipidHdl => 'HDL (Colesterolo \"Buono\")';

  @override
  String get lipidHdlRef => 'Rif: ≥ 60 mg/dL';

  @override
  String get lipidVldl => 'VLDL';

  @override
  String get lipidVldlRef => 'Rif: 2 – 30 mg/dL';

  @override
  String get lipidTriglycerides => 'Trigliceridi';

  @override
  String get lipidTrigsRef => 'Rif: < 150 mg/dL';

  @override
  String get lipidStatusOptimal => 'OTTIMALE';

  @override
  String get lipidStatusNearOptimal => 'ACCETTABILE';

  @override
  String get lipidStatusBorderline => 'AL LIMITE';

  @override
  String get lipidStatusHigh => 'ALTO';

  @override
  String get lipidStatusLow => 'BASSO';

  @override
  String get lipidStatusProtective => 'PROTETTIVO';

  @override
  String get lipidStatusAcceptable => 'ACCETTABILE';

  @override
  String get lipidOverallRisk => 'VALUTAZIONE GENERALE';

  @override
  String get lipidOverallDesc =>
      'Basato sui valori inseriti. Consulta sempre il tuo medico.';

  @override
  String get lipidAtLeastOneValue =>
      'Inserisci almeno un valore per salvare la registrazione.';

  @override
  String get lipidSavedSuccess => 'Profilo lipidico salvato con successo.';

  @override
  String get compositionTitle => 'PROFILO CORPOREO';

  @override
  String get compositionInfoBanner =>
      'Inserisci i valori dal tuo analizzatore di composizione corporea (es. bilancia impedenziometrica). Tutti i campi sono opzionali — registra ciò che il tuo dispositivo fornisce.';

  @override
  String get compositionDevice => 'DISPOSITIVO DI MISURAZIONE';

  @override
  String get compositionDeviceHint => 'Es. Bilancia OMRON HBF-514C';

  @override
  String get compositionBodyFat => 'PERCENTUALE GRASSO CORPOREO (%)';

  @override
  String get compositionMuscleMass => 'MASSA MUSCOLARE (KG)';

  @override
  String get compositionVisceralAndAge => 'GRASSO VISCERALE E ETÀ METABOLICA';

  @override
  String get compositionVisceralFat => 'GRASSO VISCERALE';

  @override
  String get compositionLevel => 'Livello';

  @override
  String get compositionMetabolicAge => 'ETÀ METABOLICA';

  @override
  String get compositionYears => 'Anni';

  @override
  String get compositionOptionalSection =>
      'OPZIONALE (ACQUA CORPOREA E MASSA OSSEA)';

  @override
  String get compositionBodyWater => 'Acqua Corporea';

  @override
  String get compositionBodyWaterRef => 'Rif: 50–65 %';

  @override
  String get compositionBoneMass => 'Massa Ossea';

  @override
  String get compositionBoneMassRef => 'Rif: 2–4 kg';

  @override
  String get compositionBmr => 'METABOLISMO BASALE (KCAL)';

  @override
  String get compositionBmrSubtitle =>
      'STIMA BASATA SULLA TUA ATTUALE COMPOSIZIONE CORPOREA';

  @override
  String get fatVeryLow => 'MOLTO BASSO';

  @override
  String get fatLow => 'BASSO';

  @override
  String get fatNormal => 'NORMALE';

  @override
  String get fatElevated => 'ELEVATO';

  @override
  String get fatHigh => 'ALTO';

  @override
  String get infoBannerAnthro =>
      'Cerca di prendere le misure sempre nelle stesse condizioni, ad esempio: ogni mattina dopo esserti svegliato, essere andato in bagno e prima di colazione.';

  @override
  String get infoBannerVitals =>
      'Cerca di misurare i segni vitali dopo aver riposato per mezz\'ora.';

  @override
  String get compositionSavedSuccess =>
      'Profilo corporeo salvato con successo.';

  @override
  String discoverGreeting(String name) {
    return 'Buongiorno, $name';
  }

  @override
  String get discoverSearchHint => 'Cerca consigli...';

  @override
  String get discoverDailyTip => 'CONSIGLIO DI SALUTE';

  @override
  String get discoverReadMore => 'Leggi di più';

  @override
  String get discoverRecommended => 'Consigliati per te';

  @override
  String get discoverCategoryAll => 'Tutti';

  @override
  String get discoverCategoryHeart => 'Salute del Cuore';

  @override
  String get discoverCategoryNutrition => 'Nutrizione';

  @override
  String get discoverCategoryEmotional => 'Salute Emotiva';

  @override
  String get discoverCategorySports => 'Sport';

  @override
  String get discoverCategorySleep => 'Riposo';

  @override
  String get discoverMinRead => 'MINUTI DI LETTURA';

  @override
  String get discoverFeatured => 'In evidenza';

  @override
  String get discoverRoutines => 'Routine';

  @override
  String get discoverArticles => 'Articoli';

  @override
  String get discoverChallenges => 'Sfide';

  @override
  String get discoverSeeAll => 'Vedi tutto';

  @override
  String get discoverMinShort => 'min';

  @override
  String get discoverStart => 'Inizia';

  @override
  String get discoverJoin => 'Partecipa';

  @override
  String get discoverLevelBeginner => 'Principiante';

  @override
  String get discoverLevelIntermediate => 'Intermedio';

  @override
  String get discoverLevelAdvanced => 'Avanzato';

  @override
  String get discoverStatusActive => 'Attivo';

  @override
  String get discoverStatusScheduled => 'Programmato';

  @override
  String get discoverStatusFinished => 'Concluso';

  @override
  String get discoverEmpty => 'Ancora nessun contenuto disponibile.';

  @override
  String discoverExercises(String count) {
    return '$count esercizi';
  }

  @override
  String discoverParticipants(String count) {
    return '$count partecipanti';
  }

  @override
  String discoverDaysShort(String count) {
    return '$count giorni';
  }

  @override
  String get privacySecurityDescription =>
      'Gestisci come vengono protette le tue informazioni mediche e personali.';

  @override
  String get biometricLockTitle => 'Blocco Biometrico';

  @override
  String get biometricLockSubtitle =>
      'Richiede impronta digitale o FaceID all\'avvio dell\'app';

  @override
  String get biometricReasoning =>
      'I tuoi dati medici sono informazioni altamente sensibili. L\'abilitazione del blocco biometrico assicura che solo tu possa accedere ai tuoi dati sanitari, proteggendo la tua privacy.';

  @override
  String get unlockAppToContinue => 'Sblocca per continuare';

  @override
  String get biometricNotAvailable =>
      'Biometria non disponibile su questo dispositivo.';

  @override
  String get healthGoalsTitle => 'Obiettivi di Salute';

  @override
  String get healthGoalsDescription =>
      'Imposta i tuoi obiettivi medici per misurare i tuoi progressi.';

  @override
  String get medicalGoalsToggle => 'Abilita Obiettivi Medici';

  @override
  String get medicalGoalsSubtitle =>
      'Abilita per impostare obiettivi di peso e composizione corporea';

  @override
  String get targetWeight => 'Peso Obiettivo';

  @override
  String get targetBodyFat => 'Grasso Corporeo Obiettivo';

  @override
  String get targetMuscleMass => 'Massa Muscolare Obiettivo';

  @override
  String get targetVisceralFat => 'Grasso Viscerale Obiettivo';

  @override
  String get goalsSavedSuccess => 'Obiettivi salvati con successo.';

  @override
  String get helpSupportPageTitle => 'Aiuto e Supporto';

  @override
  String get helpSupportPageDescription =>
      'Tutto ciò che devi sapere su My Vitals.';

  @override
  String get helpFaqTitle => 'Domande Frequenti';

  @override
  String get helpFaqDescription => 'Risposte rapide alle domande più comuni.';

  @override
  String get helpGlossaryTitle => 'Glossario Medico';

  @override
  String get helpGlossaryDescription => 'Comprendi ogni indicatore di salute.';

  @override
  String get helpLegalTitle => 'Avviso Legale';

  @override
  String get helpLegalDescription => 'Termini di utilizzo e privacy dei dati.';

  @override
  String get helpContactTitle => 'Contatto e Feedback';

  @override
  String get helpContactDescription => 'Scrivici, miglioriamo insieme.';

  @override
  String get helpSearchHint => 'Cerca...';

  @override
  String get helpNoResults => 'Nessun risultato per la tua ricerca.';

  @override
  String get helpFaqCatGeneral => 'Generale';

  @override
  String get helpFaqCatData => 'I miei dati';

  @override
  String get helpFaqCatBiometrics => 'Biometria';

  @override
  String get helpFaqCatExport => 'Esporta';

  @override
  String get helpFaqQ1 => 'Cos\'è My Vitals?';

  @override
  String get helpFaqA1 =>
      'My Vitals è un\'app di monitoraggio personale della salute che ti permette di registrare e monitorare i tuoi indicatori di benessere: misure antropometriche, segni vitali, profilo lipidico e composizione corporea.';

  @override
  String get helpFaqQ2 => 'I miei dati vengono salvati nel cloud?';

  @override
  String get helpFaqA2 =>
      'No. Tutti i tuoi dati vengono archiviati esclusivamente sul tuo dispositivo. My Vitals non invia alcuna informazione a server esterni, garantendo la massima privacy.';

  @override
  String get helpFaqQ3 => 'Posso usare l\'app senza internet?';

  @override
  String get helpFaqA3 =>
      'Sì. My Vitals funziona completamente offline. Hai bisogno di connettività solo per gli aggiornamenti dell\'app.';

  @override
  String get helpFaqQ4 => 'Come attivo il blocco biometrico?';

  @override
  String get helpFaqA4 =>
      'Vai su Profilo › Privacy e Sicurezza e attiva l\'interruttore Blocco Biometrico. Il tuo dispositivo deve avere l\'impronta digitale o FaceID configurato.';

  @override
  String get helpFaqQ5 => 'Come esporto la mia cronologia?';

  @override
  String get helpFaqA5 =>
      'In ogni schermata della cronologia (Antropometrico, Segni Vitali, ecc.) troverai i pulsanti \'Esporta PDF\' e \'Excel (CSV)\' in alto.';

  @override
  String get helpFaqQ6 => 'Posso cambiare le unità di misura?';

  @override
  String get helpFaqA6 =>
      'Sì. Vai su Profilo › Unità di Misura e scegli tra il sistema Metrico (kg, cm) o Imperiale (lb, ft/in).';

  @override
  String get helpFaqQ7 => 'Cosa succede se elimino l\'app?';

  @override
  String get helpFaqA7 =>
      'La disinstallazione dell\'app eliminerà definitivamente tutti i dati archiviati localmente. Ti consigliamo di esportare la cronologia in PDF o CSV prima di disinstallare.';

  @override
  String get helpFaqQ8 => 'Questa app sostituisce il mio medico?';

  @override
  String get helpFaqA8 =>
      'No. My Vitals è uno strumento di monitoraggio personale per aiutarti a tenere un registro organizzato. Consulta sempre un professionista sanitario per l\'interpretazione e la diagnosi medica.';

  @override
  String get helpGlossarySearchHint => 'Cerca termine...';

  @override
  String get helpGlossaryGroupAnthropo => 'Misure Antropometriche';

  @override
  String get helpGlossaryGroupVitals => 'Segni Vitali';

  @override
  String get helpGlossaryGroupLipid => 'Profilo Lipidico';

  @override
  String get helpGlossaryGroupBody => 'Composizione Corporea';

  @override
  String get helpGlossaryNormalRange => 'Intervallo normale';

  @override
  String get helpLegalPurposeTitle => 'Scopo dell\'applicazione';

  @override
  String get helpLegalPurposeBody =>
      'My Vitals è un\'applicazione di monitoraggio personale della salute progettata per aiutare gli utenti a registrare e visualizzare i propri indicatori di benessere. Non è un dispositivo medico certificato.';

  @override
  String get helpLegalNotMedicalTitle => 'Non è un dispositivo medico';

  @override
  String get helpLegalNotMedicalBody =>
      'Le informazioni visualizzate in questa applicazione sono solo a scopo di riferimento. Non sostituisce la diagnosi, il consiglio o il trattamento di un professionista sanitario. Consulta il tuo medico per qualsiasi sintomo.';

  @override
  String get helpLegalResponsibilityTitle => 'Responsabilità dell\'utente';

  @override
  String get helpLegalResponsibilityBody =>
      'L\'utente è responsabile dell\'accuratezza dei dati inseriti. My Vitals non è responsabile delle decisioni sanitarie prese sulla base delle informazioni registrate nell\'app.';

  @override
  String get helpLegalPrivacyTitle => 'Privacy e dati';

  @override
  String get helpLegalPrivacyBody =>
      'Tutti i dati vengono archiviati localmente sul dispositivo dell\'utente. My Vitals non raccoglie, trasmette o condivide informazioni personali con terze parti. Non esistono account utente o server di dati.';

  @override
  String get helpLegalContactTitle => 'Contatto sviluppatore';

  @override
  String get helpLegalContactBody =>
      'Per richieste legali o sulla privacy, puoi contattare lo sviluppatore all\'indirizzo: yesithvalencia@gmail.com';

  @override
  String get helpContactReportBug => 'Segnala un errore';

  @override
  String get helpContactReportBugDesc =>
      'Hai trovato qualcosa che non funziona bene? Dimmelo.';

  @override
  String get helpContactSuggest => 'Invia un suggerimento';

  @override
  String get helpContactSuggestDesc =>
      'Hai un\'idea per migliorare l\'app? Vogliamo sentirla.';

  @override
  String get helpContactSendEmail => 'Invia email';

  @override
  String get helpContactAppVersion => 'Versione dell\'app';

  @override
  String get helpContactWhatsNew => 'Novità';

  @override
  String get helpContactV110 => 'v1.1.0 — Attuale';

  @override
  String get helpContactV110Changes =>
      '• Blocco biometrico (impronta digitale / FaceID)\n• Obiettivi di salute personalizzati\n• Supporto lingua italiana\n• Selettore livello di attività migliorato';

  @override
  String get helpContactV100 => 'v1.0.0 — Rilascio iniziale';

  @override
  String get helpContactV100Changes =>
      '• Tracciamento misure antropometriche\n• Segni vitali e profilo lipidico\n• Composizione corporea\n• Esportazione PDF e CSV\n• Supporto multilingue (es, en, de, pt)';

  @override
  String get myDataBackup => 'I Miei Dati';

  @override
  String get backupTitle => 'Backup e Ripristino';

  @override
  String get backupDescription =>
      'Esporta o ripristina tutti i tuoi dati e le tue preferenze.';

  @override
  String get backupPrivacyTitle => 'I tuoi dati sono tuoi. E solo tuoi.';

  @override
  String get backupPrivacyBody =>
      'Tutte le nostre funzionalità per la salute sono sviluppate con la privacy al centro e sono progettate per mantenere i tuoi dati al sicuro.\n\nI tuoi dati sanitari sono crittografati sul tuo dispositivo e sono accessibili solo tramite passcode, Touch ID o Face ID. Non utilizziamo server cloud e non condividiamo mai i tuoi dati con terze parti.';

  @override
  String get backupPrivacyHighlight =>
      'I tuoi dati sanitari sono crittografati a livello locale e nemmeno noi possiamo accedere alle tue informazioni.';

  @override
  String get backupExportTitle => 'Esporta i miei dati';

  @override
  String get backupExportSubtitle =>
      'Genera un file sicuro con tutta la tua cronologia e le tue impostazioni';

  @override
  String get backupExportButton => 'Esporta Backup';

  @override
  String get backupImportTitle => 'Ripristina i miei dati';

  @override
  String get backupImportSubtitle =>
      'Importa un backup precedente di My Vitals';

  @override
  String get backupImportButton => 'Importa Backup';

  @override
  String get backupWhatIncluded => 'Cosa c\'è nel backup?';

  @override
  String get backupSuccess => 'Backup esportato con successo!';

  @override
  String get backupImportSuccess => 'Dati ripristinati con successo!';

  @override
  String get backupImportError =>
      'Errore di importazione. Verifica che il file sia valido.';

  @override
  String get backupImportConfirmTitle => 'Ripristinare i dati?';

  @override
  String get backupImportConfirmBody =>
      'Ciò sostituirà i tuoi record attuali con quelli del backup. Vuoi continuare?';

  @override
  String get backupIncludesVitalSigns => 'Cronologia Segni Vitali';

  @override
  String get backupIncludesAnthropo => 'Cronologia Antropometrica';

  @override
  String get backupIncludesLipid => 'Profilo Lipidico';

  @override
  String get backupIncludesBodyComp => 'Composizione Corporea';

  @override
  String get backupIncludesPersonalInfo => 'Informazioni Personali';

  @override
  String get backupIncludesGoals => 'Obiettivi di Salute';

  @override
  String get backupIncludesPhoto => 'Foto Profilo';

  @override
  String get backupIncludesPreferences =>
      'Preferenze (lingua, unità, tema, promemoria, dispositivo)';

  @override
  String get exportSuccess => 'Esportato correttamente';

  @override
  String get exportError => 'Impossibile esportare. Riprova.';

  @override
  String get backupCancel => 'Annulla';

  @override
  String get onboardingWelcomeTitle => 'Benvenuto in My Vitals';

  @override
  String get onboardingWelcomeSubtitle => 'Il tuo compagno di salute personale';

  @override
  String get onboardingWelcomeFeature1 =>
      'Registra i tuoi segni vitali e le misure corporee';

  @override
  String get onboardingWelcomeFeature2 =>
      'Visualizza i tuoi progressi con grafici e statistiche';

  @override
  String get onboardingWelcomeFeature3 =>
      'Sincronizza la tua cronologia in modo sicuro sui tuoi dispositivi';

  @override
  String get onboardingNext => 'Avanti';

  @override
  String get onboardingFinish => 'Inizia!';

  @override
  String get welcomeGetStarted => 'Inizia';

  @override
  String get welcomeLogIn => 'Accedi';

  @override
  String get welcomeAlreadyHaveAccount => 'Hai già un account?';

  @override
  String onboardingStep(int current, int total) {
    return 'Passo $current di $total';
  }

  @override
  String get onboardingAvatarTitle => 'La tua foto profilo';

  @override
  String get onboardingAvatarSubtitle =>
      'Dai un volto al tuo percorso di salute (opzionale)';

  @override
  String get remindersTitle => 'Promemoria e Avvisi';

  @override
  String get remindersDescription =>
      'Imposta avvisi giornalieri per ricordare i tuoi controlli medici di routine.';

  @override
  String get remindersNote =>
      '* Le notifiche arriveranno sul tuo dispositivo ogni giorno all\'ora programmata.';

  @override
  String get reminderVitals => 'Registra Segni Vitali';

  @override
  String get reminderMeds => 'Prendi Farmaci';

  @override
  String get reminderWorkout => 'Attività Fisica';

  @override
  String get reminderWater => 'Bevi Acqua';

  @override
  String get reminderTitle => 'Promemoria Medico';

  @override
  String get filterLast7Days => 'Ultimi 7 giorni';

  @override
  String get filterLast30Days => 'Ultimi 30 giorni';

  @override
  String get filterLast6Months => 'Ultimi 6 mesi';

  @override
  String get filterAllTime => 'Tutto il tempo';

  @override
  String goalRemainingWeight(String weight) {
    return '${weight}kg mancanti all\'obiettivo';
  }

  @override
  String get goalAchieved => 'Obiettivo raggiunto!';

  @override
  String get noGoalDefined => 'Nessun obiettivo definito';

  @override
  String get validationRequiredFields => 'Campi obbligatori';

  @override
  String get validationCompleteBeforeContinue =>
      'Per favore compila questi campi prima di continuare:';

  @override
  String get validationSelectLanguage => 'Seleziona una lingua';

  @override
  String get validationEnterName => 'Inserisci il tuo nome completo';

  @override
  String get validationSelectBirthDate => 'Seleziona la tua data di nascita';

  @override
  String get validationSelectGender => 'Seleziona il tuo sesso';

  @override
  String get dashboardCompositionFat => 'GRASSO';

  @override
  String get dashboardCompositionMuscle => 'MUSCOLO';

  @override
  String get dashboardCompositionVisceral => 'VISCERALE';

  @override
  String get dashboardCompositionBmr => 'MB';

  @override
  String dashboardCompositionLevel(int level) {
    return 'Liv. $level';
  }

  @override
  String get vitalsPdfTitle => 'Storico dei Segni Vitali';

  @override
  String get vitalsShareCsvSubject => 'Esportazione CSV dei Segni Vitali';

  @override
  String get lipidPdfTitle => 'Storico del Profilo Lipidico';

  @override
  String get lipidShareCsvSubject => 'Esportazione CSV dei Laboratori';

  @override
  String get compositionPdfTitle => 'Storico della Composizione Corporea';

  @override
  String get compositionShareCsvSubject =>
      'Esportazione CSV della Composizione Corporea';

  @override
  String get reminderDefaultTitle => 'Promemoria Medico';

  @override
  String get exportColComment => 'Commento';

  @override
  String get exportColHeight => 'Altezza (m)';

  @override
  String get exportColSysDia => 'Sis/Dia';

  @override
  String get exportColHrShort => 'FC';

  @override
  String get exportColStatus => 'Stato';

  @override
  String get exportColSystolic => 'Sistolica';

  @override
  String get exportColDiastolic => 'Diastolica';

  @override
  String get exportColHeartRate => 'Frequenza Cardiaca';

  @override
  String get exportColActivityState => 'Stato di Attività';

  @override
  String get exportColSymptom => 'Sintomo';

  @override
  String get exportColTotalCholShort => 'Col. Tot.';

  @override
  String get exportColTrigsShort => 'Trig.';

  @override
  String get exportColTotalCholesterol => 'Colesterolo Totale';

  @override
  String get exportColTriglycerides => 'Trigliceridi';

  @override
  String get exportColLabName => 'Laboratorio';

  @override
  String get exportColBodyFat => 'Grasso Corporeo';

  @override
  String get exportColMuscleMass => 'Massa Muscolare';

  @override
  String get exportColVisceralFat => 'Grasso Viscerale';

  @override
  String get exportColMetabolicAge => 'Età Metabolica';

  @override
  String get exportColBodyWater => 'Acqua Corporea';

  @override
  String get exportColBoneMass => 'Massa Ossea';

  @override
  String get exportColBmr => 'MB';

  @override
  String get glossaryImcName => 'IMC (Indice di Massa Corporea)';

  @override
  String get glossaryImcDefinition =>
      'Misura che mette in relazione peso e altezza per valutare se il peso di una persona è sano. Calcolato dividendo il peso (kg) per il quadrato dell\'altezza (m²).';

  @override
  String get glossaryImcRange => '18,5 – 24,9 kg/m²';

  @override
  String get glossaryPesoName => 'Peso corporeo';

  @override
  String get glossaryPesoDefinition =>
      'Massa totale del corpo in chilogrammi o libbre, inclusi muscoli, ossa, organi, grasso e acqua.';

  @override
  String get glossaryPesoRange => 'Dipende da altezza e corporatura';

  @override
  String get glossaryTallaName => 'Altezza (Statura)';

  @override
  String get glossaryTallaDefinition =>
      'Misurazione dell\'altezza di una persona dai piedi alla cima della testa, espressa in centimetri o metri.';

  @override
  String get glossarySistolicaName => 'Pressione Sistolica';

  @override
  String get glossarySistolicaDefinition =>
      'La pressione massima esercitata dal sangue sulle arterie quando il cuore si contrae (batte). È il numero superiore in una lettura della pressione sanguigna.';

  @override
  String get glossarySistolicaRange => '< 120 mmHg';

  @override
  String get glossaryDiastolicaName => 'Pressione Diastolica';

  @override
  String get glossaryDiastolicaDefinition =>
      'La pressione minima esercitata dal sangue sulle arterie tra i battiti cardiaci, quando il cuore è a riposo. È il numero inferiore in una lettura della pressione sanguigna.';

  @override
  String get glossaryDiastolicaRange => '< 80 mmHg';

  @override
  String get glossaryFcName => 'Frequenza Cardiaca';

  @override
  String get glossaryFcDefinition =>
      'Numero di volte che il cuore batte al minuto (bpm). A riposo, un cuore sano batte regolarmente entro un intervallo specifico.';

  @override
  String get glossaryFcRange => '60 – 100 bpm a riposo';

  @override
  String get glossaryColesterolTotalName => 'Colesterolo Totale';

  @override
  String get glossaryColesterolTotalDefinition =>
      'Somma di tutto il colesterolo presente nel sangue, inclusi LDL, HDL e altri lipidi. È un marcatore generale del rischio cardiovascolare.';

  @override
  String get glossaryColesterolTotalRange => '< 200 mg/dL';

  @override
  String get glossaryLdlName => 'LDL (Colesterolo \"Cattivo\")';

  @override
  String get glossaryLdlDefinition =>
      'Lipoproteina a bassa densità. Trasporta il colesterolo nelle arterie e può accumularsi nelle loro pareti, aumentando il rischio di malattie cardiovascolari.';

  @override
  String get glossaryLdlRange => '< 100 mg/dL';

  @override
  String get glossaryHdlName => 'HDL (Colesterolo \"Buono\")';

  @override
  String get glossaryHdlDefinition =>
      'Lipoproteina ad alta densità. Raccoglie il colesterolo in eccesso dalle arterie e lo porta al fegato per l\'eliminazione. Livelli alti sono protettivi.';

  @override
  String get glossaryHdlRange => '≥ 60 mg/dL';

  @override
  String get glossaryVldlName => 'VLDL';

  @override
  String get glossaryVldlDefinition =>
      'Lipoproteina a densità molto bassa. Trasporta i trigliceridi dal fegato ai tessuti. Livelli elevati sono associati a un maggiore rischio cardiovascolare.';

  @override
  String get glossaryVldlRange => '2 – 30 mg/dL';

  @override
  String get glossaryTrigliceridosName => 'Trigliceridi';

  @override
  String get glossaryTrigliceridosDefinition =>
      'Un tipo di grasso (lipide) nel sangue. Il corpo li usa come fonte di energia, ma livelli alti aumentano il rischio di malattie cardiache e pancreatiche.';

  @override
  String get glossaryTrigliceridosRange => '< 150 mg/dL';

  @override
  String get glossaryGrasaName => 'Percentuale di Grasso Corporeo';

  @override
  String get glossaryGrasaDefinition =>
      'Proporzione di massa grassa rispetto al peso corporeo totale. Include grasso essenziale e grasso di riserva.';

  @override
  String get glossaryGrasaRange => 'Uomini: 8–19% / Donne: 21–33%';

  @override
  String get glossaryMusculoName => 'Massa Muscolare';

  @override
  String get glossaryMusculoDefinition =>
      'Peso totale del tessuto muscolare nel corpo, espresso in chilogrammi. Una percentuale muscolare più alta è associata a un metabolismo più attivo.';

  @override
  String get glossaryGrasaVisceralName => 'Grasso Viscerale';

  @override
  String get glossaryGrasaVisceralDefinition =>
      'Grasso accumulato attorno agli organi interni dell\'addome (fegato, intestino, pancreas). Livelli alti sono associati a un maggiore rischio metabolico e cardiovascolare.';

  @override
  String get glossaryGrasaVisceralRange => 'Livello 1–9 (sano)';

  @override
  String get glossaryEdadMetabolicaName => 'Età Metabolica';

  @override
  String get glossaryEdadMetabolicaDefinition =>
      'Età stimata del metabolismo basale rispetto alla media della popolazione. Un\'età metabolica inferiore all\'età cronologica indica un metabolismo efficiente.';

  @override
  String get glossaryBmrName => 'BMR / Metabolismo Basale (kcal)';

  @override
  String get glossaryBmrDefinition =>
      'Quantità minima di energia (calorie) di cui il corpo ha bisogno a riposo assoluto per mantenere le funzioni vitali: respirazione, circolazione, temperatura, ecc.';

  @override
  String get glossaryAguaName => 'Acqua Corporea';

  @override
  String get glossaryAguaDefinition =>
      'Percentuale del peso corporeo corrispondente all\'acqua. L\'acqua è essenziale per tutte le funzioni cellulari, la regolazione della temperatura e il trasporto di nutrienti.';

  @override
  String get glossaryAguaRange => '50 – 65%';

  @override
  String get glossaryHuesoName => 'Massa Ossea';

  @override
  String get glossaryHuesoDefinition =>
      'Peso stimato del tessuto osseo nel corpo. Mantenere una massa ossea adeguata è fondamentale per prevenire l\'osteoporosi.';

  @override
  String get glossaryHuesoRange => '2 – 4 kg (adulto medio)';

  @override
  String get deleteRecordTitle => 'Eliminare il record?';

  @override
  String get deleteRecordBody => 'Questa azione non può essere annullata.';

  @override
  String get deleteRecordConfirm => 'Elimina';

  @override
  String get recordDeleted => 'Record eliminato';

  @override
  String get anthropoSavedSuccess => 'Misurazione salvata con successo.';

  @override
  String historyShowMore(int count) {
    return 'Mostra altri $count';
  }

  @override
  String get introSignIn => 'Accedi';

  @override
  String get introRegister => 'Crea un account';

  @override
  String get emailLabel => 'Email';

  @override
  String get validationEnterEmail => 'Inserisci la tua email';

  @override
  String get validationEmailFormat =>
      'Controlla l\'email: manca la chiocciola o il dominio';

  @override
  String validationOutOfRange(Object max, Object min) {
    return 'Inserisci un valore tra $min e $max';
  }

  @override
  String get commonRegisterFailed =>
      'Non abbiamo potuto creare il tuo account. Controlla la connessione e riprova.';

  @override
  String get logOutConfirm =>
      'Uscire su questo dispositivo? I tuoi dati restano sul dispositivo e si sincronizzeranno di nuovo al prossimo accesso.';

  @override
  String get pendingAccountTitle => 'Account in attesa';

  @override
  String get pendingAccountBody =>
      'I tuoi dati sono salvati su questo dispositivo. Creeremo il tuo account appena ci sarà connessione.';

  @override
  String get pendingAccountCreateNow => 'Crea il mio account adesso';

  @override
  String get pendingAccountCreating => 'Creazione del tuo account…';

  @override
  String get pendingAccountCreated =>
      'Account creato. Caricamento dei tuoi dati.';

  @override
  String get pendingAccountStillOffline =>
      'Ancora nessuna connessione. I tuoi dati restano al sicuro sul dispositivo.';

  @override
  String get identifyTitle => 'Recuperiamo la tua storia';

  @override
  String get identifyBody =>
      'Inserisci il tuo documento (o email). Se sei già paziente carichiamo i tuoi dati; altrimenti creiamo il tuo account.';

  @override
  String get identifyFieldLabel => 'Documento o email';

  @override
  String get identifyFieldHint => 'Es. 1032456789';

  @override
  String get identifyFoundTitle =>
      'Abbiamo trovato una cartella clinica associata a questo documento.';

  @override
  String get identifyFoundBody =>
      'Possiamo importarla e attivare il tuo account per vedere i tuoi dati dal primo giorno.';

  @override
  String get identifyBringHistory => 'Importa la mia storia e continua';

  @override
  String get identifyBringingHistory => 'Importazione in corso…';

  @override
  String get identifyNotMe => 'Non sono io — registrami come nuovo';

  @override
  String get verifyAppBarTitle => 'Verifica';

  @override
  String get verifyTitle => 'Abbiamo trovato il tuo account';

  @override
  String verifyBody(String identifier) {
    return 'Verifica la tua identità per continuare con\n$identifier.';
  }

  @override
  String get verifyPasswordLabel => 'Password';

  @override
  String get verifyTestNotice =>
      'Fase di test: la password è 1234. (In produzione qui ci sarà il codice OTP.)';

  @override
  String get verifySubmit => 'Accedi';

  @override
  String unexpectedError(String details) {
    return 'Errore imprevisto: $details';
  }

  @override
  String get accountSyncTitle => 'Account e sincronizzazione';

  @override
  String get accountSyncDescription =>
      'Accedi e sincronizza i tuoi dati con il server.';

  @override
  String get deviceScreenDescription =>
      'Scegli la bilancia che usi per interpretare le tue misurazioni.';

  @override
  String get goalsScreenDescription =>
      'Imposta i tuoi valori obiettivo e monitora i tuoi progressi.';

  @override
  String get accountYourAccount => 'Il tuo account';

  @override
  String get accountPendingBody =>
      'I tuoi dati sono su questo dispositivo. Manca creare l’account sul server.';

  @override
  String get accountLoggedOutBody =>
      'Accedi se sei già paziente, oppure registrati per iniziare.';

  @override
  String get accountFallbackName => 'Paziente';

  @override
  String get accountFromLegacy => 'Account migrato dal sistema precedente';

  @override
  String get accountCreatedInApp => 'Account creato nell’app';

  @override
  String get accountSignOut => 'Esci';

  @override
  String get accountSyncSection => 'Sincronizzazione';

  @override
  String get accountSyncBody => 'Carica i tuoi dati locali sul server.';

  @override
  String get accountSyncing => 'Sincronizzazione…';

  @override
  String get accountSyncNow => 'Sincronizza ora';

  @override
  String get accountHaveAccount => 'Ho già un account (paziente migrato)';

  @override
  String get accountImNew => 'Sono nuovo (registrami)';

  @override
  String get accountCreateAccount => 'Crea account';

  @override
  String get accountNewHere => 'Sono nuovo (registrarmi)';

  @override
  String get accountDocumentOptional => 'Documento (opzionale)';

  @override
  String get accountNameLabel => 'Nome';

  @override
  String get accountEmailLabel => 'Email';

  @override
  String get deviceScreenTitle => 'Il mio dispositivo di misura';

  @override
  String get deviceNoneTitle => 'Non ne uso nessuna';

  @override
  String get deviceNoneSubtitle =>
      'Registrerò solo misure manuali (peso, vita, altezza).';

  @override
  String get deviceNoneSaved => 'Salvato: non usi la bioimpedenza.';

  @override
  String get deviceCatalogError =>
      'Impossibile aggiornare il catalogo. Mostro le opzioni salvate.';

  @override
  String get deviceAvailableScales => 'BILANCE DISPONIBILI';

  @override
  String get deviceWhyItMatters =>
      'Ogni bilancia a bioimpedenza interpreta grasso, muscolo e grasso viscerale con intervalli propri. Dicci quale usi per mostrarti se i tuoi valori sono bassi, normali o alti. Puoi cambiarlo quando vuoi.';

  @override
  String get circumferencesSection => 'CIRCONFERENZE CORPOREE (FACOLTATIVO)';

  @override
  String get circWaist => 'Vita';

  @override
  String get circHip => 'Fianchi';

  @override
  String get circLowerAbdomen => 'Basso addome';

  @override
  String get circArm => 'Braccio';

  @override
  String get circLeg => 'Gamba';

  @override
  String get circChestBust => 'Petto/Busto';

  @override
  String get circAbdomenShort => 'Add.';

  @override
  String get lipidLabQuestion => 'In quale laboratorio hai fatto l’esame?';

  @override
  String get lipidLabLoading => 'Caricamento laboratori…';

  @override
  String get lipidLabNotSpecified => 'Non indicato / non so';

  @override
  String get lipidLabOther => 'Altro (specificare)';

  @override
  String get compositionSkeletalMuscle => 'Muscolo scheletrico';

  @override
  String get compositionSkeletalMuscleRef =>
      'Come lo riporta la tua bilancia (%)';

  @override
  String get profileAppTheme => 'Tema dell’app';

  @override
  String get profileRankObserver => 'Osservatore Vitale';

  @override
  String get themeBankLabel => 'RACCOLTA TEMI';

  @override
  String get themePickTitle => 'Scegli l’aspetto';

  @override
  String get themePickBody =>
      'Cambia colori e tipografia. Navigazione, icone e significato di ogni colore restano invariati.';

  @override
  String get themeSettingsBody =>
      'La modifica si applica subito e viene ricordata. Navigazione, icone e significato di ogni colore restano invariati.';

  @override
  String themeContinueWith(String theme) {
    return 'Continua con $theme';
  }

  @override
  String deviceSelectedSaved(String device) {
    return '$device selezionata.';
  }

  @override
  String deviceWillSyncLater(String message) {
    return '$message Verrà sincronizzato quando ci sarà connessione.';
  }

  @override
  String get introDemo => 'Guarda la demo';

  @override
  String get demoNoticeTitle => 'Sei nella demo';

  @override
  String get demoNoticeBody =>
      'Tutto quello che vedi appartiene a un paziente immaginario. Puoi registrare e modificare le misurazioni: non viene salvato nulla, e tutto sparisce quando esci dalla demo.';

  @override
  String get demoNoticeAction => 'Ho capito';

  @override
  String get demoBannerLabel => 'Dati dimostrativi';

  @override
  String get demoExit => 'Esci dalla demo';

  @override
  String get profileRankTier2 => 'Custode Costante';

  @override
  String get profileRankTier3 => 'Veterano del Benessere';

  @override
  String get mhxDocTitle => 'Riepilogo della salute personale';

  @override
  String get mhxDocSubtitle =>
      'Rapporto consolidato di misurazioni autodichiarate';

  @override
  String get mhxPatient => 'Paziente';

  @override
  String get mhxBirthDate => 'Data di nascita';

  @override
  String get mhxPeriodCovered => 'Periodo coperto';

  @override
  String get mhxGeneratedOn => 'Generato il';

  @override
  String get mhxSource => 'Fonte';

  @override
  String get mhxGeneratedBy => 'Generato da';

  @override
  String get mhxReportRef => 'Referto n.';

  @override
  String get mhxSelfReported => 'dati autodichiarati';

  @override
  String get mhxDisclaimerTitle =>
      'Riepilogo informativo - non è una diagnosi medica';

  @override
  String get mhxDisclaimerBody =>
      'Questo documento è stato generato automaticamente dalle misurazioni registrate dall\'utente. Non è una diagnosi medica né una cartella clinica ufficiale e non sostituisce la valutazione di un professionista sanitario.';

  @override
  String get mhxSummaryTitle => 'Riepilogo degli ultimi valori';

  @override
  String get mhxColIndicator => 'Indicatore';

  @override
  String get mhxColLatest => 'Ultimo valore';

  @override
  String get mhxColReference => 'Riferimento';

  @override
  String get mhxColStatus => 'Stato';

  @override
  String get mhxColNotes => 'Note';

  @override
  String get mhxBloodPressure => 'Pressione arteriosa';

  @override
  String get mhxHeartRate => 'Frequenza cardiaca';

  @override
  String get mhxWeight => 'Peso';

  @override
  String get mhxBmi => 'IMC';

  @override
  String get mhxBodyFat => 'Grasso corporeo';

  @override
  String get mhxVisceralFat => 'Grasso viscerale';

  @override
  String get mhxTotalCholesterol => 'Colesterolo totale';

  @override
  String get mhxLdl => 'LDL';

  @override
  String get mhxHdl => 'HDL';

  @override
  String get mhxTriglycerides => 'Trigliceridi';

  @override
  String get mhxSystolic => 'Sistolica';

  @override
  String get mhxDiastolic => 'Diastolica';

  @override
  String get mhxStatsMeasurements => 'Misurazioni';

  @override
  String get mhxStatsAverage => 'Media';

  @override
  String get mhxStatsRange => 'Intervallo';

  @override
  String get mhxStatsLatest => 'Ultimo';

  @override
  String get mhxFooterDisclaimer =>
      'Fonte dei dati: misurazioni inserite dal paziente tramite l\'app MY VITALS con dispositivi personali che potrebbero non essere calibrati clinicamente; la loro accuratezza non è verificata da un professionista né da un laboratorio accreditato. Gli intervalli di riferimento mostrati sono indicativi e potrebbero non applicarsi alla sua situazione individuale; un valore segnalato fuori intervallo non è una diagnosi. Non prenda decisioni terapeutiche basandosi su questo documento senza supervisione professionale. Contiene dati personali sulla salute: l\'utente è responsabile della loro custodia e condivisione.';

  @override
  String get mhxButton => 'Esporta la storia clinica completa';

  @override
  String get mhxHubHint =>
      'Un PDF con i tuoi quattro indicatori da mostrare al medico.';

  @override
  String get mhxChoosePeriod => 'Scegli il periodo';

  @override
  String get mhxPeriod6Months => 'Ultimi 6 mesi';

  @override
  String get mhxPeriod1Year => 'Ultimo anno';

  @override
  String get mhxPeriodAll => 'Tutto lo storico';

  @override
  String get mhxGenerate => 'Genera PDF';

  @override
  String get mhxNoData => 'Non ci sono ancora misurazioni da esportare.';

  @override
  String mhxAgeYears(int years) {
    return '$years anni';
  }

  @override
  String mhxPageOf(int current, int total) {
    return 'Pagina $current di $total';
  }
}
