# AOPD Architecture

English | [简体中文](#简体中文)

AOPD integrates with Flutter compilation through a patched Flutter tool, an
app-local frontend-server snapshot, and an AOP-owned Flutter target.

## Goals

- Keep `compiler/pkg/*` as a pristine Dart/Flutter SDK mirror.
- Keep all AOP-specific code in AOPD-owned files under `compiler/`.
- Avoid replacing Flutter SDK cache artifacts.
- Generate frontend-server snapshots per app under `.dart_tool/aopd`.
- Let AOPD widget source-location tracking coexist with Flutter Inspector.

## Build Flow

1. The patched Flutter tool reads the app `pubspec.yaml`.
2. If `aopd.enabled: true`, it resolves the installed `aopd` package from
   `.dart_tool/package_config.json`.
3. It runs `bin/prepare_frontend_server_snapshot.dart`.
4. The prepare script copies the compiler workspace into
   `<app>/.dart_tool/aopd/workspace/<cache-key>/`, resolves dependencies, and
   compiles `frontend_server/starter.dart` to an AOT snapshot.
5. Flutter starts that snapshot and appends `--aop 1`. If configured, it also
   appends `--aop-track-widget-creation 1`.
6. `compiler/frontend_server/server.dart` registers the AOP options, creates
   `AopdFrontendCompiler`, and delegates the lifecycle to upstream
   `package:frontend_server/starter.dart`.
7. `AopdFrontendCompiler` installs `AopdFlutterTarget` before the first real
   compile.

## Transform Phases

`AopdFlutterTarget` hooks into two Flutter target phases:

- **Pre constant evaluation**: when `track_widget_creation` is enabled, AOPD
  injects widget creation metadata for `AopLocation`.
- **Post modular transformations**: when AOPD is enabled, it applies `@Call`,
  `@Execute`, `@Inject`, `@Add`, and `@FieldGet` kernel rewrites.

The AOP rewrites run after constants are evaluated, so annotations are available
as `ConstantExpression` / `InstanceConstant` data.

## Widget Location Coexistence

AOPD uses identifiers separate from Flutter Inspector:

| Area | Flutter Inspector | AOPD |
| --- | --- | --- |
| Constructor parameter | `$creationLocationd_...` | `$creationLocationAopd_...` |
| Widget field | `_location` | `aopLocation` |
| Marker interface | `_HasCreationLocation` | `AopHasCreationLocation` |
| Location class | `_Location` | `AopLocation` |

Both trackers can run in the same debug build without colliding.

## Key Files

| File | Purpose |
| --- | --- |
| `flutter_tools.patch` | Flutter tool integration patch |
| `bin/prepare_frontend_server_snapshot.dart` | Public snapshot preparation entrypoint |
| `compiler/prepare_frontend_server_snapshot.dart` | Snapshot workspace, cache, lock, and compile logic |
| `compiler/frontend_server/server.dart` | AOPD frontend-server wrapper |
| `compiler/frontend_server/aopd_frontend_compiler.dart` | Installs the AOP Flutter target lazily |
| `compiler/transformer/aopd_flutter_target.dart` | Flutter target subclass and target registration |
| `compiler/transformer/aop_transformer.dart` | AOP orchestration |
| `compiler/transformer/rewriters/` | Annotation-specific kernel rewrites |
| `compiler/transformer/widget_location/` | AOPD widget location tracker |
| `compiler/pkg/*` | Upstream SDK mirror |

---

# 简体中文

[English](#aopd-architecture) | 简体中文

AOPD 通过 Flutter tool patch、app 本地 frontend-server snapshot，以及 AOP 自有的
Flutter target 接入 Flutter 编译流程。

## 目标

- 让 `compiler/pkg/*` 保持为干净的 Dart/Flutter SDK 镜像。
- 所有 AOP 专属代码都放在 `compiler/` 下 AOPD 自有文件中。
- 不替换 Flutter SDK cache artifact。
- 每个 app 在 `.dart_tool/aopd` 下生成自己的 frontend-server snapshot。
- 让 AOPD widget 源码位置追踪与 Flutter Inspector 共存。

## 构建流程

1. 打过 patch 的 Flutter tool 读取 app `pubspec.yaml`。
2. 如果 `aopd.enabled: true`，从 `.dart_tool/package_config.json` 中解析已安装的
   `aopd` package。
3. 执行 `bin/prepare_frontend_server_snapshot.dart`。
4. prepare 脚本将 compiler workspace 复制到
   `<app>/.dart_tool/aopd/workspace/<cache-key>/`，解析依赖，并把
   `frontend_server/starter.dart` 编译成 AOT snapshot。
5. Flutter 使用该 snapshot 启动 frontend server，并追加 `--aop 1`。如果配置开启，
   还会追加 `--aop-track-widget-creation 1`。
6. `compiler/frontend_server/server.dart` 注册 AOP 参数，创建
   `AopdFrontendCompiler`，再把生命周期交给上游
   `package:frontend_server/starter.dart`。
7. `AopdFrontendCompiler` 在第一次真正 compile 前安装 `AopdFlutterTarget`。

## 转换阶段

`AopdFlutterTarget` 接入两个 Flutter target 阶段：

- **常量求值前**：当 `track_widget_creation` 开启时，AOPD 注入 `AopLocation`
  所需的 widget 创建位置元数据。
- **模块转换后**：当 AOPD 开启时，执行 `@Call`、`@Execute`、`@Inject`、`@Add`、
  `@FieldGet` 的 kernel 改写。

AOP 改写发生在常量求值之后，因此注解已经可以以 `ConstantExpression` /
`InstanceConstant` 数据读取。

## Widget 位置追踪共存

AOPD 使用与 Flutter Inspector 分离的标识符：

| 区域 | Flutter Inspector | AOPD |
| --- | --- | --- |
| 构造函数参数 | `$creationLocationd_...` | `$creationLocationAopd_...` |
| Widget 字段 | `_location` | `aopLocation` |
| 标记接口 | `_HasCreationLocation` | `AopHasCreationLocation` |
| 位置类 | `_Location` | `AopLocation` |

两套 tracker 可以在同一个 debug build 中同时运行，不会互相冲突。

## 关键文件

| 文件 | 作用 |
| --- | --- |
| `flutter_tools.patch` | Flutter tool 集成 patch |
| `bin/prepare_frontend_server_snapshot.dart` | 对外的 snapshot 准备入口 |
| `compiler/prepare_frontend_server_snapshot.dart` | Snapshot workspace、cache、lock 和编译逻辑 |
| `compiler/frontend_server/server.dart` | AOPD frontend-server wrapper |
| `compiler/frontend_server/aopd_frontend_compiler.dart` | 延迟安装 AOP Flutter target |
| `compiler/transformer/aopd_flutter_target.dart` | Flutter target 子类与 target 注册 |
| `compiler/transformer/aop_transformer.dart` | AOP 编排 |
| `compiler/transformer/rewriters/` | 各注解对应的 kernel 改写 |
| `compiler/transformer/widget_location/` | AOPD widget 位置追踪 |
| `compiler/pkg/*` | 上游 SDK 镜像 |
