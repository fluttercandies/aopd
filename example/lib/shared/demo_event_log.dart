import 'package:flutter/foundation.dart';

enum DemoEventKind { user, target, aspect, result, error }

class DemoEvent {
  const DemoEvent({
    required this.kind,
    required this.title,
    required this.message,
    required this.time,
  });

  final DemoEventKind kind;
  final String title;
  final String message;
  final DateTime time;
}

class DemoEventLog {
  DemoEventLog._();

  static final DemoEventLog instance = DemoEventLog._();

  final ValueNotifier<List<DemoEvent>> events =
      ValueNotifier<List<DemoEvent>>(<DemoEvent>[]);

  void add(DemoEventKind kind, String title, String message) {
    events.value = <DemoEvent>[
      DemoEvent(
          kind: kind, title: title, message: message, time: DateTime.now()),
      ...events.value,
    ].take(40).toList(growable: false);
  }

  void addUser(String title, String message) {
    add(DemoEventKind.user, title, message);
  }

  void addTarget(String title, String message) {
    add(DemoEventKind.target, title, message);
  }

  void addAspect(String title, String message) {
    add(DemoEventKind.aspect, title, message);
  }

  void addResult(String title, String message) {
    add(DemoEventKind.result, title, message);
  }

  void addError(String title, String message) {
    add(DemoEventKind.error, title, message);
  }

  void clear() {
    events.value = <DemoEvent>[];
  }
}
