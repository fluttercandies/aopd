import 'dart:convert';

import 'package:example/demos/json_model/json_models.dart';
import 'package:example/l10n/generated/app_localizations.dart';
import 'package:example/shared/showcase_shell.dart';
import 'package:ff_annotation_route_library/ff_annotation_route_library.dart';
import 'package:flutter/material.dart';

@FFRoute(
  name: 'aopd://json-model',
  routeName: 'JSON model',
  description:
      'Auto-serialize models with AOP instead of dart:mirrors; toJson has no field code.',
  exts: <String, dynamic>{
    'group': 'demo',
    'subgroup': 'compiler',
    'order': '2',
    'icon': 'json',
    'color': 'teal',
  },
)
class JsonModelPage extends StatelessWidget {
  const JsonModelPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ShowcaseShell(
      title: 'JSON model',
      subtitle:
          'Flutter forbids dart:mirrors, so this weaves toJson at compile time by reading model fields.',
      child: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          final bool wide = constraints.maxWidth >= 980;
          const Widget left = _ModelPanel();
          const Widget right = _JsonPanel();
          if (wide) {
            return const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Expanded(child: left),
                SizedBox(width: 20),
                Expanded(child: right),
              ],
            );
          }
          return const Column(
            children: <Widget>[left, SizedBox(height: 18), right],
          );
        },
      ),
    );
  }
}

class _ModelPanel extends StatelessWidget {
  const _ModelPanel();

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    return _Card(
      title: l10n.jsonModelPanelTitle,
      child: const _Code('''class User implements JsonModel {
  final String name;
  final int age;
  final bool premium;
  final List<String> tags;
  final Address address;

  // stub - the @Execute aspect fills this
  Map<String, dynamic> toJson() => {};
}'''),
    );
  }
}

class _JsonPanel extends StatelessWidget {
  const _JsonPanel();

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final Map<String, dynamic> json = sampleUser.toJson();
    final String pretty = const JsonEncoder.withIndent('  ').convert(json);
    final bool woven = json.isNotEmpty;

    return _Card(
      title: l10n.jsonOutputTitle,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          DecoratedBox(
            decoration: BoxDecoration(
              color: woven ? const Color(0xFFECFDF5) : const Color(0xFFFEF2F2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                children: <Widget>[
                  Icon(
                    woven ? Icons.check_circle_rounded : Icons.error_rounded,
                    size: 18,
                    color: woven
                        ? const Color(0xFF047857)
                        : const Color(0xFFB91C1C),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      woven
                          ? l10n.jsonWovenStatus(json.length)
                          : l10n.jsonUnwovenStatus,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),
          _Code(pretty, key: const Key('json.output')),
          const SizedBox(height: 12),
          Text(
            l10n.jsonNote,
            style: const TextStyle(
              color: Color(0xFF667085),
              height: 1.35,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}

class _Code extends StatelessWidget {
  const _Code(this.code, {super.key});

  final String code;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFF0B1220),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Text(
          code,
          style: const TextStyle(
            color: Color(0xFFE5E7EB),
            height: 1.4,
            fontFamily: 'monospace',
            fontSize: 12.5,
          ),
        ),
      ),
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(28),
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              title,
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 14),
            child,
          ],
        ),
      ),
    );
  }
}
