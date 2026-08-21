import 'package:flutter_test/flutter_test.dart';
import 'package:myvitals_healthtracker_app/features/discover/data/models/article.dart';
import 'package:myvitals_healthtracker_app/features/discover/data/models/discover_feed.dart';
import 'package:myvitals_healthtracker_app/features/discover/data/models/discover_models.dart';

/// El feed de «Descubre» se carga de un JSON que produce el backoffice y que la
/// app trae empaquetado por idioma (`assets/data/discover_<lang>.json`). Ese
/// contrato es EXTERNO y evoluciona: hay formas nuevas y formas heredadas
/// conviviendo (`category`/`categoryId`, `text`/`subtitle`), campos que pueden
/// faltar y valores que llegan como número donde el modelo espera otra cosa.
///
/// El parsing está escrito para tolerar todo eso sin reventar —cae a valores por
/// defecto y descarta lo que no entiende—, precisamente porque un feed a medio
/// migrar no debe dejar la pantalla en blanco. Estas pruebas fijan esa tolerancia
/// campo a campo: son la red que permite tocar el parsing sabiendo si se rompe el
/// contrato con el contenido ya publicado.
void main() {
  group('ContentLevel.fromJson ·', () {
    test('mapea los tres niveles, sin importar mayúsculas', () {
      expect(ContentLevel.fromJson('intermedio'), ContentLevel.intermedio);
      expect(ContentLevel.fromJson('AVANZADO'), ContentLevel.avanzado);
      expect(ContentLevel.fromJson('Principiante'), ContentLevel.principiante);
    });

    test('null o desconocido cae a principiante', () {
      expect(ContentLevel.fromJson(null), ContentLevel.principiante);
      expect(ContentLevel.fromJson(''), ContentLevel.principiante);
      expect(ContentLevel.fromJson('experto'), ContentLevel.principiante);
    });
  });

  group('ChallengeStatus.fromJson ·', () {
    test('mapea los tres estados, sin importar mayúsculas', () {
      expect(ChallengeStatus.fromJson('activo'), ChallengeStatus.activo);
      expect(
        ChallengeStatus.fromJson('FINALIZADO'),
        ChallengeStatus.finalizado,
      );
      expect(
        ChallengeStatus.fromJson('Programado'),
        ChallengeStatus.programado,
      );
    });

    test('null o desconocido cae a programado', () {
      expect(ChallengeStatus.fromJson(null), ChallengeStatus.programado);
      expect(ChallengeStatus.fromJson('pausado'), ChallengeStatus.programado);
    });
  });

  group('Routine.fromJson ·', () {
    test('lee todos los campos cuando están presentes', () {
      final r = Routine.fromJson({
        'id': 'r1',
        'title': 'Fuerza en casa',
        'subtitle': '20 min sin material',
        'category': 'sports',
        'level': 'intermedio',
        'durationMin': 20,
        'exercises': 6,
      });
      expect(r.id, 'r1');
      expect(r.title, 'Fuerza en casa');
      expect(r.level, ContentLevel.intermedio);
      expect(r.durationMin, 20);
      expect(r.exercises, 6);
    });

    test('aplica los valores por defecto cuando faltan campos', () {
      final r = Routine.fromJson({'id': 'r2'});
      expect(r.title, '');
      expect(r.subtitle, '');
      expect(r.category, 'sports');
      expect(r.level, ContentLevel.principiante);
      expect(r.durationMin, 0);
      expect(r.exercises, 0);
    });

    test('convierte números en coma a entero (durationMin/exercises)', () {
      final r = Routine.fromJson({
        'id': 'r3',
        'durationMin': 12.9,
        'exercises': 3.0,
      });
      expect(r.durationMin, 12);
      expect(r.exercises, 3);
    });
  });

  group('Challenge.fromJson ·', () {
    test(
      'lee todos los campos y por defecto deja participantes/duración en 0',
      () {
        final full = Challenge.fromJson({
          'id': 'c1',
          'title': 'Reto de pasos',
          'goal': '10 000 pasos/día',
          'participants': 128,
          'status': 'activo',
          'durationDays': 30,
        });
        expect(full.participants, 128);
        expect(full.status, ChallengeStatus.activo);
        expect(full.durationDays, 30);

        final bare = Challenge.fromJson({'id': 'c2'});
        expect(bare.goal, '');
        expect(bare.participants, 0);
        expect(bare.status, ChallengeStatus.programado);
        expect(bare.durationDays, 0);
      },
    );
  });

  group('DailyTip.fromJson ·', () {
    test('acepta la forma nueva (text) y la heredada (subtitle)', () {
      expect(
        DailyTip.fromJson({'id': 't1', 'text': 'Bebe agua'}).text,
        'Bebe agua',
      );
      expect(
        DailyTip.fromJson({'id': 't2', 'subtitle': 'Camina 10 min'}).text,
        'Camina 10 min',
      );
    });

    test('prefiere text sobre subtitle cuando vienen ambos', () {
      final tip = DailyTip.fromJson({'id': 't3', 'text': 'A', 'subtitle': 'B'});
      expect(tip.text, 'A');
    });
  });

  group('Article.fromJson ·', () {
    test('prefiere category y cae a categoryId heredado y luego a general', () {
      expect(
        Article.fromJson({'id': 'a1', 'category': 'heart'}).category,
        'heart',
      );
      expect(
        Article.fromJson({'id': 'a2', 'categoryId': 'sleep'}).category,
        'sleep',
      );
      expect(Article.fromJson({'id': 'a3'}).category, 'general');
    });

    test('readTime se normaliza a texto venga como número o como cadena', () {
      expect(Article.fromJson({'id': 'a4', 'readTime': 5}).readTime, '5');
      expect(Article.fromJson({'id': 'a5', 'readTime': '7'}).readTime, '7');
      expect(Article.fromJson({'id': 'a6'}).readTime, '3');
    });

    test('featured por defecto es false', () {
      expect(Article.fromJson({'id': 'a7'}).featured, isFalse);
      expect(Article.fromJson({'id': 'a8', 'featured': true}).featured, isTrue);
    });
  });

  group('DiscoverFeed.fromJson ·', () {
    test('parsea las cuatro colecciones', () {
      final feed = DiscoverFeed.fromJson({
        'dailyTips': [
          {'id': 't1', 'text': 'Bebe agua'},
        ],
        'articles': [
          {'id': 'a1', 'title': 'Corazón', 'featured': true},
          {'id': 'a2', 'title': 'Sueño'},
        ],
        'routines': [
          {'id': 'r1'},
        ],
        'challenges': [
          {'id': 'c1'},
        ],
      });
      expect(feed.dailyTips, hasLength(1));
      expect(feed.articles, hasLength(2));
      expect(feed.routines, hasLength(1));
      expect(feed.challenges, hasLength(1));
    });

    test('una clave que no es lista se trata como colección vacía', () {
      final feed = DiscoverFeed.fromJson({
        'articles': 'no-soy-una-lista',
        'routines': null,
      });
      expect(feed.articles, isEmpty);
      expect(feed.routines, isEmpty);
      expect(feed.isEmpty, isTrue);
    });

    test('descarta los elementos de la lista que no son objetos', () {
      final feed = DiscoverFeed.fromJson({
        'articles': [
          {'id': 'a1', 'title': 'Válido'},
          'basura',
          42,
          null,
        ],
      });
      expect(feed.articles, hasLength(1));
      expect(feed.articles.single.id, 'a1');
    });

    test(
      'featuredArticles y standardArticles reparten por el flag featured',
      () {
        final feed = DiscoverFeed.fromJson({
          'articles': [
            {'id': 'a1', 'featured': true},
            {'id': 'a2', 'featured': false},
            {'id': 'a3', 'featured': true},
          ],
        });
        expect(feed.featuredArticles.map((a) => a.id), ['a1', 'a3']);
        expect(feed.standardArticles.map((a) => a.id), ['a2']);
      },
    );

    test('isEmpty es true solo cuando no hay nada', () {
      expect(DiscoverFeed.empty.isEmpty, isTrue);
      expect(const DiscoverFeed().isEmpty, isTrue);
      final withOne = DiscoverFeed.fromJson({
        'dailyTips': [
          {'id': 't1', 'text': 'x'},
        ],
      });
      expect(withOne.isEmpty, isFalse);
    });
  });
}
