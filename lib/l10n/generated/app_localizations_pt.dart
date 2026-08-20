// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Portuguese (`pt`).
class AppLocalizationsPt extends AppLocalizations {
  AppLocalizationsPt([String locale = 'pt']) : super(locale);

  @override
  String get appTitle => 'Meus Vitais';

  @override
  String get dashboard => 'Início';

  @override
  String get history => 'Histórico';

  @override
  String get record => 'Registrar';

  @override
  String get discover => 'Descobrir';

  @override
  String get profile => 'Perfil';

  @override
  String get language => 'Idioma';

  @override
  String get savePreferences => 'Salvar Preferências';

  @override
  String get selectLanguage => 'Selecione seu idioma preferido';

  @override
  String get personalInfo => 'Informações Pessoais';

  @override
  String get measurementUnits => 'Unidades de Medida';

  @override
  String get notifications => 'Notificações';

  @override
  String get privacySecurity => 'Privacidade e Segurança';

  @override
  String get helpSupport => 'Ayuda e Suporte';

  @override
  String get logOut => 'Sair';

  @override
  String level(int value) {
    return 'Nível $value';
  }

  @override
  String get newUserInfo => 'Novo Usuário';

  @override
  String xpForNextLevel(int current, int total) {
    return '$current / $total XP para o próximo nível';
  }

  @override
  String get levelProgress => 'Progresso do Nível';

  @override
  String get vitalSigns => 'Signos Vitais';

  @override
  String get vitalsSubtitle => 'Pressão arterial e Frequência cardíaca';

  @override
  String get noDataYet => 'Ainda não há dados registrados.';

  @override
  String get recordVitalsAction => 'Registrar pressão e frequência ›';

  @override
  String get bodyComposition => 'Composição Corporal';

  @override
  String get compositionSubtitle => 'Gordura, músculo, água e massa ósea.';

  @override
  String get completeBodyProfile => 'Completar perfil corporal ›';

  @override
  String get anthropometricHistory => 'Histórico Antropométrico';

  @override
  String get anthroSubtitle => 'Meça seu peso, altura e progresso físico.';

  @override
  String get recordFirstMeasure => 'Registrar primeira medida ›';

  @override
  String get lipidProfile => 'Perfil Lipídico';

  @override
  String get lipidSubtitle => 'Monitore colesterol e triglicerídeos.';

  @override
  String get recordLabResults => 'Registrar resultados de laboratório ›';

  @override
  String get medicalDisclaimerTitle => 'Aviso Médico';

  @override
  String get medicalDisclaimerText =>
      'Este aplicativo é apenas para fins informativos. Não substitui o conselho médico profissional.';

  @override
  String get selfCareProgress => 'Progresso de Autocuidado';

  @override
  String get myHealthAchievements => 'Minhas Conquistas de Saúde';

  @override
  String get badgeFirstStep => 'Primeiro Passo';

  @override
  String get badgeFirstStepDesc => 'Início da jornada';

  @override
  String get badgeStrongHeart => 'Coração Forte';

  @override
  String get badgeStrongHeartDesc => 'Saúde Cardio';

  @override
  String get badgeVitalHabit => 'Hábito Vital';

  @override
  String get badgeVitalHabitDesc => '7 dias seguidos';

  @override
  String get badgeAwareness => 'Consciência';

  @override
  String get badgeAwarenessDesc => 'Visão Geral';

  @override
  String get badgeBalance => 'Equilíbrio';

  @override
  String get badgeBalanceDesc => 'Meta corporal';

  @override
  String get badgeGuardian => 'Guardião';

  @override
  String get badgeGuardianDesc => 'Compromiso';

  @override
  String get metricSystem => 'Métrico (kg, cm, °C)';

  @override
  String get registerIndicators => 'Registrar Indicadores';

  @override
  String get anthropometry => 'Antropometria';

  @override
  String get unitOfMeasureTitle => 'Unidade de Medida';

  @override
  String get unitOfMeasureDescription =>
      'Como você prefere ver suas medições? Selecione o sistema que melhor se adapta a você para um acompanhamento preciso do seu bem-estar.';

  @override
  String get metricOption => 'Métrico (kg, cm)';

  @override
  String get metricSubtitle => 'Quilogramas e centímetros';

  @override
  String get imperialOption => 'Imperial (lb, ft/in)';

  @override
  String get imperialSubtitle => 'Libras e pés/polegadas';

  @override
  String get continueAction => 'Continuar';

  @override
  String get languageTitle => 'Seleção de Idioma';

  @override
  String get languageDescription =>
      'Selecione seu idioma preferido para adaptar o aplicativo às suas necessidades. Você pode alterá-lo a qualquer momento nesta tela.';

  @override
  String get profileImageTitle => 'Imagem de perfil';

  @override
  String get gallery => 'Galeria';

  @override
  String get camera => 'Câmera';

  @override
  String get deletePhoto => 'Excluir foto';

  @override
  String get cancel => 'Cancelar';

  @override
  String get personalInfoTitle => 'Informações Pessoais';

  @override
  String get personalInfoDescription =>
      'Mantenha seus dados atualizados para receber recomendações de saúde mais precisas e personalizadas.';

  @override
  String get fullName => 'Nome completo';

  @override
  String get birthDate => 'Data de nascimento';

  @override
  String get emailOptional => 'E-mail (Opcional)';

  @override
  String get phoneOptional => 'Telefone (Opcional)';

  @override
  String get selectCountry => 'Selecione seu país';

  @override
  String get searchCountry => 'Buscar país';

  @override
  String get gender => 'Gênero';

  @override
  String get male => 'Homem';

  @override
  String get female => 'Mulher';

  @override
  String get other => 'Outro';

  @override
  String get activityLevel => 'Nível de Atividade';

  @override
  String get activitySedentary => 'Sedentário';

  @override
  String get activityLightlyActive => 'Levemente Ativo';

  @override
  String get activityModeratelyActive => 'Moderadamente Ativo';

  @override
  String get activityVeryActive => 'Muito Ativo';

  @override
  String get activityExtraActive => 'Extra Ativo';

  @override
  String get selectDate => 'Selecionar data';

  @override
  String get recordAnthropometricTitle => 'MEDIDAS ANTROPOMÉTRICAS';

  @override
  String get dateTimeOfMeasurement => 'DATA E HORA DA MEDIÇÃO';

  @override
  String get dateLabel => 'Data';

  @override
  String get timeLabel => 'Hora';

  @override
  String get bodyMeasurements => 'MEDIDAS CORPORAIS';

  @override
  String get weightLabel => 'Peso';

  @override
  String get heightLabel => 'Altura';

  @override
  String get bmiTitle => 'Índice de Massa Corporal (IMC)';

  @override
  String get manual => 'Manual';

  @override
  String get bmiLow => 'BAIXO';

  @override
  String get bmiNormal => 'NORMAL';

  @override
  String get bmiOverweight => 'SOBREPESO';

  @override
  String get bmiObesity => 'OBESIDADE';

  @override
  String get commentOptional => 'COMENTÁRIO (OPCIONAL)';

  @override
  String get commentHint => 'Alguma observação sobre esta medição?';

  @override
  String get saveAndEarnXp => 'Salvar e ganhar +10 XP';

  @override
  String get historyGoodJob => 'Bom trabalho!';

  @override
  String get historyGoalProgress =>
      'Você registrou uma nova medição este mês, mantendo-se no caminho do bem-estar.';

  @override
  String historyWeightLoss(String weight) {
    return 'Você perdeu ${weight}kg este mês, aproximando-se da sua meta de bem-estar.';
  }

  @override
  String get historyBmiTrend => 'TENDÊNCIA DE IMC';

  @override
  String get historyLast6Months => 'Últimos 6 meses';

  @override
  String get historyTargetZone => 'Zona Alvo';

  @override
  String get historyBmiUnit => 'IMC';

  @override
  String get historyExportPdf => 'Exportar para PDF';

  @override
  String get historyExportCsv => 'Excel (CSV)';

  @override
  String get historyMeasurements => 'HISTÓRICO DE MEDIÇÕES';

  @override
  String get historyNoMeasurements =>
      'Nenhuma medição ainda. Registre a primeira para iniciar seu histórico.';

  @override
  String get historyColDate => 'Data';

  @override
  String get historyColWeight => 'Peso (kg)';

  @override
  String get historyColBmi => 'IMC';

  @override
  String get historyColCategory => 'Categoria';

  @override
  String get historyUnknown => 'Desconhecido';

  @override
  String get historyPdfTitle => 'Histórico Antropométrico';

  @override
  String get historyShareCsvSubject => 'Histórico de medições CSV';

