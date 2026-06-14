import 'package:example/demos/performance/performance_events.dart';
import 'package:example/demos/performance/performance_runtime.dart';
import 'package:flutter/material.dart';

class PerformanceEventPanel extends StatelessWidget {
  const PerformanceEventPanel({
    super.key,
    required this.routeName,
    required this.allowedKinds,
    required this.emptyMessage,
  });

  final String routeName;
  final Set<PerformanceEventKind> allowedKinds;
  final String emptyMessage;

  @override
  Widget build(BuildContext context) {
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
                const Expanded(
                  child: Text(
                    'Performance events',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: PerformanceRuntime.instance.clear,
                  child: const Text('Clear'),
                ),
              ],
            ),
            const SizedBox(height: 10),
            ValueListenableBuilder<List<PerformanceEvent>>(
              valueListenable: PerformanceRuntime.instance.events,
              builder:
                  (BuildContext context, List<PerformanceEvent> events, _) {
                final List<PerformanceEvent> visibleEvents = events
                    .where(
                      (PerformanceEvent event) =>
                          event.routeName == routeName &&
                          allowedKinds.contains(event.kind),
                    )
                    .take(12)
                    .toList(growable: false);
                if (visibleEvents.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    child: Text(
                      emptyMessage,
                      style: const TextStyle(color: Color(0xFFCBD5E1)),
                    ),
                  );
                }
                return Column(
                  children: <Widget>[
                    for (final PerformanceEvent event in visibleEvents)
                      _PerformanceEventTile(event: event),
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

class _PerformanceEventTile extends StatelessWidget {
  const _PerformanceEventTile({required this.event});

  final PerformanceEvent event;

  @override
  Widget build(BuildContext context) {
    final Color color = switch (event.kind) {
      PerformanceEventKind.build => const Color(0xFFFCA5A5),
      PerformanceEventKind.frame => const Color(0xFFFDE68A),
      PerformanceEventKind.phase => const Color(0xFFA7F3D0),
      PerformanceEventKind.image => const Color(0xFF93C5FD),
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
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              if (event.isIssue)
                const Text(
                  'issue',
                  style: TextStyle(
                    color: Color(0xFFFCA5A5),
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
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
              fontFamily: 'monospace',
            ),
          ),
        ],
      ),
    );
  }
}
