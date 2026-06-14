import 'package:example/demos/basic/basic_targets.dart';
import 'package:example/demos/basic/inject_class_target.dart';
import 'package:example/demos/basic/inject_dedup_a.dart' as dedup_a;
import 'package:example/demos/basic/inject_dedup_b.dart' as dedup_b;
import 'package:example/l10n/generated/app_localizations.dart';
import 'package:example/shared/demo_card.dart';
import 'package:example/shared/demo_event_log.dart';
import 'package:example/shared/event_log_panel.dart';
import 'package:example/shared/showcase_shell.dart';
import 'package:ff_annotation_route_library/ff_annotation_route_library.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

@FFRoute(
  name: 'aopd://basic-annotations',
  routeName: 'Basic annotations',
  description:
      'Aspect, Execute, Call, FieldGet, Inject, and Add in small loops.',
  exts: <String, dynamic>{
    'group': 'demo',
    'subgroup': 'core',
    'order': '1',
    'icon': 'spark',
    'color': 'teal',
  },
)
class BasicAnnotationsPage extends StatelessWidget {
  const BasicAnnotationsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final List<_BasicDemoSpec> specs = _basicDemoSpecs(l10n);
    return ShowcaseShell(
      title: l10n.routeBasicAnnotationsTitle,
      subtitle: l10n.basicPageSubtitle,
      child: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          final bool wide = constraints.maxWidth >= 760;
          return Wrap(
            spacing: 16,
            runSpacing: 16,
            children: <Widget>[
              for (int i = 0; i < specs.length; i++)
                _BasicDemoEntryCard(spec: specs[i], wide: wide)
                    .animate(delay: (70 * i).ms)
                    .fadeIn(duration: 260.ms)
                    .slideY(begin: .04, end: 0),
            ],
          );
        },
      ),
    );
  }
}

class _BasicDemoEntryCard extends StatelessWidget {
  const _BasicDemoEntryCard({required this.spec, required this.wide});

  final _BasicDemoSpec spec;
  final bool wide;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: wide ? 360 : double.infinity,
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(26),
        child: InkWell(
          key: Key('basic.entry.${spec.id}'),
          borderRadius: BorderRadius.circular(26),
          onTap: () {
            DemoEventLog.instance.clear();
            Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => _BasicDemoDetailPage(spec: spec),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: spec.color.withValues(alpha: .12),
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Icon(spec.icon, color: spec.color),
                    ),
                    const Spacer(),
                    const Icon(Icons.arrow_forward_rounded),
                  ],
                ),
                const SizedBox(height: 18),
                Text(
                  spec.title,
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 8),
                Text(
                  spec.description,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: const Color(0xFF667085),
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _BasicDemoDetailPage extends StatefulWidget {
  const _BasicDemoDetailPage({required this.spec});

  final _BasicDemoSpec spec;

  @override
  State<_BasicDemoDetailPage> createState() => _BasicDemoDetailPageState();
}

class _BasicDemoDetailPageState extends State<_BasicDemoDetailPage> {
  final BasicTarget _target = BasicTarget();

  @override
  Widget build(BuildContext context) {
    final _BasicDemoSpec spec = widget.spec;
    return ShowcaseShell(
      title: spec.title,
      subtitle: spec.detailSubtitle,
      child: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          final Widget demo = DemoCard(
            id: spec.id,
            title: spec.title,
            description: spec.description,
            target: spec.target,
            aspect: spec.aspect,
            onRun: () => _run(spec.resultTitle, () => spec.run(_target)),
          );
          const Widget log = EventLogPanel();
          if (constraints.maxWidth >= 980) {
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Expanded(flex: 7, child: demo),
                const SizedBox(width: 20),
                const Expanded(flex: 5, child: log),
              ],
            );
          }
          return Column(
            children: <Widget>[demo, const SizedBox(height: 18), log],
          );
        },
      ),
    );
  }

  void _run(String title, Object? Function() action) {
    try {
      final Object? result = action();
      DemoEventLog.instance.addResult(title, '$result');
    } catch (error, stackTrace) {
      DemoEventLog.instance.addError(title, '$error\n$stackTrace');
    }
  }
}

typedef _BasicDemoRunner = Object? Function(BasicTarget target);

class _BasicDemoSpec {
  const _BasicDemoSpec({
    required this.id,
    required this.title,
    required this.description,
    required this.detailSubtitle,
    required this.target,
    required this.aspect,
    required this.resultTitle,
    required this.icon,
    required this.color,
    required this.run,
  });

