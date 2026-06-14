# AOPD Optimization Backlog

English | [简体中文](#简体中文)

Updated: 2026-06-16

There is no known P0 blocker for the current 0.1.x line. The items below are
the remaining optimization and polish work after the example app and docs were
consolidated.

## High-Value Follow-Ups

### 1. Hot Reload / Resident Incremental Weaving

Current state:

- Full builds and first `flutter run` compilation are the supported path.
- Resident incremental compilation is intentionally documented as experimental.
- The decentralized `proceedClosure` model removed the old runtime crash risk
  caused by stale central `proceed()` branches, but not every incremental
  invalidation shape is a supported product surface yet.

Recommended work:

- Build a maintained incremental harness for `compile` -> `accept` ->
  `recompile` flows.
- Add green/red cases for editing target libraries, aspect libraries, and shared
  runtime libraries.
- Promote hot reload support only after the harness can reproduce and verify the
  intended behavior.

Risk: high. Value: high if hot reload is a product requirement.

### 2. In-Transform Kernel Verification And Rollback

Current state:

- Offline DILL verification and runtime tests provide useful coverage.
- Individual weave failures degrade with diagnostics.

Recommended work:

- Evaluate running kernel verification after the AOP transform in debug or
  development builds.
- If verification fails, roll back AOP changes for the current transform pass
  and emit a diagnostic instead of handing invalid kernel to the VM.

Risk: high. Value: medium. This needs a concrete failure case before taking on
the complexity.

### 3. Mode-Specific `AopItemInfo` Types

Current state:

- `AopItemInfo.tryCreate` validates mode-specific required fields before items
  reach rewriters.
- Required accessors remove the main null-crash risk.

Recommended work:

- Split into mode-specific data types such as `CallInfo`, `ExecuteInfo`,
  `InjectInfo`, `AddInfo`, and `FieldGetInfo` if readability starts to suffer.

Risk: low to medium. Value: mostly maintainability.

### 4. Build-Time Coverage Manifest Generation

Current state:

- The example code-coverage demo declares its manifest manually so the demo is
  deterministic and self-contained.
- The wildcard coverage demo is discover-on-hit and does not pretend to know a
  denominator at runtime.

Recommended work:

- Add an optional build-time generator that emits a coverage manifest from the
  compiled package/class list.
- Keep the runtime collector outside matched wildcard folders to avoid weaving
  itself recursively.

Risk: medium. Value: medium for production-like coverage workflows.

### 5. SDK Upgrade Playbook

Current state:

- `compiler/pkg/*` is kept as an upstream SDK mirror.
- `compiler-maintenance.md` and `development.md` document the update policy and
  widget tracker sync rules.

Recommended work:

- When moving beyond Flutter 3.35.x / Dart 3.9.x, turn the manual SDK mirror
  update steps into a repeatable checklist with exact source revision capture.
- Add a smoke test that confirms the patched Flutter tool starts the expected
  app-local snapshot after the upgrade.

Risk: medium. Value: high for future releases.

---

# 简体中文

[English](#aopd-optimization-backlog) | 简体中文

更新日期：2026-06-16

当前 0.1.x 版本线没有已知 P0 阻塞。下面是 example app 和文档整理完成后，仍值得后续处理的
优化和打磨项。

## 高价值后续项

### 1. Hot Reload / Resident 增量织入

当前状态：

- 正式支持面是全量 build 和首次 `flutter run` 编译。
- Resident 增量编译目前明确标记为实验能力。
- 去中心化 `proceedClosure` 模型已经移除了旧的中心化 `proceed()` 分支过期导致的运行期
  crash 风险，但不是所有增量 invalidation 形态都已经作为产品能力承诺。

建议工作：

- 建立长期维护的增量 harness，覆盖 `compile` -> `accept` -> `recompile` 流程。
- 为修改目标库、修改 aspect 库、修改共享 runtime 库分别加入红绿用例。
- 只有当 harness 能稳定复现并验证预期行为后，再把 hot reload 支持提升为正式能力。

风险：高。价值：如果 hot reload 是产品要求，则价值高。

### 2. Transform 内 Kernel 校验与回滚

当前状态：

- 离线 DILL 校验和运行时测试已经提供了有用覆盖。
- 单点织入失败会降级并输出诊断。

建议工作：

- 评估在 debug 或开发构建中，于 AOP transform 后运行 kernel verification。
- 如果 verification 失败，回滚当前 transform pass 的 AOP 改动并输出诊断，而不是把非法
  kernel 交给 VM。

风险：高。价值：中。建议等出现明确失败案例后再承担这部分复杂度。

### 3. Mode-Specific `AopItemInfo` 类型拆分

当前状态：

- `AopItemInfo.tryCreate` 已经在 item 进入 rewriter 前校验各 mode 必需字段。
- required accessor 已经移除了主要的 null crash 风险。

建议工作：

- 如果可读性开始下降，可以拆成 `CallInfo`、`ExecuteInfo`、`InjectInfo`、`AddInfo`、
  `FieldGetInfo` 等 mode-specific 数据类型。

风险：低到中。价值：主要是可维护性。

### 4. 构建期 Coverage Manifest 生成

当前状态：

- example 的代码覆盖率 demo 手写 manifest，保证 demo 自包含且确定。
- 通配覆盖率 demo 使用 discover-on-hit，不在运行时假装知道总量。

建议工作：

- 增加一个可选构建期 generator，从编译产物或类列表生成 coverage manifest。
- 保持 runtime collector 位于 wildcard 匹配目录之外，避免它被织入自身导致递归。

风险：中。价值：对生产化覆盖率工作流是中等价值。

### 5. SDK 升级 Playbook

当前状态：

- `compiler/pkg/*` 作为上游 SDK 镜像维护。
- `compiler-maintenance.md` 和 `development.md` 已记录更新策略和 widget tracker 同步规则。

建议工作：

- 当升级到 Flutter 3.35.x / Dart 3.9.x 之后的版本时，把手动 SDK 镜像更新步骤整理成
  可重复 checklist，并记录精确源码 revision。
- 增加 smoke test，确认 patch 后的 Flutter tool 会启动预期的 app 本地 snapshot。

风险：中。价值：对后续版本发布高。
