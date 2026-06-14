# AOPD Documentation

English | [简体中文](#简体中文)

This directory contains the maintained documentation for the current AOPD
project. Historical review and implementation-plan notes were removed; remaining
future work is tracked in [Optimization Backlog](optimization-backlog.md).

## Reading Order

| Document | Purpose |
| --- | --- |
| [Architecture](architecture.md) | Build flow, frontend-server integration, transform phases, and key files. |
| [AOP Internals](aop-internals.md) | Annotation resolution, proceed closures, rewriter responsibilities, and safety model. |
| [Flutter Tooling](flutter-tooling.md) | Flutter tool patch behavior, app config, snapshot cache, and failure policy. |
| [Compiler Maintenance](compiler-maintenance.md) | SDK mirror policy, tracker sync, snapshot generation, and clean rebuild rules. |
| [Debugging](debugging.md) | Quick commands for frontend-server debugging, DILL dumping, and common problems. |
| [Troubleshooting](troubleshooting.md) | User-facing diagnostics, known limits, snapshot locks, and stale build fixes. |
| [First-Version Decisions](decisions.md) | AOPD 0.1.x support boundaries and failure policy. |
| [Development And Maintenance](development.md) | Contributor workflow, detailed frontend-server debugging, and upgrade steps. |
| [Optimization Backlog](optimization-backlog.md) | Deferred work that remains worth considering. |

## Current Support Snapshot

- AOPD `0.1.x` targets Flutter 3.35.7 / Dart 3.9.2.
- Full builds and first `flutter run` compilation are the supported path.
- Hot reload / resident incremental compilation remains experimental.
- `compiler/pkg/*` is an upstream SDK mirror, not AOP patch storage.
- Snapshot preparation is app-local under `.dart_tool/aopd`.
- Individual weave failures should degrade loudly with `[AOPD]` diagnostics.

---

# 简体中文

[English](#aopd-documentation) | 简体中文

本目录包含当前 AOPD 项目的正式维护文档。历史 review 和实现计划类笔记已经移除；仍值得后续
处理的事项集中记录在 [剩余优化项](optimization-backlog.md)。

## 阅读顺序

| 文档 | 用途 |
| --- | --- |
| [架构](architecture.md) | 构建流程、frontend-server 接入、转换阶段和关键文件。 |
| [AOP 内部机制](aop-internals.md) | 注解解析、proceed closure、rewriter 职责和安全模型。 |
| [Flutter Tooling](flutter-tooling.md) | Flutter tool patch 行为、app 配置、snapshot cache 和失败策略。 |
| [Compiler 维护](compiler-maintenance.md) | SDK 镜像策略、tracker 同步、snapshot 生成和 clean rebuild 规则。 |
| [调试](debugging.md) | Frontend-server 调试、DILL dump 和常见问题的快速命令。 |
| [排障](troubleshooting.md) | 面向用户的诊断、已知限制、snapshot 锁和陈旧构建处理。 |
| [首版决策](decisions.md) | AOPD 0.1.x 支持边界和失败策略。 |
| [开发维护](development.md) | 贡献者流程、详细 frontend-server 调试和升级步骤。 |
| [剩余优化项](optimization-backlog.md) | 仍值得考虑的暂缓工作。 |

## 当前支持快照

- AOPD `0.1.x` 面向 Flutter 3.35.7 / Dart 3.9.2。
- 正式支持全量 build 和首次 `flutter run` 编译。
- Hot reload / resident 增量编译仍是实验能力。
- `compiler/pkg/*` 是上游 SDK 镜像，不存放 AOP patch。
- Snapshot 在 app 本地 `.dart_tool/aopd` 下生成。
- 单点织入失败应通过 `[AOPD]` 诊断显式降级。
