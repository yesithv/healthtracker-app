/// Los rangos de referencia de la persona de la demostracion, congelados.
///
/// ## Por que existe esto
///
/// La demo corre **sin servidor y sin cuenta**, asi que `GET /me/reference-ranges`
/// no se puede pedir: sin estas cifras los clasificadores caian a sus cortes de
/// fabrica y las graficas salian **sin ninguna franja de color**.
///
/// Y los cortes de fabrica no eran los de la clinica. Para esta persona -mujer de
/// 36 anos, bascula Omron HBF-514C- un 26 por ciento de grasa es **NORMAL**: su
/// banda va de 21 a 32.9. El respaldo generico, ciego a sexo, edad y bascula, lo
/// llamaba «elevada». La serie de la demo baja justo de 36 a 26, asi que el relato
/// entero -«bajo y llego a lo saludable»- terminaba en ambar diciendo lo contrario.
///
/// ## De donde salen estas cifras
///
/// **No estan escritas a mano.** Son la respuesta literal de la API para esa
/// persona, capturada en `test/fixtures/demo_reference_ranges.json` y comprobada
/// contra este fichero por `test/core/demo/demo_reference_ranges_test.dart`.
/// El fixture se regenera desde la base con
/// `healthtracker-localdev/scripts/check-demo-ranges.sh`.
///
/// ## La trampa de la edad
///
/// La persona de la demo nacio el 22-05-1990, asi que hoy tiene 36 y cae en el
/// tramo **20-39**. En 2030 cruzara al de 40-59 y estas cifras dejaran de ser las
/// suyas **sin que nada avise**. Por eso la prueba comprueba tambien la edad: el
/// dia que se salga del tramo falla, y dice que hay que regenerar el fixture.
library;

/// La respuesta de `GET /api/v1/me/reference-ranges` para la persona de la demo,
/// con la forma exacta que espera `ReferenceRangesStore`.
const List<Map<String, Object>> kDemoReferenceRangeIndicators = [
  {
    'indicatorCode': 'BMI',
    'indicatorName': 'IMC',
    'unit': 'kg/m2',
    'scope': 'BASELINE',
    'bands': [
      {
        'bandCode': 'UNDERWEIGHT',
        'bandLabel': 'Bajo peso',
        'minValue': 0.0,
        'maxValue': 18.4,
        'sortOrder': 1,
      },
      {
        'bandCode': 'NORMAL',
        'bandLabel': 'Normal',
        'minValue': 18.5,
        'maxValue': 24.9,
        'sortOrder': 2,
      },
      {
        'bandCode': 'OVERWEIGHT',
        'bandLabel': 'Sobrepeso',
        'minValue': 25.0,
        'maxValue': 29.9,
        'sortOrder': 3,
      },
      {
        'bandCode': 'OBESE',
        'bandLabel': 'Obesidad',
        'minValue': 30.0,
        'maxValue': 100.0,
        'sortOrder': 4,
      },
    ],
  },
  {
    'indicatorCode': 'BODY_FAT',
    'indicatorName': 'Grasa corporal',
    'unit': '%',
    'scope': 'DEVICE',
    'bands': [
      {
        'bandCode': 'LOW',
        'bandLabel': 'Bajo',
        'minValue': 5.0,
        'maxValue': 20.9,
        'sortOrder': 1,
      },
      {
        'bandCode': 'NORMAL',
        'bandLabel': 'Normal',
        'minValue': 21.0,
        'maxValue': 32.9,
        'sortOrder': 2,
      },
      {
        'bandCode': 'HIGH',
        'bandLabel': 'Alto',
        'minValue': 33.0,
        'maxValue': 38.9,
        'sortOrder': 3,
      },
      {
        'bandCode': 'VERY_HIGH',
        'bandLabel': 'Muy alto',
        'minValue': 39.0,
        'maxValue': 60.0,
        'sortOrder': 4,
      },
    ],
  },
  {
    'indicatorCode': 'VISCERAL_FAT_LEVEL',
    'indicatorName': 'Grasa visceral (nivel)',
    'unit': 'nivel',
    'scope': 'DEVICE',
    'bands': [
      {
        'bandCode': 'NORMAL',
        'bandLabel': 'Normal',
        'minValue': 1.0,
        'maxValue': 9.0,
        'sortOrder': 2,
      },
      {
        'bandCode': 'HIGH',
        'bandLabel': 'Alto',
        'minValue': 10.0,
        'maxValue': 14.0,
        'sortOrder': 3,
      },
      {
        'bandCode': 'VERY_HIGH',
        'bandLabel': 'Muy alto',
        'minValue': 15.0,
        'maxValue': 30.0,
        'sortOrder': 4,
      },
    ],
  },
  {
    'indicatorCode': 'MUSCLE_PCT',
    'indicatorName': 'Músculo',
    'unit': '%',
    'scope': 'DEVICE',
    'bands': [
      {
        'bandCode': 'LOW',
        'bandLabel': 'Bajo',
        'minValue': 5.0,
        'maxValue': 24.2,
        'sortOrder': 1,
      },
      {
        'bandCode': 'NORMAL',
        'bandLabel': 'Normal',
        'minValue': 24.3,
        'maxValue': 30.3,
        'sortOrder': 2,
      },
      {
        'bandCode': 'HIGH',
        'bandLabel': 'Alto',
        'minValue': 30.4,
        'maxValue': 35.3,
        'sortOrder': 3,
      },
      {
        'bandCode': 'VERY_HIGH',
        'bandLabel': 'Muy alto',
        'minValue': 35.4,
        'maxValue': 60.0,
        'sortOrder': 4,
      },
    ],
  },
];

/// Fecha de nacimiento de la persona de la demo, la misma que siembra `DemoSeeder`.
/// Aqui para que la prueba pueda comprobar en que tramo de edad cae.
final DateTime kDemoBirthDate = DateTime(1990, 5, 22);

/// El tramo de edad al que corresponden las cifras congeladas, en anos cumplidos.
const int kDemoAgeBandMin = 20;
const int kDemoAgeBandMax = 39;
