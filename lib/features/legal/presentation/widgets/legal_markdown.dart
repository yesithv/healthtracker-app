import 'package:flutter/material.dart';
import 'package:myvitals_healthtracker_app/core/theme/theme_context.dart';

/// Pinta el Markdown de los documentos legales.
///
/// **Es a propósito un intérprete pequeño**, no una librería: los textos los
/// escribimos nosotros y usan seis construcciones —títulos, separadores, citas,
/// viñetas, negrita y párrafos—. Traer un motor completo para eso añadiría una
/// dependencia y una superficie de render que aquí no hace falta.
///
/// Lo que no reconozca se pinta como texto plano: un documento legal tiene que
/// poder leerse entero aunque alguien añada mañana una construcción nueva.
class LegalMarkdown extends StatelessWidget {
  final String source;

  const LegalMarkdown(this.source, {super.key});

  @override
  Widget build(BuildContext context) {
    final surfaces = Theme.of(context).surfaces;
    final children = <Widget>[];

    for (final block in _blocks(source)) {
      children.add(_render(context, block));
    }

    return DefaultTextStyle(
      style: TextStyle(fontSize: 14, height: 1.6, color: surfaces.inkSecondary),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }

  Widget _render(BuildContext context, _Block block) {
    final surfaces = Theme.of(context).surfaces;

    switch (block.kind) {
      case _Kind.h1:
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Text(
            block.text,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              height: 1.3,
              color: surfaces.ink,
            ),
          ),
        );
      case _Kind.h2:
        return Padding(
          padding: const EdgeInsets.only(top: 20, bottom: 8),
          child: Text(
            block.text,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              height: 1.35,
              color: surfaces.ink,
            ),
          ),
        );
      case _Kind.rule:
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Divider(
            height: 1,
            color: surfaces.inkMuted.withValues(alpha: 0.25),
          ),
        );
      case _Kind.quote:
        // Aquí es donde va el aviso de borrador: se separa del resto del texto
        // porque no dice lo mismo que él.
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Theme.of(
              context,
            ).clinical.caution.accent.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(12),
            border: Border(
              left: BorderSide(
                color: Theme.of(context).clinical.caution.accent,
                width: 3,
              ),
            ),
          ),
          child: _rich(context, block.text, size: 13),
        );
      case _Kind.bullet:
        return Padding(
          padding: const EdgeInsets.only(bottom: 8, left: 4),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 7, right: 10),
                child: Container(
                  width: 5,
                  height: 5,
                  decoration: BoxDecoration(
                    color: surfaces.inkMuted,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
              Expanded(child: _rich(context, block.text)),
            ],
          ),
        );
      case _Kind.paragraph:
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _rich(context, block.text),
        );
    }
  }

  /// Resuelve la negrita. Un `**` sin pareja se queda como texto: mejor un
  /// asterisco a la vista que media frase perdida.
  Widget _rich(BuildContext context, String text, {double size = 14}) {
    final surfaces = Theme.of(context).surfaces;
    final base = TextStyle(
      fontSize: size,
      height: 1.6,
      color: surfaces.inkSecondary,
    );
    final spans = <TextSpan>[];

    var bold = false;
    for (final piece in text.split('**')) {
      if (piece.isNotEmpty) {
        spans.add(
          TextSpan(
            text: piece,
            style: bold
                ? base.copyWith(
                    fontWeight: FontWeight.bold,
                    color: surfaces.ink,
                  )
                : base,
          ),
        );
      }
      bold = !bold;
    }

    return Text.rich(TextSpan(children: spans), style: base);
  }

  /// Parte el texto en bloques. Las líneas sueltas de un mismo párrafo —o de una
  /// misma viñeta— se unen: el original va cortado a 100 columnas y respetar ese
  /// corte dejaría el texto con saltos donde no los hay.
  static List<_Block> _blocks(String source) {
    final blocks = <_Block>[];
    final buffer = StringBuffer();
    var kind = _Kind.paragraph;

    void flush() {
      final text = buffer.toString().trim();
      buffer.clear();
      if (text.isNotEmpty) blocks.add(_Block(kind, text));
      kind = _Kind.paragraph;
    }

    for (final raw in source.split('\n')) {
      final line = raw.trimRight();
      final trimmed = line.trim();

      if (trimmed.isEmpty) {
        flush();
        continue;
      }
      if (trimmed == '---' || trimmed == '***') {
        flush();
        blocks.add(const _Block(_Kind.rule, ''));
        continue;
      }
      if (trimmed.startsWith('## ')) {
        flush();
        blocks.add(_Block(_Kind.h2, trimmed.substring(3).trim()));
        continue;
      }
      if (trimmed.startsWith('# ')) {
        flush();
        blocks.add(_Block(_Kind.h1, trimmed.substring(2).trim()));
        continue;
      }
      if (trimmed.startsWith('> ')) {
        if (kind != _Kind.quote) flush();
        kind = _Kind.quote;
        _append(buffer, trimmed.substring(2).trim());
        continue;
      }
      if (trimmed.startsWith('- ') || trimmed.startsWith('* ')) {
        flush();
        kind = _Kind.bullet;
        _append(buffer, trimmed.substring(2).trim());
        continue;
      }
      // Una línea que continúa el bloque anterior (párrafo, viñeta o cita).
      _append(buffer, trimmed);
    }
    flush();

    return blocks;
  }

  static void _append(StringBuffer buffer, String text) {
    if (buffer.isNotEmpty) buffer.write(' ');
    buffer.write(text);
  }
}

enum _Kind { h1, h2, rule, quote, bullet, paragraph }

class _Block {
  final _Kind kind;
  final String text;
  const _Block(this.kind, this.text);
}
