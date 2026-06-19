import 'package:flutter/material.dart';

class Reminder {
  final String id;
  final String translationKey; // Identificador para traducirlo dinamicamente
  final TimeOfDay time;
  final bool isEnabled;

  const Reminder({
    required this.id,
    required this.translationKey,
    required this.time,
    required this.isEnabled,
  });

  Reminder copyWith({
    String? id,
    String? translationKey,
    TimeOfDay? time,
    bool? isEnabled,
  }) {
    return Reminder(
      id: id ?? this.id,
      translationKey: translationKey ?? this.translationKey,
      time: time ?? this.time,
      isEnabled: isEnabled ?? this.isEnabled,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'translationKey': translationKey,
      'hour': time.hour,
      'minute': time.minute,
      'isEnabled': isEnabled,
    };
  }

  factory Reminder.fromJson(Map<String, dynamic> json) {
    return Reminder(
      id: json['id'] as String,
      translationKey: json['translationKey'] as String,
      time: TimeOfDay(
        hour: json['hour'] as int,
        minute: json['minute'] as int,
      ),
      isEnabled: json['isEnabled'] as bool,
    );
  }
}
