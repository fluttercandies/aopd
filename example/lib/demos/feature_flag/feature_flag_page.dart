import 'package:example/demos/feature_flag/feature_flag_runtime.dart';
import 'package:example/demos/feature_flag/feature_flag_targets.dart';
import 'package:example/l10n/generated/app_localizations.dart';
import 'package:example/shared/event_log_panel.dart';
import 'package:example/shared/showcase_shell.dart';
import 'package:ff_annotation_route_library/ff_annotation_route_library.dart';
import 'package:flutter/material.dart';

@FFRoute(
  name: 'aopd://feature-flags',
  routeName: 'Feature flags',
  description:
      'Route gray-release behavior through advice while business methods stay stable.',
  exts: <String, dynamic>{
    'group': 'demo',
    'subgroup': 'behavior',
    'order': '9',
    'icon': 'flag',
    'color': 'green',
  },
)
class FeatureFlagPage extends StatelessWidget {
  const FeatureFlagPage({super.key});

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    return ShowcaseShell(
      title: l10n.featureTitle,
      subtitle: l10n.featureSubtitle,
      child: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          final bool wide = constraints.maxWidth >= 980;
          const Widget controls = _FlagControls();
          const Widget decisions = _DecisionPanel();
          if (wide) {
            return const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Expanded(flex: 5, child: controls),
                SizedBox(width: 20),
                Expanded(flex: 6, child: decisions),
              ],
            );
          }
          return const Column(
            children: <Widget>[controls, SizedBox(height: 18), decisions],
          );
        },
      ),
    );
  }
}

class _FlagControls extends StatelessWidget {
  const _FlagControls();

  static final CheckoutDecisionService _service = CheckoutDecisionService();

  @override
  Widget build(BuildContext context) {
    final FeatureFlagRuntime runtime = FeatureFlagRuntime.instance;
    final AppLocalizations l10n = AppLocalizations.of(context);
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(28),
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              l10n.featureToggleExperiments,
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 6),
            Text(
              l10n.featureToggleExperimentsBody,
              style: const TextStyle(color: Color(0xFF667085), height: 1.35),
            ),
            const SizedBox(height: 12),
            ValueListenableBuilder<bool>(
              valueListenable: runtime.checkoutV2Enabled,
              builder: (BuildContext context, bool value, Widget? _) {
                return SwitchListTile(
                  key: const Key('flags.checkoutV2'),
                  contentPadding: EdgeInsets.zero,
                  title: Text(l10n.featureCheckoutV2Title),
                  subtitle: Text(l10n.featureCheckoutV2Subtitle),
                  value: value,
                  onChanged: runtime.setCheckoutV2,
                );
              },
            ),
            ValueListenableBuilder<bool>(
              valueListenable: runtime.gatewayV2Enabled,
              builder: (BuildContext context, bool value, Widget? _) {
                return SwitchListTile(
                  key: const Key('flags.gatewayV2'),
                  contentPadding: EdgeInsets.zero,
                  title: Text(l10n.featureGatewayV2Title),
                  subtitle: Text(l10n.featureGatewayV2Subtitle),
                  value: value,
                  onChanged: runtime.setGatewayV2,
                );
              },
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: <Widget>[
                _RunButton(
                  id: 'vipDiscount',
                  label: l10n.featureVipDiscount,
                  onRun: () =>
                      '${_service.loyaltyDiscountPercent('vip', 7600)}%',
                ),
                _RunButton(
                  id: 'cartDiscount',
                  label: l10n.featureLargeCart,
                  onRun: () =>
                      '${_service.loyaltyDiscountPercent('guest', 14200)}%',
                ),
                _RunButton(
                  id: 'euGateway',
                  label: l10n.featureEuGateway,
                  onRun: () => _service.paymentGateway('EU'),
                ),
                _RunButton(
                  id: 'usGateway',
                  label: l10n.featureUsGateway,
                  onRun: () => _service.paymentGateway('US'),
                ),
              ],
            ),
            const SizedBox(height: 18),
            const EventLogPanel(),
          ],
        ),
      ),
    );
  }
}

class _RunButton extends StatelessWidget {
  const _RunButton({
    required this.id,
    required this.label,
    required this.onRun,
  });

  final String id;
  final String label;
  final String Function() onRun;

  @override
  Widget build(BuildContext context) {
    return FilledButton.tonalIcon(
      key: Key('flags.$id'),
      onPressed: () {
        final String result = onRun();
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('$label -> $result')));
      },
      icon: const Icon(Icons.flag_rounded),
      label: Text(label),
    );
  }
}

class _DecisionPanel extends StatelessWidget {
  const _DecisionPanel();

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(28),
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    l10n.featureFlagDecisions,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                OutlinedButton.icon(
                  key: const Key('flags.reset'),
                  onPressed: FeatureFlagRuntime.instance.reset,
                  icon: const Icon(Icons.refresh_rounded, size: 18),
                  label: Text(l10n.commonReset),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ValueListenableBuilder<List<FlagDecision>>(
              valueListenable: FeatureFlagRuntime.instance.decisions,
              builder:
                  (
                    BuildContext context,
                    List<FlagDecision> decisions,
                    Widget? _,
                  ) {
                    if (decisions.isEmpty) {
                      return Text(
                        l10n.featureFlagEmpty,
                        style: const TextStyle(color: Color(0xFF667085)),
                      );
                    }
                    return Column(
                      children: <Widget>[
                        for (final FlagDecision decision in decisions)
                          _DecisionRow(decision: decision),
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

class _DecisionRow extends StatelessWidget {
  const _DecisionRow({required this.decision});

  final FlagDecision decision;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final Color color = decision.enabled
        ? const Color(0xFF047857)
        : const Color(0xFF6B7280);
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(vertical: 6),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: decision.enabled
            ? const Color(0xFFECFDF5)
            : const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Icon(Icons.flag_rounded, color: color, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  decision.flag,
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Text(
                decision.enabled ? l10n.featureFlagOn : l10n.featureFlagOff,
                style: TextStyle(color: color, fontWeight: FontWeight.w900),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            decision.result,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 4),
          Text(decision.note, style: const TextStyle(color: Color(0xFF667085))),
        ],
      ),
    );
  }
}
