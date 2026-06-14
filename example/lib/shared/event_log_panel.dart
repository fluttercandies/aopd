import 'package:example/l10n/generated/app_localizations.dart';
import 'package:example/shared/demo_event_log.dart';
import 'package:flutter/material.dart';

class EventLogPanel extends StatelessWidget {
  const EventLogPanel({super.key});

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    return Material(
      color: const Color(0xFF111827),
      borderRadius: BorderRadius.circular(28),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    l10n.resultLogTitle,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: DemoEventLog.instance.clear,
                  child: Text(l10n.commonClear),
                ),
              ],
            ),
            const SizedBox(height: 10),
            ValueListenableBuilder<List<DemoEvent>>(
              valueListenable: DemoEventLog.instance.events,
              builder: (BuildContext context, List<DemoEvent> events, _) {
                if (events.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    child: Text(
                      l10n.resultLogEmpty,
                      style: const TextStyle(color: Color(0xFFCBD5E1)),
                    ),
                  );
                }
                return Column(
                  children: <Widget>[
                    // Show enough events that a multi-pointcut demo (the
                    // Advanced matrix logs ~15) does not truncate its earliest
                    // events. The whole page is inside a CustomScrollView, so a
                    // taller log just scrolls. The model itself caps at 40.
                    for (final DemoEvent event in events.take(24))
                      _EventTile(event: event),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _EventTile extends StatelessWidget {
  const _EventTile({required this.event});

  final DemoEvent event;

  @override
  Widget build(BuildContext context) {
    final Color color = switch (event.kind) {
      DemoEventKind.user => const Color(0xFF93C5FD),
      DemoEventKind.target => const Color(0xFFA7F3D0),
      DemoEventKind.aspect => const Color(0xFFFDE68A),
      DemoEventKind.result => const Color(0xFFC4B5FD),
      DemoEventKind.error => const Color(0xFFFCA5A5),
    };
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .06),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withValues(alpha: .35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Container(
                width: 9,
                height: 9,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  event.title,
                  style: TextStyle(color: color, fontWeight: FontWeight.w800),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            event.message,
            style: const TextStyle(
              color: Color(0xFFE5E7EB),
              height: 1.35,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}
