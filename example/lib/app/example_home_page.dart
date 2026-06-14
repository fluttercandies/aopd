import 'package:example/example_routes.dart';
import 'package:example/example_route.dart';
import 'package:example/l10n/app_locale_controller.dart';
import 'package:example/l10n/generated/app_localizations.dart';
import 'package:example/l10n/route_text.dart';
import 'package:example/shared/showcase_shell.dart';
import 'package:ff_annotation_route_library/ff_annotation_route_library.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

@FFRoute(
  name: 'aopd://home',
  routeName: 'AOPD Example Home',
  exts: <String, dynamic>{'group': 'catalog', 'order': '0'},
)
class ExampleHomePage extends StatelessWidget {
  const ExampleHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final List<_CatalogSection> sections = _CatalogSection.demoSections(l10n);

    return ShowcaseShell(
      title: l10n.appTitle,
      subtitle: l10n.homeSubtitle,
      child: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          final bool wide = constraints.maxWidth >= 780;
          final Widget hero = _HeroPanel(wide: wide);
          final Widget catalog = _CatalogGrid(sections: sections, wide: wide);
          if (wide) {
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Expanded(flex: 5, child: hero),
                const SizedBox(width: 24),
                Expanded(flex: 6, child: catalog),
              ],
            );
          }
          return Column(
            children: <Widget>[hero, const SizedBox(height: 20), catalog],
          );
        },
      ),
    );
  }
}

class _HeroPanel extends StatelessWidget {
  const _HeroPanel({required this.wide});

  final bool wide;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(wide ? 32 : 24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: <Color>[Color(0xFF042F2E), Color(0xFF0F766E)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(32),
        boxShadow: const <BoxShadow>[
          BoxShadow(
            color: Color(0x330F766E),
            blurRadius: 30,
            offset: Offset(0, 18),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          _Pill(label: l10n.homeHeroPill),
          const SizedBox(height: 24),
          Text(
            l10n.homeHeroTitle,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              height: 1.05,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            l10n.homeHeroBody,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: const Color(0xFFD7FFFA),
              height: 1.45,
            ),
          ),
          const SizedBox(height: 22),
          const _LanguageSelector(),
          const SizedBox(height: 28),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: const <Widget>[
              _CapabilityChip(label: '@Execute'),
              _CapabilityChip(label: '@Call'),
              _CapabilityChip(label: '@FieldGet'),
              _CapabilityChip(label: '@Inject'),
              _CapabilityChip(label: '@Add'),
            ],
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms).slideY(begin: .08, end: 0);
  }
}

class _LanguageSelector extends StatelessWidget {
  const _LanguageSelector();

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    return ValueListenableBuilder<AppLocaleChoice>(
      valueListenable: AppLocaleController.instance.choice,
      builder: (BuildContext context, AppLocaleChoice choice, Widget? _) {
        return Tooltip(
          message: l10n.languageTooltip,
          child: SegmentedButton<AppLocaleChoice>(
            style: ButtonStyle(
              backgroundColor: WidgetStateProperty.resolveWith((states) {
                if (states.contains(WidgetState.selected)) {
                  return Colors.white;
                }
                return Colors.white.withValues(alpha: .10);
              }),
              foregroundColor: WidgetStateProperty.resolveWith((states) {
                if (states.contains(WidgetState.selected)) {
                  return const Color(0xFF115E59);
                }
                return Colors.white;
              }),
              side: WidgetStateProperty.all(
                BorderSide(color: Colors.white.withValues(alpha: .35)),
              ),
            ),
            segments: <ButtonSegment<AppLocaleChoice>>[
              ButtonSegment<AppLocaleChoice>(
                value: AppLocaleChoice.system,
                icon: const Icon(Icons.settings_suggest_rounded),
                label: Text(l10n.languageSystem),
              ),
              ButtonSegment<AppLocaleChoice>(
                value: AppLocaleChoice.english,
                icon: const Icon(Icons.language_rounded),
                label: Text(l10n.languageEnglish),
              ),
              ButtonSegment<AppLocaleChoice>(
                value: AppLocaleChoice.chinese,
                icon: const Icon(Icons.translate_rounded),
                label: Text(l10n.languageChinese),
              ),
            ],
            selected: <AppLocaleChoice>{choice},
            onSelectionChanged: (Set<AppLocaleChoice> selected) {
              AppLocaleController.instance.setChoice(selected.single);
            },
          ),
        );
      },
    );
  }
}

