// Copyright 2026 AOPD contributors. All rights reserved.
// Use of this source code is governed by the MIT license in the LICENSE file.

import 'package:kernel/ast.dart';
import 'package:kernel/clone.dart';

import 'aop_item_info.dart';
import 'aop_transform_utils.dart';

class AopStatementsInsertInfo {
  AopStatementsInsertInfo({
    required this.library,
    this.source,
    this.constructor,
    this.procedure,
    this.node,
    this.aopItemInfo,
    this.aopInsertStatements,
  });

  final Library library;
  final Source? source;
  final Constructor? constructor;
  final Procedure? procedure;
  final Node? node;
  final AopItemInfo? aopItemInfo;
  final List<Statement>? aopInsertStatements;
}

class AopInjectImplTransformer extends Transformer {
  AopInjectImplTransformer(
    this._aopItemInfoList,
    this._libraryMap,
    this._uriToSource,
  );

  late final List<AopItemInfo> _aopItemInfoList;
  late final Map<String, Library> _libraryMap;
  late final Map<Uri, Source> _uriToSource;
  final Set<VariableDeclaration> _mockedVariableDeclaration =
      <VariableDeclaration>{};
  final Map<String, VariableDeclaration> _originalVariableDeclaration =
      <String, VariableDeclaration>{};
  // A2 (#15): same-inject-point items folded by [mergeTransform]. Keyed by the
  // SURVIVING item; the value lists its merged siblings (newest-first, matching
  // the previous front-insertion order). onPrepareTransform clones each
  // sibling's advice in turn -- no advice body is mutated.
  final Map<AopItemInfo, List<AopItemInfo>> _mergedSiblings =
      <AopItemInfo, List<AopItemInfo>>{};
  late Class _curClass;
  late Node _curMethodNode;
  Library? _curAopLibrary;
  AopStatementsInsertInfo? _curAopStatementsInsertInfo;

  @override
  VariableDeclaration visitVariableDeclaration(VariableDeclaration node) {
    node.transformChildren(this);
    // Kernel produces unnamed synthetic VariableDeclarations (async/await and
    // for-loop desugaring temporaries, let-binders). They are never //AOPD
    // Ignore mock-var targets, so skip them -- `node.name!` would throw and
    // abort the whole inject item on any method containing such temps.
    final String? name = node.name;
    if (name != null) {
      _originalVariableDeclaration.putIfAbsent(name, () => node);
    }
    return node;
  }

  @override
  VariableGet visitVariableGet(VariableGet node) {
    node.transformChildren(this);
    if (_mockedVariableDeclaration.contains(node.variable)) {
      final VariableGet variableGet = VariableGet(
        _originalVariableDeclaration[node.variable.name]!,
      );
      return variableGet;
    }
    return node;
  }

  @override
  InstanceGet visitInstanceGet(InstanceGet node) {
    node.transformChildren(this);

    // final Reference reference = node.interfaceTargetReference;

    // if (reference == null) {
    //   return node;
    // }

    final Node? interfaceTargetNode = node.interfaceTargetReference.node;
    if (_curAopLibrary != null) {
      if (interfaceTargetNode is Field) {
        if (interfaceTargetNode.fileUri == _curAopLibrary!.fileUri) {
          if (node.receiver is ThisExpression) {
            final Class cls = _curClass;
            final Field? field = AopUtils.findFieldForClassWithName(
              cls,
              node.name.text,
            );
            if (field == null) {
              // #2: advice references a field the target class does not have.
              // Degrade with a diagnostic instead of `null!`.
              AopUtils.diagnostics?.warning(
                null,
                'inject advice references field "${node.name.text}" not found '
                'in target class "${cls.name}"; leaving it unremapped.',
              );
              return node;
            }

            final ThisExpression thisE = ThisExpression();

            final InstanceGet instanceGet = InstanceGet(
              InstanceAccessKind.Instance,
              thisE,
              Name(field.name.text, _curClass.parent as Library),
              interfaceTarget: field,
              resultType: field.type,
            );

            return instanceGet;
          } else {
            // Resolve the receiver variable's name from the AST directly. This
            // used to be parsed out of node.toString() (fragile to kernel's
            // debug-string format, and it broke on file paths containing dots).
            // Only a VariableGet receiver can map to a target variable by name.
            final Expression receiver = node.receiver;
            final String? firstEle = receiver is VariableGet
                ? receiver.variable.name
                : null;
            final VariableDeclaration? variableDeclaration = firstEle == null
                ? null
                : _originalVariableDeclaration[firstEle];

            if (variableDeclaration == null) {
              return node;
            }
            if (variableDeclaration.type is InterfaceType) {
              final Class cls = _curClass;
              final Field? field = AopUtils.findFieldForClassWithName(
                cls,
                node.name.text,
              );
              if (field == null) {
                // #2: degrade instead of `null!` when the target lacks the field.
                AopUtils.diagnostics?.warning(
                  null,
                  'inject advice references field "${node.name.text}" not '
                  'found in target class "${cls.name}"; leaving it '
                  'unremapped.',
                );
                return node;
              }
              final InstanceGet instanceGet = InstanceGet(
                InstanceAccessKind.Instance,
                node.receiver,
                field.name,
                interfaceTarget: node.interfaceTarget,
                resultType: node.resultType,
              );
              return instanceGet;
            }
          }
        }
      }
    }
    return node;
  }

