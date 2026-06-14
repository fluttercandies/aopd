import 'package:example/demos/network_tracing/network_tracing_runtime.dart';
import 'package:example/demos/network_tracing/network_tracing_targets.dart';
import 'package:example/l10n/generated/app_localizations.dart';
import 'package:example/shared/event_log_panel.dart';
import 'package:example/shared/showcase_shell.dart';
import 'package:ff_annotation_route_library/ff_annotation_route_library.dart';
import 'package:flutter/material.dart';

@FFRoute(
  name: 'aopd://network-tracing',
  routeName: 'Network tracing',
  description:
      'Trace API calls with ids, latency, and status without request-code logging.',
  exts: <String, dynamic>{
    'group': 'demo',
    'subgroup': 'observability',
    'order': '5',
    'icon': 'network',
    'color': 'blue',
  },
)
class NetworkTracingPage extends StatelessWidget {
  const NetworkTracingPage({super.key});

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    return ShowcaseShell(
      title: l10n.networkTitle,
      subtitle: l10n.networkSubtitle,
      child: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          final bool wide = constraints.maxWidth >= 980;
          const Widget controls = _NetworkControls();
          const Widget traces = _TracePanel();
          if (wide) {
            return const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Expanded(flex: 5, child: controls),
                SizedBox(width: 20),
                Expanded(flex: 6, child: traces),
              ],
            );
          }
          return const Column(
            children: <Widget>[controls, SizedBox(height: 18), traces],
          );
        },
      ),
    );
  }
}

class _NetworkControls extends StatelessWidget {
  const _NetworkControls();

  static final DemoApiClient _client = DemoApiClient();

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
              l10n.networkRunApiCalls,
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 6),
            Text(
              l10n.networkRunApiCallsBody,
              style: const TextStyle(color: Color(0xFF667085), height: 1.35),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: <Widget>[
                _ApiButton(
                  id: 'order',
                  label: l10n.networkFetchOrder,
                  onRun: () => _client.fetchOrder('A-1042'),
                ),
                _ApiButton(
                  id: 'paymentOk',
                  label: l10n.networkSubmitPayment,
                  onRun: () => _client.submitPayment('A-1042', 2400),
                ),
                _ApiButton(
                  id: 'paymentReview',
                  label: l10n.networkPaymentReview,
                  onRun: () => _client.submitPayment('A-1042', 8800),
                ),
                _ApiButton(
                  id: 'search',
                  label: l10n.networkSearch,
                  onRun: () => _client.searchProducts('kernel'),
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

class _ApiButton extends StatelessWidget {
  const _ApiButton({
    required this.id,
    required this.label,
    required this.onRun,
  });

  final String id;
  final String label;
  final Future<ApiResponse> Function() onRun;

  @override
  Widget build(BuildContext context) {
    return FilledButton.tonalIcon(
      key: Key('network.$id'),
      onPressed: () async {
        final ApiResponse response = await onRun();
        if (context.mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(response.summary)));
        }
      },
      icon: const Icon(Icons.route_rounded),
      label: Text(label),
    );
  }
}

class _TracePanel extends StatelessWidget {
  const _TracePanel();

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
                    l10n.networkTraceRecords,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                OutlinedButton.icon(
                  key: const Key('network.reset'),
                  onPressed: NetworkTracingRuntime.instance.reset,
                  icon: const Icon(Icons.refresh_rounded, size: 18),
                  label: Text(l10n.commonReset),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ValueListenableBuilder<List<NetworkTraceRecord>>(
              valueListenable: NetworkTracingRuntime.instance.traces,
              builder:
                  (BuildContext context, List<NetworkTraceRecord> traces, _) {
                    if (traces.isEmpty) {
                      return Text(
                        l10n.networkTraceEmpty,
                        style: const TextStyle(color: Color(0xFF667085)),
                      );
                    }
                    return Column(
                      children: <Widget>[
                        for (final NetworkTraceRecord trace in traces)
                          _TraceRow(trace: trace),
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

class _TraceRow extends StatelessWidget {
  const _TraceRow({required this.trace});

  final NetworkTraceRecord trace;

  @override
  Widget build(BuildContext context) {
    final Color color = trace.failed
        ? const Color(0xFFB91C1C)
        : const Color(0xFF047857);
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(vertical: 6),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: trace.failed ? const Color(0xFFFEF2F2) : const Color(0xFFECFDF5),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Icon(Icons.route_rounded, color: color, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  trace.traceId,
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Text(
                '${(trace.elapsedMicros / 1000).toStringAsFixed(1)} ms',
                style: TextStyle(color: color, fontWeight: FontWeight.w800),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            trace.operation,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          Text(
            '${trace.statusCode}  ${trace.outcome}',
            style: const TextStyle(fontFamily: 'monospace', fontSize: 12.5),
          ),
        ],
      ),
    );
  }
}
