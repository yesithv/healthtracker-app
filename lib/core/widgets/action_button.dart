import 'package:flutter/material.dart';

class ActionButton extends StatelessWidget {
  final String text;
  final Color color;
  final bool solid;
  final VoidCallback? onPressed;

  const ActionButton({
    super.key,
    required this.text,
    required this.color,
    required this.solid,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: solid ? color : color.withValues(alpha: 0.05),
      borderRadius: BorderRadius.circular(30),
      child: InkWell(
        onTap: onPressed ?? () {},
        borderRadius: BorderRadius.circular(30),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(30),
            border: solid
                ? null
                : Border.all(color: color.withValues(alpha: 0.3), width: 1.5),
          ),
          alignment: Alignment.center,
          child: Text(
            text,
            style: TextStyle(
              color: solid ? Colors.white : color,
              fontWeight: FontWeight.bold,
              fontSize: 13,
              letterSpacing: 0.3,
            ),
          ),
        ),
      ),
    );
  }
}