class _CatalogGrid extends StatelessWidget {
  const _CatalogGrid({required this.sections, required this.wide});

  final List<_CatalogSection> sections;
  final bool wide;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        for (int i = 0; i < sections.length; i++) ...<Widget>[
          _CatalogSectionView(section: sections[i])
              .animate(delay: (100 * i).ms)
              .fadeIn(duration: 360.ms)
              .slideX(begin: wide ? .06 : 0, end: 0)
              .slideY(begin: wide ? 0 : .06, end: 0),
          if (i != sections.length - 1) const SizedBox(height: 18),
        ],
      ],
    );
  }
}

class _CatalogSectionView extends StatelessWidget {
  const _CatalogSectionView({required this.section});

  final _CatalogSection section;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 0, 4, 10),
          child: Row(
            children: <Widget>[
              Icon(section.icon, color: section.color, size: 22),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      section.title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                        color: const Color(0xFF102A2A),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      section.subtitle,
                      style: const TextStyle(
                        color: Color(0xFF667085),
                        height: 1.25,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        for (int i = 0; i < section.items.length; i++) ...<Widget>[
          _CatalogCard(item: section.items[i]),
          if (i != section.items.length - 1) const SizedBox(height: 12),
        ],
      ],
    );
  }
}

class _CatalogCard extends StatelessWidget {
  const _CatalogCard({required this.item});