  @override
  FunctionExpression visitFunctionExpression(FunctionExpression node) {
    node.transformChildren(this);
    checkIfInsertInFunction(node.function);
    return node;
  }

  @override
  FunctionDeclaration visitFunctionDeclaration(FunctionDeclaration node) {
    node.transformChildren(this);
    checkIfInsertInFunction(node.function);
    return node;
  }

  @override
  InstanceSet visitInstanceSet(InstanceSet node) {
    node.transformChildren(this);

    if (node.receiver is! ThisExpression) {
      return node;
    }

    final String text = node.name.text;
    Field? exchangeField;
    for (Field field in _curClass.fields) {
      if (field.name.text == text) {
        exchangeField = field;
        break;
      }
    }

    if (exchangeField != null) {
      final ThisExpression thisE = ThisExpression();

      // final InstanceGet property = InstanceGet(InstanceAccessKind.Instance,
      //     thisE, Name(exchangeField.name.text, _curClass.parent as Library),
      //     interfaceTarget: exchangeField, resultType: exchangeField.type);

      final InstanceSet newSet = InstanceSet(
        node.kind,
        thisE,
        exchangeField.name,
        node.value,
        interfaceTarget: exchangeField,
      );
      return newSet;
    }

    return node;
  }

  @override
  FunctionNode visitFunctionNode(FunctionNode node) {
    node.transformChildren(this);
    checkIfInsertInFunction(node);
    return node;
  }

  @override
  Block visitBlock(Block node) {
    node.transformChildren(this);
    if (_curAopStatementsInsertInfo != null) {
      final Library library = _curAopStatementsInsertInfo!.library;
      final Source source = _curAopStatementsInsertInfo!.source!;
      final AopItemInfo aopItemInfo = _curAopStatementsInsertInfo!.aopItemInfo!;
      final List<Statement> aopInsertStatements =
          _curAopStatementsInsertInfo!.aopInsertStatements!;
      insertStatementsToBody(
        library,
        source,
        node,
        aopItemInfo,
        aopInsertStatements,
      );
    }
    return node;
  }

  void aopTransform() {
    // Crash-safety: @Inject requires lineNum. Drop items without it up front so
    // sortTransform's `lineNum!` comparison cannot throw, and so one bad item is
    // skipped (with a diagnostic) instead of aborting every inject.
    _aopItemInfoList.removeWhere((AopItemInfo item) {
      if (!item.hasLineNum) {
        AopUtils.diagnostics?.error(
          item,
          '@Inject requires lineNum; skipping this aspect item.',
        );
        return true;
      }
      return false;
    });

    //Inject from the beginning of the file to the end
    sortTransform();

    //Merge aop items that inject in the same line.
    mergeTransform();

    for (AopItemInfo aopItemInfo in _aopItemInfoList) {
      try {
        _transformInjectItem(aopItemInfo);
      } catch (e, st) {
        // Per-item isolation (P1b): a failing inject must neither abort the
        // other inject items nor kill the build (degrade but loud).
        AopUtils.diagnostics?.error(
          aopItemInfo,
          'inject weave failed: $e\n$st',
        );
      }
    }
  }

