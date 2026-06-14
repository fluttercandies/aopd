# Flutter Tooling

English | [简体中文](#简体中文)

AOPD requires a small Flutter tool patch. The patch lets an app opt into AOPD
from `pubspec.yaml`; apps that do not opt in keep the stock Flutter behavior.

## App Configuration

```yaml
aopd:
  enabled: true
  track_widget_creation: false
```

- `enabled`: starts the AOPD frontend-server snapshot for this app.
- `track_widget_creation`: enables AOPD runtime widget source-location tracking.
  It defaults to `false`.

No separate config file is required.

## Patch Behavior

When AOPD is enabled, the patched Flutter tool:

1. reads the app `pubspec.yaml`;
2. resolves the installed `aopd` package from `.dart_tool/package_config.json`;
3. runs `bin/prepare_frontend_server_snapshot.dart` from that package;
4. reads the emitted `AOPD_SNAPSHOT_PATH=...` marker;
5. starts frontend server with that snapshot;
6. appends `--aop 1`;
7. appends `--aop-track-widget-creation 1` when configured.

When AOPD is not enabled, Flutter keeps the stock frontend server path.

## Snapshot Location

Generated snapshots are app-local:

```text
<app>/.dart_tool/aopd/snapshots/<cache-key>/frontend_server_aot.dart.snapshot
```

The cache key includes AOPD compiler sources and the Flutter/Dart version. A
first AOPD build may spend extra time copying the compiler workspace, resolving
dependencies, and compiling the snapshot. Later builds reuse the snapshot while
the cache key is unchanged.

The AOPD package directory is not modified, even when it is installed from pub
cache. The Flutter SDK cache snapshot is not replaced.

## Failure Policy

Snapshot preparation fails fast. AOPD must not silently fall back to the stock
frontend server because users would believe instrumentation is active when it is
not.

Inside the transformer, individual weave failures use a degrade-but-loud policy:
the failing site is skipped, a diagnostic is printed, and the original code is
kept whenever possible.

## Updating The Patch

When moving to a new Flutter SDK:

1. Port the AOPD hook files under `packages/flutter_tools/lib/src/aop/`.
2. Re-apply the compile/build target call-site changes.
3. Delete `bin/cache/flutter_tools.stamp` in the Flutter SDK.
4. Run an AOPD-enabled app and confirm the log shows the app-local snapshot.
5. Regenerate `flutter_tools.patch` from the Flutter SDK worktree.

---

# 简体中文

[English](#flutter-tooling) | 简体中文

AOPD 需要一个很小的 Flutter tool patch。这个 patch 允许 app 通过 `pubspec.yaml`
选择启用 AOPD；没有启用的 app 继续走 Flutter 原生行为。

## App 配置

```yaml
aopd:
  enabled: true
  track_widget_creation: false
```

- `enabled`：为当前 app 启动 AOPD frontend-server snapshot。
- `track_widget_creation`：启用 AOPD 运行时 widget 源码位置追踪，默认是 `false`。

不需要额外配置文件。

## Patch 行为

当 AOPD 启用时，打过 patch 的 Flutter tool 会：

1. 读取 app `pubspec.yaml`；
2. 从 `.dart_tool/package_config.json` 中解析已安装的 `aopd` package；
3. 执行该 package 中的 `bin/prepare_frontend_server_snapshot.dart`；
4. 读取输出的 `AOPD_SNAPSHOT_PATH=...` 标记；
5. 使用该 snapshot 启动 frontend server；
6. 追加 `--aop 1`；
7. 在配置开启时追加 `--aop-track-widget-creation 1`。

当 AOPD 未启用时，Flutter 保持 stock frontend server 路径。

## Snapshot 位置

生成的 snapshot 位于 app 本地：

```text
<app>/.dart_tool/aopd/snapshots/<cache-key>/frontend_server_aot.dart.snapshot
```

Cache key 包含 AOPD compiler 源码和 Flutter/Dart 版本。第一次 AOPD 构建可能需要额外
时间复制 compiler workspace、解析依赖并编译 snapshot。后续构建会在 cache key 不变时
复用该 snapshot。

即使 AOPD 安装在 pub cache 中，也不会修改 package 目录。Flutter SDK cache snapshot
也不会被替换。

## 失败策略

Snapshot 准备失败时会 fail fast。AOPD 不能静默回退到 stock frontend server，否则用户会
误以为 instrumentation 已经生效。

Transformer 内部的单点织入失败采用“降级但显式报告”的策略：跳过失败位置、打印诊断，并在
可行时保留原始代码。

## 更新 Patch

迁移到新的 Flutter SDK 时：

1. 移植 `packages/flutter_tools/lib/src/aop/` 下的 AOPD hook 文件。
2. 重新应用 compile/build target 调用点改动。
3. 删除 Flutter SDK 中的 `bin/cache/flutter_tools.stamp`。
4. 运行启用 AOPD 的 app，确认日志显示 app 本地 snapshot。
5. 从 Flutter SDK worktree 重新生成 `flutter_tools.patch`。
