# Troubleshooting

English | [简体中文](#简体中文)

AOPD diagnostics are printed with an `[AOPD]` prefix by the frontend server.

## Aspect Does Not Take Effect

### Aspect Library Is Not Reachable

AOPD only weaves libraries that enter the kernel component. Import the aspect
library from reachable app code. A common pattern is a barrel file such as:

```dart
// lib/aop/aspects/aspects.dart
export 'analytics_aspect.dart';
export 'coverage_aspect.dart';
```

Then import the barrel from the app entrypoint.

### App Is Using The Stock Frontend Server

Check the build log for:

```text
[AOPD] Using frontend_server snapshot: <path>
```

If it is missing, confirm:

- the Flutter SDK has `flutter_tools.patch` applied;
- the app has `aopd.enabled: true`;
- `flutter pub get` has generated `.dart_tool/package_config.json`.

### Target Strings Do Not Match

Unless `isRegex: true` is used, `importUri`, `clsName`, `methodName`, and
`fieldName` must match exactly.

Method name prefixes:

- `-methodName`: instance method.
- `+methodName`: static or top-level function.

Regex pointcuts use partial matching (`hasMatch`). Use `^...$` when exact
matching is required.

## Common Diagnostics

| Diagnostic | Meaning | Fix |
| --- | --- | --- |
| `invalid regex pattern` | A regex pointcut cannot compile. | Fix the regex. |
| `constructor @Execute is not supported` | `@Execute` does not support constructors in 0.1.x. | Use `@Call` on constructor call sites. |
| `@Inject requires lineNum` | `@Inject` needs an explicit source line. | Provide `lineNum`. |
| `inject target library not found` | The target library is not in the component. | Check URI and reachability. |
| `instance @Call target could not be resolved` | The call target is unresolved at that site. | Prefer precise targets or skip that site. |
| `multiple AOP annotations` | One advice method has more than one AOP annotation. | Split each annotation into its own method. |
| `SDK helpers not found` | Core SDK helper lookup failed. | Check build mode and report if reproducible. |

These diagnostics usually mean that a site was skipped while the original code
was kept. Snapshot preparation failures are different: they fail fast because a
silent fallback would make users think AOP is active.

## Known Limits

- Full builds and first `flutter run` compilation are the supported path for
  0.1.x. Hot reload / resident incremental compilation remains experimental.
- Generic methods can be woven, but type parameters are erased to `dynamic`.
- `@Execute` does not support constructors.
- `@Inject` matches exact `importUri` / `clsName` / `methodName` only.
- Multiple exact-target `@Call` or `@FieldGet` aspects use last-wins behavior.
  `@Execute` can stack. Same-name `@Add` keeps the first match.

## Snapshot Lock

`[AOPD] Waiting for snapshot generation lock...` means another build is creating
the app-local snapshot. It should continue automatically.

If the lock is stale, stop lingering Dart processes and rebuild. On Windows,
Task Manager or `taskkill` can be used for stuck `dart.exe` /
`dartaotruntime.exe` processes.

## Stale Compiler Changes

If you edited `compiler/` but the app behaves as if nothing changed, clean the
example first:

```shell
cd example
flutter clean
flutter pub get
flutter test
```

Flutter's build system does not track AOPD compiler sources as app kernel
inputs.

---

# 简体中文

[English](#troubleshooting) | 简体中文

AOPD 诊断信息由 frontend server 打印，并带有 `[AOPD]` 前缀。

## 切面没有生效

### Aspect Library 不可达

AOPD 只会织入进入 kernel component 的 library。请从 app 可达代码 import aspect
library。常见做法是使用 barrel 文件：

```dart
// lib/aop/aspects/aspects.dart
export 'analytics_aspect.dart';
export 'coverage_aspect.dart';
```

然后从 app 入口 import 这个 barrel。

### App 仍在使用 Stock Frontend Server

检查构建日志是否包含：

```text
[AOPD] Using frontend_server snapshot: <path>
```

如果没有，确认：

- Flutter SDK 已应用 `flutter_tools.patch`；
- app 配置了 `aopd.enabled: true`；
- `flutter pub get` 已生成 `.dart_tool/package_config.json`。

### Target 字符串不匹配

除非使用 `isRegex: true`，否则 `importUri`、`clsName`、`methodName`、`fieldName`
必须精确匹配。

方法名前缀：

- `-methodName`：实例方法。
- `+methodName`：静态方法或顶层函数。

Regex pointcut 使用部分匹配（`hasMatch`）。需要精确匹配时请使用 `^...$`。

## 常见诊断

| 诊断 | 含义 | 处理 |
| --- | --- | --- |
| `invalid regex pattern` | regex pointcut 无法编译。 | 修正 regex。 |
| `constructor @Execute is not supported` | 0.1.x 的 `@Execute` 不支持构造函数。 | 对构造调用点使用 `@Call`。 |
| `@Inject requires lineNum` | `@Inject` 需要显式源码行。 | 提供 `lineNum`。 |
| `inject target library not found` | 目标 library 不在 component 中。 | 检查 URI 和可达性。 |
| `instance @Call target could not be resolved` | 该位置调用目标未解析。 | 优先使用精确目标，或跳过该位置。 |
| `multiple AOP annotations` | 一个 advice 方法上有多个 AOP 注解。 | 每个注解拆到独立方法。 |
| `SDK helpers not found` | Core SDK helper 查找失败。 | 检查构建模式，如可复现请反馈。 |

这些诊断通常表示某个位置被跳过，同时原始代码被保留。Snapshot 准备失败不同：它会 fail fast，
因为静默回退会让用户误以为 AOP 已经生效。

## 已知限制

- 0.1.x 正式支持全量 build 和首次 `flutter run` 编译。Hot reload / resident 增量编译仍是
  实验能力。
- 泛型方法可以被织入，但类型参数会被擦除为 `dynamic`。
- `@Execute` 不支持构造函数。
- `@Inject` 只支持精确 `importUri` / `clsName` / `methodName` 匹配。
- 多个精确目标的 `@Call` 或 `@FieldGet` 使用最后命中生效；`@Execute` 可以叠加；
  同名 `@Add` 保留第一个命中。

## Snapshot 锁

`[AOPD] Waiting for snapshot generation lock...` 表示另一个构建正在创建 app 本地 snapshot，
正常会自动继续。

如果锁已陈旧，请停止残留 Dart 进程后重新构建。在 Windows 上，可以用任务管理器或
`taskkill` 处理卡住的 `dart.exe` / `dartaotruntime.exe` 进程。

## Compiler 改动陈旧

如果你修改了 `compiler/`，但 app 表现像没有变化，先 clean example：

```shell
cd example
flutter clean
flutter pub get
flutter test
```

Flutter build system 不会把 AOPD compiler 源码作为 app kernel 输入来追踪。
