# AOPD Internals

English | [简体中文](#简体中文)

This document explains the current AOPD compiler mechanism. For the higher-level
architecture, see [Architecture](architecture.md).

## Two Independent Hook Paths

The upstream frontend server has more than one transformation path. AOPD uses
the kernel target path for AOP.

| Path | AOPD role |
| --- | --- |
| `AopdFlutterTarget extends FlutterTarget` | Runs widget location tracking and AOP kernel rewrites. |
| `ProgramTransformer` / `ToStringTransformer` | Kept as upstream frontend-server behavior; not the AOP rewrite path. |

`compiler/frontend_server/server.dart` registers AOP options and delegates the
rest of the frontend-server lifecycle to upstream `starter.dart`. This avoids
copying resident compiler dispatch logic.

## Target Installation

`AopdFrontendCompiler` wraps the upstream `FrontendCompiler`. Before the first
real compile, it calls `installAopdFlutterTarget()`.

That function calls upstream `installAdditionalTargets()` and replaces
`targets['flutter']` with a builder that returns `AopdFlutterTarget`.

The install is idempotent and happens before `createFrontEndTarget('flutter')`
is resolved for the compile.

## Transform Timing

`AopdFlutterTarget` hooks two phases:

1. `performPreConstantEvaluationTransformations`
   - Runs only when `--aop-track-widget-creation 1` is passed.
   - Injects AOPD widget location metadata before constant evaluation.
2. `performModularTransformationsOnLibraries`
   - Runs after upstream VM modular transformations.
   - Applies AOP rewrites after annotations have been evaluated to constants.
   - Receives `CoreTypes`, which AOPD uses for SDK helper lookup.

## Annotation Resolution

The transformer scans reachable libraries for `@Aspect` classes, then scans
members for AOP annotations:

- `@Call`
- `@Execute`
- `@Inject`
- `@Add`
- `@FieldGet`

Each annotation becomes an `AopItemInfo`. `AopItemInfo.tryCreate` validates
mode-specific required fields before a rewriter sees the item.

One advice method may carry only one AOP annotation. Multiple AOP annotations on
one method are rejected with an `[AOPD]` diagnostic.

## Proceed Model

Woven `@Call`, `@Execute`, and `@FieldGet` sites construct a `PointCut` that
carries a `proceedClosure`.

```dart
Object? proceed() {
  final Object? Function(PointCut)? closure = proceedClosure;
  if (closure != null) {
    return closure(this);
  }
  return null;
}
```

This is decentralized: each woven site carries its own original-operation
closure. There is no central `PointCut.proceed()` dispatch table and no generated
`aop_stub_N` branch chain for dispatch.

The closure receives the `PointCut`, so advice can mutate
`positionalParams` / `namedParams` before calling `proceed()`.

## Rewriter Responsibilities

| Mode | Current behavior |
| --- | --- |
| `@Call` | Replaces matching call sites with advice calls. Constructor call sites are supported through `@Call`. |
| `@Execute` | Moves the original method body behind a proceed closure and invokes advice. Constructors are skipped with an unsupported diagnostic. |
| `@Inject` | Clones advice statements and inserts them at the requested source line. |
| `@Add` | Clones an advice method into matched target classes. |
| `@FieldGet` | Replaces field reads with advice calls and passes a real `PointCut`. |

## Safety Model

AOPD treats AOP as an enhancement. If a site cannot be woven safely, it should be
skipped with a diagnostic and the original code should remain valid.

Current guardrails include:

- mode-specific `AopItemInfo` validation;
- invalid regex diagnostics;
- constructor `@Execute` unsupported diagnostics;
- advice form validation for static vs instance advice;
- instance advice constructor checks;
- SDK helper lookup through `CoreTypes`;
- per-item and per-site failure isolation in rewriters where practical;
- cloned parameters/statements instead of moving reusable AST nodes.

## Incremental Compilation

Full builds and first `flutter run` compilation are the supported surface for
0.1.x. Resident incremental compilation remains experimental.

The decentralized `proceedClosure` model removes the old runtime risk where a
stale central proceed table could return `null` for a woven site. Some
incremental invalidation shapes still need dedicated harness coverage before hot
reload can be promoted to a supported product surface.

See [Optimization Backlog](optimization-backlog.md).

---

# 简体中文

[English](#aopd-internals) | 简体中文

本文说明当前 AOPD compiler 机制。更高层的架构说明见 [Architecture](architecture.md)。

## 两条独立 Hook 路径

上游 frontend server 内部有不止一条转换路径。AOPD 使用 kernel target 路径实现 AOP。

| 路径 | AOPD 中的作用 |
| --- | --- |
| `AopdFlutterTarget extends FlutterTarget` | 运行 widget 位置追踪和 AOP kernel 改写。 |
| `ProgramTransformer` / `ToStringTransformer` | 保留上游 frontend-server 行为；不是 AOP 改写路径。 |

`compiler/frontend_server/server.dart` 注册 AOP 参数，然后把其余 frontend-server 生命周期交给
上游 `starter.dart`。这样无需复制 resident compiler 的分发逻辑。

## Target 安装

`AopdFrontendCompiler` 包裹上游 `FrontendCompiler`。在第一次真正 compile 之前，它会调用
`installAopdFlutterTarget()`。

该函数先调用上游 `installAdditionalTargets()`，再用返回 `AopdFlutterTarget` 的 builder
替换 `targets['flutter']`。

安装过程是幂等的，并且发生在本次 compile 解析 `createFrontEndTarget('flutter')` 之前。

## 转换时机

`AopdFlutterTarget` 接入两个阶段：

1. `performPreConstantEvaluationTransformations`
   - 仅当传入 `--aop-track-widget-creation 1` 时运行。
   - 在常量求值前注入 AOPD widget 位置元数据。
2. `performModularTransformationsOnLibraries`
   - 在上游 VM modular transformations 之后运行。
   - 在注解已经被求值为常量后执行 AOP 改写。
   - 接收 `CoreTypes`，AOPD 用它查找 SDK helper。

## 注解解析

Transformer 扫描 reachable library 中的 `@Aspect` class，再扫描成员上的 AOP 注解：

- `@Call`
- `@Execute`
- `@Inject`
- `@Add`
- `@FieldGet`

每个注解会变成一个 `AopItemInfo`。`AopItemInfo.tryCreate` 会在 item 进入 rewriter 前校验各
mode 必需字段。

一个 advice 方法只能携带一个 AOP 注解。同一方法上多个 AOP 注解会被拒绝，并输出 `[AOPD]`
诊断。

## Proceed 模型

织入后的 `@Call`、`@Execute`、`@FieldGet` 位置会构造带有 `proceedClosure` 的
`PointCut`。

```dart
Object? proceed() {
  final Object? Function(PointCut)? closure = proceedClosure;
  if (closure != null) {
    return closure(this);
  }
  return null;
}
```

这是去中心化模型：每个织入点都携带自己的原始操作闭包。不存在中心化
`PointCut.proceed()` 分发表，也不再生成用于分发的 `aop_stub_N` 分支链。

闭包接收 `PointCut`，因此 advice 可以在调用 `proceed()` 前修改
`positionalParams` / `namedParams`。

## Rewriter 职责

| Mode | 当前行为 |
| --- | --- |
| `@Call` | 将匹配调用点替换为 advice 调用。构造函数调用点可通过 `@Call` 支持。 |
| `@Execute` | 将原方法体移到 proceed closure 后面并调用 advice。构造函数会输出 unsupported 诊断并跳过。 |
| `@Inject` | 克隆 advice 语句，并插入到请求的源码行。 |
| `@Add` | 将 advice 方法克隆到匹配的目标类。 |
| `@FieldGet` | 将字段读取替换为 advice 调用，并传入真实 `PointCut`。 |

## 安全模型

AOPD 把 AOP 视为增强能力。如果某个位置不能安全织入，应跳过该位置、输出诊断，并保持原始代码
合法。

当前护栏包括：

- mode-specific `AopItemInfo` 校验；
- 非法 regex 诊断；
- constructor `@Execute` unsupported 诊断；
- static / instance advice 形态校验；
- instance advice 构造函数校验；
- 通过 `CoreTypes` 查找 SDK helper；
- rewriter 中尽量进行 per-item / per-site 失败隔离；
- 克隆参数和语句，避免移动可复用 AST 节点。

## 增量编译

0.1.x 正式支持全量 build 和首次 `flutter run` 编译。Resident 增量编译仍是实验能力。

去中心化 `proceedClosure` 模型移除了旧的运行期风险：陈旧中心 proceed 表导致某个织入点返回
`null`。但部分增量 invalidation 形态仍需要专门 harness 覆盖，才能把 hot reload 提升为正式
支持面。

详见 [剩余优化项](optimization-backlog.md)。
