import 'package:example/demos/arg_rewrite/arg_rewrite_runtime.dart';
import 'package:example/demos/arg_rewrite/arg_rewrite_targets.dart';
import 'package:example/l10n/generated/app_localizations.dart';
import 'package:example/shared/showcase_shell.dart';
import 'package:ff_annotation_route_library/ff_annotation_route_library.dart';
import 'package:flutter/material.dart';

@FFRoute(
  name: 'aopd://arg-rewrite',
  routeName: 'Argument rewrite',
  description:
      'Advice rewrites a method’s inputs before it runs — PII redaction and input sanitizing.',
  exts: <String, dynamic>{
    'group': 'demo',
    'subgroup': 'behavior',
    'order': '4',
    'icon': 'rewrite',
    'color': 'blue',
  },
)
class ArgRewritePage extends StatelessWidget {
  const ArgRewritePage({super.key});

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    return ShowcaseShell(
      title: l10n.routeArgumentRewriteTitle,
      subtitle: l10n.routeArgumentRewriteDescription,
      child: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          final bool wide = constraints.maxWidth >= 980;
          const Widget controls = _ControlsPanel();
          const Widget log = _ReceivedPanel();
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
              l10n.argSendDirtyInput,
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 4),
            Text(
              l10n.argSendDirtyInputBody,
              style: const TextStyle(color: Color(0xFF667085), height: 1.35),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: <Widget>[
                FilledButton.tonal(
                  key: const Key('rewrite.log'),
                  onPressed: () => AuditLog().record(
                    'order ok, reach me at 13800001111 or ada@example.com',
                  ),
                  child: Text(l10n.argLogPii),
                ),
                FilledButton.tonal(
                  key: const Key('rewrite.signup'),
                  onPressed: () =>
                      SignupService().register('  ADA@Example.COM ', 200),
                  child: Text(l10n.argRegisterMessy),
                ),
              ],
            ),
            const SizedBox(height: 18),
            const _RewritePanel(),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              key: const Key('rewrite.reset'),
              onPressed: ArgRewriteRuntime.instance.reset,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: Text(l10n.commonReset),
            ),
          ],
        ),
      ),
    );
  }
}

class _RewritePanel extends StatelessWidget {
  const _RewritePanel();

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    return ValueListenableBuilder<List<RewriteEvent>>(
      valueListenable: ArgRewriteRuntime.instance.rewrites,
      builder: (BuildContext context, List<RewriteEvent> events, Widget? _) {
        if (events.isEmpty) {
          return Text(
            l10n.argNoRewrites,
            style: const TextStyle(color: Color(0xFF667085)),
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            for (final RewriteEvent e in events)
              Container(
                margin: const EdgeInsets.symmetric(vertical: 6),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      e.method,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontFamily: 'monospace',
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${l10n.argBefore}  ${e.before}',
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 12.5,
                        color: Color(0xFF9CA3AF),
                      ),
                    ),
                    Text(
                      '${l10n.argAfter}   ${e.after}',
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 12.5,
                        color: Color(0xFF1D4ED8),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        );
      },
    );
  }
}

class _ReceivedPanel extends StatelessWidget {
  const _ReceivedPanel();

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
              l10n.argReceivedTitle,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 4),
            Text(
              l10n.argReceivedBody,
              style: const TextStyle(color: Color(0xFF667085), height: 1.35),
            ),
            const SizedBox(height: 14),
            ValueListenableBuilder<List<String>>(
              valueListenable: ArgRewriteRuntime.instance.received,
              builder: (BuildContext context, List<String> lines, Widget? _) {
                if (lines.isEmpty) {
                  return Text(
                    l10n.argNothingReceived,
                    style: const TextStyle(color: Color(0xFF667085)),
                  );
                }
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    for (final String line in lines)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            const Icon(
                              Icons.south_east_rounded,
                              size: 16,
                              color: Color(0xFF047857),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                line,
                                style: const TextStyle(
                                  fontFamily: 'monospace',
                                  fontSize: 12.5,
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
          ],
        ),
      ),
    );
  }
}