  @override
  String get historyBmiLabel => 'IMC';

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
  String get recordVitalSignsTitle => 'SINAIS VITAIS';

  @override
  String get bloodPressureTitle => 'PRESSÃO ARTERIAL (MMHG)';

  @override
  String get systolicLabel => 'SISTÓLICA';

  @override
  String get diastolicLabel => 'DIASTÓLICA';

  @override
  String get heartRateTitle => 'FREQUÊNCIA CARDÍACA (BPM)';

  @override
  String get vitalMetricBpShort => 'Pressão Arterial';

  @override
  String get vitalMetricHrShort => 'Frequência Cardíaca';

  @override
  String get heartRateSeriesLabel => 'Frequência Cardíaca';

  @override
  String get symptomMarkerLegend => 'Com sintoma';

  @override
  String get contextAndSymptoms => 'CONTEXTO E SINTOMAS';

  @override
  String get activityState => 'ESTADO DE ATIVIDADE';

  @override
  String get activityRest => 'Repouso';

  @override
  String get activityExercise => 'Exercício';

  @override
  String get activityPostOp => 'Pós-op';

  @override
  String get howDoYouFeel => 'COMO VOCÊ SE SENTE?';

  @override
  String get symptomNormal => 'Normal';

  @override
  String get symptomDizziness => 'Tontura';

  @override
  String get symptomPain => 'Dor';

  @override
  String get symptomFatigue => 'Fadiga';

  @override
  String get bpLow => 'BAIXA';

  @override
  String get bpNormal => 'NORMAL';

  @override
  String get bpElevated => 'ELEVADA';

  @override
  String get bpHigh => 'ALTA';

  @override
  String get hrLow => 'BAIXA';

  @override
  String get hrNormal => 'NORMAL';

  @override
  String get hrHigh => 'ALTA';

  @override
  String get vitalsSavedSuccess => 'Sinais vitais salvos com sucesso.';

  @override
  String get lipidProfileTitle => 'PERFIL LIPÍDICO';

  @override
  String get lipidInfoBanner =>
      'Insira os valores do seu último exame laboratorial. Todos os campos são opcionais, mas preencher todos proporciona uma avaliação mais completa.';

  @override
  String get lipidLabInfo => 'INFORMAÇÕES DO LABORATÓRIO';

  @override
  String get lipidLabName => 'Nome do Laboratório';

  @override
  String get lipidLabNameHint => 'Ex: Laboratório São Lucas';

  @override
  String get lipidResultsTitle => 'RESULTADOS DA ANÁLISE (mg/dL)';

  @override
  String get lipidTotalCholesterol => 'Colesterol Total';

  @override
  String get lipidTcRef => 'Ref: < 200 mg/dL';

  @override
  String get lipidLdl => 'LDL (Colesterol \"Ruim\")';

  @override
  String get lipidLdlRef => 'Ref: < 100 mg/dL';

  @override
  String get lipidHdl => 'HDL (Colesterol \"Bom\")';

  @override
  String get lipidHdlRef => 'Ref: ≥ 60 mg/dL';

  @override
  String get lipidVldl => 'VLDL';

  @override
  String get lipidVldlRef => 'Ref: 2 – 30 mg/dL';

  @override
  String get lipidTriglycerides => 'Triglicerídeos';

  @override
  String get lipidTrigsRef => 'Ref: < 150 mg/dL';

  @override
  String get lipidStatusOptimal => 'ÓTIMO';

  @override
  String get lipidStatusNearOptimal => 'ACEITÁVEL';

  @override
  String get lipidStatusBorderline => 'LIMIAR';

  @override
  String get lipidStatusHigh => 'ALTO';

  @override
  String get lipidStatusLow => 'BAIXO';

  @override
  String get lipidStatusProtective => 'PROTETOR';

  @override
  String get lipidStatusAcceptable => 'ACEITÁVEL';

  @override
  String get lipidOverallRisk => 'AVALIAÇÃO GERAL';

  @override
  String get lipidOverallDesc =>
      'Baseado nos valores inseridos. Consulte sempre o seu médico.';

  @override
  String get lipidAtLeastOneValue =>
      'Insira pelo menos um valor para salvar o registro.';

  @override
  String get lipidSavedSuccess => 'Perfil lipídico salvo com sucesso.';

  @override
  String get compositionTitle => 'PERFIL CORPORAL';

  @override
  String get compositionInfoBanner =>
      'Insira os valores obtidos do seu analisador de composição corporal (ex: balança de bioimpedância). Todos os campos são opcionais; registe os que o seu dispositivo fornecer.';

  @override
  String get compositionDevice => 'DISPOSITIVO DE MEDIÇÃO';

  @override
  String get compositionDeviceHint => 'Ex: Balança OMRON HBF-514C';

  @override
  String get compositionBodyFat => 'PERCENTAGEM DE GORDURA CORPORAL (%)';

  @override
  String get compositionMuscleMass => 'MASSA MUSCULAR (KG)';

  @override
  String get compositionVisceralAndAge => 'GORDURA VISCERAL E IDADE METABÓLICA';

  @override
  String get compositionVisceralFat => 'GORDURA VISCERAL';

  @override
  String get compositionLevel => 'Nível';

  @override
  String get compositionMetabolicAge => 'IDADE METABÓLICA';

  @override
  String get compositionYears => 'Anos';

  @override
  String get compositionOptionalSection =>
      'OPCIONAIS (ÁGUA CORPORAL E MASSA ÓSSEA)';

  @override
  String get compositionBodyWater => 'Água Corporal';

  @override
  String get compositionBodyWaterRef => 'Ref: 50–65 %';

  @override
  String get compositionBoneMass => 'Massa Óssea';

  @override
  String get compositionBoneMassRef => 'Ref: 2–4 kg';

  @override
  String get compositionBmr => 'TAXA METABÓLICA BASAL (KCAL)';

  @override
  String get compositionBmrSubtitle =>
      'ESTIMATIVA COM BASE NA SUA COMPOSIÇÃO CORPORAL ATUAL';

  @override
  String get fatVeryLow => 'MUITO BAIXO';

  @override
  String get fatLow => 'BAIXO';

  @override
  String get fatNormal => 'NORMAL';

  @override
  String get fatElevated => 'ELEVADO';

  @override
  String get fatHigh => 'ALTO';

  @override
  String get infoBannerAnthro =>
      'Tente fazer a medição sempre nas mesmas condições, por exemplo: todas as manhãs depois de acordar, ir ao banheiro e antes do café da manhã.';

  @override
  String get infoBannerVitals =>
      'Tente verificar seus sinais vitais após descansar por meia hora.';

  @override
  String get compositionSavedSuccess => 'Perfil corporal salvo com sucesso.';

  @override
  String discoverGreeting(String name) {
    return 'Bom dia, $name';
  }

  @override
  String get discoverSearchHint => 'Procurar dicas...';

  @override
  String get discoverDailyTip => 'DICA DIÁRIA DE SAÚDE';

  @override
  String get discoverReadMore => 'Ler mais';

  @override
  String get discoverRecommended => 'Recomendado para si';

  @override
  String get discoverCategoryAll => 'Todos';

  @override
  String get discoverCategoryHeart => 'Saúde do Coração';

  @override
  String get discoverCategoryNutrition => 'Nutrição';

  @override
  String get discoverCategoryEmotional => 'Saúde Emocional';

  @override
  String get discoverCategorySports => 'Esporte';

  @override
  String get discoverCategorySleep => 'Descanso';

  @override
  String get discoverMinRead => 'MIN LEITURA';

  @override
  String get discoverFeatured => 'Destaques';

  @override
  String get discoverRoutines => 'Rotinas';

  @override
  String get discoverArticles => 'Artigos';

  @override
  String get discoverChallenges => 'Desafios';

  @override
  String get discoverSeeAll => 'Ver tudo';

  @override
  String get discoverMinShort => 'min';

  @override
  String get discoverStart => 'Começar';

  @override
  String get discoverJoin => 'Participar';

  @override
  String get discoverLevelBeginner => 'Iniciante';

  @override
  String get discoverLevelIntermediate => 'Intermédio';

  @override
  String get discoverLevelAdvanced => 'Avançado';

  @override
  String get discoverStatusActive => 'Ativo';

  @override
  String get discoverStatusScheduled => 'Agendado';

  @override
  String get discoverStatusFinished => 'Concluído';

  @override
  String get discoverEmpty => 'Ainda não há conteúdo disponível.';

  @override
  String discoverExercises(String count) {
    return '$count exercícios';
  }

  @override
  String discoverParticipants(String count) {
    return '$count participantes';
  }

  @override
  String discoverDaysShort(String count) {
    return '$count dias';
  }

