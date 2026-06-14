# AOPD Example

English | [简体中文](#简体中文)

This Flutter app is the main showcase for AOPD annotations and practical AOP
patterns. It is localized with Flutter's official `gen-l10n` flow and supports
English, Simplified Chinese, and system-locale selection from the home page.

## What It Demonstrates

- Basic annotation loops for `@Aspect`, `@Execute`, `@Call`, `@FieldGet`,
  `@Inject`, and `@Add`.
- Advanced pointcut recipes for instance, static, constructor, library, and
  regex matching.
- Practical business demos: auto analytics, network tracing, feature flags,
  exception guards, argument rewriting, around advice, framework patching, JSON
  model serialization, and code coverage.
- Performance demos for widget rebuilds, frame phases, and image loading.
- A shared in-app event log so demo results are visible without reading console
  output.

## Run

Apply the Flutter tool patch from the repository root first, then run:

```sh
flutter pub get
flutter run
```

The app enables AOPD from `pubspec.yaml` with `aopd.enabled: true`.

## Test

```sh
flutter test
flutter analyze
```

When testing weaving-sensitive runtime assertions after compiler changes, use a
clean build:

```sh
flutter clean
flutter pub get
flutter test
```

---

# 简体中文

[English](#aopd-example) | 简体中文

这个 Flutter app 是 AOPD 注解和实际 AOP 场景的主展示工程。它使用 Flutter 官方
`gen-l10n` 方案做国际化，支持英文、简体中文，以及在首页选择跟随系统语言。

## 演示内容

- `@Aspect`、`@Execute`、`@Call`、`@FieldGet`、`@Inject`、`@Add` 的基础注解闭环。
- 实例方法、静态方法、构造函数、library、regex 等进阶 pointcut 配方。
- 业务化 demo：自动埋点、网络链路追踪、特性开关、异常保护、参数改写、环绕增强、
  框架 patch、JSON 模型序列化和代码覆盖率。
- Widget rebuild、frame phase、image loading 相关的性能监控 demo。
- 共享的 app 内事件日志，不用看控制台也能看到 demo 结果。

## 运行

先在仓库根目录对应的 Flutter SDK 上应用 Flutter tool patch，然后运行：

```sh
flutter pub get
flutter run
```

示例 app 通过 `pubspec.yaml` 中的 `aopd.enabled: true` 启用 AOPD。

## 测试

```sh
flutter test
flutter analyze
```

如果修改过 compiler，并且要验证依赖织入的运行时断言，请使用干净构建：

```sh
flutter clean
flutter pub get
flutter test
```
