import 'package:example/l10n/generated/app_localizations.dart';
import 'package:example/shared/demo_event_log.dart';
import 'package:example/shared/event_log_panel.dart';
import 'package:example/shared/showcase_shell.dart';
import 'package:ff_annotation_route_library/ff_annotation_route_library.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

@FFRoute(
  name: 'aopd://auto-analytics',
  routeName: 'Auto analytics',
  description:
      'A practical full-tracking demo inspired by real click analytics instrumentation.',
  exts: <String, dynamic>{
    'group': 'demo',
    'subgroup': 'observability',
    'order': '1',
    'icon': 'click',
    'color': 'blue',
  },
)
class AutoAnalyticsPage extends StatelessWidget {
  const AutoAnalyticsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ShowcaseShell(
      title: 'Auto analytics',
      subtitle:
          'A practical full-tracking demo inspired by a real click-tracking flow.',
      child: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          final bool wide = constraints.maxWidth >= 980;
          final Widget demo = const _AnalyticsDemoSurface();
          const Widget log = EventLogPanel();
          if (wide) {
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Expanded(flex: 7, child: demo),
                const SizedBox(width: 20),
                const Expanded(flex: 4, child: log),
              ],
            );
          }
          return const Column(
            children: <Widget>[
              _AnalyticsDemoSurface(),
              SizedBox(height: 18),
              EventLogPanel(),
            ],
          );
        },
      ),
    );
  }
}

class _AnalyticsDemoSurface extends StatelessWidget {
  const _AnalyticsDemoSurface();

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    return Column(
      children: <Widget>[
        _ScenarioBrief(onClear: DemoEventLog.instance.clear),
        const SizedBox(height: 16),
        _ProductCard(
          title: 'AOPD Field Notes',
          subtitle: l10n.analyticsProductNotesSubtitle,
          price: r'$24',
          accent: const Color(0xFF0F766E),
          onBuy: () => _showPurchaseDialog(context),
        ),
        const SizedBox(height: 14),
        _ProductCard(
          title: 'Kernel Explorer Mug',
          subtitle: l10n.analyticsProductMugSubtitle,
          price: r'$16',
          accent: const Color(0xFFB45309),
          onBuy: () => _showPurchaseDialog(context),
        ),
        const SizedBox(height: 14),
        const _ActionStrip(),
      ],
    );
  }

  void _showPurchaseDialog(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    showDialog<void>(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: Text(l10n.analyticsConfirmPurchase),
          content: Text(l10n.analyticsDialogBody),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(l10n.analyticsCancel),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(l10n.analyticsConfirmOrder),
            ),
          ],
        );
      },
    );
  }
}

class _ScenarioBrief extends StatelessWidget {
  const _ScenarioBrief({required this.onClear});

  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: const Color(0xFF102A2A),
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            l10n.analyticsBriefTitle,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 21,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            l10n.analyticsBriefBody,
            style: const TextStyle(color: Color(0xFFD7FFFA), height: 1.45),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: <Widget>[
              const _HookChip(label: '@Call HitTestTarget.handleEvent'),
              const _HookChip(
                label: '@Execute GestureRecognizer.invokeCallback',
              ),
              const _HookChip(label: 'track_widget_creation: true'),
              OutlinedButton.icon(
                onPressed: onClear,
                icon: const Icon(Icons.cleaning_services_rounded),
                label: Text(l10n.analyticsClearLog),
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

class _ProductCard extends StatefulWidget {
  const _ProductCard({
    required this.title,
    required this.subtitle,
    required this.price,
    required this.accent,
    required this.onBuy,
  });

  final String title;
  final String subtitle;
  final String price;
  final Color accent;
  final VoidCallback onBuy;

  @override
  State<_ProductCard> createState() => _ProductCardState();
}

class _ProductCardState extends State<_ProductCard> {
  bool _favorited = false;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(28),
      child: InkWell(
        borderRadius: BorderRadius.circular(28),
        onTap: () {},
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            children: <Widget>[
              Container(
                width: 74,
                height: 74,
                decoration: BoxDecoration(
                  color: widget.accent.withValues(alpha: .14),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Icon(
                  Icons.inventory_2_rounded,
                  color: widget.accent,
                  size: 34,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      widget.title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      widget.subtitle,
                      style: const TextStyle(
                        color: Color(0xFF667085),
                        height: 1.35,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: <Widget>[
                        Text(
                          widget.price,
                          style: TextStyle(
                            color: widget.accent,
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const Spacer(),
                        IconButton.filledTonal(
                          onPressed: () {
                            setState(() => _favorited = !_favorited);
                          },
                          icon: Icon(
                            _favorited
                                ? Icons.favorite_rounded
                                : Icons.favorite_border_rounded,
                          ),
                        ),
                        const SizedBox(width: 8),
                        FilledButton(
                          onPressed: widget.onBuy,
                          child: Text(l10n.analyticsBuyNow),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    ).animate().fadeIn(duration: 280.ms).slideY(begin: .04, end: 0);
  }
}

class _ActionStrip extends StatelessWidget {
  const _ActionStrip();

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    return Row(
      children: <Widget>[
        Expanded(
          child: FilledButton.tonalIcon(
            onPressed: () {},
            icon: const Icon(Icons.local_offer_rounded),
            label: Text(l10n.analyticsApplyCoupon),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: FilledButton.tonalIcon(
            onPressed: () {},
            icon: const Icon(Icons.support_agent_rounded),
            label: Text(l10n.analyticsContactSupport),
          ),
        ),
      ],
    );
  }
}