  @override
  String get privacySecurityDescription =>
      'Gerencie como suas informações médicas e pessoais são protegidas.';

  @override
  String get biometricLockTitle => 'Bloqueio Biométrico';

  @override
  String get biometricLockSubtitle =>
      'Requer Impressão Digital ou FaceID ao iniciar o app';

  @override
  String get biometricReasoning =>
      'Seus registros médicos são informações confidenciais. Ativar o bloqueio biométrico garante que apenas você possa acessar seus dados de saúde, protegendo sua privacidade.';

  @override
  String get unlockAppToContinue => 'Desbloqueie para continuar';

  @override
  String get biometricNotAvailable =>
      'Biometria não disponível neste dispositivo.';

  @override
  String get healthGoalsTitle => 'Metas de Saúde';

  @override
  String get goalsScreenDescription =>
      'Define os teus valores-alvo e acompanha o teu progresso.';

  @override
  String get healthGoalsDescription =>
      'Defina seus objetivos médicos para acompanhar seu progresso.';

  @override
  String get medicalGoalsToggle => 'Ativar Objetivos Médicos';

  @override
  String get medicalGoalsSubtitle =>
      'Habilite para definir metas de peso e composição corporal';

  @override
  String get targetWeight => 'Peso Alvo';

  @override
  String get targetBodyFat => 'Gordura Corporal Alvo';

  @override
  String get targetMuscleMass => 'Massa Muscular Alvo';

  @override
  String get targetVisceralFat => 'Gordura Visceral Alvo';

  @override
  String get goalsSavedSuccess => 'Metas salvas com sucesso.';

  @override
  String get helpSupportPageTitle => 'Ajuda e Suporte';

  @override
  String get helpSupportPageDescription =>
      'Tudo o que você precisa saber sobre o My Vitals.';

  @override
  String get helpFaqTitle => 'Perguntas Frequentes';

  @override
  String get helpFaqDescription =>
      'Respostas rápidas para as dúvidas mais comuns.';

  @override
  String get helpGlossaryTitle => 'Glossário Médico';

  @override
  String get helpGlossaryDescription => 'Entenda cada indicador de saúde.';

  @override
  String get helpLegalTitle => 'Aviso Legal';

  @override
  String get helpLegalDescription => 'Termos de uso e privacidade de dados.';

  @override
  String get helpContactTitle => 'Contato e Feedback';

  @override
  String get helpContactDescription => 'Escreva para nós, melhoramos juntos.';

  @override
  String get helpSearchHint => 'Pesquisar...';

  @override
  String get helpNoResults => 'Sem resultados para sua pesquisa.';

  @override
  String get helpFaqCatGeneral => 'Geral';

  @override
  String get helpFaqCatData => 'Meus Dados';

  @override
  String get helpFaqCatBiometrics => 'Biometria';

  @override
  String get helpFaqCatExport => 'Exportar';

  @override
  String get helpFaqQ1 => 'O que é o My Vitals?';

  @override
  String get helpFaqA1 =>
      'My Vitals é um aplicativo de acompanhamento pessoal de saúde que permite registrar e monitorar seus indicadores de bem-estar: medidas antropométricas, sinais vitais, perfil lipídico e composição corporal.';

  @override
  String get helpFaqQ2 => 'Meus dados são salvos na nuvem?';

  @override
  String get helpFaqA2 =>
      'Não. Todos os seus dados são armazenados exclusivamente no seu dispositivo. O My Vitals não envia nenhuma informação para servidores externos, garantindo total privacidade.';

  @override
  String get helpFaqQ3 => 'Posso usar o aplicativo sem internet?';

  @override
  String get helpFaqA3 =>
      'Sim. O My Vitals funciona completamente offline. Você só precisa de conectividade para atualizações do aplicativo.';

  @override
  String get helpFaqQ4 => 'Como ativo o bloqueio biométrico?';

  @override
  String get helpFaqA4 =>
      'Vá para Perfil › Privacidade e Segurança e ative o interruptor de Bloqueio Biométrico. Seu dispositivo deve ter impressão digital ou FaceID configurado.';

  @override
  String get helpFaqQ5 => 'Como exporto meu histórico?';

  @override
  String get helpFaqA5 =>
      'Em cada tela de histórico (Antropométrico, Sinais Vitais, etc.) você encontrará os botões \'Exportar PDF\' e \'Excel (CSV)\' na parte superior.';

  @override
  String get helpFaqQ6 => 'Posso alterar as unidades de medida?';

  @override
  String get helpFaqA6 =>
      'Sim. Vá para Perfil › Unidades de Medida e escolha entre o sistema Métrico (kg, cm) ou Imperial (lb, ft/in).';

  @override
  String get helpFaqQ7 => 'O que acontece se eu excluir o aplicativo?';

  @override
  String get helpFaqA7 =>
      'Ao desinstalar o aplicativo, todos os dados armazenados localmente serão excluídos permanentemente. Recomendamos exportar seu histórico em PDF ou CSV antes de desinstalar.';

  @override
  String get helpFaqQ8 => 'Este aplicativo substitui meu médico?';

  @override
  String get helpFaqA8 =>
      'Não. O My Vitals é uma ferramenta de acompanhamento pessoal para ajudá-lo a manter um registro organizado. Sempre consulte um profissional de saúde para interpretação e diagnóstico médico.';

  @override
  String get helpGlossarySearchHint => 'Buscar termo...';

  @override
  String get helpGlossaryGroupAnthropo => 'Medidas Antropométricas';

  @override
  String get helpGlossaryGroupVitals => 'Sinais Vitais';

  @override
  String get helpGlossaryGroupLipid => 'Perfil Lipídico';

  @override
  String get helpGlossaryGroupBody => 'Composição Corporal';

  @override
  String get helpGlossaryNormalRange => 'Intervalo normal';

  @override
  String get helpLegalPurposeTitle => 'Propósito do aplicativo';

  @override
  String get helpLegalPurposeBody =>
      'My Vitals é um aplicativo de acompanhamento pessoal de saúde projetado para ajudar os usuários a registrar e visualizar seus indicadores de bem-estar. Não é um dispositivo médico certificado.';

  @override
  String get helpLegalNotMedicalTitle => 'Não é um dispositivo médico';

  @override
  String get helpLegalNotMedicalBody =>
      'As informações exibidas neste aplicativo são apenas para referência. Não substitui o diagnóstico, conselho ou tratamento de um profissional de saúde. Consulte seu médico diante de qualquer sintoma.';

  @override
  String get helpLegalResponsibilityTitle => 'Responsabilidade do usuário';

  @override
  String get helpLegalResponsibilityBody =>
      'O usuário é responsável pela precisão dos dados inseridos. O My Vitals não se responsabiliza por decisões de saúde tomadas com base nas informações registradas no aplicativo.';

  @override
  String get helpLegalPrivacyTitle => 'Privacidade e dados';

  @override
  String get helpLegalPrivacyBody =>
      'Todos os dados são armazenados localmente no dispositivo do usuário. O My Vitals não coleta, transmite ou compartilha informações pessoais com terceiros. Não existem contas de usuário ou servidores de dados.';

  @override
  String get helpLegalContactTitle => 'Contato do desenvolvedor';

  @override
  String get helpLegalContactBody =>
      'Para consultas legais ou de privacidade, você pode contatar o desenvolvedor em: yesithvalencia@gmail.com';

  @override
  String get helpContactReportBug => 'Relatar um erro';

  @override
  String get helpContactReportBugDesc =>
      'Encontrou algo que não está funcionando bem? Conte para nós.';

  @override
  String get helpContactSuggest => 'Enviar sugestão';

  @override
  String get helpContactSuggestDesc =>
      'Tem uma ideia para melhorar o aplicativo? Queremos ouvi-la.';

  @override
  String get helpContactSendEmail => 'Enviar e-mail';

  @override
  String get helpContactAppVersion => 'Versão do aplicativo';

  @override
  String get helpContactWhatsNew => 'Novidades';

  @override
  String get helpContactV110 => 'v1.1.0 — Atual';

  @override
  String get helpContactV110Changes =>
      '• Bloqueio biométrico (impressão digital / FaceID)\n• Metas de saúde personalizadas\n• Suporte ao idioma italiano\n• Seletor de nível de atividade aprimorado';

  @override
  String get helpContactV100 => 'v1.0.0 — Lançamento inicial';

  @override
  String get helpContactV100Changes =>
      '• Rastreamento de medidas antropométricas\n• Sinais vitais e perfil lipídico\n• Composição corporal\n• Exportação PDF e CSV\n• Suporte multilíngue (es, en, de, pt)';

  @override
  String get myDataBackup => 'Meus Dados';

  @override
  String get backupTitle => 'Backup e Restauração';