  final String id;
  final String title;
  final String description;
  final String detailSubtitle;
  final String target;
  final String aspect;
  final String resultTitle;
  final IconData icon;
  final Color color;
  final _BasicDemoRunner run;
}

List<_BasicDemoSpec> _basicDemoSpecs(AppLocalizations l10n) {
  return <_BasicDemoSpec>[
    _BasicDemoSpec(
      id: 'basic.execute',
      title: '@Execute',
      description: l10n.basicExecuteDescription,
      detailSubtitle: l10n.basicExecuteDetail,
      target: 'int BasicTarget.runExecuteDemo()',
      aspect: '@Execute(..., "BasicTarget", "-runExecuteDemo")',
      resultTitle: l10n.basicExecuteResult,
      icon: Icons.bolt_rounded,
      color: const Color(0xFF0F766E),
      run: (BasicTarget target) => target.runExecuteDemo(),
    ),
    _BasicDemoSpec(
      id: 'basic.call',
      title: '@Call',
      description: l10n.basicCallDescription,
      detailSubtitle: l10n.basicCallDetail,
      target: 'createGreeting("AOPD", tone: "curious")',
      aspect: '@Call(..., "BasicTarget", "-createGreeting")',
      resultTitle: l10n.basicCallResult,
      icon: Icons.call_split_rounded,
      color: const Color(0xFF2563EB),
      run: (BasicTarget target) => target.runCallDemo(),
    ),
    _BasicDemoSpec(
      id: 'basic.field_get',
      title: '@FieldGet',
      description: l10n.basicFieldGetDescription,
      detailSubtitle: l10n.basicFieldGetDetail,
      target: 'BasicFieldStore.releaseChannel',
      aspect: '@FieldGet(..., "releaseChannel", true)',
      resultTitle: l10n.basicFieldGetResult,
      icon: Icons.dataset_rounded,
      color: const Color(0xFF7C3AED),
      run: (BasicTarget target) => target.runFieldGetDemo(),
    ),
    _BasicDemoSpec(
      id: 'basic.inject',
      title: '@Inject',
      description: l10n.basicInjectDescription,
      detailSubtitle: l10n.basicInjectDetail,
      target: 'runInjectTarget() marker line',
      aspect: '@Inject(..., "+runInjectTarget", lineNum: marker)',
      resultTitle: l10n.basicInjectResult,
      icon: Icons.input_rounded,
      color: const Color(0xFFB45309),
      run: (BasicTarget target) => target.runInjectDemo(),
    ),
    _BasicDemoSpec(
      id: 'basic.inject_class',
      title: l10n.basicInjectClassTitle,
      description: l10n.basicInjectClassDescription,
      detailSubtitle: l10n.basicInjectClassDetail,
      target: 'int InjectClassTarget.compute()',
      aspect: '@Inject(..., "InjectClassTarget", "-compute", lineNum: 6)',
      resultTitle: l10n.basicInjectClassResult,
      icon: Icons.account_tree_rounded,
      color: const Color(0xFF0EA5E9),
      run: (BasicTarget target) =>
          'compute() = ${InjectClassTarget().compute()}  '
          '(field starts at 1; @Inject adds +100 → expect 101, un-woven would be 1)',
    ),
    _BasicDemoSpec(
      id: 'basic.inject_scope',
      title: l10n.basicInjectScopeTitle,
      description: l10n.basicInjectScopeDescription,
      detailSubtitle: l10n.basicInjectScopeDetail,
      target: 'DedupTarget.compute() — inject_dedup_a vs inject_dedup_b',
      aspect: '@Inject(".../inject_dedup_a.dart", "DedupTarget", "-compute")',
      resultTitle: l10n.basicInjectScopeResult,
      icon: Icons.alt_route_rounded,
      color: const Color(0xFF059669),
      run: (BasicTarget target) =>
          'a.compute() = ${dedup_a.DedupTarget().compute()} (targeted → expect 101)   |   '
          'b.compute() = ${dedup_b.DedupTarget().compute()} (same class name, other library → expect 1, NOT injected)',
    ),
    _BasicDemoSpec(
      id: 'basic.add',
      title: '@Add',
      description: l10n.basicAddDescription,
      detailSubtitle: l10n.basicAddDetail,
      target: 'dynamic AddedMethodTarget.generatedBadge()',
      aspect: '@Add(..., "AddedMethodTarget")',
      resultTitle: l10n.basicAddResult,
      icon: Icons.add_circle_rounded,
      color: const Color(0xFFE11D48),
      run: (BasicTarget target) => target.runAddDemo(),
    ),
  ];
}
