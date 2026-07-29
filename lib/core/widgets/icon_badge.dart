import 'package:flutter/material.dart';
import 'package:myvitals_healthtracker_app/core/theme/theme_context.dart';

/// LA CAJA QUE ENCIERRA UN ICONO. Un cuadrado redondeado, nunca un círculo.
///
/// La app tenía las dos formas conviviendo sin criterio: el menú de Historial
/// dibujaba su caja con `BorderRadius.circular(10)`, la hoja de «Registrar
/// indicadores» con `shape: BoxShape.circle`, y Perfil, Ayuda, Legal y
/// Recordatorios cada uno con lo suyo. Dos listas con la misma anatomía —icono,
/// rótulo, chevron— se veían distintas según por dónde se entrara, y no había
/// dónde mirar para saber cuál era la correcta.
///
/// El redondeo sale de `surfaces.radiusIcon`, así que lo decide el tema: si
/// mañana entra uno más blando o más recto, todas las cajas de la app le
/// obedecen a la vez. Por eso la forma no se puede pasar por parámetro.
///
/// No cubre los círculos que SÍ tienen que ser círculos: un avatar, el punto de
/// un radio, la perilla de un deslizador, un adorno redondo del fondo. Ésos
/// están inventariados en `test/core/theme/icon_enclosure_shape_test.dart`.
class IconBadge extends StatelessWidget {
  /// El icono. Se dibuja centrado.
  final IconData icon;

  /// Color del icono.
  final Color color;

  /// Relleno de la caja.
  final Color background;

  /// Lado de la caja, si tiene que medir exactamente eso. Cuando es `null` la
  /// caja se ajusta al icono más [padding], que es lo que quieren las filas de
  /// lista.
  final double? size;

  /// Aire alrededor del icono cuando [size] es `null`.
  final double padding;

  /// Tamaño del icono.
  final double iconSize;

  /// Filete opcional.
  final BoxBorder? border;

  /// Sombra opcional. Pásala siempre desde `surfaces.glow(...)` o
  /// `surfaces.cardShadow`, nunca escrita a mano: un `BoxShadow` a mano no sabe
  /// si el tema levanta las cosas del lienzo o las deja planas.
  final List<BoxShadow>? shadow;

  /// Cuánto tarda en cambiar de color cuando la caja tiene estados —elegido y
  /// sin elegir—. `null` (lo normal) dibuja una caja quieta.
  final Duration? animateDuration;

  const IconBadge(
    this.icon, {
    super.key,
    required this.color,
    required this.background,
    this.size,
    this.padding = 8,
    this.iconSize = 20,
    this.border,
    this.shadow,
    this.animateDuration,
  });

  @override
  Widget build(BuildContext context) {
    final surfaces = Theme.of(context).surfaces;
    final decoration = BoxDecoration(
      color: background,
      borderRadius: surfaces.iconRadius,
      border: border,
      boxShadow: shadow,
    );
    final child = Center(
      child: Icon(icon, color: color, size: iconSize),
    );

    if (animateDuration != null) {
      return AnimatedContainer(
        duration: animateDuration!,
        width: size,
        height: size,
        padding: size == null ? EdgeInsets.all(padding) : null,
        decoration: decoration,
        child: child,
      );
    }

    return Container(
      width: size,
      height: size,
      padding: size == null ? EdgeInsets.all(padding) : null,
      decoration: decoration,
      child: child,
    );
  }
}