  @override
  String get backupDescription =>
      'Exporte ou restaure todos os seus dados e preferências.';

  @override
  String get backupPrivacyTitle => 'Os seus dados são seus. E apenas seus.';

  @override
  String get backupPrivacyBody =>
      'Todos os nossos recursos de saúde são desenvolvidos com privacidade no centro e são projetados para manter os seus dados seguros.\n\nOs seus dados de saúde são criptografados no seu dispositivo e podem ser acedidos apenas com o seu código de acesso, Touch ID ou Face ID. Não utilizamos servidores na nuvem e nunca partilhamos os seus dados com terceiros.';

  @override
  String get backupPrivacyHighlight =>
      'Os seus dados de saúde são criptografados localmente e nem mesmo nós podemos aceder às suas informações.';

  @override
  String get backupExportTitle => 'Exportar meus dados';

  @override
  String get backupExportSubtitle =>
      'Gera um arquivo seguro com todo o seu histórico e configurações';

  @override
  String get backupExportButton => 'Exportar Backup';

  @override
  String get backupImportTitle => 'Restaurar meus dados';

  @override
  String get backupImportSubtitle => 'Importe um backup anterior do My Vitals';

  @override
  String get backupImportButton => 'Importar Backup';

  @override
  String get backupWhatIncluded => 'O que está incluído no backup?';

  @override
  String get backupSuccess => 'Backup exportado com sucesso!';

  @override
  String get backupImportSuccess => 'Dados restaurados com sucesso!';

  @override
  String get backupImportError =>
      'Erro de importação. Verifique se o arquivo é válido.';

  @override
  String get backupImportConfirmTitle => 'Restaurar dados?';

  @override
  String get backupImportConfirmBody =>
      'Isso substituirá seus registros atuais pelos do backup. Deseja continuar?';

  @override
  String get backupIncludesVitalSigns => 'Histórico de Sinais Vitais';

  @override
  String get backupIncludesAnthropo => 'Histórico Antropométrico';

  @override
  String get backupIncludesLipid => 'Perfil Lipídico';

  @override
  String get backupIncludesBodyComp => 'Composição Corporal';

  @override
  String get backupIncludesPersonalInfo => 'Informações Pessoais';

  @override
  String get backupIncludesGoals => 'Metas de Saúde';

  @override
  String get backupIncludesPhoto => 'Foto de Perfil';

  @override
  String get backupIncludesPreferences =>
      'Preferências (idioma, unidades, tema, lembretes, dispositivo)';

  @override
  String get exportSuccess => 'Exportado com sucesso';

  @override
  String get exportError => 'Não foi possível exportar. Tente novamente.';

  @override
  String get backupCancel => 'Cancelar';

  @override
  String get onboardingWelcomeTitle => 'Bem-vindo ao My Vitals';

  @override
  String get onboardingWelcomeSubtitle => 'Seu companheiro de saúde pessoal';

  @override
  String get onboardingWelcomeFeature1 =>
      'Registre seus sinais vitais e medidas corporais';

  @override
  String get onboardingWelcomeFeature2 =>
      'Visualize seu progresso com gráficos e estatísticas';

  @override
  String get onboardingWelcomeFeature3 =>
      'Sincronize seu histórico com segurança nos seus dispositivos';

  @override
  String get onboardingNext => 'Próximo';

  @override
  String get onboardingFinish => 'Começar!';

  @override
  String get welcomeGetStarted => 'Começar';

  @override
  String get welcomeLogIn => 'Iniciar sessão';

  @override
  String get welcomeAlreadyHaveAccount => 'Já tem conta?';

  @override
  String onboardingStep(int current, int total) {
    return 'Passo $current de $total';
  }

  @override
  String get onboardingAvatarTitle => 'Sua foto de perfil';

  @override
  String get onboardingAvatarSubtitle =>
      'Dê um rosto à sua jornada de saúde (opcional)';

  @override
  String get remindersTitle => 'Lembretes e Alertas';

  @override
  String get remindersDescription =>
      'Configure alertas diários para lembrar seus exames de rotina.';

  @override
  String get remindersNote =>
      '* As notificações chegarão ao seu dispositivo diariamente no horário agendado.';

  @override
  String get reminderVitals => 'Registrar Sinais Vitais';

  @override
  String get reminderMeds => 'Tomar Medicação';

  @override
  String get reminderWorkout => 'Atividade Física';

  @override
  String get reminderWater => 'Beber Água';

  @override
  String get reminderTitle => 'Lembrete Médico';

  @override
  String get filterLast7Days => 'Últimos 7 dias';

  @override
  String get filterLast30Days => 'Últimos 30 dias';

  @override
  String get filterLast6Months => 'Últimos 6 meses';

  @override
  String get filterAllTime => 'Sempre';

  @override
  String goalRemainingWeight(String weight) {
    return 'Faltam ${weight}kg para a meta';
  }

  @override
  String get goalAchieved => 'Meta alcançada!';

  @override
  String get noGoalDefined => 'Meta não definida';

  @override
  String get validationRequiredFields => 'Campos obrigatórios';

  @override
  String get validationCompleteBeforeContinue =>
      'Por favor preencha estes campos antes de continuar:';

  @override
  String get validationSelectLanguage => 'Selecione um idioma';

  @override
  String get validationEnterName => 'Informe seu nome completo';

  @override
  String get validationSelectBirthDate => 'Selecione sua data de nascimento';

  @override
  String get validationSelectGender => 'Selecione seu sexo';

  @override
  String get dashboardCompositionFat => 'GORDURA';

  @override
  String get dashboardCompositionMuscle => 'MÚSCULO';

  @override
  String get dashboardCompositionVisceral => 'VISCERAL';

  @override
  String get dashboardCompositionBmr => 'TMB';

  @override
  String get dashboardLastMeasured => 'Última medição';

  @override
  String dashboardCompositionLevel(int level) {
    return 'Nv. $level';
  }

  @override
  String get vitalsPdfTitle => 'Histórico de Sinais Vitais';

  @override
  String get vitalsShareCsvSubject => 'Exportação CSV de Sinais Vitais';

  @override
  String get lipidPdfTitle => 'Histórico do Perfil Lipídico';

  @override
  String get lipidShareCsvSubject => 'Exportação CSV de Laboratórios';

  @override
  String get compositionPdfTitle => 'Histórico da Composição Corporal';

  @override
  String get compositionShareCsvSubject =>
      'Exportação CSV da Composição Corporal';

  @override
  String get reminderDefaultTitle => 'Lembrete Médico';

  @override
  String get exportColComment => 'Comentário';

  @override
  String get exportColHeight => 'Altura (m)';

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
  String get exportColHeartRate => 'Frequência Cardíaca';

  @override
  String get exportColActivityState => 'Estado de Atividade';

  @override
  String get exportColSymptom => 'Sintoma';

  @override
  String get exportColTotalCholShort => 'Col. Total';

  @override
  String get exportColTrigsShort => 'Trig.';

  @override
  String get exportColTotalCholesterol => 'Colesterol Total';

  @override
  String get exportColTriglycerides => 'Triglicéridos';

  @override
  String get exportColLabName => 'Laboratório';

  @override
  String get exportColBodyFat => 'Gordura Corporal';

  @override
  String get exportColMuscleMass => 'Massa Muscular';

  @override
  String get exportColVisceralFat => 'Gordura Visceral';

  @override
  String get exportColMetabolicAge => 'Idade Metabólica';

  @override
  String get exportColBodyWater => 'Água Corporal';

  @override
  String get exportColBoneMass => 'Massa Óssea';

  @override
  String get exportColBmr => 'TMB';

  @override
  String get glossaryImcName => 'IMC (Índice de Massa Corporal)';

  @override
  String get glossaryImcDefinition =>
      'Medida que relaciona peso e altura para avaliar se o peso de uma pessoa é saudável. Calculado dividindo o peso (kg) pela altura ao quadrado (m²).';

  @override
  String get glossaryImcRange => '18,5 – 24,9 kg/m²';

  @override
  String get glossaryPesoName => 'Peso corporal';

  @override
  String get glossaryPesoDefinition =>
      'Massa total do corpo em quilogramas ou libras, incluindo músculos, ossos, órgãos, gordura e água.';

  @override
  String get glossaryPesoRange => 'Depende da altura e compleição';

  @override
  String get glossaryTallaName => 'Altura (Estatura)';

  @override
  String get glossaryTallaDefinition =>
      'Medida da altura de uma pessoa dos pés ao topo da cabeça, expressa em centímetros ou metros.';

  @override
  String get glossarySistolicaName => 'Pressão Sistólica';

