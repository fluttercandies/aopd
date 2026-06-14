# First-Version Decisions

English | [简体中文](#简体中文)

Date: 2026-06-13. Reviewed for current docs: 2026-06-16.

This page records the support boundaries for AOPD `0.1.x`.

## Supported Build Surface

Full builds and first `flutter run` compilation are the supported surface.
Hot reload / resident incremental compilation is still experimental.

AOPD uses decentralized `proceedClosure` callbacks, so woven call/execute/
field-get sites no longer depend on a central `PointCut.proceed()` dispatch
table.

## SDK Compatibility

AOPD targets the Flutter/Dart SDK line declared in the root `pubspec.yaml`.
Release-to-release support changes are recorded in `CHANGELOG.md`.

The package uses a Dart SDK upper bound as the real compatibility gate. Flutter
upper bounds are not used because pub.dev has deprecated them.

## Annotation Boundaries

- `@Call`: replaces call sites. For exact duplicate targets, last match wins.
- `@Execute`: wraps method execution and can stack. Constructors are not
  supported in 0.1.x.
- `@Inject`: exact `importUri` / `clsName` / `methodName` matching only; requires
  `lineNum`.
- `@Add`: adds methods. Same-name methods keep the first match.
- `@FieldGet`: replaces field reads. For exact duplicate targets, last match
  wins.

One advice method should carry one AOP annotation. Multiple AOP annotations on
the same method are rejected with a diagnostic.

## Failure Policy

Highest priority: AOP must be an enhancement. A weave failure must not add crash
risk to the host app or build.

- Snapshot preparation failures fail fast.
- Individual weave failures degrade loudly: skip the failing site, print an
  `[AOPD]` diagnostic, and keep original code whenever possible.

## Deferred Items

Open optimization work is tracked in
[Optimization Backlog](optimization-backlog.md).

---

# 简体中文

[English](#first-version-decisions) | 简体中文

确立日期：2026-06-13。当前文档校对日期：2026-06-16。

本文记录 AOPD `0.1.x` 的支持边界。

## 支持的构建面

正式支持全量 build 和首次 `flutter run` 编译。Hot reload / resident 增量编译仍是实验能力。

AOPD 使用去中心化 `proceedClosure` 回调，因此 woven call / execute / field-get 位置不再
依赖中心化的 `PointCut.proceed()` 分发表。

## SDK 兼容性

AOPD 面向根目录 `pubspec.yaml` 中声明的 Flutter/Dart SDK 支持范围。每个发布版本的支持变化记录在
`CHANGELOG.md` 中。

包内使用 Dart SDK 上界作为真正的兼容性闸。Flutter 上界没有使用，因为 pub.dev 已经废弃
Flutter 上界。

## 注解边界

- `@Call`：替换调用点。精确重复目标最后命中生效。
- `@Execute`：包裹方法执行，可以叠加。0.1.x 不支持构造函数。
- `@Inject`：只支持精确 `importUri` / `clsName` / `methodName` 匹配；需要 `lineNum`。
- `@Add`：添加方法。同名方法保留第一个命中。
- `@FieldGet`：替换字段读取。精确重复目标最后命中生效。

一个 advice 方法只应携带一个 AOP 注解。同一方法上出现多个 AOP 注解时，会输出诊断并拒绝处理。

## 失败策略

最高优先级：AOP 必须是增强能力。织入失败不能给宿主 app 或构建增加崩溃风险。

- Snapshot 准备失败会 fail fast。
- 单点织入失败会显式降级：跳过失败位置，打印 `[AOPD]` 诊断，并在可行时保留原始代码。

## 暂缓项

未完成的优化工作记录在 [剩余优化项](optimization-backlog.md)。
