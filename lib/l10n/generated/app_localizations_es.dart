// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get appTitle => 'Mis Constantes';

  @override
  String get dashboard => 'Inicio';

  @override
  String get history => 'Historial';

  @override
  String get record => 'Registrar';

  @override
  String get discover => 'Descubrir';

  @override
  String get profile => 'Perfil';

  @override
  String get language => 'Idioma';

  @override
  String get savePreferences => 'Guardar preferencias';

  @override
  String get selectLanguage => 'Seleccione su idioma de preferencia';

  @override
  String get personalInfo => 'Información Personal';

  @override
  String get measurementUnits => 'Unidades de Medida';

  @override
  String get notifications => 'Notificaciones';

  @override
  String get privacySecurity => 'Privacidad y Seguridad';

  @override
  String get helpSupport => 'Ayuda y Soporte';

  @override
  String get logOut => 'Cerrar Sesión';

  @override
  String level(int value) {
    return 'Nivel $value';
  }

  @override
  String get newUserInfo => 'Nuevo Usuario';

  @override
  String xpForNextLevel(int current, int total) {
    return '$current / $total XP para el siguiente nivel';
  }

  @override
  String get levelProgress => 'Progreso de Nivel';

  @override
  String get vitalSigns => 'Signos Vitales';

  @override
  String get vitalsSubtitle => 'Presión arterial & Frecuencia Cardiaca';

  @override
  String get noDataYet => 'No hay datos registrados aún.';

  @override
  String get recordVitalsAction => 'Registra tu presión y frecuencia ›';

  @override
  String get bodyComposition => 'Perfil Corporal';

  @override
  String get compositionSubtitle => 'Grasa, músculo, agua y masa ósea.';

  @override
  String get completeBodyProfile => 'Completar tu perfil corporal ›';

  @override
  String get anthropometricHistory => 'Medidas Antropométricas';

  @override
  String get anthroSubtitle => 'Mide tu peso, talla y progreso físico.';

  @override
  String get recordFirstMeasure => 'Registrar tu primera Medida ›';

  @override
  String get lipidProfile => 'Perfil Lipídico';

  @override
  String get lipidSubtitle => 'Monitorea tu colesterol y triglicéridos.';

  @override
  String get recordLabResults => 'Registra tus resultados de laboratorio ›';

  @override
  String get medicalDisclaimerTitle => 'Descargo de Responsabilidad Médica';

  @override
  String get medicalDisclaimerText =>
      'Esta aplicación es únicamente para fines informativos y de seguimiento personal. No sustituye el consejo, diagnóstico o tratamiento médico profesional. Siempre busque el consejo de su médico u otro proveedor de salud calificado ante cualquier duda.';

  @override
  String get selfCareProgress => 'Progreso de Autocuidado';

  @override
  String get myHealthAchievements => 'Mis Logros de Salud';

  @override
  String get badgeFirstStep => 'Primer Paso';

  @override
  String get badgeFirstStepDesc => 'Inicio del camino';

  @override
  String get badgeStrongHeart => 'Corazón Fuerte';

  @override
  String get badgeStrongHeartDesc => 'Salud Cardio';

  @override
  String get badgeVitalHabit => 'Hábito Vital';

  @override
  String get badgeVitalHabitDesc => '7 días seguidos';

  @override
  String get badgeAwareness => 'Conciencia';

  @override
  String get badgeAwarenessDesc => 'Big Picture';

  @override
  String get badgeBalance => 'Equilibrio';

  @override
  String get badgeBalanceDesc => 'Meta corporal';

  @override
  String get badgeGuardian => 'Guardián';

  @override
  String get badgeGuardianDesc => 'Compromiso';

  @override
  String get metricSystem => 'Métrico (kg, cm, °C)';

  @override
  String get historyComingSoon => 'Historial — Próximamente';

  @override
  String get discoverComingSoon => 'Educación y consejos — Próximamente';

  @override
  String get registerIndicators => 'Registrar Indicadores';

  @override
  String get anthropometry => 'Medidas Antropométricas';

  @override
  String get unitOfMeasureTitle => 'Unidad de Medida';

  @override
  String get unitOfMeasureDescription =>
      '¿Cómo prefieres ver tus mediciones? Selecciona el sistema que mejor se adapte a ti para un seguimiento preciso de tu bienestar.';

  @override
  String get metricOption => 'Métrico (kg, cm)';

  @override
  String get metricSubtitle => 'Kilogramos y centímetros';

  @override
  String get imperialOption => 'Imperial (lb, ft/in)';

  @override
  String get imperialSubtitle => 'Libras y pies/pulgadas';

  @override
  String get continueAction => 'Continuar';

  @override
  String get languageTitle => 'Selección de Idioma';

  @override
  String get languageDescription =>
      'Selecciona tu idioma de preferencia para que la aplicación se adapte a ti. Puedes cambiarlo en cualquier momento desde esta pantalla.';

  @override
  String get profileImageTitle => 'Imagen de perfil';

  @override
  String get gallery => 'Galería';

  @override
  String get camera => 'Cámara';

  @override
  String get deletePhoto => 'Eliminar foto';

  @override
  String get cancel => 'Cancelar';

  @override
  String get personalInfoTitle => 'Información Personal';

  @override
  String get personalInfoDescription =>
      'Mantén tus datos actualizados para recibir recomendaciones de salud más precisas y personalizadas.';

  @override
  String get fullName => 'Nombre completo';

  @override
  String get birthDate => 'Fecha de nacimiento';

  @override
  String get emailOptional => 'Correo electrónico (Opcional)';

  @override
  String get phoneOptional => 'Teléfono (Opcional)';

  @override
  String get selectCountry => 'Selecciona tu país';

  @override
  String get searchCountry => 'Buscar país';

  @override
  String get gender => 'Sexo';

  @override
  String get male => 'Hombre';

  @override
  String get female => 'Mujer';

  @override
  String get other => 'Otro';

  @override
  String get activityLevel => 'Nivel de Actividad';

  @override
  String get activitySedentary => 'Sedentario';

  @override
  String get activityLightlyActive => 'Ligeramente Activo';

  @override
  String get activityModeratelyActive => 'Moderadamente Activo';

  @override
  String get activityVeryActive => 'Muy Activo';

  @override
  String get activityExtraActive => 'Extra Activo';

  @override
  String get selectDate => 'Seleccionar fecha';

  @override
  String get recordAnthropometricTitle => 'MEDIDAS ANTROPOMÉTRICAS';

  @override
  String get dateTimeOfMeasurement => 'FECHA Y HORA DE LA TOMA';

  @override
  String get dateLabel => 'Fecha';

  @override
  String get timeLabel => 'Hora';

  @override
  String get bodyMeasurements => 'MEDIDAS CORPORALES';

  @override
  String get weightLabel => 'Peso';

  @override
  String get heightLabel => 'Talla';

  @override
  String get bmiTitle => 'Índice de Masa Corporal (IMC)';

  @override
  String get manual => 'Manual';

  @override
  String get bmiLow => 'BAJO';

  @override
  String get bmiNormal => 'NORMAL';

  @override
  String get bmiOverweight => 'SOBREPESO';

  @override
  String get bmiObesity => 'OBESIDAD';

  @override
  String get commentOptional => 'COMENTARIO (OPCIONAL)';

  @override
  String get commentHint => '¿Alguna observación sobre esta toma?';

  @override
  String get saveAndEarnXp => 'Guardar y ganar +10 XP ✦';

  @override
  String get historyGoodJob => '¡Buen trabajo!';

  @override
  String get historyGoalProgress =>
      'Has registrado una nueva medición este mes, manteniéndote en tu ruta de bienestar.';

  @override
  String historyWeightLoss(String weight) {
    return 'Has perdido ${weight}kg este mes, acercándote a tu meta de bienestar.';
  }

  @override
  String get historyBmiTrend => 'TENDENCIA DE IMC';

  @override
  String get historyLast6Months => 'Últimos 6 meses';

  @override
  String get historyTargetZone => 'Zona Objetivo';

  @override
  String get historyBmiUnit => 'IMC';

  @override
  String get historyExportPdf => 'Exportar a PDF';

  @override
  String get historyExportCsv => 'Excel (CSV)';

  @override
  String get historyMeasurements => 'HISTORIAL DE MEDICIONES';

  @override
  String get historyNoMeasurements =>
      'Aún no hay mediciones. Registra la primera para comenzar tu historial.';

  @override
  String get historyColDate => 'Fecha';

  @override
  String get historyColWeight => 'Peso (kg)';

  @override
  String get historyColBmi => 'IMC';

  @override
  String get historyColCategory => 'Categoría';

  @override
  String get historyUnknown => 'Desconocido';

  @override
  String get historyPdfTitle => 'Historial Antropométrico';

  @override
  String get historyShareCsvSubject => 'Historial de mediciones CSV';

  @override
  String get historyBmiLabel => 'IMC';

  @override
  String get recordVitalSignsTitle => 'SIGNOS VITALES';

  @override
  String get bloodPressureTitle => 'PRESIÓN ARTERIAL (MMHG)';

  @override
  String get systolicLabel => 'SISTÓLICA';

  @override
  String get diastolicLabel => 'DIASTÓLICA';

  @override
  String get heartRateTitle => 'FRECUENCIA CARDÍACA (BPM)';

  @override
  String get contextAndSymptoms => 'CONTEXTO Y SÍNTOMAS';

  @override
  String get activityState => 'ESTADO DE ACTIVIDAD';

  @override
  String get activityRest => 'Reposo';

  @override
  String get activityExercise => 'Ejercicio';

  @override
  String get activityPostOp => 'Post-op';

  @override
  String get howDoYouFeel => '¿CÓMO TE SIENTES?';

  @override
  String get symptomNormal => 'Normal';

  @override
  String get symptomDizziness => 'Mareo';

  @override
  String get symptomPain => 'Dolor';

  @override
  String get symptomFatigue => 'Fatiga';

  @override
  String get bpLow => 'BAJA';

  @override
  String get bpNormal => 'NORMAL';

  @override
  String get bpElevated => 'ELEVADA';

  @override
  String get bpHigh => 'ALTA';

  @override
  String get hrLow => 'BAJA';

  @override
  String get hrNormal => 'NORMAL';

  @override
  String get hrHigh => 'ALTA';

  @override
  String get vitalsSavedSuccess => 'Signos vitales guardados exitosamente.';

  @override
  String get lipidProfileTitle => 'PERFIL LIPÍDICO';

  @override
  String get lipidInfoBanner =>
      'Ingresa los valores de tu último análisis de laboratorio. Todos los campos son opcionales, pero se recomienda registrarlos completos para una mejor evaluación.';

  @override
  String get lipidLabInfo => 'INFORMACIÓN DEL LABORATORIO';

  @override
  String get lipidLabName => 'Nombre del Laboratorio';

  @override
  String get lipidLabNameHint => 'Ej: Lab Clínico San Rafael';

  @override
  String get lipidResultsTitle => 'RESULTADOS DEL ANÁLISIS (mg/dL)';

  @override
  String get lipidTotalCholesterol => 'Colesterol Total';

  @override
  String get lipidTcRef => 'Ref: < 200 mg/dL';

  @override
  String get lipidLdl => 'LDL (Colesterol \"Malo\")';

  @override
  String get lipidLdlRef => 'Ref: < 100 mg/dL';

  @override
  String get lipidHdl => 'HDL (Colesterol \"Bueno\")';

  @override
  String get lipidHdlRef => 'Ref: ≥ 60 mg/dL';

  @override
  String get lipidVldl => 'VLDL';

  @override
  String get lipidVldlRef => 'Ref: 2 – 30 mg/dL';

  @override
  String get lipidTriglycerides => 'Triglicéridos';

  @override
  String get lipidTrigsRef => 'Ref: < 150 mg/dL';

  @override
  String get lipidStatusOptimal => 'ÓPTIMO';

  @override
  String get lipidStatusNearOptimal => 'ACEPTABLE';

  @override
  String get lipidStatusBorderline => 'LÍMITE';

  @override
  String get lipidStatusHigh => 'ALTO';

  @override
  String get lipidStatusLow => 'BAJO';

  @override
  String get lipidStatusProtective => 'PROTECTOR';

  @override
  String get lipidStatusAcceptable => 'ACEPTABLE';

  @override
  String get lipidOverallRisk => 'EVALUACIÓN GENERAL';

  @override
  String get lipidOverallDesc =>
      'Basado en los valores ingresados. Consulta siempre a tu médico.';

  @override
  String get lipidAtLeastOneValue =>
      'Ingresa al menos un valor para guardar el registro.';

  @override
  String get lipidSavedSuccess => 'Perfil lipídico guardado exitosamente.';

  @override
  String get compositionTitle => 'PERFIL CORPORAL';

  @override
  String get compositionInfoBanner =>
      'Ingresa los valores obtenidos de tu analizador corporal (p. ej., báscula de bioimpedancia). Todos los campos son opcionales; registra los que tu dispositivo proporcione.';

  @override
  String get compositionDevice => 'DISPOSITIVO DE MEDICIÓN';

  @override
  String get compositionDeviceHint => 'Ej: Báscula OMRON HBF-514C';

  @override
  String get compositionBodyFat => 'PORCENTAJE DE GRASA CORPORAL (%)';

  @override
  String get compositionMuscleMass => 'MASA MUSCULAR (KG)';

  @override
  String get compositionVisceralAndAge => 'GRASA VISCERAL Y EDAD METABÓLICA';

  @override
  String get compositionVisceralFat => 'GRASA VISCERAL';

  @override
  String get compositionLevel => 'Nivel';

  @override
  String get compositionMetabolicAge => 'EDAD METABÓLICA';

  @override
  String get compositionYears => 'Años';

  @override
  String get compositionOptionalSection =>
      'OPCIONALES (AGUA CORPORAL Y MASA ÓSEA)';

  @override
  String get compositionBodyWater => 'Agua Corporal';

  @override
  String get compositionBodyWaterRef => 'Ref: 50–65 %';

  @override
  String get compositionBoneMass => 'Masa Ósea';

  @override
  String get compositionBoneMassRef => 'Ref: 2–4 kg';

  @override
  String get compositionBmr => 'METABOLISMO BASAL (KCAL)';

  @override
  String get compositionBmrSubtitle =>
      'CÁLCULO ESTIMADO BASADO EN TU COMPOSICIÓN ACTUAL';

  @override
  String get fatVeryLow => 'MUY BAJO';

  @override
  String get fatLow => 'BAJO';

  @override
  String get fatNormal => 'NORMAL';

  @override
  String get fatElevated => 'ELEVADO';

  @override
  String get fatHigh => 'ALTO';

  @override
  String get infoBannerAnthro =>
      'Trate de tomar la medida todas las veces en las mismas condiciones, por ejemplo: todas las mañanas después de levantarse, ir al baño y antes de desayunar.';

  @override
  String get infoBannerVitals =>
      'Trate de tomarse los signos vitales después de llevar media hora en reposo.';

  @override
  String get compositionSavedSuccess =>
      'Perfil corporal guardado exitosamente.';

  @override
  String discoverGreeting(String name) {
    return 'Buenos días, $name';
  }

  @override
  String get discoverSearchHint => 'Buscar consejos...';

  @override
  String get discoverDailyTip => 'CONSEJO DE SALUD DIARIO';

  @override
  String get discoverReadMore => 'Leer más';

  @override
  String get discoverRecommended => 'Recomendado para ti';

  @override
  String get discoverCategoryAll => 'Todos';

  @override
  String get discoverCategoryHeart => 'Salud del Corazón';

  @override
  String get discoverCategoryNutrition => 'Nutrición';

  @override
  String get discoverCategoryEmotional => 'Salud Emocional';

  @override
  String get discoverCategorySports => 'Deporte';

  @override
  String get discoverCategorySleep => 'Descanso';

  @override
  String get discoverMinRead => 'MIN DE LECTURA';

  @override
  String get discoverFeatured => 'Destacados';

  @override
  String get discoverRoutines => 'Rutinas';

  @override
  String get discoverArticles => 'Artículos';

  @override
  String get discoverChallenges => 'Retos';

  @override
  String get discoverSeeAll => 'Ver todo';

  @override
  String get discoverMinShort => 'min';

  @override
  String get discoverStart => 'Empezar';

  @override
  String get discoverJoin => 'Unirme';

  @override
  String get discoverLevelBeginner => 'Principiante';

  @override
  String get discoverLevelIntermediate => 'Intermedio';

  @override
  String get discoverLevelAdvanced => 'Avanzado';

  @override
  String get discoverStatusActive => 'Activo';

  @override
  String get discoverStatusScheduled => 'Programado';

  @override
  String get discoverStatusFinished => 'Finalizado';

  @override
  String get discoverEmpty => 'Aún no hay contenido disponible.';

  @override
  String discoverExercises(String count) {
    return '$count ejercicios';
  }

  @override
  String discoverParticipants(String count) {
    return '$count participantes';
  }

  @override
  String discoverDaysShort(String count) {
    return '$count días';
  }

  @override
  String get privacySecurityDescription =>
      'Gestiona cómo se protege tu información médica y personal.';

  @override
  String get biometricLockTitle => 'Bloqueo Biométrico';

  @override
  String get biometricLockSubtitle =>
      'Requiere Huella o FaceID al iniciar la app';

  @override
  String get biometricReasoning =>
      'Tus registros médicos son información confidencial. Activar el bloqueo biométrico garantiza que solo tú puedas acceder a tus datos de salud, protegiendo tu privacidad.';

  @override
  String get unlockAppToContinue => 'Desbloquea para continuar';

  @override
  String get biometricNotAvailable =>
      'Biometría no disponible en este dispositivo.';

  @override
  String get healthGoalsTitle => 'Metas de Salud';

  @override
  String get healthGoalsDescription =>
      'Establece tus objetivos médicos para hacer un seguimiento de tu progreso.';

  @override
  String get medicalGoalsToggle => 'Activar Objetivos médicos';

  @override
  String get medicalGoalsSubtitle =>
      'Habilitar para establecer metas de peso y composición corporal';

  @override
  String get targetWeight => 'Peso Objetivo';

  @override
  String get targetBodyFat => 'Objetivo de Grasa Corporal';

  @override
  String get targetMuscleMass => 'Objetivo de Masa Muscular';

  @override
  String get targetVisceralFat => 'Objetivo de Grasa Visceral';

  @override
  String get goalsSavedSuccess => 'Metas guardadas exitosamente.';

  @override
  String get helpSupportPageTitle => 'Ayuda y Soporte';

  @override
  String get helpSupportPageDescription =>
      'Todo lo que necesitas saber sobre My Vitals.';

  @override
  String get helpFaqTitle => 'Preguntas Frecuentes';

  @override
  String get helpFaqDescription =>
      'Respuestas rápidas a las dudas más comunes.';

  @override
  String get helpGlossaryTitle => 'Glosario Médico';

  @override
  String get helpGlossaryDescription => 'Entiende cada indicador de tu salud.';

  @override
  String get helpLegalTitle => 'Aviso Legal';

  @override
  String get helpLegalDescription => 'Términos de uso y privacidad de datos.';

  @override
  String get helpContactTitle => 'Contacto y Feedback';

  @override
  String get helpContactDescription => 'Escríbenos, mejoramos contigo.';

  @override
  String get helpSearchHint => 'Buscar...';

  @override
  String get helpNoResults => 'Sin resultados para tu búsqueda.';

  @override
  String get helpFaqCatGeneral => 'General';

  @override
  String get helpFaqCatData => 'Mis Datos';

  @override
  String get helpFaqCatBiometrics => 'Biometría';

  @override
  String get helpFaqCatExport => 'Exportar';

  @override
  String get helpFaqQ1 => '¿Qué es My Vitals?';

  @override
  String get helpFaqA1 =>
      'My Vitals es una aplicación de seguimiento de salud personal que te permite registrar y monitorear tus indicadores de bienestar: medidas antropométricas, signos vitales, perfil lipídico y composición corporal.';

  @override
  String get helpFaqQ2 => '¿Mis datos se guardan en la nube?';

  @override
  String get helpFaqA2 =>
      'No. Todos tus datos se almacenan exclusivamente en tu dispositivo. My Vitals no envía ninguna información a servidores externos, garantizando total privacidad.';

  @override
  String get helpFaqQ3 => '¿Puedo usar la app sin internet?';

  @override
  String get helpFaqA3 =>
      'Sí. My Vitals funciona completamente sin conexión a internet. Solo necesitas conectividad para actualizaciones de la aplicación.';

  @override
  String get helpFaqQ4 => '¿Cómo activo el bloqueo biométrico?';

  @override
  String get helpFaqA4 =>
      'Ve a Perfil → Privacidad y Seguridad y activa el interruptor de Bloqueo Biométrico. Tu dispositivo debe tener huella dactilar o FaceID configurado.';

  @override
  String get helpFaqQ5 => '¿Cómo exporto mi historial?';

  @override
  String get helpFaqA5 =>
      'En cada pantalla de historial (Antropométrico, Signos Vitales, etc.) encontrarás los botones \'Exportar PDF\' y \'Excel (CSV)\' en la parte superior.';

  @override
  String get helpFaqQ6 => '¿Puedo cambiar las unidades de medida?';

  @override
  String get helpFaqA6 =>
      'Sí. Ve a Perfil → Unidades de Medida y elige entre el sistema Métrico (kg, cm) o Imperial (lb, ft/in).';

  @override
  String get helpFaqQ7 => '¿Qué pasa si borro la app?';

  @override
  String get helpFaqA7 =>
      'Al desinstalar la app, todos los datos almacenados localmente se eliminarán permanentemente. Te recomendamos exportar tu historial en PDF o CSV antes de desinstalar.';

  @override
  String get helpFaqQ8 => '¿Esta app reemplaza a mi médico?';

  @override
  String get helpFaqA8 =>
      'No. My Vitals es una herramienta de seguimiento personal para ayudarte a llevar un registro organizado. Siempre consulta a un profesional de la salud para interpretación y diagnóstico médico.';

  @override
  String get helpGlossarySearchHint => 'Buscar término...';

  @override
  String get helpGlossaryGroupAnthropo => 'Medidas Antropométricas';

  @override
  String get helpGlossaryGroupVitals => 'Signos Vitales';

  @override
  String get helpGlossaryGroupLipid => 'Perfil Lipídico';

  @override
  String get helpGlossaryGroupBody => 'Perfil Corporal';

  @override
  String get helpGlossaryNormalRange => 'Rango normal';

  @override
  String get helpLegalPurposeTitle => 'Propósito de la aplicación';

  @override
  String get helpLegalPurposeBody =>
      'My Vitals es una aplicación de seguimiento personal de salud diseñada para ayudar a los usuarios a registrar y visualizar sus indicadores de bienestar. No es un dispositivo médico certificado.';

  @override
  String get helpLegalNotMedicalTitle => 'No es un dispositivo médico';

  @override
  String get helpLegalNotMedicalBody =>
      'La información mostrada en esta aplicación es únicamente de referencia. No sustituye el diagnóstico, consejo o tratamiento de un profesional de la salud. Ante cualquier síntoma o duda médica, consulte a su médico.';

  @override
  String get helpLegalResponsibilityTitle => 'Responsabilidad del usuario';

  @override
  String get helpLegalResponsibilityBody =>
      'El usuario es responsable de la exactitud de los datos ingresados. My Vitals no se hace responsable de decisiones de salud tomadas con base en la información registrada en la app.';

  @override
  String get helpLegalPrivacyTitle => 'Privacidad y datos';

  @override
  String get helpLegalPrivacyBody =>
      'Todos los datos se almacenan localmente en el dispositivo del usuario. My Vitals no recopila, transmite ni comparte información personal con terceros. No existen cuentas de usuario ni servidores de datos.';

  @override
  String get helpLegalContactTitle => 'Contacto del desarrollador';

  @override
  String get helpLegalContactBody =>
      'Para consultas legales o de privacidad, puede contactar al desarrollador en: yesithvalencia@gmail.com';

  @override
  String get helpContactReportBug => 'Reportar un error';

  @override
  String get helpContactReportBugDesc =>
      '¿Encontraste algo que no funciona bien? Cuéntanos.';

  @override
  String get helpContactSuggest => 'Enviar sugerencia';

  @override
  String get helpContactSuggestDesc =>
      '¿Tienes una idea para mejorar la app? La queremos escuchar.';

  @override
  String get helpContactSendEmail => 'Enviar correo';

  @override
  String get helpContactAppVersion => 'Versión de la aplicación';

  @override
  String get helpContactWhatsNew => 'Novedades';

  @override
  String get helpContactV110 => 'v1.1.0 — Actual';

  @override
  String get helpContactV110Changes =>
      '• Bloqueo biométrico (huella / FaceID)\n• Metas de salud personalizadas\n• Soporte para idioma italiano\n• Mejoras en el selector de nivel de actividad';

  @override
  String get helpContactV100 => 'v1.0.0 — Lanzamiento inicial';

  @override
  String get helpContactV100Changes =>
      '• Registro de medidas antropométricas\n• Signos vitales y perfil lipídico\n• Composición corporal\n• Exportación PDF y CSV\n• Soporte multiidioma (es, en, de, pt)';

  @override
  String get myDataBackup => 'Mis Datos';

  @override
  String get backupTitle => 'Backup & Restauración';

  @override
  String get backupDescription =>
      'Exporta o restaura todos tus datos y preferencias.';

  @override
  String get backupPrivacyTitle => 'Tus datos son tuyos. Y solo tuyos.';

  @override
  String get backupPrivacyBody =>
      'Todas nuestras funciones de salud están diseñadas con la privacidad como núcleo y para mantener tus datos seguros.\n\nTus datos de salud están encriptados en tu dispositivo y solo son accesibles con tu código, Touch ID o Face ID. No usamos servidores en la nube y nunca compartimos tus datos con terceros.';

  @override
  String get backupPrivacyHighlight =>
      'Tus datos de salud están encriptados localmente y ni siquiera nosotros podemos acceder a tu información.';

  @override
  String get backupExportTitle => 'Exportar mis datos';

  @override
  String get backupExportSubtitle =>
      'Genera un archivo seguro con todo tu historial y configuración';

  @override
  String get backupExportButton => 'Exportar Backup';

  @override
  String get backupImportTitle => 'Restaurar mis datos';

  @override
  String get backupImportSubtitle => 'Importa un backup previo de My Vitals';

  @override
  String get backupImportButton => 'Importar Backup';

  @override
  String get backupWhatIncluded => '¿Qué incluye el backup?';

  @override
  String get backupSuccess => '¡Backup exportado exitosamente!';

  @override
  String get backupImportSuccess => '¡Datos restaurados correctamente!';

  @override
  String get backupImportError =>
      'Error al importar. Verifica que el archivo sea válido.';

  @override
  String get backupImportConfirmTitle => '¿Restaurar datos?';

  @override
  String get backupImportConfirmBody =>
      'Esto reemplazará tus registros actuales con los del backup. ¿Deseas continuar?';

  @override
  String get backupIncludesVitalSigns => 'Historial de Signos Vitales';

  @override
  String get backupIncludesAnthropo => 'Historial Antropométrico';

  @override
  String get backupIncludesLipid => 'Perfil Lipídico';

  @override
  String get backupIncludesBodyComp => 'Composición Corporal';

  @override
  String get backupIncludesPersonalInfo => 'Información Personal';

  @override
  String get backupIncludesGoals => 'Objetivos de Salud';

  @override
  String get backupIncludesPhoto => 'Foto de Perfil';

  @override
  String get backupIncludesPreferences => 'Preferencias (idioma, unidades)';

  @override
  String get backupCancel => 'Cancelar';

  @override
  String get onboardingWelcomeTitle => 'Bienvenido a My Vitals';

  @override
  String get onboardingWelcomeSubtitle => 'Tu compañero de salud personal';

  @override
  String get onboardingWelcomeFeature1 =>
      'Registra tus signos vitales y medidas corporales';

  @override
  String get onboardingWelcomeFeature2 =>
      'Visualiza tu progreso con gráficas y estadísticas';

  @override
  String get onboardingWelcomeFeature3 =>
      '100% privado, todo se guarda en tu dispositivo';

  @override
  String get onboardingNext => 'Siguiente';

  @override
  String get onboardingFinish => '¡Empezar!';

  @override
  String get onboardingSkip => 'Omitir';

  @override
  String onboardingStep(int current, int total) {
    return 'Paso $current de $total';
  }

  @override
  String get onboardingAvatarTitle => 'Tu foto de perfil';

  @override
  String get onboardingAvatarSubtitle =>
      'Ponle cara a tu experiencia de salud (opcional)';

  @override
  String get remindersTitle => 'Recordatorios y Alertas';

  @override
  String get remindersDescription =>
      'Configura alertas diarias para recordar tus chequeos médicos de rutina.';

  @override
  String get remindersNote =>
      '* Las notificaciones llegarán a tu dispositivo diariamente a la hora programada.';

  @override
  String get reminderVitals => 'Registrar Signos Vitales';

  @override
  String get reminderMeds => 'Tomar Medicación';

  @override
  String get reminderWorkout => 'Actividad Física';

  @override
  String get reminderWater => 'Tomar Agua';

  @override
  String get reminderTitle => 'Recordatorio Médico';

  @override
  String get filterLast7Days => 'Últimos 7 días';

  @override
  String get filterLast30Days => 'Últimos 30 días';

  @override
  String get filterLast6Months => 'Últimos 6 meses';

  @override
  String get filterAllTime => 'Siempre';

  @override
  String goalRemainingWeight(String weight) {
    return 'Faltan ${weight}kg para tu meta';
  }

  @override
  String get goalAchieved => '¡Meta cumplida!';

  @override
  String get noGoalDefined => 'Meta no definida';

  @override
  String get validationRequiredFields => 'Campos requeridos';

  @override
  String get validationCompleteBeforeContinue =>
      'Completa estos campos antes de continuar:';

  @override
  String get validationSelectLanguage => 'Selecciona un idioma';

  @override
  String get validationEnterName => 'Ingresa tu nombre completo';

  @override
  String get validationSelectBirthDate => 'Selecciona tu fecha de nacimiento';

  @override
  String get validationSelectGender => 'Selecciona tu sexo';

  @override
  String get dashboardCompositionFat => 'GRASA';

  @override
  String get dashboardCompositionMuscle => 'MÚSCULO';

  @override
  String get dashboardCompositionVisceral => 'VISCERAL';

  @override
  String get dashboardCompositionBmr => 'TMB';

  @override
  String dashboardCompositionLevel(int level) {
    return 'Nv. $level';
  }

  @override
  String get vitalsPdfTitle => 'Historial de Signos Vitales';

  @override
  String get vitalsShareCsvSubject => 'Exportación CSV de Signos Vitales';

  @override
  String get lipidPdfTitle => 'Historial de Perfil Lipídico';

  @override
  String get lipidShareCsvSubject => 'Exportación CSV de Laboratorios';

  @override
  String get compositionPdfTitle => 'Historial de Composición Corporal';

  @override
  String get compositionShareCsvSubject =>
      'Exportación CSV de Composición Corporal';

  @override
  String get reminderDefaultTitle => 'Recordatorio Médico';

  @override
  String get exportColComment => 'Comentario';

  @override
  String get exportColHeight => 'Talla (m)';

  @override
  String get exportColSysDia => 'Sís/Dia';

  @override
  String get exportColHrShort => 'FC';

  @override
  String get exportColStatus => 'Estado';

  @override
  String get exportColSystolic => 'Sistólica';

  @override
  String get exportColDiastolic => 'Diastólica';

  @override
  String get exportColHeartRate => 'Frecuencia Cardíaca';

  @override
  String get exportColActivityState => 'Estado de Actividad';

  @override
  String get exportColSymptom => 'Síntoma';

  @override
  String get exportColTotalCholShort => 'Col. Total';

  @override
  String get exportColTrigsShort => 'Trig.';

  @override
  String get exportColTotalCholesterol => 'Colesterol Total';

  @override
  String get exportColTriglycerides => 'Triglicéridos';

  @override
  String get exportColLabName => 'Laboratorio';

  @override
  String get exportColBodyFat => 'Grasa Corporal';

  @override
  String get exportColMuscleMass => 'Masa Muscular';

  @override
  String get exportColVisceralFat => 'Grasa Visceral';

  @override
  String get exportColMetabolicAge => 'Edad Metabólica';

  @override
  String get exportColBodyWater => 'Agua Corporal';

  @override
  String get exportColBoneMass => 'Masa Ósea';

  @override
  String get exportColBmr => 'TMB';

  @override
  String get glossaryImcName => 'IMC (Índice de Masa Corporal)';

  @override
  String get glossaryImcDefinition =>
      'Medida que relaciona el peso y la talla de una persona para evaluar si su peso es saludable. Se calcula dividiendo el peso (kg) entre la talla al cuadrado (m²).';

  @override
  String get glossaryImcRange => '18.5 – 24.9 kg/m²';

  @override
  String get glossaryPesoName => 'Peso corporal';

  @override
  String get glossaryPesoDefinition =>
      'Masa total del cuerpo expresada en kilogramos o libras. Incluye músculos, huesos, órganos, grasa y agua.';

  @override
  String get glossaryPesoRange => 'Depende de la talla y complexión';

  @override
  String get glossaryTallaName => 'Talla (Estatura)';

  @override
  String get glossaryTallaDefinition =>
      'Medida de la altura de una persona desde los pies hasta la parte superior de la cabeza, expresada en centímetros o metros.';

  @override
  String get glossarySistolicaName => 'Presión Sistólica';

  @override
  String get glossarySistolicaDefinition =>
      'Es la presión máxima que ejerce la sangre sobre las arterias cuando el corazón se contrae (late). Es el número superior en una lectura de presión arterial.';

  @override
  String get glossarySistolicaRange => '< 120 mmHg';

  @override
  String get glossaryDiastolicaName => 'Presión Diastólica';

  @override
  String get glossaryDiastolicaDefinition =>
      'Es la presión mínima que ejerce la sangre sobre las arterias entre latidos, cuando el corazón está en reposo. Es el número inferior en una lectura de presión arterial.';

  @override
  String get glossaryDiastolicaRange => '< 80 mmHg';

  @override
  String get glossaryFcName => 'Frecuencia Cardíaca';

  @override
  String get glossaryFcDefinition =>
      'Número de veces que el corazón late por minuto (lpm). En reposo, un corazón saludable late de forma regular y en un rango específico.';

  @override
  String get glossaryFcRange => '60 – 100 lpm en reposo';

  @override
  String get glossaryColesterolTotalName => 'Colesterol Total';

  @override
  String get glossaryColesterolTotalDefinition =>
      'Suma de todo el colesterol presente en la sangre, incluyendo LDL, HDL y otros lípidos. Es un marcador general del riesgo cardiovascular.';

  @override
  String get glossaryColesterolTotalRange => '< 200 mg/dL';

  @override
  String get glossaryLdlName => 'LDL (Colesterol \"Malo\")';

  @override
  String get glossaryLdlDefinition =>
      'Lipoproteína de baja densidad. Transporta colesterol al interior de las arterias y puede acumularse en sus paredes, aumentando el riesgo de enfermedad cardiovascular.';

  @override
  String get glossaryLdlRange => '< 100 mg/dL';

  @override
  String get glossaryHdlName => 'HDL (Colesterol \"Bueno\")';

  @override
  String get glossaryHdlDefinition =>
      'Lipoproteína de alta densidad. Recoge el colesterol sobrante de las arterias y lo lleva al hígado para ser eliminado. Niveles altos son protectores.';

  @override
  String get glossaryHdlRange => '≥ 60 mg/dL';

  @override
  String get glossaryVldlName => 'VLDL';

  @override
  String get glossaryVldlDefinition =>
      'Lipoproteína de muy baja densidad. Transporta triglicéridos desde el hígado hacia los tejidos. Niveles elevados se asocian con mayor riesgo cardiovascular.';

  @override
  String get glossaryVldlRange => '2 – 30 mg/dL';

  @override
  String get glossaryTrigliceridosName => 'Triglicéridos';

  @override
  String get glossaryTrigliceridosDefinition =>
      'Tipo de grasa (lípido) presente en la sangre. El cuerpo los usa como fuente de energía, pero niveles altos aumentan el riesgo de enfermedades cardíacas y pancreáticas.';

  @override
  String get glossaryTrigliceridosRange => '< 150 mg/dL';

  @override
  String get glossaryGrasaName => 'Porcentaje de Grasa Corporal';

  @override
  String get glossaryGrasaDefinition =>
      'Proporción de masa grasa respecto al peso total del cuerpo. Incluye grasa esencial (necesaria para funciones vitales) y grasa de reserva.';

  @override
  String get glossaryGrasaRange => 'Hombres: 8–19% / Mujeres: 21–33%';

  @override
  String get glossaryMusculoName => 'Masa Muscular';

  @override
  String get glossaryMusculoDefinition =>
      'Peso total del tejido muscular en el cuerpo, expresado en kilogramos. Un mayor porcentaje de músculo se asocia con un metabolismo más activo.';

  @override
  String get glossaryGrasaVisceralName => 'Grasa Visceral';

  @override
  String get glossaryGrasaVisceralDefinition =>
      'Grasa acumulada alrededor de los órganos internos del abdomen (hígado, intestinos, páncreas). Niveles altos están asociados a mayor riesgo metabólico y cardiovascular.';

  @override
  String get glossaryGrasaVisceralRange => 'Nivel 1–9 (saludable)';

  @override
  String get glossaryEdadMetabolicaName => 'Edad Metabólica';

  @override
  String get glossaryEdadMetabolicaDefinition =>
      'Edad estimada del metabolismo basal comparado con la media de la población. Una edad metabólica menor a la cronológica indica un metabolismo eficiente.';

  @override
  String get glossaryBmrName => 'BMR / Metabolismo Basal (kcal)';

  @override
  String get glossaryBmrDefinition =>
      'Cantidad mínima de energía (calorías) que el cuerpo necesita en reposo absoluto para mantener las funciones vitales: respiración, circulación, temperatura, etc.';

  @override
  String get glossaryAguaName => 'Agua Corporal';

  @override
  String get glossaryAguaDefinition =>
      'Porcentaje del peso corporal que corresponde al agua. El agua es esencial para todas las funciones celulares, regulación de temperatura y transporte de nutrientes.';

  @override
  String get glossaryAguaRange => '50 – 65%';

  @override
  String get glossaryHuesoName => 'Masa Ósea';

  @override
  String get glossaryHuesoDefinition =>
      'Peso estimado del tejido óseo en el cuerpo. Mantener una masa ósea adecuada es fundamental para prevenir la osteoporosis.';

  @override
  String get glossaryHuesoRange => '2 – 4 kg (adulto promedio)';

  @override
  String get deleteRecordTitle => '¿Eliminar registro?';

  @override
  String get deleteRecordBody => 'Esta acción no se puede deshacer.';

  @override
  String get deleteRecordConfirm => 'Eliminar';

  @override
  String get recordDeleted => 'Registro eliminado';

  @override
  String get anthropoSavedSuccess => 'Medida guardada exitosamente.';

  @override
  String historyShowMore(int count) {
    return 'Ver $count más';
  }
}