  @override
  String get glossarySistolicaDefinition =>
      'A pressão máxima exercida pelo sangue sobre as artérias quando o coração se contrai (bate). É o número superior em uma leitura de pressão arterial.';

  @override
  String get glossarySistolicaRange => '< 120 mmHg';

  @override
  String get glossaryDiastolicaName => 'Pressão Diastólica';

  @override
  String get glossaryDiastolicaDefinition =>
      'A pressão mínima exercida pelo sangue sobre as artérias entre os batimentos cardíacos, quando o coração está em repouso. É o número inferior em uma leitura de pressão arterial.';

  @override
  String get glossaryDiastolicaRange => '< 80 mmHg';

  @override
  String get glossaryFcName => 'Frequência Cardíaca';

  @override
  String get glossaryFcDefinition =>
      'Número de vezes que o coração bate por minuto (bpm). Em repouso, um coração saudável bate regularmente dentro de um intervalo específico.';

  @override
  String get glossaryFcRange => '60 – 100 bpm em repouso';

  @override
  String get glossaryColesterolTotalName => 'Colesterol Total';

  @override
  String get glossaryColesterolTotalDefinition =>
      'Soma de todo o colesterol presente no sangue, incluindo LDL, HDL e outros lipídios. É um marcador geral do risco cardiovascular.';

  @override
  String get glossaryColesterolTotalRange => '< 200 mg/dL';

  @override
  String get glossaryLdlName => 'LDL (Colesterol \"Ruim\")';

  @override
  String get glossaryLdlDefinition =>
      'Lipoproteína de baixa densidade. Transporta colesterol para o interior das artérias e pode se acumular em suas paredes, aumentando o risco de doença cardiovascular.';

  @override
  String get glossaryLdlRange => '< 100 mg/dL';

  @override
  String get glossaryHdlName => 'HDL (Colesterol \"Bom\")';

  @override
  String get glossaryHdlDefinition =>
      'Lipoproteína de alta densidade. Coleta o excesso de colesterol das artérias e o leva ao fígado para eliminação. Níveis altos são protetores.';

  @override
  String get glossaryHdlRange => '≥ 60 mg/dL';

  @override
  String get glossaryVldlName => 'VLDL';

  @override
  String get glossaryVldlDefinition =>
      'Lipoproteína de densidade muito baixa. Transporta triglicerídeos do fígado para os tecidos. Níveis elevados estão associados a maior risco cardiovascular.';

  @override
  String get glossaryVldlRange => '2 – 30 mg/dL';

  @override
  String get glossaryTrigliceridosName => 'Triglicerídeos';

  @override
  String get glossaryTrigliceridosDefinition =>
      'Tipo de gordura (lipídio) presente no sangue. O corpo os usa como fonte de energia, mas níveis altos aumentam o risco de doenças cardíacas e pancreáticas.';

  @override
  String get glossaryTrigliceridosRange => '< 150 mg/dL';

  @override
  String get glossaryGrasaName => 'Percentual de Gordura Corporal';

  @override
  String get glossaryGrasaDefinition =>
      'Proporção de massa gorda em relação ao peso corporal total. Inclui gordura essencial e gordura de reserva.';

  @override
  String get glossaryGrasaRange => 'Homens: 8–19% / Mulheres: 21–33%';

  @override
  String get glossaryMusculoName => 'Massa Muscular';

  @override
  String get glossaryMusculoDefinition =>
      'Peso total do tecido muscular no corpo, expresso em quilogramas. Um maior percentual de músculo está associado a um metabolismo mais ativo.';

  @override
  String get glossaryGrasaVisceralName => 'Gordura Visceral';

  @override
  String get glossaryGrasaVisceralDefinition =>
      'Gordura acumulada ao redor dos órgãos internos do abdome (fígado, intestinos, pâncreas). Níveis altos estão associados a maior risco metabólico e cardiovascular.';

  @override
  String get glossaryGrasaVisceralRange => 'Nível 1–9 (saudável)';

  @override
  String get glossaryEdadMetabolicaName => 'Idade Metabólica';

  @override
  String get glossaryEdadMetabolicaDefinition =>
      'Idade estimada do metabolismo basal em comparação com a média da população. Uma idade metabólica menor que a cronológica indica um metabolismo eficiente.';

  @override
  String get glossaryBmrName => 'BMR / Metabolismo Basal (kcal)';

  @override
  String get glossaryBmrDefinition =>
      'Quantidade mínima de energia (calorias) que o corpo precisa em repouso absoluto para manter as funções vitais: respiração, circulação, temperatura, etc.';

  @override
  String get glossaryAguaName => 'Água Corporal';

  @override
  String get glossaryAguaDefinition =>
      'Percentual do peso corporal correspondente à água. A água é essencial para todas as funções celulares, regulação da temperatura e transporte de nutrientes.';

  @override
  String get glossaryAguaRange => '50 – 65%';

  @override
  String get glossaryHuesoName => 'Massa Óssea';

  @override
  String get glossaryHuesoDefinition =>
      'Peso estimado do tecido ósseo no corpo. Manter uma massa óssea adequada é fundamental para prevenir a osteoporose.';

  @override
  String get glossaryHuesoRange => '2 – 4 kg (adulto médio)';

  @override
  String get deleteRecordTitle => 'Excluir registro?';

  @override
  String get deleteRecordBody => 'Esta ação não pode ser desfeita.';

  @override
  String get deleteRecordConfirm => 'Excluir';

  @override
  String get recordDeleted => 'Registro excluído';

  @override
  String get anthropoSavedSuccess => 'Medida salva com sucesso.';

  @override
  String historyShowMore(int count) {
    return 'Ver mais $count';
  }

  @override
  String get introSignIn => 'Iniciar sessão';

  @override
  String get introRegister => 'Criar conta';

  @override
  String get emailLabel => 'Email';

  @override
  String get validationEnterEmail => 'Introduza o seu email';

  @override
  String get validationEmailFormat =>
      'Verifique o email: falta a arroba ou o domínio';

  @override
  String validationOutOfRange(Object max, Object min) {
    return 'Introduza um valor entre $min e $max';
  }

  @override
  String get commonRegisterFailed =>
      'Não foi possível criar a sua conta. Verifique a ligação e tente novamente.';

  @override
  String get logOutConfirm =>
      'Terminar sessão neste dispositivo? Os seus registos ficam no dispositivo e voltarão a sincronizar quando iniciar sessão de novo.';

  @override
  String get pendingAccountTitle => 'Conta pendente';

  @override
  String get pendingAccountBody =>
      'Os seus dados estão guardados neste dispositivo. Criaremos a sua conta assim que houver ligação.';

  @override
  String get pendingAccountCreateNow => 'Criar a minha conta agora';

  @override
  String get pendingAccountCreating => 'A criar a sua conta…';

  @override
  String get pendingAccountCreated =>
      'Conta criada. A enviar os seus registos.';

  @override
  String get pendingAccountStillOffline =>
      'Ainda sem ligação. Os seus dados continuam seguros neste dispositivo.';

  @override
  String get identifyTitle => 'Vamos buscar o seu histórico';

  @override
  String get identifyBody =>
      'Introduza o seu documento (ou email). Se já é paciente carregamos os seus dados; caso contrário, criamos a sua conta.';

  @override
  String get identifyFieldLabel => 'Documento ou email';

  @override
  String get identifyFieldHint => 'Ex.: 1032456789';

  @override
  String get identifyFoundTitle =>
      'Encontrámos um histórico clínico associado a este documento.';

  @override
  String get identifyFoundBody =>
      'Podemos trazê-lo e ativar a sua conta para ver os seus dados desde o primeiro dia.';

  @override
  String get identifyBringHistory => 'Trazer o meu histórico e continuar';

  @override
  String get identifyBringingHistory => 'A trazer o seu histórico…';

  @override
  String get identifyNotMe => 'Não sou eu — registar-me como novo';

  @override
  String get verifyAppBarTitle => 'Verificação';

  @override
  String get verifyTitle => 'Encontrámos a sua conta';

  @override
  String verifyBody(String identifier) {
    return 'Verifique a sua identidade para continuar com\n$identifier.';
  }

  @override
  String get verifyPasswordLabel => 'Palavra-passe';

  @override
  String get verifyTestNotice =>
      'Fase de testes: a palavra-passe é 1234. (Em produção ficará aqui o código OTP.)';

  @override
  String get verifySubmit => 'Entrar';

  @override
  String unexpectedError(String details) {
    return 'Erro inesperado: $details';
  }

  @override
  String get accountSyncTitle => 'Conta e sincronização';

  @override
  String get accountSyncDescription =>
      'Inicie sessão e sincronize os seus registos com o servidor.';

  @override
  String get accountYourAccount => 'A sua conta';

