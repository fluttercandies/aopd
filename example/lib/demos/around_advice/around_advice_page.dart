import 'package:example/demos/around_advice/around_advice_runtime.dart';
import 'package:example/demos/around_advice/around_advice_targets.dart';
import 'package:example/l10n/generated/app_localizations.dart';
import 'package:example/shared/showcase_shell.dart';
import 'package:ff_annotation_route_library/ff_annotation_route_library.dart';
import 'package:flutter/material.dart';

@FFRoute(
  name: 'aopd://around-advice',
  routeName: 'Around advice',
  description:
      'Time a method (slow-call alert) and cache another by skipping the original body.',
  exts: <String, dynamic>{
    'group': 'demo',
    'subgroup': 'behavior',
    'order': '1',
    'icon': 'around',
    'color': 'rose',
  },
)
class AroundAdvicePage extends StatelessWidget {
  const AroundAdvicePage({super.key});

  @override
  Widget build(BuildContext context) {
    return ShowcaseShell(
      title: 'Around advice',
      subtitle:
          'Advice runs around the target, so it can measure it or replace it without calling it.',
      child: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          final bool wide = constraints.maxWidth >= 980;
          const Widget timing = _TimingPanel();
          const Widget cache = _CachePanel();
          if (wide) {
            return const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Expanded(child: timing),
                SizedBox(width: 20),
                Expanded(child: cache),
              ],
            );
          }
          return const Column(
            children: <Widget>[timing, SizedBox(height: 18), cache],
          );
        },
      ),
    );
  }
}

class _TimingPanel extends StatelessWidget {
  const _TimingPanel();

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    return _Card(
      title: l10n.aroundTimingTitle,
      subtitle: l10n.aroundTimingSubtitle(
        AroundAdviceRuntime.slowThresholdMicros ~/ 1000,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: <Widget>[
              FilledButton.tonal(
                key: const Key('around.fast'),
                onPressed: () => ReportService().generate(1),
                child: Text(l10n.aroundFastReport),
              ),
              FilledButton(
                key: const Key('around.slow'),
                onPressed: () => ReportService().generate(12),
                child: Text(l10n.aroundHeavyReport),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ValueListenableBuilder<List<TimingRecord>>(
            valueListenable: AroundAdviceRuntime.instance.timings,
            builder:
                (BuildContext context, List<TimingRecord> records, Widget? _) {
                  if (records.isEmpty) {
                    return Text(
                      l10n.aroundTimingEmpty,
                      style: const TextStyle(color: Color(0xFF667085)),
                    );
                  }
                  return Column(
                    children: <Widget>[
                      for (final TimingRecord r in records)
                        _TimingRow(record: r),
                    ],
                  );
                },
          ),
        ],
      ),
    );
  }
}

class _TimingRow extends StatelessWidget {
  const _TimingRow({required this.record});

  final TimingRecord record;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final Color color = record.slow
        ? const Color(0xFFB91C1C)
        : const Color(0xFF047857);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: <Widget>[
          Icon(
            record.slow ? Icons.warning_amber_rounded : Icons.timer_outlined,
            size: 20,
            color: color,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              record.label,
              style: const TextStyle(fontFamily: 'monospace'),
            ),
          ),
          Text(
            '${(record.micros / 1000).toStringAsFixed(1)} ms'
            '${record.slow ? '  ${l10n.aroundSlowBadge}' : ''}',
            style: TextStyle(color: color, fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }
}

class _CachePanel extends StatelessWidget {
  const _CachePanel();

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    return _Card(
      title: l10n.aroundCacheTitle,
      subtitle: l10n.aroundCacheSubtitle,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: <Widget>[
              FilledButton.tonal(
                key: const Key('around.quoteA'),
                onPressed: () => PricingService.instance.quote('SKU-A'),
                child: Text(l10n.aroundQuoteSkuA),
              ),
              FilledButton.tonal(
                key: const Key('around.quoteB'),
                onPressed: () => PricingService.instance.quote('SKU-B'),
                child: Text(l10n.aroundQuoteSkuB),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ValueListenableBuilder<List<String>>(
            valueListenable: AroundAdviceRuntime.instance.cacheLog,
            builder: (BuildContext context, List<String> log, Widget? _) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  _ProofRow(),
                  const SizedBox(height: 12),
                  if (log.isEmpty)
                    Text(
                      l10n.aroundCacheEmpty,
                      style: const TextStyle(color: Color(0xFF667085)),
                    )
                  else
                    for (final String line in log)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 3),
                        child: Text(
                          line,
                          style: const TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 12.5,
                          ),
                        ),
                      ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _ProofRow extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFFFFF1F2),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            Text(
              l10n.aroundRealComputations,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            Text(
              '${PricingService.instance.realComputations}',
              key: const Key('around.computations'),
              style: const TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 18,
                color: Color(0xFFBE123C),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({
    required this.title,
    required this.subtitle,
    required this.child,
  });

  final String title;
  final String subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(28),
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              title,
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              style: const TextStyle(color: Color(0xFF667085), height: 1.35),
            ),
            const SizedBox(height: 18),
            child,
          ],
        ),
      ),
    );
  }
}
