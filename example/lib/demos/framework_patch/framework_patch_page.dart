import 'package:example/demos/framework_patch/framework_patch_runtime.dart';
import 'package:example/l10n/generated/app_localizations.dart';
import 'package:example/shared/showcase_shell.dart';
import 'package:ff_annotation_route_library/ff_annotation_route_library.dart';
import 'package:flutter/material.dart';

@FFRoute(
  name: 'aopd://framework-patch',
  routeName: 'Framework patch',
  description:
      'Patch a private Flutter SDK method (text scaler) to clamp font scaling without an SDK fork.',
  exts: <String, dynamic>{
    'group': 'demo',
    'subgroup': 'compiler',
    'order': '1',
    'icon': 'patch',
    'color': 'blue',
  },
)
class FrameworkPatchPage extends StatefulWidget {
  const FrameworkPatchPage({super.key});

  @override
  State<FrameworkPatchPage> createState() => _FrameworkPatchPageState();
}

class _FrameworkPatchPageState extends State<FrameworkPatchPage> {
  final FrameworkPatchRuntime _runtime = FrameworkPatchRuntime.instance;
  double _systemScale = 2.4;

  @override
  Widget build(BuildContext context) {
    final TextScaler scaler = TextScaler.linear(_systemScale);
    const double baseFontSize = 16;
    final double effective = scaler.scale(baseFontSize);

    return ShowcaseShell(
      title: 'Framework patch',
      subtitle:
          'Fix the framework without forking it by weaving Flutter text scaling.',
      child: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          final bool wide = constraints.maxWidth >= 980;
          final Widget controls = _controls(effective, baseFontSize);
          final Widget preview = _preview(scaler, baseFontSize);
          if (wide) {
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Expanded(flex: 5, child: controls),
                const SizedBox(width: 20),
                Expanded(flex: 6, child: preview),
              ],
            );
          }
          return Column(
            children: <Widget>[controls, const SizedBox(height: 18), preview],
          );
        },
      ),
    );
  }

  Widget _controls(double effective, double baseFontSize) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(28),
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            SwitchListTile(
              key: const Key('patch.toggle'),
              contentPadding: EdgeInsets.zero,
              title: Text(
                l10n.patchEnableTitle,
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
              subtitle: Text(
                _runtime.enabled
                    ? l10n.patchActiveSubtitle(
                        _runtime.maxScaleFactor.toStringAsFixed(1),
                      )
                    : l10n.patchOffSubtitle,
              ),
              value: _runtime.enabled,
              onChanged: (bool v) => setState(() => _runtime.enabled = v),
            ),
            const Divider(height: 28),
            Text(
              l10n.patchSystemScale(_systemScale.toStringAsFixed(1)),
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            Slider(
              key: const Key('patch.systemScale'),
              min: 1,
              max: 3,
              divisions: 20,
              label: '${_systemScale.toStringAsFixed(1)}x',
              value: _systemScale,
              onChanged: (double v) => setState(() => _systemScale = v),
            ),
            Text(
              l10n.patchCap(_runtime.maxScaleFactor.toStringAsFixed(1)),
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            Slider(
              key: const Key('patch.cap'),
              min: 1,
              max: 2.5,
              divisions: 15,
              label: '${_runtime.maxScaleFactor.toStringAsFixed(1)}x',
              value: _runtime.maxScaleFactor,
              onChanged: (double v) =>
                  setState(() => _runtime.maxScaleFactor = v),
            ),
            const SizedBox(height: 8),
            _ProofTile(
              baseFontSize: baseFontSize,
              effective: effective,
              enabled: _runtime.enabled,
            ),
          ],
        ),
      ),
    );
  }

  Widget _preview(TextScaler scaler, double baseFontSize) {
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
              l10n.patchPreviewTitle,
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
            ),
            const SizedBox(height: 4),
            Text(
              l10n.patchPreviewBody,
              style: const TextStyle(color: Color(0xFF667085), height: 1.35),
            ),
            const SizedBox(height: 18),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Text(
                l10n.patchPreviewText,
                textScaler: scaler,
                style: TextStyle(
                  fontSize: baseFontSize,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            const SizedBox(height: 16),
            _clampSummary(),
          ],
        ),
      ),
    );
  }

  Widget _clampSummary() {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final int count = _runtime.clampCount;
    final ClampEvent? last = _runtime.lastClamp;
    if (count == 0) {
      return Text(
        l10n.patchNoClamps,
        style: const TextStyle(color: Color(0xFF667085)),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          l10n.patchClampsApplied(count),
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        if (last != null) ...<Widget>[
          const SizedBox(height: 8),
          Text(
            'last fontSize ${last.fontSize.toStringAsFixed(0)}: '
            '${last.original.toStringAsFixed(1)} -> '
            '${last.clamped.toStringAsFixed(1)}',
            style: const TextStyle(fontFamily: 'monospace', fontSize: 12.5),
          ),
        ],
      ],
    );
  }
}

class _ProofTile extends StatelessWidget {
  const _ProofTile({
    required this.baseFontSize,
    required this.effective,
    required this.enabled,
  });

  final double baseFontSize;
  final double effective;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: enabled ? const Color(0xFFEFF6FF) : const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              l10n.patchScaleReturned(baseFontSize),
              style: const TextStyle(color: Color(0xFF475569)),
            ),
            const SizedBox(height: 4),
            Text(
              '${effective.toStringAsFixed(1)} px'
              '  (${enabled ? l10n.patchPatched : l10n.patchPureFlutter})',
              key: const Key('patch.effective'),
              style: TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 18,
                color: enabled
                    ? const Color(0xFF1D4ED8)
                    : const Color(0xFF334155),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
