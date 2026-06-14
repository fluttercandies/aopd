import 'package:example/demos/performance/performance_case_spec.dart';
import 'package:example/demos/performance/performance_runtime.dart';
import 'package:example/shared/showcase_shell.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

class PerformanceCatalog extends StatelessWidget {
  const PerformanceCatalog({super.key});

  @override
  Widget build(BuildContext context) {
    final List<PerformanceCaseSpec> cases = PerformanceCaseSpec.routeCases();
    return ShowcaseShell(
      title: 'Performance monitoring',
      subtitle:
          'Choose one performance case at a time so the event stream stays focused.',
      child: Column(
        children: <Widget>[
          _PerformanceBrief(onClear: PerformanceRuntime.instance.clear),
          const SizedBox(height: 16),
          for (int i = 0; i < cases.length; i++) ...<Widget>[
            _PerformanceCaseEntry(
              spec: cases[i],
            )
                .animate(delay: (80 * i).ms)
                .fadeIn(duration: 280.ms)
                .slideY(begin: .04, end: 0),
            if (i != cases.length - 1) const SizedBox(height: 14),
          ],
        ],
      ),
    );
  }
}

class _PerformanceBrief extends StatelessWidget {
  const _PerformanceBrief({required this.onClear});

  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: <Color>[Color(0xFF3B0A16), Color(0xFF9F1239)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Text(
            'Observe Flutter performance without touching feature code',
            style: TextStyle(
              color: Colors.white,
              fontSize: 21,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'This demo hooks StatefulElement.performRebuild, BuildOwner.buildScope, '
            'PipelineOwner.flushLayout / flushPaint, ImageCache.putIfAbsent, and '
            'PaintingBinding image codec APIs.',
            style: TextStyle(color: Color(0xFFFFE4E6), height: 1.45),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: <Widget>[
              const _HookChip(label: '@Execute performRebuild'),
              const _HookChip(label: '@Execute build/layout/paint'),
              const _HookChip(label: '@Execute image cache/codec'),
              OutlinedButton.icon(
                onPressed: onClear,
                icon: const Icon(Icons.cleaning_services_rounded),
                label: const Text('Clear events'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: const BorderSide(color: Colors.white38),
                ),
              ),
            ],
          ),
        ],
      ),
    ).animate().fadeIn(duration: 320.ms).slideY(begin: .04, end: 0);
  }
}

class _PerformanceCaseEntry extends StatelessWidget {
  const _PerformanceCaseEntry({required this.spec});

  final PerformanceCaseSpec spec;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(28),
      child: InkWell(
        borderRadius: BorderRadius.circular(28),
        onTap: () => Navigator.of(context).pushNamed(spec.routeName),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: <Widget>[
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: spec.color.withValues(alpha: .12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Icon(spec.icon, color: spec.color, size: 30),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      spec.title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      spec.description,
                      style: const TextStyle(
                        color: Color(0xFF667085),
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              const Icon(Icons.arrow_forward_rounded),
            ],
          ),
        ),
      ),
    );
  }
}

class _HookChip extends StatelessWidget {
  const _HookChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .10),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white24),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}