  void _transformInjectItem(AopItemInfo aopItemInfo) {
    final Library? aopAnnoLibrary = _libraryMap[aopItemInfo.importUri];
    final String clsName = aopItemInfo.clsName;
    if (aopAnnoLibrary == null) {
      // A missing target library is not fatal: skip just this item.
      AopUtils.diagnostics?.warning(
        aopItemInfo,
        'inject target library not found; skipping.',
      );
      return;
    }
    // Transform class static methods and instance methods.
    if (clsName.isNotEmpty) {
      Class expectedCls;
      for (Class cls in aopAnnoLibrary.classes) {
        if (cls.name == aopItemInfo.clsName) {
          expectedCls = cls;
          final String methodName = aopItemInfo.requiredMethodName;
          final bool isStatic = aopItemInfo.requiredIsStatic;
          //Check Constructors
          if (methodName == aopItemInfo.clsName ||
              methodName.startsWith('${aopItemInfo.clsName}.')) {
            for (Constructor constructor in cls.constructors) {
              if (cls.name +
                          (constructor.name.text == ''
                              ? ''
                              : '.${constructor.name.text}') ==
                      methodName &&
                  isStatic) {
                _curClass = expectedCls;
                transformConstructor(
                  aopAnnoLibrary,
                  _uriToSource[aopAnnoLibrary.fileUri]!,
                  constructor,
                  aopItemInfo,
                );
              }
            }
          }
          //Check Procedures
          for (Procedure procedure in cls.procedures) {
            if (procedure.name.text == methodName &&
                procedure.isStatic == isStatic) {
              _curClass = expectedCls;
              transformMethodProcedure(
                aopAnnoLibrary,
                _uriToSource[aopAnnoLibrary.fileUri]!,
                procedure,
                aopItemInfo,
              );
            }
          }
          break;
        }
      }
      // (M3.2) The explicit loop over aopAnnoLibrary.classes above already
      // handles the annotation's target (importUri + clsName). A previous
      // `_libraryMap.forEach` scanned EVERY library for a same-named
      // class+method and injected there too -- wrong (it ignored importUri)
      // and only "safe" because onPostTransform's clear() emptied the advice
      // body so the second pass no-op'd. Removed: inject now strictly targets
      // the annotated library, and clear() no longer masks a double scan.
    } else {
      final String methodName = aopItemInfo.requiredMethodName;
      final bool isStatic = aopItemInfo.requiredIsStatic;
      for (Procedure procedure in aopAnnoLibrary.procedures) {
        if (procedure.name.text == methodName &&
            procedure.isStatic == isStatic) {
          transformMethodProcedure(
            aopAnnoLibrary,
            _uriToSource[aopAnnoLibrary.fileUri]!,
            procedure,
            aopItemInfo,
          );
        }
      }
    }
  }

  void transformMethodProcedure(
    Library library,
    Source source,
    Procedure procedure,
    AopItemInfo aopItemInfo,
  ) {
    // onPostTransform MUST run even if insertion/remap throws: it clears the
    // mock-var maps and _curAopLibrary. Without finally, a throw here (caught by
    // the per-item guard in aopTransform) would leak those into the next inject
    // item's remap -- a cross-item state leak that breaks per-item isolation.
    try {
      final List<Statement> aopInsertStatements = onPrepareTransform(
        library,
        procedure,
        aopItemInfo,
      );
      if (procedure.function.body is Block && aopInsertStatements.isNotEmpty) {
        _curMethodNode = procedure;
        insertStatementsToBody(
          library,
          source,
          procedure.function,
          aopItemInfo,
          aopInsertStatements,
        );
      }
    } finally {
      onPostTransform(aopItemInfo);
    }
  }

