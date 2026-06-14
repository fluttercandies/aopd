import 'package:example/demos/performance/performance_case_spec.dart';
import 'package:example/demos/performance/performance_event_panel.dart';
import 'package:example/demos/performance/performance_runtime.dart';
import 'package:example/shared/showcase_shell.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

class PerformanceCasePage extends StatefulWidget {
  const PerformanceCasePage({super.key, required this.spec});

  final PerformanceCaseSpec spec;

  @override
  State<PerformanceCasePage> createState() => _PerformanceCasePageState();
}

class _PerformanceCasePageState extends State<PerformanceCasePage> {
  @override
  void initState() {
    super.initState();
    PerformanceRuntime.instance.clear();
  }

  @override
  Widget build(BuildContext context) {
    return ShowcaseShell(
      title: widget.spec.title,
      subtitle: widget.spec.description,
      child: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          final bool wide = constraints.maxWidth >= 1020;
          final Widget demo = _DemoSectionCard(
            icon: widget.spec.icon,
            color: widget.spec.color,
            title: widget.spec.title,
            description: widget.spec.description,
            target: widget.spec.target,
            child: widget.spec.child,
          );
          final Widget log = PerformanceEventPanel(
            routeName: widget.spec.routeName,
            allowedKinds: widget.spec.eventKinds,
            emptyMessage:
                'Run this ${widget.spec.title.toLowerCase()} workload to see matching events here.',
          );
          if (wide) {
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Expanded(flex: 7, child: demo),
                const SizedBox(width: 20),
                Expanded(flex: 4, child: log),
              ],
            );
          }
          return Column(
            children: <Widget>[
              demo,
              const SizedBox(height: 18),
              log,
            ],
          );
        },
      ),
    );
  }
}

class _DemoSectionCard extends StatelessWidget {
  const _DemoSectionCard({
    required this.icon,
    required this.color,
    required this.title,
    required this.description,
    required this.target,
    required this.child,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String description;
  final String target;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(28),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: .12),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Icon(icon, color: color),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        target,
                        style: TextStyle(
                          color: color,
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              description,
              style: const TextStyle(color: Color(0xFF667085), height: 1.4),
            ),
            const SizedBox(height: 16),
            child,
          ],
        ),
      ),
    ).animate().fadeIn(duration: 280.ms).slideY(begin: .04, end: 0);
  }
}
