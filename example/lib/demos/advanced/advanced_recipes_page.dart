import 'package:example/demos/advanced/advanced_targets.dart';
import 'package:example/l10n/generated/app_localizations.dart';
import 'package:example/shared/demo_card.dart';
import 'package:example/shared/demo_event_log.dart';
import 'package:example/shared/event_log_panel.dart';
import 'package:example/shared/showcase_shell.dart';
import 'package:ff_annotation_route_library/ff_annotation_route_library.dart';
import 'package:flutter/material.dart';

@FFRoute(
  name: 'aopd://advanced-recipes',
  routeName: 'Advanced recipes',
  description:
      'Instance, static, constructor, library, regex pointcuts, and PointCut data.',
  exts: <String, dynamic>{
    'group': 'demo',
    'subgroup': 'core',
    'order': '2',
    'icon': 'tree',
    'color': 'amber',
  },
)
class AdvancedRecipesPage extends StatelessWidget {
  const AdvancedRecipesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final AdvancedRunner runner = AdvancedRunner();
    return ShowcaseShell(
      title: l10n.routeAdvancedRecipesTitle,
      subtitle: l10n.routeAdvancedRecipesDescription,
      child: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          final bool wide = constraints.maxWidth >= 980;
          final Widget demos = Column(
            children: <Widget>[
              DemoCard(
                id: 'advanced.matrix',
                title: l10n.advancedMatrixTitle,
                description: l10n.advancedMatrixDescription,
                target:
                    'AdvancedTarget(...)\n'
                    'target.instanceRecipe(...)\n'
                    'AdvancedTarget.staticRecipe(...)\n'
                    'advancedLibraryRecipe(...)\n'
                    'target.regexAlpha() / regexBeta()',
                aspect:
                    '@Call instance/static/constructor/library\n'
                    '@Execute(..., "-regex.*", isRegex: true)',
                onRun: () {
                  try {
                    final List<String> results = runner.runAll();
                    DemoEventLog.instance.addResult(
                      l10n.advancedMatrixResult,
                      results.join('\n'),
                    );
                  } catch (error, stackTrace) {
                    DemoEventLog.instance.addError(
                      l10n.advancedMatrixResult,
                      '$error\n$stackTrace',
                    );
                  }
                },
              ),
            ],
          );
          const Widget log = EventLogPanel();
          if (wide) {
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Expanded(flex: 7, child: demos),
                const SizedBox(width: 20),
                const Expanded(flex: 4, child: log),
              ],
            );
          }
          return Column(
            children: <Widget>[demos, const SizedBox(height: 18), log],
          );
        },
      ),
    );
  }
}
