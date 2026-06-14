# Debugging

English | [简体中文](#简体中文)

This page lists quick debugging commands. For the full contributor workflow,
see [Development And Maintenance](development.md).

## Debug AOPD Frontend Server From Source

Prepare one example build first:

```shell
cd example
flutter build apk --debug
cd ..
```

Then launch the source-level frontend server:

```shell
dart --packages=compiler/.dart_tool/package_config.json bin/debug_server.dart example
```

The custom package config is required so the Dart VM can resolve workspace
packages such as `frontend_server`, `kernel`, `vm`, and `front_end`.

The script reuses the latest `example/.dart_tool/flutter_build/<hash>/`
directory, prints the frontend-server arguments, deletes stale `app.dill`, and
starts `compiler/frontend_server/server.dart`.

The repository also includes a VS Code launch config:

```text
Debug debug_server.dart (example)
```

Useful breakpoint targets:

- `compiler/frontend_server/server.dart`
- `compiler/frontend_server/aopd_frontend_compiler.dart`
- `compiler/transformer/aopd_flutter_target.dart`
- `compiler/transformer/aop_transformer.dart`
- `compiler/transformer/rewriters/*.dart`

## Dump Built Kernel

Build the example app, then run:

```shell
dart bin/dump.dart
```

The script finds the latest `example/.dart_tool/flutter_build/**/app.dill` and
writes `example/out.dill.txt`.

Useful search markers:

- `PointCut::proceed`
- `proceedClosure`
- `aopLocation`
- `$creationLocationAopd_`
- `AutoAnalyticsAspect`
- `PerformanceAspect`

Validate expected markers:

```shell
dart bin/validate_example_dill.dart
```

## Common Problems

| Symptom | Likely cause | Fix |
| --- | --- | --- |
| `package:frontend_server` cannot be found | Debug launch did not use compiler package config | Pass `--packages=compiler/.dart_tool/package_config.json` |
| AOP markers are missing | App did not enable AOPD or stale kernel output was reused | Check `pubspec.yaml`, clean, and rebuild |
| Widget paths have no `aopLocation` | `track_widget_creation` is disabled | Set `aopd.track_widget_creation: true` |
| Snapshot generation fails | Workspace copy, pub get, or Dart compile failed | Read the first `[AOPD]` error in the log |

---

# 简体中文

[English](#debugging) | 简体中文

这页列出快速调试命令。完整贡献者流程见
[开发维护文档](development.md)。

## 从源码调试 AOPD Frontend Server

先生成一次 example build：

```shell
cd example
flutter build apk --debug
cd ..
```

然后启动源码级 frontend server：

```shell
dart --packages=compiler/.dart_tool/package_config.json bin/debug_server.dart example
```

这个 package config 是必须的，这样 Dart VM 才能解析 `frontend_server`、`kernel`、
`vm`、`front_end` 等 workspace package。

脚本会复用最新的 `example/.dart_tool/flutter_build/<hash>/` 目录，打印 frontend-server
参数，删除旧的 `app.dill`，并启动 `compiler/frontend_server/server.dart`。

仓库中也包含 VS Code launch config：

```text
Debug debug_server.dart (example)
```

常用断点位置：

- `compiler/frontend_server/server.dart`
- `compiler/frontend_server/aopd_frontend_compiler.dart`
- `compiler/transformer/aopd_flutter_target.dart`
- `compiler/transformer/aop_transformer.dart`
- `compiler/transformer/rewriters/*.dart`

## Dump 构建后的 Kernel

先构建 example app，然后运行：

```shell
dart bin/dump.dart
```

脚本会找到最新的 `example/.dart_tool/flutter_build/**/app.dill`，并写出
`example/out.dill.txt`。

常用搜索标记：

- `PointCut::proceed`
- `proceedClosure`
- `aopLocation`
- `$creationLocationAopd_`
- `AutoAnalyticsAspect`
- `PerformanceAspect`

验证关键标记：

```shell
dart bin/validate_example_dill.dart
```

## 常见问题

| 现象 | 常见原因 | 处理 |
| --- | --- | --- |
| 找不到 `package:frontend_server` | 调试启动没有使用 compiler package config | 传入 `--packages=compiler/.dart_tool/package_config.json` |
| 缺少 AOP 标记 | app 未启用 AOPD，或复用了陈旧 kernel 输出 | 检查 `pubspec.yaml`，clean 后重建 |
| Widget 路径没有 `aopLocation` | `track_widget_creation` 未开启 | 设置 `aopd.track_widget_creation: true` |
| Snapshot 生成失败 | workspace copy、pub get 或 Dart compile 失败 | 看日志中第一条 `[AOPD]` 错误 |