  void transformConstructor(
    Library library,
    Source source,
    Constructor constructor,
    AopItemInfo aopItemInfo,
  ) {
    // Mirror transformMethodProcedure: onPostTransform in finally so a throw
    // cannot leak the mock-var maps / _curAopLibrary into the next inject item.
    try {
      _transformConstructorBody(library, source, constructor, aopItemInfo);
    } finally {
      onPostTransform(aopItemInfo);
    }
  }

  void _transformConstructorBody(
    Library library,
    Source source,
    Constructor constructor,
    AopItemInfo aopItemInfo,
  ) {
    final List<Statement> aopInsertStatements = onPrepareTransform(
      library,
      constructor,
      aopItemInfo,
    );

    // #3: const / redirecting / external constructors have no body. Degrade with
    // a diagnostic instead of `null!` (which would throw -- caught by the
    // per-item guard, but only after onPrepareTransform populated shared maps).
    final Statement? body = constructor.function.body;
    if (body == null) {
      AopUtils.diagnostics?.unsupported(
        aopItemInfo,
        'inject target constructor "${constructor.name.text}" has no body '
        '(const/redirecting/external); unsupported, skipping this aspect item.',
      );
      return;
    }
    bool canBeInitializers = true;
    for (Statement statement in aopInsertStatements) {
      if (statement is! AssertStatement) {
        canBeInitializers = false;
      }
    }
    //Insert in body part
    if (!canBeInitializers ||
        ((body is Block) &&
            body.statements.isNotEmpty &&
            aopItemInfo.requiredLineNum >=
                AopUtils.getLineStartNumForStatement(
                  source,
                  body.statements.first,
                )) ||
        (constructor.initializers.isNotEmpty &&
            aopItemInfo.requiredLineNum >
                AopUtils.getLineStartNumForInitializer(
                  source,
                  constructor.initializers.last,
                ))) {
      _curMethodNode = constructor;
      insertStatementsToBody(
        library,
        source,
        constructor.function,
        aopItemInfo,
        aopInsertStatements,
      );
    }
    //Insert in Initializers
    else {
      final int len = constructor.initializers.length;
      for (int i = 0; i < len; i++) {
        final Initializer initializer = constructor.initializers[i];
        final int lineStart = AopUtils.getLineStartNumForInitializer(
          source,
          initializer,
        );
        if (lineStart == -1) {
          continue;
        }
        int lineEnds = -1;
        if (i == len - 1) {
          lineEnds =
              AopUtils.getLineNumBySourceAndOffset(
                source,
                constructor.function.fileEndOffset,
              ) -
              1;
        } else {
          lineEnds =
              AopUtils.getLineStartNumForInitializer(
                source,
                constructor.initializers[i + 1],
              ) -
              1;
        }
        final int lineNum2Insert = aopItemInfo.requiredLineNum;
        if (lineNum2Insert > lineStart && lineNum2Insert <= lineEnds) {
          // Inject point falls inside an initializer's line range -- an
          // unsupported position. Degrade with a diagnostic instead of
          // asserting (which throws under --enable-asserts).
          AopUtils.diagnostics?.unsupported(
            aopItemInfo,
            'inject lineNum falls inside a constructor initializer range; '
            'unsupported position, skipping this aspect item.',
          );
          break;
        } else {
          int statement2InsertPos = -1;
          if (lineNum2Insert <= lineStart) {
            statement2InsertPos = i;
          } else if (lineNum2Insert > lineEnds && i == len - 1) {
            statement2InsertPos = len;
          }
          if (statement2InsertPos != -1) {
            final List<Initializer> tmpInitializers = <Initializer>[];
            for (Statement statement in aopInsertStatements) {
              if (statement is AssertStatement) {
                tmpInitializers.add(AssertInitializer(statement));
              }
            }
            constructor.initializers.insertAll(
              statement2InsertPos,
              tmpInitializers,
            );
          }
        }
      }
    }
    visitConstructor(constructor);
  }

