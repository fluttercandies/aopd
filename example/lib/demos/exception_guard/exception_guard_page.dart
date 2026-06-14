import 'package:example/demos/exception_guard/exception_guard_runtime.dart';
import 'package:example/demos/exception_guard/exception_guard_targets.dart';
import 'package:example/l10n/generated/app_localizations.dart';
import 'package:example/shared/showcase_shell.dart';
import 'package:ff_annotation_route_library/ff_annotation_route_library.dart';
import 'package:flutter/material.dart';

@FFRoute(
  name: 'aopd://exception-guard',
  routeName: 'Exception guard',
  description:
      'Woven try/catch turns a throwing method into a safe fallback — the app never crashes.',
  exts: <String, dynamic>{
    'group': 'demo',
    'subgroup': 'behavior',
    'order': '2',
    'icon': 'guard',
    'color': 'amber',
  },
)
class ExceptionGuardPage extends StatelessWidget {
  const ExceptionGuardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ShowcaseShell(
      title: 'Exception guard',
      subtitle:
          'The error path: each method below throws on bad input and has no '
          'try/catch of its own. The woven advice catches the throw, logs it '
          'with context, and returns a fallback — so the tap never crashes.',
      child: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          final bool wide = constraints.maxWidth >= 980;
          const Widget controls = _ControlsPanel();
          const Widget log = _CaughtPanel();
          if (wide) {
            return const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Expanded(flex: 5, child: controls),
                SizedBox(width: 20),
                Expanded(flex: 6, child: log),
              ],
            );
          }
          return const Column(
            children: <Widget>[controls, SizedBox(height: 18), log],
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
            Text(
              l10n.guardTriggerTitle,
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 4),
            Text(
              l10n.guardTriggerBody,
              style: const TextStyle(color: Color(0xFF667085), height: 1.35),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: <Widget>[
                _GuardButton(
                  id: 'parse',
                  label: 'Parse "12x" → throws',
                  onRun: () => ParsingService().parseAmount('12x'),
                ),
                _GuardButton(
                  id: 'divide',
                  label: 'Divide by 0 → throws',
                  onRun: () => MathService().safeRatio(10, 0),
                ),
                _GuardButton(
                  id: 'feed',
                  label: 'Flaky feed → throws once',
                  onRun: () => FeedService().latestHeadlines().join(', '),
                ),
                _GuardButton(
                  id: 'parseOk',
                  label: 'Parse "42" → ok',
                  onRun: () => ParsingService().parseAmount('42'),
                ),
              ],
            ),
            const SizedBox(height: 18),
            DecoratedBox(
              decoration: BoxDecoration(
                color: const Color(0xFFFFFBEB),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: ValueListenableBuilder<String>(
                  valueListenable: ExceptionGuardRuntime.instance.lastValue,
                  builder: (BuildContext context, String value, Widget? _) {
                    return Row(
                      children: <Widget>[
                        const Icon(
                          Icons.check_circle_rounded,
                          color: Color(0xFFB45309),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            l10n.guardReturnedValue(value),
                            key: const Key('guard.value'),
                            style: const TextStyle(
                              fontFamily: 'monospace',
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CaughtPanel extends StatelessWidget {
  const _CaughtPanel();

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
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                Text(
                  l10n.guardCaughtTitle,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                OutlinedButton.icon(
                  key: const Key('guard.reset'),
                  onPressed: ExceptionGuardRuntime.instance.reset,
                  icon: const Icon(Icons.refresh_rounded, size: 18),
                  label: Text(l10n.commonReset),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ValueListenableBuilder<List<GuardedError>>(
              valueListenable: ExceptionGuardRuntime.instance.caught,
              builder:
                  (BuildContext context, List<GuardedError> errors, Widget? _) {
                    if (errors.isEmpty) {
                      return const Text(
                        'No failures yet. Trigger one — it will be caught here, not '
                        'thrown to the UI.',
                        style: TextStyle(color: Color(0xFF667085)),
                      );
                    }
                    return Column(
                      children: <Widget>[
                        for (final GuardedError e in errors)
                          _CaughtRow(error: e),
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

class _CaughtRow extends StatelessWidget {
  const _CaughtRow({required this.error});

  final GuardedError error;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF2F2),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              const Icon(
                Icons.shield_rounded,
                color: Color(0xFFB91C1C),
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                error.method,
                style: const TextStyle(
                  fontFamily: 'monospace',
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'threw  ${error.error}',
            style: const TextStyle(
              fontFamily: 'monospace',
              fontSize: 12.5,
              color: Color(0xFF7F1D1D),
            ),
          ),
          Text(
            'fallback  ${error.fallback}',
            style: const TextStyle(
              fontFamily: 'monospace',
              fontSize: 12.5,
              color: Color(0xFF047857),
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _GuardButton extends StatelessWidget {
  const _GuardButton({
    required this.id,
    required this.label,
    required this.onRun,
  });

  final String id;
  final String label;
  final Object? Function() onRun;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final String displayLabel = switch (id) {
      'parse' => l10n.guardParseThrows,
      'divide' => l10n.guardDivideThrows,
      'feed' => l10n.guardFeedThrows,
      'parseOk' => l10n.guardParseOk,
      _ => label,
    };
    return FilledButton.tonal(
      key: Key('guard.$id'),
      onPressed: () {
        // The guard makes this tap safe: onRun calls a throwing method, but the
        // woven advice returns a fallback instead of letting the throw escape.
        final Object? value = onRun();
        ExceptionGuardRuntime.instance.publishValue('$value');
      },
      child: Text(displayLabel),
    );
  }
}
