// Copyright 2026 AOPD contributors. All rights reserved.
// Use of this source code is governed by the MIT license in the LICENSE file.

// The method signatures here mirror upstream `pkg/vm` SDK code which uses the
// raw `DiagnosticReporter` generic. Suppress the workspace-level lint locally
// rather than diverge from the upstream signature.
// ignore_for_file: always_specify_types

import 'package:kernel/ast.dart' show Component, Library;
import 'package:kernel/class_hierarchy.dart' show ClassHierarchy;
import 'package:kernel/core_types.dart' show CoreTypes;
import 'package:kernel/reference_from_index.dart' show ReferenceFromIndex;
import 'package:kernel/target/changed_structure_notifier.dart';
import 'package:kernel/target/targets.dart'
    show DiagnosticReporter, TargetFlags, targets;
import 'package:vm/modular/target/flutter.dart' show FlutterTarget;
import 'package:vm/modular/target/install.dart' show installAdditionalTargets;

import 'aop_transformer.dart';

/// A [FlutterTarget] subclass that wires AOPD transformations into the
/// kernel pipeline without modifying the SDK's pristine `pkg/vm` sources.
///
/// AOP needs two distinct hook points:
///   1. **Pre constant-evaluation**: emit the AOP `aopLocation` widget creator
///      info so the resulting `ConstConstructorInvocation` nodes get folded
///      into `Constant`s by the constant evaluator.
///   2. **Post modular transformations**: run the actual AOP rewriters after
///      annotations have been promoted to `ConstantExpression`s.
///
/// The AOP widget tracker uses a different parameter name
/// (`$creationLocationAopd_...`) and a different field name (`aopLocation`)
/// from the upstream stock tracker (`$creationLocationd_...` / `_location`).
/// Because the two trackers no longer share any kernel-level identifier, they
/// can run on the same constructor without colliding: the stock tracker still
/// powers the DevTools widget inspector, and AOP drives its own runtime.
class AopdFlutterTarget extends FlutterTarget {
  AopdFlutterTarget(super.flags, {this.trackWidgetCreation = false});

  final bool trackWidgetCreation;

  final AopWrapperTransformer _aopTransformer = AopWrapperTransformer();

  @override
  void performPreConstantEvaluationTransformations(
    Component component,
    CoreTypes coreTypes,
    List<Library> libraries,
    DiagnosticReporter diagnosticReporter, {
    void Function(String msg)? logger,
    ChangedStructureNotifier? changedStructureNotifier,
  }) {
    if (trackWidgetCreation) {
      // Phase 1: emit AOP widget creation tracking BEFORE constant evaluation
      // so the ConstConstructorInvocation nodes get folded into Constants.
      _aopTransformer.transformWidgetCreator(component, logger: logger);
    }

    super.performPreConstantEvaluationTransformations(
      component,
      coreTypes,
      libraries,
      diagnosticReporter,
      logger: logger,
      changedStructureNotifier: changedStructureNotifier,
    );
  }

  @override
  void performModularTransformationsOnLibraries(
    Component component,
    CoreTypes coreTypes,
    ClassHierarchy hierarchy,
    List<Library> libraries,
    Map<String, String>? environmentDefines,
    DiagnosticReporter diagnosticReporter,
    ReferenceFromIndex? referenceFromIndex, {
    void Function(String msg)? logger,
    ChangedStructureNotifier? changedStructureNotifier,
  }) {
    super.performModularTransformationsOnLibraries(
      component,
      coreTypes,
      hierarchy,
      libraries,
      environmentDefines,
      diagnosticReporter,
      referenceFromIndex,
      logger: logger,
      changedStructureNotifier: changedStructureNotifier,
    );

    // Phase 2: AOP rewrites must run AFTER constant evaluation so that
    // annotations are stored as ConstantExpression rather than
    // RedirectingFactoryInvocation. Pass coreTypes so SDK helpers (dart:core
    // ==, List/Map []) resolve even under --no-link-platform (#33).
    _aopTransformer.transform(component, coreTypes: coreTypes, logger: logger);
  }
}

/// Replaces `targets['flutter']` with a builder that produces an
/// [AopdFlutterTarget]. Idempotent and safe to call multiple times.
///
/// Must be called BEFORE [FrontendCompiler.compile] resolves the target
/// (i.e. before any code path that runs `createFrontEndTarget('flutter', ...)`).
void installAopdFlutterTarget({bool trackWidgetCreation = false}) {
  // Make sure the upstream targets are installed first; `installAdditionalTargets`
  // is idempotent and registers the vanilla `flutter` builder. We then override
  // it with our AOP-aware builder.
  installAdditionalTargets();
  targets['flutter'] = (TargetFlags flags) =>
      AopdFlutterTarget(flags, trackWidgetCreation: trackWidgetCreation);
}