  List<Statement> onPrepareTransform(
    Library library,
    Node methodNode,
    AopItemInfo aopItemInfo,
  ) {
    // Record the TARGET method's params once, so mock (//AOPD Ignore) variables
    // can be remapped to them by name.
    _recordOriginalVariables(methodNode);

    // Clone each merged sibling's advice first (preserving the previous
    // front-insertion order: newest-first), then this item's own advice. None
    // of the advice bodies are mutated -- A2 (#15) replaces the old
    // move-into-lastInfo + clear() with per-advice cloning.
    final List<Statement> tmpStatements = <Statement>[];
    for (final AopItemInfo sibling
        in _mergedSiblings[aopItemInfo] ?? const <AopItemInfo>[]) {
      _collectClonedAdviceStatements(library, sibling, tmpStatements);
    }
    _collectClonedAdviceStatements(library, aopItemInfo, tmpStatements);
    return tmpStatements;
  }

  /// Clones [aopItemInfo]'s advice statements into [into] (and registers any
  /// `//AOPD Ignore` mock vars), without mutating the advice body. One cloner
  /// per advice keeps the mock-var / local-var clone mappings consistent.
  void _collectClonedAdviceStatements(
    Library library,
    AopItemInfo aopItemInfo,
    List<Statement> into,
  ) {
    final Procedure advice = aopItemInfo.requiredAdviceProcedure;
    final Statement? adviceBody = advice.function.body;
    if (adviceBody is! Block) {
      // Aspect advice with a non-block body (e.g. `=> expr`) has no statements
      // to inject. Degrade: nothing to inject for this item.
      AopUtils.diagnostics?.unsupported(
        aopItemInfo,
        'inject aspect method has no block body; nothing to inject.',
      );
      return;
    }
    final Block block2Insert = adviceBody;
    final Library aopLibrary = aopItemInfo.adviceLibrary;
    final CloneVisitorNotMembers cloner = CloneVisitorNotMembers();
    final FunctionNode adviceFn = advice.function;
    // Preserve prior behavior for any reference to the advice's OWN params:
    // map them to themselves (the body is no longer cleared, so this shares no
    // more than the previous move did) and avoid a missing-clone failure.
    for (final VariableDeclaration p in <VariableDeclaration>[
      ...adviceFn.positionalParameters,
      ...adviceFn.namedParameters,
    ]) {
      cloner.setVariableClone(p, p);
    }
    final int adviceOffset = advice.fileOffset;
    for (Statement statement in block2Insert.statements) {
      final VariableDeclaration? variableDeclaration =
          AopUtils.checkIfSkipableVarDeclaration(
            _uriToSource[aopLibrary.fileUri]!,
            statement,
          );

      if (variableDeclaration != null) {
        // Skipped (//AOPD Ignore) mock var: clone+register it so the cloned kept
        // statements resolve their references to this node, which visitVariableGet
        // then remaps by name to the target's variable. The clone is not inserted.
        final VariableDeclaration mockClone = cloner.clone(variableDeclaration);
        _mockedVariableDeclaration.add(mockClone);
      } else {
        final Statement cloned = cloner.clone(statement);
        // Cloning a bare statement loses file offsets (no active file uri);
        // backfill to the advice member so the verifier accepts the injected code.
        AopUtils.setMissingFileOffsets(cloned, adviceOffset);
        into.add(cloned);
      }
    }
    for (LibraryDependency libraryDependency in aopLibrary.dependencies) {
      AopUtils.insertLibraryDependency(
        library,
        libraryDependency.importedLibraryReference.node as Library,
      );
    }
  }

  void _recordOriginalVariables(Node methodNode) {
    if (methodNode is Procedure) {
      for (VariableDeclaration variableDeclaration
          in methodNode.function.namedParameters) {
        _originalVariableDeclaration.putIfAbsent(
          variableDeclaration.name!,
          () => variableDeclaration,
        );
      }
      for (VariableDeclaration variableDeclaration
          in methodNode.function.positionalParameters) {
        _originalVariableDeclaration.putIfAbsent(
          variableDeclaration.name!,
          () => variableDeclaration,
        );
      }
    } else if (methodNode is Constructor) {
      for (VariableDeclaration variableDeclaration
          in methodNode.function.namedParameters) {
        _originalVariableDeclaration.putIfAbsent(
          variableDeclaration.name!,
          () => variableDeclaration,
        );
      }
      for (VariableDeclaration variableDeclaration
          in methodNode.function.positionalParameters) {
        _originalVariableDeclaration.putIfAbsent(
          variableDeclaration.name!,
          () => variableDeclaration,
        );
      }
    }
  }

