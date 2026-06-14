import 'package:example/demos/code_coverage/wildcard/feature_targets.dart';
import 'package:example/demos/code_coverage/wildcard_coverage_runtime.dart';
import 'package:example/l10n/generated/app_localizations.dart';
import 'package:example/shared/demo_card.dart';
import 'package:example/shared/showcase_shell.dart';
import 'package:ff_annotation_route_library/ff_annotation_route_library.dart';
import 'package:flutter/material.dart';

@FFRoute(
  name: 'aopd://wildcard-coverage',
  routeName: 'Wildcard coverage',
  description:
      'One regex pointcut instruments a whole package subtree - no per-class annotation.',
  exts: <String, dynamic>{
    'group': 'demo',
    'subgroup': 'observability',
    'order': '5',
    'icon': 'wildcard',
    'color': 'teal',
  },
)
class WildcardCoveragePage extends StatelessWidget {
  const WildcardCoveragePage({super.key});

  @override
  Widget build(BuildContext context) {
    return ShowcaseShell(
      title: 'Wildcard coverage',
      subtitle:
          'A single pointcut weaves every method of every class under '
          'lib/demos/code_coverage/wildcard/. No per-class annotation is needed.',
      child: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          final bool wide = constraints.maxWidth >= 980;
          const Widget left = _ControlsPanel();
          const Widget right = _DiscoveredPanel();
          if (wide) {
            return const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Expanded(flex: 6, child: left),
                SizedBox(width: 20),
                Expanded(flex: 5, child: right),
              ],
            );
          }
          return const Column(
            children: <Widget>[left, SizedBox(height: 18), right],
          );
        },
      ),
    );
  }
}

class _ControlsPanel extends StatelessWidget {
  const _ControlsPanel();

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    return Column(
      children: <Widget>[
        DemoCard(
          id: 'wildcard.exercise',
          title: l10n.wildcardDemoTitle,
          description: l10n.wildcardDemoDescription,
          target:
              'SearchFeature.query(...)\n'
              'CartFeature.addToCart(...) / subtotal()\n'
              'ProfileFeature.displayName() / signOut()',
          aspect:
              "@Execute('package:example/demos/code_coverage/wildcard/.*',\n"
              "         '.*', '-.*', isRegex: true)",
          onRun: () {
            SearchFeature().query('aopd');
            final CartFeature cart = CartFeature();
            cart.addToCart('sku-1');
            cart.subtotal();
            ProfileFeature().displayName();
          },
        ),
        const SizedBox(height: 14),
        Material(
          color: const Color(0xFFF0FDFA),
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  l10n.wildcardWhyTitle,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 8),
                Text(
                  l10n.wildcardWhyBody,
                  style: const TextStyle(color: Color(0xFF0F766E), height: 1.4),
                ),
                const SizedBox(height: 10),
                Text(
                  l10n.wildcardCollectorNote,
                  style: const TextStyle(color: Color(0xFF0F766E), height: 1.4),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _DiscoveredPanel extends StatelessWidget {
  const _DiscoveredPanel();

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(28),
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: ValueListenableBuilder<Set<String>>(
          valueListenable: WildcardCoverageRuntime.instance.hits,
          builder: (BuildContext context, Set<String> hits, Widget? _) {
            final List<String> sorted = hits.toList()..sort();
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    Text(
                      l10n.wildcardDiscoveredUnits(hits.length),
                      key: const Key('wildcard.count'),
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    OutlinedButton.icon(
                      key: const Key('wildcard.reset'),
                      onPressed: WildcardCoverageRuntime.instance.reset,
                      icon: const Icon(Icons.refresh_rounded, size: 18),
                      label: Text(l10n.commonReset),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (sorted.isEmpty)
                  Text(
                    l10n.wildcardEmpty,
                    style: const TextStyle(color: Color(0xFF667085)),
                  )
                else
                  for (final String id in sorted)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Row(
                        children: <Widget>[
                          const Icon(
                            Icons.check_circle_rounded,
                            color: Color(0xFF10B981),
                            size: 22,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              id,
                              style: const TextStyle(
                                fontFamily: 'monospace',
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
              ],
            );
          },
        ),
      ),
    );
  }
}