  final _CatalogItem item;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(28),
      child: InkWell(
        borderRadius: BorderRadius.circular(28),
        onTap: () {
          Navigator.of(context).pushNamed(item.routeName);
        },
        child: Padding(
          padding: const EdgeInsets.all(22),
          child: Row(
            children: <Widget>[
              Container(
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  color: item.color.withValues(alpha: .12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Icon(item.icon, color: item.color, size: 30),
              ),
              const SizedBox(width: 18),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      item.title,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      item.subtitle,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: const Color(0xFF667085),
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

class _Pill extends StatelessWidget {
  const _Pill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: .2)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        child: Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class _CapabilityChip extends StatelessWidget {
  const _CapabilityChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        child: Text(
          label,
          style: const TextStyle(
            color: Color(0xFF115E59),
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}

class _CatalogItem {
  const _CatalogItem({
    required this.title,
    required this.subtitle,
    required this.subgroup,
    required this.icon,
    required this.color,
    required this.routeName,
    required this._order,
  });

  final String title;
  final String subtitle;
  final String subgroup;
  final IconData icon;
  final Color color;
  final String routeName;

  static List<_CatalogItem> demoItems(AppLocalizations l10n) {
    final List<_CatalogItem> items = <_CatalogItem>[
      for (final String routeName in routeNames)
        if (_CatalogItem._fromRouteName(l10n, routeName)
            case final _CatalogItem item)
          item,
    ];
    items.sort(
      (_CatalogItem a, _CatalogItem b) => a._order.compareTo(b._order),
    );
    return items;
  }

  static _CatalogItem? _fromRouteName(AppLocalizations l10n, String routeName) {
    final FFRouteSettings settings = getRouteSettings(name: routeName);
    final Map<String, dynamic> exts =
        settings.exts ?? const <String, dynamic>{};
    if (exts['group'] != 'demo') {
      return null;
    }

    return _CatalogItem(
      title: localizedRouteTitle(
        l10n,
        routeName,
        settings.routeName ?? routeName,
      ),
      subtitle: localizedRouteDescription(
        l10n,
        routeName,
        settings.description ?? '',
      ),
      subgroup: exts['subgroup']?.toString() ?? 'core',
      icon: _iconFor(exts['icon'] as String?),
      color: _colorFor(exts['color'] as String?),
      routeName: settings.name ?? routeName,
      order: int.tryParse(exts['order']?.toString() ?? '') ?? 0,
    );
  }

  static IconData _iconFor(String? value) {
    return switch (value) {
      'tree' => Icons.account_tree_rounded,
      'click' => Icons.ads_click_rounded,
      'speed' => Icons.speed_rounded,
      'coverage' => Icons.fact_check_rounded,
      'wildcard' => Icons.blur_on_rounded,
      'around' => Icons.all_inclusive_rounded,
      'guard' => Icons.shield_rounded,
      'patch' => Icons.healing_rounded,
      'json' => Icons.data_object_rounded,
      'rewrite' => Icons.auto_fix_high_rounded,
      'network' => Icons.route_rounded,
      'flag' => Icons.flag_rounded,
      'spark' || _ => Icons.auto_awesome_rounded,
    };
  }

  static Color _colorFor(String? value) {
    return switch (value) {
      'amber' => const Color(0xFFB45309),
      'blue' => const Color(0xFF1D4ED8),
      'rose' => const Color(0xFFBE123C),
      'green' => const Color(0xFF047857),
      'cyan' => const Color(0xFF0891B2),
      'teal' || _ => const Color(0xFF0F766E),
    };
  }

  final int _order;
}

class _CatalogSection {
  const _CatalogSection({
    required this.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.order,
    required this.items,
  });

  final String key;
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final int order;
  final List<_CatalogItem> items;

  static List<_CatalogSection> demoSections(AppLocalizations l10n) {
    final Map<String, List<_CatalogItem>> grouped =
        <String, List<_CatalogItem>>{};
    for (final _CatalogItem item in _CatalogItem.demoItems(l10n)) {
      grouped.putIfAbsent(item.subgroup, () => <_CatalogItem>[]).add(item);
    }

    final List<_CatalogSection> sections = <_CatalogSection>[
      for (final MapEntry<String, List<_CatalogItem>> entry in grouped.entries)
        _CatalogSection._fromSubgroup(l10n, entry.key, entry.value),
    ];
    sections.sort(
      (_CatalogSection a, _CatalogSection b) => a.order.compareTo(b.order),
    );
    return sections;
  }

  static _CatalogSection _fromSubgroup(
    AppLocalizations l10n,
    String subgroup,
    List<_CatalogItem> items,
  ) {
    items.sort(
      (_CatalogItem a, _CatalogItem b) => a._order.compareTo(b._order),
    );
    return switch (subgroup) {
      'core' => _CatalogSection(
        key: subgroup,
        title: l10n.sectionCoreTitle,
        subtitle: l10n.sectionCoreSubtitle,
        icon: Icons.auto_awesome_rounded,
        color: const Color(0xFF0F766E),
        order: 1,
        items: items,
      ),
      'observability' => _CatalogSection(
        key: subgroup,
        title: l10n.sectionObservabilityTitle,
        subtitle: l10n.sectionObservabilitySubtitle,
        icon: Icons.query_stats_rounded,
        color: const Color(0xFF1D4ED8),
        order: 2,
        items: items,
      ),
      'behavior' => _CatalogSection(
        key: subgroup,
        title: l10n.sectionBehaviorTitle,
        subtitle: l10n.sectionBehaviorSubtitle,
        icon: Icons.tune_rounded,
        color: const Color(0xFF047857),
        order: 3,
        items: items,
      ),
      'compiler' => _CatalogSection(
        key: subgroup,
        title: l10n.sectionCompilerTitle,
        subtitle: l10n.sectionCompilerSubtitle,
        icon: Icons.construction_rounded,
        color: const Color(0xFFB45309),
        order: 4,
        items: items,
      ),
      _ => _CatalogSection(
        key: subgroup,
        title: l10n.sectionOtherTitle,
        subtitle: l10n.sectionOtherSubtitle,
        icon: Icons.widgets_rounded,
        color: const Color(0xFF667085),
        order: 99,
        items: items,
      ),
    };
  }
}
