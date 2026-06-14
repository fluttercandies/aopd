import 'dart:convert';

import 'package:example/demos/code_coverage/coverage_manifest.dart';
import 'package:example/demos/code_coverage/coverage_runtime.dart';
import 'package:example/demos/code_coverage/coverage_targets.dart';
import 'package:example/l10n/generated/app_localizations.dart';
import 'package:example/shared/showcase_shell.dart';
import 'package:ff_annotation_route_library/ff_annotation_route_library.dart';
import 'package:flutter/material.dart';

@FFRoute(
  name: 'aopd://code-coverage',
  routeName: 'Code coverage',
  description: 'Method-level coverage via woven hit-recording advice.',
  exts: <String, dynamic>{
    'group': 'demo',
    'subgroup': 'observability',
    'order': '4',
    'icon': 'coverage',
    'color': 'green',
  },
)
class CodeCoveragePage extends StatelessWidget {
  const CodeCoveragePage({super.key});

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    return ShowcaseShell(
      title: l10n.routeCodeCoverageTitle,
      subtitle: l10n.routeCodeCoverageDescription,
      child: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          final bool wide = constraints.maxWidth >= 980;
          const Widget controls = _ControlsPanel();
          const Widget checklist = _CoverageChecklist();
          if (wide) {
            return const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Expanded(flex: 5, child: controls),
                SizedBox(width: 20),
                Expanded(flex: 6, child: checklist),
              ],
            );
          }
          return const Column(
            children: <Widget>[controls, SizedBox(height: 18), checklist],
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
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(28),
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            const _CoverageMeter(),
            const SizedBox(height: 20),
            Text(
              l10n.coverageExerciseUnits,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 4),
            const Text(
              'Each button runs real catalog code. The woven advice records the '
              'hit before proceeding — behavior is unchanged.',
              style: TextStyle(color: Color(0xFF667085), height: 1.35),
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: <Widget>[
                _ActionButton(
                  id: 'cart',
                  label: l10n.coverageUseCart,
                  onRun: () {
                    final CartService cart = CartService();
                    cart.addItem(500);
                    cart.total();
                  },
                ),
                _ActionButton(
                  id: 'checkout',
                  label: l10n.coverageRunCheckout,
                  onRun: () {
                    final CheckoutService checkout = CheckoutService();
                    checkout.applyCoupon('AOPD');
                    checkout.pay(1200);
                  },
                ),
                _ActionButton(
                  id: 'onboardingStart',
                  label: l10n.coverageOnboardingStart,
                  onRun: () => OnboardingFlow().start(),
                ),
                _ActionButton(
                  id: 'onboardingFinish',
                  label: l10n.coverageOnboardingFinish,
                  onRun: () => OnboardingFlow().finish(),
                ),
                _ActionButton(
                  id: 'formatPrice',
                  label: l10n.coverageFormatPrice,
                  onRun: () => formatPrice(1299),
                ),
                _ActionButton(
                  id: 'runAll',
                  label: l10n.coverageRunAll,
                  emphasized: true,
                  onRun: () {
                    final CartService cart = CartService();
                    cart.addItem(500);
                    cart.total();
                    final CheckoutService checkout = CheckoutService();
                    checkout.applyCoupon('AOPD');
                    checkout.pay(1200);
                    OnboardingFlow().start();
                    OnboardingFlow().finish();
                    formatPrice(1299);
                  },
                ),
              ],
            ),
            const SizedBox(height: 18),
            Row(
              children: <Widget>[
                OutlinedButton.icon(
                  key: const Key('coverage.reset'),
                  onPressed: CoverageRuntime.instance.reset,
                  icon: const Icon(Icons.refresh_rounded),
                  label: Text(l10n.commonReset),
                ),
                const SizedBox(width: 12),
                OutlinedButton.icon(
                  key: const Key('coverage.export'),
                  onPressed: () => _showExport(context),
                  icon: const Icon(Icons.upload_file_rounded),
                  label: Text(l10n.coverageExportJson),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showExport(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final String payload = const JsonEncoder.withIndent(
      '  ',
    ).convert(CoverageRuntime.instance.exportJson());
    showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(l10n.coverageUploadPayload),
          content: SingleChildScrollView(
            child: SelectableText(
              payload,
              style: const TextStyle(fontFamily: 'monospace', fontSize: 12.5),
            ),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(l10n.coverageClose),
            ),
          ],
        );
      },
    );
  }
}

class _CoverageMeter extends StatelessWidget {
  const _CoverageMeter();

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    return ValueListenableBuilder<Set<String>>(
      valueListenable: CoverageRuntime.instance.hits,
      builder: (BuildContext context, Set<String> _, Widget? _) {
        final CoverageRuntime runtime = CoverageRuntime.instance;
        final double ratio = runtime.coverageRatio;
        final int percent = (ratio * 100).round();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              '$percent% ${l10n.coverageCovered}',
              key: const Key('coverage.percent'),
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w800,
                color: const Color(0xFF047857),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              '${runtime.coveredCount} / ${runtime.totalCount} ${l10n.coverageUnitsHit}',
              style: const TextStyle(color: Color(0xFF667085)),
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                value: ratio,
                minHeight: 12,
                backgroundColor: const Color(0xFFE5E7EB),
                color: const Color(0xFF10B981),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _CoverageChecklist extends StatelessWidget {
  const _CoverageChecklist();

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    return ValueListenableBuilder<Set<String>>(
      valueListenable: CoverageRuntime.instance.hits,
      builder: (BuildContext context, Set<String> hits, Widget? _) {
        return Material(
          color: Colors.white,
          borderRadius: BorderRadius.circular(28),
          child: Padding(
            padding: const EdgeInsets.all(22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  l10n.coverageCatalogUnits,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 12),
                for (final CoverageUnit unit in kCoverageManifest)
                  _UnitRow(unit: unit, covered: hits.contains(unit.id)),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _UnitRow extends StatelessWidget {
  const _UnitRow({required this.unit, required this.covered});

  final CoverageUnit unit;
  final bool covered;

  @override
  Widget build(BuildContext context) {
    final Color color = covered
        ? const Color(0xFF10B981)
        : (unit.isDeadCodeProbe
              ? const Color(0xFFB91C1C)
              : const Color(0xFF9CA3AF));
    final IconData icon = covered
        ? Icons.check_circle_rounded
        : (unit.isDeadCodeProbe
              ? Icons.warning_amber_rounded
              : Icons.radio_button_unchecked_rounded);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: <Widget>[
          Icon(icon, color: color, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  unit.label,
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (unit.isDeadCodeProbe && !covered)
                  const Text(
                    'never invoked — dead-code candidate',
                    style: TextStyle(color: Color(0xFFB91C1C), fontSize: 12),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.id,
    required this.label,
    required this.onRun,
    this.emphasized = false,
  });

  final String id;
  final String label;
  final VoidCallback onRun;
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    if (emphasized) {
      return FilledButton(
        key: Key('coverage.$id'),
        onPressed: onRun,
        child: Text(label),
      );
    }
    return FilledButton.tonal(
      key: Key('coverage.$id'),
      onPressed: onRun,
      child: Text(label),
    );
  }
}