  void onPostTransform(AopItemInfo aopItemInfo) {
    // A2 (#15): do NOT clear the advice body anymore. Statements are cloned in
    // onPrepareTransform, so the advice stays intact and reusable (multi-target /
    // incremental). The double-scan that clear() once masked was removed (M3.2),
    // so clearing is no longer needed for correctness either.
    _mockedVariableDeclaration.clear();
    _originalVariableDeclaration.clear();
    _curAopLibrary = null;
  }

  void sortTransform() {
    _aopItemInfoList.sort((a, b) => a.importUri.compareTo(b.importUri));
    _aopItemInfoList.sort(
      (a, b) => a.requiredLineNum.compareTo(b.requiredLineNum),
    );
  }

  void mergeTransform() {
    AopItemInfo? lastInfo;

    final List<AopItemInfo> removeList = [];

    for (AopItemInfo item in _aopItemInfoList) {
      if (lastInfo == null) {
        lastInfo = item;
        continue;
      }

      if (lastInfo.importUri == item.importUri &&
          lastInfo.clsName == item.clsName &&
          lastInfo.requiredLineNum == item.requiredLineNum) {
        // Same inject point: fold `item` into `lastInfo` WITHOUT mutating any
        // advice body (A2 #15). Previously this did
        // `lastStatements.insertAll(0, item.statements)`, moving item's nodes
        // into lastInfo's advice body (corrupting it for reuse / incremental).
        // Now we just record the sibling; onPrepareTransform clones each one.
        // insert(0, ...) preserves the old newest-first ordering.
        (_mergedSiblings[lastInfo] ??= <AopItemInfo>[]).insert(0, item);
        removeList.add(item);
      } else {
        lastInfo = item;
      }
    }
    for (var item in removeList) {
      _aopItemInfoList.remove(item);
    }
  }

  void checkIfInsertInFunction(FunctionNode functionNode) {
    if (_curAopStatementsInsertInfo != null) {
      final int lineFrom = AopUtils.getLineNumBySourceAndOffset(
        _curAopStatementsInsertInfo!.source!,
        functionNode.fileOffset,
      );
      final int lineTo = AopUtils.getLineNumBySourceAndOffset(
        _curAopStatementsInsertInfo!.source!,
        functionNode.fileEndOffset,
      );
      final int expectedLineNum =
          _curAopStatementsInsertInfo!.aopItemInfo!.requiredLineNum;
      if (expectedLineNum >= lineFrom && expectedLineNum <= lineTo) {
        final Library library = _curAopStatementsInsertInfo!.library;
        final Source source = _curAopStatementsInsertInfo!.source!;
        final AopItemInfo aopItemInfo =
            _curAopStatementsInsertInfo!.aopItemInfo!;
        final List<Statement> aopInsertStatements =
            _curAopStatementsInsertInfo!.aopInsertStatements!;
        _curAopStatementsInsertInfo = null;
        functionNode.body = insertStatementsToBody(
          library,
          source,
          functionNode,
          aopItemInfo,
          aopInsertStatements,
        );
      }
    }
  }