  @override
  String get accountPendingBody =>
      'Os seus dados estão neste dispositivo. Falta criar a conta no servidor.';

  @override
  String get accountLoggedOutBody =>
      'Inicie sessão se já é paciente, ou registe-se para começar.';

  @override
  String get accountFallbackName => 'Paciente';

  @override
  String get accountFromLegacy => 'Conta migrada do sistema anterior';

  @override
  String get accountCreatedInApp => 'Conta criada na app';

  @override
  String get accountSignOut => 'Sair';

  @override
  String get accountSyncSection => 'Sincronização';

  @override
  String get accountSyncBody =>
      'Envie os seus registos locais para o servidor.';

  @override
  String get accountSyncing => 'A sincronizar…';

  @override
  String get accountSyncNow => 'Sincronizar agora';

  @override
  String get accountHaveAccount => 'Já tenho conta (paciente migrado)';

  @override
  String get accountImNew => 'Sou novo (registar-me)';

  @override
  String get accountCreateAccount => 'Criar conta';

  @override
  String get accountNewHere => 'Sou novo (registar-me)';

  @override
  String get accountDocumentOptional => 'Documento (opcional)';

  @override
  String get accountNameLabel => 'Nome';

  @override
  String get accountEmailLabel => 'Email';

  @override
  String get deviceScreenTitle => 'O meu dispositivo de medição';

  @override
  String get deviceScreenDescription =>
      'Escolhe a balança que usas para interpretar as tuas medições.';

  @override
  String get deviceNoneTitle => 'Não uso nenhuma';

  @override
  String get deviceNoneSubtitle =>
      'Vou registar apenas medidas manuais (peso, cintura, altura).';

  @override
  String get deviceNoneSaved => 'Guardado: não usa bioimpedância.';

  @override
  String get deviceCatalogError =>
      'Não foi possível atualizar o catálogo. A mostrar as opções guardadas.';

  @override
  String get deviceAvailableScales => 'BALANÇAS DISPONÍVEIS';

  @override
  String get deviceWhyItMatters =>
      'Cada balança de bioimpedância interpreta a gordura, o músculo e a gordura visceral com intervalos próprios. Diga-nos qual usa para lhe mostrarmos se os seus valores estão baixos, normais ou altos. Pode mudar quando quiser.';

  @override
  String get circumferencesSection => 'PERÍMETROS CORPORAIS (OPCIONAL)';

  @override
  String get circWaist => 'Cintura';

  @override
  String get circHip => 'Anca';

  @override
  String get circLowerAbdomen => 'Abdómen inferior';

  @override
  String get circArm => 'Braço';

  @override
  String get circLeg => 'Perna';

  @override
  String get circChestBust => 'Peito/Busto';

  @override
  String get circAbdomenShort => 'Abd.';

  @override
  String get lipidLabQuestion => 'Em que laboratório fez o exame?';

  @override
  String get lipidLabLoading => 'A carregar laboratórios…';

  @override
  String get lipidLabNotSpecified => 'Não indicado / não sei';

  @override
  String get lipidLabOther => 'Outro (especificar)';

  @override
  String get compositionSkeletalMuscle => 'Músculo esquelético';

  @override
  String get compositionSkeletalMuscleRef =>
      'Como reportado pela sua balança (%)';

  @override
  String get profileAppTheme => 'Tema da app';

  @override
  String get profileRankObserver => 'Observador Vital';

  @override
  String get themeBankLabel => 'BIBLIOTECA DE TEMAS';

  @override
  String get themePickTitle => 'Escolha o aspeto';

  @override
  String get themePickBody =>
      'Muda cores e tipografia. A navegação, os ícones e o significado de cada cor mantêm-se intactos.';

  @override
  String get themeSettingsBody =>
      'A alteração aplica-se de imediato e fica guardada. A navegação, os ícones e o significado de cada cor mantêm-se intactos.';

  @override
  String themeContinueWith(String theme) {
    return 'Continuar com $theme';
  }

  @override
  String deviceSelectedSaved(String device) {
    return '$device selecionada.';
  }

  @override
  String deviceWillSyncLater(String message) {
    return '$message Será sincronizado quando houver ligação.';
  }

  @override
  String get introDemo => 'Ver a demonstração';

  @override
  String get demoNoticeTitle => 'Está na demonstração';

  @override
  String get demoNoticeBody =>
      'Tudo o que vê pertence a um paciente fictício. Pode registar e editar medições: nada é guardado, e tudo desaparece ao sair da demonstração.';

  @override
  String get demoNoticeAction => 'Entendido';

  @override
  String get demoBannerLabel => 'Dados de demonstração';

  @override
  String get demoExit => 'Sair da demonstração';

  @override
  String get profileRankTier2 => 'Cuidador Constante';

  @override
  String get profileRankTier3 => 'Veterano do Bem-estar';

  @override
  String get mhxDocTitle => 'Resumo de saúde pessoal';

  @override
  String get mhxDocSubtitle =>
      'Relatório consolidado de medições autorrelatadas';

  @override
  String get mhxPatient => 'Paciente';

  @override
  String get mhxBirthDate => 'Data de nascimento';

  @override
  String get mhxPeriodCovered => 'Período abrangido';

  @override
  String get mhxGeneratedOn => 'Gerado em';

  @override
  String get mhxSource => 'Fonte';

  @override
  String get mhxGeneratedBy => 'Gerado por';

  @override
  String get mhxReportRef => 'Relatório n.º';

  @override
  String get mhxSelfReported => 'dados autorrelatados';

  @override
  String get mhxDisclaimerTitle =>
      'Resumo informativo - não é um diagnóstico médico';

  @override
  String get mhxDisclaimerBody =>
      'Este documento foi gerado automaticamente a partir de medições registradas pelo usuário. Não é um diagnóstico médico nem um prontuário oficial e não substitui a avaliação de um profissional de saúde.';

  @override
  String get mhxSummaryTitle => 'Resumo dos últimos valores';

  @override
  String get mhxColIndicator => 'Indicador';

  @override
  String get mhxColLatest => 'Último valor';

  @override
  String get mhxColReference => 'Referência';

  @override
  String get mhxColStatus => 'Estado';

  @override
  String get mhxColNotes => 'Observações';

  @override
  String get mhxBloodPressure => 'Pressão arterial';

  @override
  String get mhxHeartRate => 'Frequência cardíaca';

  @override
  String get mhxWeight => 'Peso';

  @override
  String get mhxBmi => 'IMC';

  @override
  String get mhxBodyFat => 'Gordura corporal';

  @override
  String get mhxVisceralFat => 'Gordura visceral';

  @override
  String get mhxTotalCholesterol => 'Colesterol total';

  @override
  String get mhxLdl => 'LDL';

  @override
  String get mhxHdl => 'HDL';

  @override
  String get mhxTriglycerides => 'Triglicerídeos';

  @override
  String get mhxSystolic => 'Sistólica';

  @override
  String get mhxDiastolic => 'Diastólica';

  @override
  String get mhxStatsMeasurements => 'Medições';

  @override
  String get mhxStatsAverage => 'Média';

  @override
  String get mhxStatsRange => 'Intervalo';

  @override
  String get mhxStatsLatest => 'Último';

  @override
  String get mhxFooterDisclaimer =>
      'Fonte dos dados: medições inseridas pelo paciente através do app MY VITALS com dispositivos pessoais que podem não estar clinicamente calibrados; a sua exatidão não é verificada por um profissional nem por um laboratório acreditado. Os intervalos de referência mostrados são orientativos e podem não se aplicar à sua situação individual; um valor marcado fora do intervalo não é um diagnóstico. Não tome decisões de tratamento com base neste documento sem supervisão profissional. Contém dados pessoais de saúde: o usuário é responsável pela sua guarda e por com quem o compartilha.';

  @override
  String get mhxButton => 'Exportar histórico clínico completo';

  @override
  String get mhxHubHint =>
      'Um PDF com os seus quatro indicadores para mostrar ao médico.';

  @override
  String get mhxChoosePeriod => 'Escolha o período';

  @override
  String get mhxPeriod6Months => 'Últimos 6 meses';

  @override
  String get mhxPeriod1Year => 'Último ano';

  @override
  String get mhxPeriodAll => 'Todo o histórico';

  @override
  String get mhxGenerate => 'Gerar PDF';

  @override
  String get mhxNoData => 'Ainda não há medições para exportar.';

  @override
  String mhxAgeYears(int years) {
    return '$years anos';
  }

  @override
  String mhxPageOf(int current, int total) {
    return 'Página $current de $total';
  }

  @override
  String get medicationsTitle => 'Medicamentos';

  @override
  String get medicationsMenuTitle => 'Medicamentos';

