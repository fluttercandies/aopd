# AOPD Development And Maintenance

English | [简体中文](#简体中文)

This document is for contributors who modify AOPD compiler code, Flutter tool
integration, or the example app's AOP demonstrations.

## Quick Checks

Use the root check script for normal development:

```shell
dart bin/check.dart
```

Use the full check after compiler changes or before publishing:

```shell
dart bin/check.dart --full
```

`--full` performs the clean example rebuild path, which matters after editing
`compiler/`.

## Debugging The Frontend Server

AOPD provides a source-level debug entrypoint at `bin/debug_server.dart`. It
starts AOPD's `compiler/frontend_server/server.dart` directly, using arguments
derived from the latest `example/` Flutter build.

### 1. Prepare Dependencies

Run dependency resolution for both the root package and the compiler workspace:

```shell
dart pub get
cd compiler
dart pub get
cd ..
cd example
flutter pub get
cd ..
```

### 2. Create A Flutter Build Once

`debug_server.dart` reuses the latest Flutter build hash directory and depfile.
Create those files first:

```shell
cd example
flutter build apk --debug
cd ..
```

If you only changed AOPD compiler code, clean the example before rebuilding:

```shell
cd example
flutter clean
flutter pub get
flutter build apk --debug
cd ..
```

### 3. Launch From The Command Line

Run the debug entrypoint with the compiler package config:

```shell
dart --packages=compiler/.dart_tool/package_config.json bin/debug_server.dart example
```

The custom package config is required. Without it, the Dart VM cannot resolve
workspace packages such as `frontend_server`, `kernel`, `vm`, and `front_end`.

The script prints:

- the detected Flutter SDK root;
- the build hash directory;
- the depfile path;
- the full frontend server argument list.

It also deletes a stale `app.dill` before starting so the run forces a fresh AOP
compile.

### 4. Launch From VS Code

The repository includes `.vscode/launch.json` with:

```text
Debug debug_server.dart (example)
```

That launch config:

- runs `bin/debug_server.dart`;
- sets `cwd` to `example/`;
- passes `--packages=<repo>/compiler/.dart_tool/package_config.json`;
- passes `example` as the demo project argument.

Set breakpoints in files such as:

- `compiler/frontend_server/server.dart`
- `compiler/frontend_server/aopd_frontend_compiler.dart`
- `compiler/transformer/aopd_flutter_target.dart`
- `compiler/transformer/aop_transformer.dart`
- `compiler/transformer/rewriters/*.dart`

### 5. Inspect The Generated DILL

After a debug compile or normal example build, dump the kernel text:

```shell
dart bin/dump.dart
```

Useful markers:

- `PointCut::proceed`
- `proceedClosure`
- `aopLocation`
- `$creationLocationAopd_`
- aspect class names such as `AutoAnalyticsAspect` and `PerformanceAspect`

Validate the expected markers:

```shell
dart bin/validate_example_dill.dart
```

## Why Clean Builds Matter After Compiler Changes

Flutter's build system tracks the app's Dart sources, package config, and engine
artifacts. It does not track AOPD's `compiler/` sources. If you edit only
`compiler/`, Flutter can decide the app kernel step is already up to date and
skip the compile where AOPD would run.

Practical rule:

```shell
cd example
flutter clean
flutter pub get
flutter test
```

`dart bin/check.dart --full` performs this clean path automatically.

## Updating The Flutter Tool Patch

When moving to a new Flutter SDK:

1. Port the AOPD hook files under `packages/flutter_tools/lib/src/aop/`.
2. Re-apply the compile/build target call-site changes.
3. Delete `bin/cache/flutter_tools.stamp` in the Flutter SDK.
4. Run an AOPD-enabled app and confirm the log shows the app-local snapshot
   path.
5. Regenerate `flutter_tools.patch` from the Flutter SDK worktree.

## Updating The SDK Mirror

`compiler/pkg/*` is an upstream SDK mirror. Do not store AOP-specific patches in
it.

When upgrading:

1. Identify the Dart SDK revision used by the target Flutter SDK.
2. Replace mirrored packages under `compiler/pkg/` from that SDK revision.
3. Keep `compiler/pkg/*` pristine.
4. Update `compiler/pubspec.yaml` `dependency_overrides` if upstream package
   names change.
5. Run dependency resolution in `compiler/`.
6. Fix compatibility issues in AOPD-owned files under `compiler/`.
7. Rebuild an app-local frontend server snapshot and validate the example app.

---

# 简体中文

[English](#aopd-development-and-maintenance) | 简体中文

这份文档面向修改 AOPD compiler、Flutter tool 集成，或 example app AOP demo 的贡献者。

## 快速检查

日常开发使用根目录检查脚本：

```shell
dart bin/check.dart
```

修改 compiler 后或发布前使用完整检查：

```shell
dart bin/check.dart --full
```

`--full` 会走干净的 example 重建路径。修改 `compiler/` 后这点很重要。

## 调试 Frontend Server

AOPD 提供了源码级调试入口：`bin/debug_server.dart`。它会直接启动 AOPD 的
`compiler/frontend_server/server.dart`，并从最近一次 `example/` Flutter build 中复用
编译参数。

### 1. 准备依赖

先在根 package、compiler workspace 和 example 中解析依赖：

```shell
dart pub get
cd compiler
dart pub get
cd ..
cd example
flutter pub get
cd ..
```

### 2. 先生成一次 Flutter Build

`debug_server.dart` 会复用最新的 Flutter build hash 目录和 depfile。先创建这些文件：

```shell
cd example
flutter build apk --debug
cd ..
```

如果只改了 AOPD compiler 代码，重建前先 clean example：

```shell
cd example
flutter clean
flutter pub get
flutter build apk --debug
cd ..
```

### 3. 命令行启动

使用 compiler package config 运行调试入口：

```shell
dart --packages=compiler/.dart_tool/package_config.json bin/debug_server.dart example
```

这个 package config 是必须的。没有它，Dart VM 无法解析 `frontend_server`、`kernel`、
`vm`、`front_end` 等 workspace package。

脚本会打印：

- 检测到的 Flutter SDK root；
- build hash 目录；
- depfile 路径；
- 完整 frontend server 参数。

启动前它也会删除旧的 `app.dill`，强制这次运行重新执行 AOP 编译。

### 4. VS Code 启动

仓库里已经包含 `.vscode/launch.json`：

```text
Debug debug_server.dart (example)
```

这个 launch config 会：

- 运行 `bin/debug_server.dart`；
- 将 `cwd` 设为 `example/`；
- 传入 `--packages=<repo>/compiler/.dart_tool/package_config.json`；
- 将 `example` 作为 demo 工程参数。

常用断点位置：

- `compiler/frontend_server/server.dart`
- `compiler/frontend_server/aopd_frontend_compiler.dart`
- `compiler/transformer/aopd_flutter_target.dart`
- `compiler/transformer/aop_transformer.dart`
- `compiler/transformer/rewriters/*.dart`

### 5. 查看生成的 DILL

调试编译或正常 example build 后，可以 dump kernel 文本：

```shell
dart bin/dump.dart
```

常用搜索标记：

- `PointCut::proceed`
- `proceedClosure`
- `aopLocation`
- `$creationLocationAopd_`
- aspect class 名称，比如 `AutoAnalyticsAspect`、`PerformanceAspect`

验证关键织入标记：

```shell
dart bin/validate_example_dill.dart
```

## 为什么改 Compiler 后需要 Clean Build

Flutter build system 追踪的是 app Dart 源码、package config 和 engine artifacts。它不追踪
AOPD 的 `compiler/` 源码。如果你只改 `compiler/`，Flutter 可能认为 app kernel step
已经是最新的，从而跳过真正会运行 AOPD 的编译步骤。

实用规则：

```shell
cd example
flutter clean
flutter pub get
flutter test
```

`dart bin/check.dart --full` 会自动走这条 clean 路径。

## 更新 Flutter Tool Patch

迁移到新的 Flutter SDK 时：

1. 移植 `packages/flutter_tools/lib/src/aop/` 下的 AOPD hook 文件。
2. 重新应用 compile/build target 调用点改动。
3. 删除 Flutter SDK 中的 `bin/cache/flutter_tools.stamp`。
4. 运行启用 AOPD 的 app，确认日志显示 app 本地 snapshot 路径。
5. 从 Flutter SDK worktree 重新生成 `flutter_tools.patch`。

## 更新 SDK 镜像

`compiler/pkg/*` 是上游 SDK 镜像。不要在里面保存 AOP 专属 patch。

升级时：

1. 确认目标 Flutter SDK 使用的 Dart SDK revision。
2. 用该 SDK revision 的源码替换 `compiler/pkg/` 下的镜像 package。
3. 保持 `compiler/pkg/*` 干净。
4. 如果上游 package 名称变化，更新 `compiler/pubspec.yaml` 的
   `dependency_overrides`。
5. 在 `compiler/` 中解析依赖。
6. 修复 `compiler/` 下 AOPD 自有文件的兼容性问题。
7. 重建 app 本地 frontend server snapshot，并验证 example app。