  Statement insertStatementsToBody(
    Library library,
    Source source,
    Node node,
    AopItemInfo aopItemInfo,
    List<Statement> aopInsertStatements,
  ) {
    late Statement body;
    if (node is FunctionNode) {
      body = node.body!;
      if (body is EmptyStatement) {
        final List<Statement> statements = <Statement>[body];
        body = Block(statements);
        node.body = body;
      }
    } else if (node is Block) {
      body = node;
    }
    if (body is TryCatch && body.fileOffset == -1) {
      final TryCatch tryCatch = body;
      body = tryCatch.body;
    }
    if (body is Block) {
      final List<Statement> statements = body.statements;
      final int len = statements.length;
      for (int i = 0; i < len; i++) {
        final Statement statement = statements[i];
        final Node? nodeToVisitRecursively = AopUtils.getNodeToVisitRecursively(
          statement,
        );
        int lineStart = AopUtils.getLineStartNumForStatement(source, statement);
        int lineEnds = -1;
        final int lineNum2Insert = aopItemInfo.requiredLineNum;
        int statement2InsertPos = -1;
        if (i != len - 1) {
          lineEnds =
              AopUtils.getLineStartNumForStatement(source, statements[i + 1]) -
              1;
        }
        if (lineStart < 0 || lineEnds < 0) {
          if (node is FunctionNode) {
            if (lineStart < 0) {
              lineStart = AopUtils.getLineNumBySourceAndOffset(
                source,
                node.fileOffset,
              );
            }
            if (lineEnds < 0 && !AopUtils.isAsyncFunctionNode(node)) {
              lineEnds =
                  AopUtils.getLineNumBySourceAndOffset(
                    source,
                    node.fileEndOffset,
                  ) -
                  1;
            }
          } else if (node is Block) {
            if (_curMethodNode is Procedure) {
              final Procedure procedure = _curMethodNode as Procedure;
              if (AopUtils.isAsyncFunctionNode(procedure.function) &&
                  procedure ==
                      body
                          .parent
                          ?.parent
                          ?.parent
                          ?.parent
                          ?.parent
                          ?.parent
                          ?.parent
                          ?.parent) {
                if (lineEnds < 0 && i == len - 1) {
                  lineEnds = lineNum2Insert;
                }
              } else {
                if (node.parent is FunctionNode) {
                  final FunctionNode functionNode =
                      node.parent! as FunctionNode;
                  if (lineStart < 0) {
                    lineStart = AopUtils.getLineNumBySourceAndOffset(
                      source,
                      functionNode.fileOffset,
                    );
                  }
                  if (lineEnds < 0) {
                    lineEnds = AopUtils.getLineNumBySourceAndOffset(
                      source,
                      functionNode.fileEndOffset,
                    );
                  }
                }
              }
            }
          }
        }

        if ((lineNum2Insert >= lineStart && lineNum2Insert < lineEnds) ||
            (lineEnds < lineStart && lineEnds != -1) ||
            lineStart == -1) {
          if (nodeToVisitRecursively != null) {
            _curAopStatementsInsertInfo = AopStatementsInsertInfo(
              library: library,
              source: source,
              constructor: null,
              procedure: null,
              node: nodeToVisitRecursively,
              aopItemInfo: aopItemInfo,
              aopInsertStatements: aopInsertStatements,
            );
            visitNode(nodeToVisitRecursively);

            continue;
          }
        }
        if (lineNum2Insert == lineStart - 1 || lineNum2Insert == lineStart) {
          statement2InsertPos = i;
        } else if (lineEnds != -1 && lineNum2Insert == lineEnds + 1) {
          statement2InsertPos = i + 1;
        } else if (lineNum2Insert >= lineEnds && i == len - 1) {
          statement2InsertPos = len;
        }
        if (statement2InsertPos != -1) {
          _curAopStatementsInsertInfo = null;

          statements.insertAll(statement2InsertPos, aopInsertStatements);
          _curAopLibrary = aopItemInfo.adviceLibrary;
          visitNode(node);
          break;
        }
      }
    } else {
      // Target function body is not a Block (e.g. an abstract/external method
      // or `=> expr`). Nothing to insert into; degrade with a diagnostic
      // instead of asserting (which throws under --enable-asserts).
      AopUtils.diagnostics?.unsupported(
        aopItemInfo,
        'inject target function has no block body; cannot insert, '
        'skipping this aspect item.',
      );
    }
    return body;
  }

  void visitNode(Object node) {
    if (node is Constructor) {
      visitConstructor(node);
    } else if (node is Procedure) {
      visitProcedure(node);
    } else if (node is LabeledStatement) {
      visitLabeledStatement(node);
    } else if (node is FunctionNode) {
      visitFunctionNode(node);
    } else if (node is Block) {
      visitBlock(node);
    }
  }
}