  @override
  String get medicationAdd => 'Adicionar medicamento';

  @override
  String get medicationTaken => 'Tomado';

  @override
  String get medicationSkipped => 'Ignorado';

  @override
  String get medicationRefill => 'Reabastecer';

  @override
  String medicationDoseNotifTitle(String name) {
    return 'Hora de $name';
  }

  @override
  String get medicationDoseNotifBody => 'Está na hora da sua dose.';

  @override
  String medicationRefillNotifTitle(String name) {
    return 'Reabastecer $name';
  }

  @override
  String get medicationRefillNotifBody => 'Seu estoque está acabando.';

  @override
  String medicationUnitsLeft(int count) {
    return '$count unidades restantes';
  }

  @override
  String get medicationOutOfStock => 'Sem estoque';

  @override
  String get medFormNameCapsule => 'Cápsula';

  @override
  String get medFormNameTablet => 'Comprimido';

  @override
  String get medFormNameLiquid => 'Líquido';

  @override
  String get medFormNameInjection => 'Injeção';

  @override
  String get medFormNameDrops => 'Gotas';

  @override
  String get medFormNameOther => 'Unidade';

  @override
  String medUnitCapsule(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'cápsulas',
      one: 'cápsula',
    );
    return '$_temp0';
  }

  @override
  String medUnitTablet(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'comprimidos',
      one: 'comprimido',
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
      other: 'injeções',
      one: 'injeção',
    );
    return '$_temp0';
  }

  @override
  String medUnitDrops(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'gotas',
      one: 'gota',
    );
    return '$_temp0';
  }

  @override
  String medUnitOther(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'unidades',
      one: 'unidade',
    );
    return '$_temp0';
  }

  @override
  String get medScheduleDaily => 'Todos os dias';

  @override
  String medScheduleEveryNDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'A cada $count dias',
      one: 'Todo dia',
    );
    return '$_temp0';
  }

  @override
  String get medMenuDescription =>
      'Gerencie suas doses, seu estoque e sua adesão em um só lugar.';

  @override
  String medMenuTodaySubtitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count doses pendentes',
      one: '1 dose pendente',
      zero: 'Sem doses pendentes',
    );
    return '$_temp0';
  }

  @override
  String medMenuInventorySubtitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count acabando',
      one: '1 acabando',
      zero: 'Tudo em estoque',
    );
    return '$_temp0';
  }

  @override
  String medMenuAdherenceSubtitle(int pct, int streak) {
    return '$pct% neste mês · $streak dias seguidos';
  }

  @override
  String get medTodayTitle => 'Hoje';

  @override
  String get medTodayDescription =>
      'Registre as doses de hoje e revise o que foi feito.';

  @override
  String get medSectionToTakeToday => 'PARA TOMAR HOJE';

  @override
  String get medSectionLogged => 'REGISTRADO';

  @override
  String get medSectionYourMeds => 'SEUS MEDICAMENTOS';

  @override
  String medDosesProgress(int done, int total) {
    return '$done de $total';
  }

  @override
  String get medNoPendingToday => 'Nenhuma dose restante para hoje.';

  @override
  String get medInventoryTitle => 'Estoque';

  @override
  String get medInventoryDescription =>
      'Quantas unidades restam e quando reabastecer.';

  @override
  String get medSectionInventory => 'ESTOQUE';

  @override
  String medStockLeftUnits(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Restam $count unidades',
      one: 'Resta 1 unidade',
    );
    return '$_temp0';
  }

  @override
  String medRunsOutOn(String date) {
    return 'acaba em $date';
  }

  @override
  String medStockDonutOf(int total) {
    return 'de $total';
  }

  @override
  String get medAdherenceTitle => 'Adesão';

  @override
  String get medAdherenceDescription =>
      'Sua constância com o tratamento ao longo do mês.';

  @override
  String medComplianceMonth(String month) {
    return 'adesão · $month';
  }

  @override
  String get medStreakDays => 'dias seguidos';

  @override
  String get medLegendTaken => 'Tomado';

  @override
  String get medLegendSkipped => 'Pulado';

  @override
  String get medLegendNoData => 'Sem dados';

  @override
  String get medSectionSchedule => 'ESQUEMA';

  @override
  String get medSectionAdherence => 'ADESÃO';

  @override
  String get medSectionInformation => 'INFORMAÇÃO';

  @override
  String medRemainingUnits(int count) {
    return '$count unidades';
  }

  @override
  String medBuyBefore(String date) {
    return 'Compre antes de $date';
  }

  @override
  String medPackAndThreshold(int pack, int threshold) {
    return 'Caixa de $pack · aviso em: $threshold';
  }

  @override
  String get medThisMonth => 'este mês';

  @override
  String get medEdit => 'Editar';

  @override
  String get medDelete => 'Excluir';

  @override
  String get medDeleteTitle => 'Excluir medicamento?';

  @override
  String get medDeleteBody =>
      'O medicamento e todo o seu histórico serão apagados. Esta ação não pode ser desfeita.';

  @override
  String get medInfoSoon => 'Em breve';

  @override
  String get medInfoSoonBody => 'Interações, gravidez e amamentação.';

  @override
  String get medRegisterDose => 'Registrar dose';

  @override
  String medDoseAtTime(String amount, String time) {
    return '$amount às $time';
  }

  @override
  String get medSkip => 'Pular';

  @override
  String medMultipleTitle(int count, String time) {
    return '$count doses às $time';
  }

  @override
  String get medMultipleSubtitle =>
      'Marque cada uma ou registre todas de uma vez.';

  @override
  String get medSkipRest => 'Pular o resto';

  @override
  String medRegisterNSelected(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Registrar $count doses',
      one: 'Registrar 1 dose',
      zero: 'Registrar doses',
    );
    return '$_temp0';
  }

  @override
  String get medNotifTitle => 'Ative os lembretes';

  @override
  String get medNotifBody =>
      'Avisamos na hora de cada dose e quando o estoque estiver acabando. Você pode mudar isso quando quiser.';

  @override
  String get medNotifWebWarning =>
      'As notificações não estão disponíveis na versão web. Use o app para iOS ou Android.';

  @override
  String get medAllowNotifications => 'Permitir notificações';

  @override
  String get medNotNow => 'Agora não';

  @override
  String medWizardStepOf(int step, int total) {
    return 'PASSO $step DE $total';
  }

  @override
  String get medBack => 'Voltar';

  @override
  String get medStepIdentity => 'Identidade';

  @override
  String get medStepDose => 'Dose';

  @override
  String get medStepFrequency => 'Frequência';

  @override
  String get medStepDates => 'Datas';

  @override
  String get medStepInventory => 'Estoque';

  @override
  String get medFieldName => 'NOME';

  @override
  String get medFieldForm => 'FORMA';

  @override
  String get medFieldStrength => 'CONCENTRAÇÃO';

  @override
  String get medFieldColorIcon => 'COR E ÍCONE';

  @override
  String get medShapeCapsule => 'Cápsula';

  @override
  String get medShapeRound => 'Redonda';

  @override
  String get medFieldReason => 'PARA QUÊ (OPCIONAL)';

  @override
  String get medFieldQtyPerDose => 'QUANTIDADE POR DOSE';

  @override
  String get medWithFood => 'Tomar com comida';

  @override
  String get medWithFoodSub => 'Sugestão no lembrete';

  @override
  String get medSpecialInstruction => 'Instrução especial';

  @override
  String get medSpecialInstructionSub => 'Ex. dissolver em água';

  @override
  String get medFreqDaily => 'Diário';

  @override
  String get medFreqSpecificDays => 'Dias específicos';

  @override
  String get medFreqEveryNDays => 'A cada N dias';

  @override
  String get medFieldWeekdays => 'DIAS DA SEMANA';

  @override
  String get medFieldDoseTimes => 'HORÁRIOS DAS DOSES';

  @override
  String get medAddTime => 'Adicionar horário';

  @override
  String get medIntervalLabel => 'A cada quantos dias';

  @override
  String get medFieldStart => 'INÍCIO';

  @override
  String get medWithEndDate => 'Com data de término';

  @override
  String get medWithEndDateSub => 'Encerra o tratamento em uma data';

  @override
  String get medFieldEnd => 'TÉRMINO';

  @override
  String get medTrackInventory => 'Controlar estoque';

  @override
  String get medTrackInventorySub => 'Desconta do estoque a cada dose';

  @override
  String get medCurrentUnits => 'Unidades atuais';

  @override
  String get medAlertWhenRemaining => 'Avise quando restarem';

  @override
  String get medLeadTimeDays => 'Antecedência (dias)';

  @override
  String get medPackSize => 'Tamanho da caixa';

  @override
  String get medRefillAlerts => 'Alertas de recompra';

  @override
  String get medRefillAlertsSub => 'Com prazo estimado';

  @override
  String get medSaveMedication => 'Salvar medicamento';

  @override
  String get medContinue => 'Continuar';

  @override
  String get medErrorNameRequired => 'Digite um nome';

  @override
  String get medErrorSelectDays => 'Escolha ao menos um dia';

  @override
  String get medErrorAddTime => 'Adicione ao menos um horário';

  @override
  String get medUnitsSuffix => 'un.';

  @override
  String get medRefillTitle => 'Reabastecer estoque';

  @override
  String medRunsOutInDays(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days dias',
      one: '1 dia',
    );
    return 'Acaba em ~$_temp0';
  }

  @override
  String get medAddABox => 'Adicione uma caixa';

  @override
  String get medAddABoxSub => 'Soma ao estoque atual';

  @override
  String medWillRemain(int units, int days) {
    return 'Restarão $units unidades · dura ~$days dias';
  }

  @override
  String get medRemindOneDay => 'Lembre-me em 1 dia';

  @override
  String get medBought => 'Já comprei';

  @override
  String get medEmptyTitle => 'Ainda sem medicamentos';

  @override
  String get medEmptyBody =>
      'Adicione seu primeiro medicamento e lembraremos de cada dose e avisaremos antes que acabe.';

  @override
  String get medDashTodayLabel => 'DOSES DE HOJE';

  @override
  String get medDashSeeModule => 'Ver módulo ›';

  @override
  String get medDashNextDose => 'Próxima dose';

  @override
  String get medDashNoDoses => 'Sem doses próximas';

  @override
  String medLowStockBannerTitle(String name, int count) {
    return '$name tem $count unidades restantes';
  }

  @override
  String get medDashMedsTitle => 'Medicamentos';

  @override
  String get medDashApptsTitle => 'Consultas';

  @override
  String get specialtyNone => 'Sem especialidade';

  @override
  String get specialtyGeneralMedicine => 'Clínica geral';

  @override
  String get specialtyCardiology => 'Cardiologia';

  @override
  String get specialtyEndocrinology => 'Endocrinologia';

  @override
  String get specialtyDermatology => 'Dermatologia';

  @override
  String get specialtyGynecology => 'Ginecologia';

  @override
  String get specialtyDentistry => 'Odontologia';

  @override
  String get specialtyOphthalmology => 'Oftalmologia';

  @override
  String get specialtyOtolaryngology => 'Otorrinolaringologia';

  @override
  String get specialtyNeurology => 'Neurologia';

  @override
  String get specialtyNeuropsychology => 'Neuropsicologia';

  @override
  String get specialtyPsychiatry => 'Psiquiatria';

  @override
  String get specialtyOrthopedics => 'Ortopedia';

  @override
  String get specialtyUrology => 'Urologia';

  @override
  String get specialtyGastroenterology => 'Gastroenterologia';

  @override
  String get specialtyNutrition => 'Nutrição';

  @override
  String get specialtyPediatrics => 'Pediatria';

  @override
  String get specialtyPhysiotherapy => 'Fisioterapia';

  @override
  String get specialtyClinicalLaboratory => 'Laboratório clínico';

  @override
  String get medDashApptsSoon => 'Em breve';

  @override
  String medDashTodayProgress(int done, int total) {
    return '$done/$total hoje';
  }

  @override
  String medDashStreakShort(int days) {
    return '$days d';
  }

  @override
  String get medDashAllDone => 'Tudo em dia';

  @override
  String get medDashAddMed => 'Adicionar';

  @override
  String medDashLowShort(int count) {
    return 'Restam $count';
  }

  @override
  String get appointmentsTitle => 'As minhas consultas';

  @override
  String get appointmentsDescription => 'Acompanha as consultas que tens e as que ainda precisas de marcar.';

  @override
  String get appointmentsAddCta => 'Adicionar consulta';

  @override
  String get appointmentsSectionToBook => 'Por marcar';

  @override
  String get appointmentsSectionScheduled => 'Marcadas';

  @override
  String get appointmentsSectionHistory => 'Histórico';

  @override
  String get appointmentsEmptyTitle => 'Ainda não tens consultas';

  @override
  String get appointmentsEmptyBody => 'Adiciona as consultas que precisas de marcar ou as que já tens agendadas.';

  @override
  String get appointmentsOverdueChip => 'Vencida';

  @override
  String appointmentDueOn(String date) {
    return 'Marcar antes de $date';
  }

  @override
  String get appointmentNoDate => 'Sem data';

  @override
  String appointmentScheduledOn(String date, String time) {
    return '$date às $time';
  }

  @override
  String get appointmentStatusAttended => 'Compareceste';

  @override
  String get appointmentStatusMissed => 'Faltaste';

  @override
  String get appointmentStatusCancelled => 'Anulada';

  @override
  String get appointmentActionBook => 'Já marquei';

  @override
  String get appointmentActionPostpone => 'Adiar';

  @override
  String get appointmentActionAttended => 'Compareci';

  @override
  String get appointmentActionMissed => 'Faltei';

  @override
  String get appointmentActionDelete => 'Eliminar';

  @override
  String get appointmentDeleteTitle => 'Eliminar esta consulta?';

  @override
  String get appointmentAddTitle => 'Nova consulta';

  @override
  String get appointmentModeToBook => 'Preciso de marcar';

  @override
  String get appointmentModeScheduled => 'Já tenho data';

  @override
  String get appointmentFieldTitle => 'Título';

  @override
  String get appointmentFieldTitleHint => 'Ex. Consulta de endocrinologia';

  @override
  String get appointmentFieldSpecialty => 'Especialidade';

  @override
  String get appointmentFieldSpecialtyHint => 'Ex. Endocrinologia';

  @override
  String get appointmentFieldDate => 'Data';

  @override
  String get appointmentFieldTargetDate => 'Data-alvo para marcar';

  @override
  String get appointmentFieldProvider => 'Médico ou local';

  @override
  String get appointmentFieldNotes => 'Notas';

  @override
  String get appointmentPickDate => 'Escolher data';

  @override
  String get appointmentPickTime => 'Escolher hora';

  @override
  String get appointmentTitleRequired => 'Escreve um título para a consulta';

  @override
  String get appointmentDateRequired => 'Escolhe uma data';

  @override
  String get appointmentSave => 'Guardar';

  @override
  String get apptDashAdd => 'Adicionar consulta';

  @override
  String get apptDashNextTitle => 'Próxima consulta';

  @override
  String get apptDashToBookTitle => 'Por marcar';

  @override
  String get apptDashOverdue => 'Vencida';

  @override
  String get apptDashAllClear => 'Tudo em dia';

  @override
  String apptScheduledNotifTitle(String title) {
    return 'Consulta: $title';
  }

  @override
  String get apptScheduledNotifBody => 'Tens uma consulta em breve.';

  @override
  String apptToBookNotifTitle(String title) {
    return 'Hora de marcar: $title';
  }

  @override
  String get apptToBookNotifBody => 'Momento de marcar esta consulta.';

  @override
  String apptOverdueNotifTitle(String title) {
    return 'Consulta pendente: $title';
  }

  @override
  String get apptOverdueNotifBody => 'Tens uma consulta vencida.';

  @override
  String get appointmentFieldLocation => 'Local';

  @override
  String get appointmentFieldLocationHint => 'ex. endereço da clínica';

  @override
  String get appointmentFieldRecurring => 'Controle periódico';

  @override
  String get appointmentRecurringHint => 'Quando confirmar que compareceu, vamos lembrá-lo de marcar a próxima automaticamente.';

  @override
  String get appointmentFrequencyLabel => 'Com que frequência';

  @override
  String appointmentEveryNMonths(int count) {
    return 'A cada $count meses';
  }

  @override
  String get appointmentEditTitle => 'Editar consulta';

  @override
  String get appointmentActionEdit => 'Editar';

  @override
  String get appointmentNextSpawned => 'Anotamos o próximo controle para marcar.';

  @override
  String get appointmentComplianceRedTitle => 'Requer atenção';

  @override
  String get appointmentComplianceAmberTitle => 'Em breve';

  @override
  String get appointmentComplianceGreenTitle => 'Tudo em dia';

  @override
  String get appointmentComplianceGreenBody => 'Nenhuma consulta pendente ou atrasada.';

  @override
  String appointmentNextActionOverdue(String title) {
    return '$title · atrasada';
  }

  @override
  String appointmentNextActionUpcoming(String title, String date) {
    return '$title · $date';
  }

  @override
  String appointmentRecurringEvery(int count) {
    return 'A cada $count m';
  }
}
