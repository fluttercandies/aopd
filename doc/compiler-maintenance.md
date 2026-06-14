# Compiler Maintenance

English | [简体中文](#简体中文)

This document covers maintainer tasks for AOPD compiler sources.

## `compiler/pkg/*` Policy

`compiler/pkg/*` is an upstream SDK mirror. Do not store AOP-specific patches in
it.

AOPD uses the mirror as import and compile reference source for packages such as
`vm`, `frontend_server`, `kernel`, and `front_end`. AOPD-owned logic belongs in
files such as:

- `compiler/frontend_server/*`
- `compiler/transformer/*`
- `compiler/prepare_frontend_server_snapshot.dart`

## Updating The SDK Mirror

1. Identify the Dart SDK revision used by the target Flutter SDK.
2. Replace mirrored packages under `compiler/pkg/` from that SDK revision.
3. Keep `compiler/pkg/*` pristine.
4. Update `compiler/pubspec.yaml` `dependency_overrides` if upstream package
   names change.
5. Run `dart pub get` in `compiler/`.
6. Fix compatibility issues in AOPD-owned files under `compiler/`.
7. Rebuild an app-local frontend-server snapshot and validate `example/`.

## Widget Tracker Sync

`compiler/transformer/widget_location/track_widget_constructor_locations.dart`
is derived from the upstream kernel widget tracker. When upgrading SDK sources,
merge upstream logic while keeping AOPD-specific identifiers:

- `$creationLocationAopd_...`
- `aopLocation`
- `AopHasCreationLocation`
- `AopLocation`
- `ownerImportUri`

The diff between the upstream tracker and the AOPD tracker should remain focused
on those AOPD-specific changes.

## Snapshot Generation

Normal Flutter builds invoke snapshot preparation through the patched Flutter
tool. Maintainers can call it directly when debugging:

```shell
dart run bin/prepare_frontend_server_snapshot.dart --flutter-root <flutter-root> --app-root <app-root> --aopd-root <aopd-root>
```

Generated snapshots live under the app:

```text
<app>/.dart_tool/aopd/snapshots/<cache-key>/
```

## Rebuilding After Compiler Changes

A compiler-only edit does not trigger a Flutter app rebuild on its own. Flutter
tracks the app's Dart sources and package config for the kernel step, not
AOPD's `compiler/` sources.

Practical rule while iterating on `compiler/`:

```shell
cd example
flutter clean
flutter pub get
flutter test
```

`dart bin/check.dart --full` performs the clean example path automatically.

## Validation Markers

After building `example/`, dump `app.dill`:

```shell
dart bin/dump.dart
```

Useful markers include:

- `PointCut::proceed`
- `proceedClosure`
- `aopLocation` when `track_widget_creation` is enabled
- `$creationLocationAopd_`
- example aspect classes such as `AutoAnalyticsAspect` and `PerformanceAspect`

---

# 简体中文

[English](#compiler-maintenance) | 简体中文

这份文档说明 AOPD compiler 源码的维护任务。

## `compiler/pkg/*` 策略

`compiler/pkg/*` 是上游 SDK 镜像。不要把 AOP 专属 patch 放进去。

AOPD 只把这份镜像作为 `vm`、`frontend_server`、`kernel`、`front_end` 等 package
的 import 和编译参考。AOPD 自有逻辑应该放在这些文件中：

- `compiler/frontend_server/*`
- `compiler/transformer/*`
- `compiler/prepare_frontend_server_snapshot.dart`

## 更新 SDK 镜像

1. 确认目标 Flutter SDK 使用的 Dart SDK revision。
2. 用该 SDK revision 的源码替换 `compiler/pkg/` 下的镜像 package。
3. 保持 `compiler/pkg/*` 干净。
4. 如果上游 package 名称变化，更新 `compiler/pubspec.yaml` 的
   `dependency_overrides`。
5. 在 `compiler/` 中运行 `dart pub get`。
6. 修复 `compiler/` 下 AOPD 自有文件的兼容性问题。
7. 重建 app 本地 frontend-server snapshot，并验证 `example/`。

## Widget Tracker 同步

`compiler/transformer/widget_location/track_widget_constructor_locations.dart`
派生自上游 kernel widget tracker。升级 SDK 源码时，需要合并上游逻辑，同时保留
AOPD 专属标识符：

- `$creationLocationAopd_...`
- `aopLocation`
- `AopHasCreationLocation`
- `AopLocation`
- `ownerImportUri`

上游 tracker 与 AOPD tracker 的 diff 应尽量只集中在这些 AOPD 专属改动上。

## Snapshot 生成

正常 Flutter 构建会通过 patched Flutter tool 触发 snapshot 准备。维护者调试时也可以直接
调用：

```shell
dart run bin/prepare_frontend_server_snapshot.dart --flutter-root <flutter-root> --app-root <app-root> --aopd-root <aopd-root>
```

生成的 snapshot 位于 app 下：

```text
<app>/.dart_tool/aopd/snapshots/<cache-key>/
```

## 修改 Compiler 后重建

只修改 compiler 不会自动触发 Flutter app 重建。Flutter kernel step 追踪的是 app Dart
源码和 package config，不追踪 AOPD 的 `compiler/` 源码。

迭代 `compiler/` 时的实用规则：

```shell
cd example
flutter clean
flutter pub get
flutter test
```

`dart bin/check.dart --full` 会自动执行干净的 example 路径。

## 验证标记

构建 `example/` 后 dump `app.dill`：

```shell
dart bin/dump.dart
```

常用标记包括：

- `PointCut::proceed`
- `proceedClosure`
- 启用 `track_widget_creation` 时的 `aopLocation`
- `$creationLocationAopd_`
- `AutoAnalyticsAspect`、`PerformanceAspect` 等 example aspect class
