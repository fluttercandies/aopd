# AOPD

[English](README.md) | [简体中文](README-CN.md)

AOPD 是一个面向 Flutter/Dart 的 AOP 与编译增强框架，演进自
[AspectD](https://github.com/XianyuTech/aspectd)、
[Beike_AspectD](https://github.com/LianjiaTech/Beike_AspectD) 以及其他
AspectD 衍生项目。它保留了熟悉的注解模型，同时将 AOP 集成逻辑从
`compiler/pkg/*` 中移出，让 Dart/Flutter SDK 镜像源码尽量保持与上游一致。

> **开始前请注意：** AOPD 不是 `flutter pub add` 即可的开箱即用包。和所有
> AspectD 系框架一样，它在编译期织入，因此需要**一次性给你的 Flutter SDK
> 打补丁**（`git apply flutter_tools.patch`，见[快速开始](#快速开始)），并锁定
> **精确的 SDK 版本**（Flutter 3.35.7 / Dart 3.9.x）。仅添加依赖、不打补丁
> 不会有任何效果。

## 提供什么

AOPD 会在 Flutter 编译期间转换 Dart kernel 输出。当前支持：

- `@Call`：替换调用点，包括构造函数调用点。
- `@Execute`：包裹方法执行。
- `@Inject`：在稳定源码位置插入语句。
- `@Add`：给匹配到的类追加方法。
- `@FieldGet`：替换字段读取。
- `AopLocation` 和 `AopHasCreationLocation`：可选的运行时 widget 源码位置追踪。

## 有什么不同

它最重要的架构变化是：AOP 专属逻辑不再作为 patch 写在
`compiler/pkg/*` 里面。

- `compiler/pkg/*` 被视为干净的 SDK 镜像。
- AOPD 会在 frontend server 启动时安装 AOP 自己的 Flutter target：
  `AopdFlutterTarget`。
- Widget 位置追踪使用 `aopLocation` 和 `$creationLocationAopd_...`，因此可以与
  Flutter Inspector 的 `_location` 追踪共存。
- Frontend server snapshot 会按 app 生成在 `.dart_tool/aopd` 下，本仓库不会提交
  预构建的、平台相关的 snapshot。

## 环境要求

AOPD `0.1.x` 当前面向 **Flutter 3.35.7 / Dart 3.9.2**。包内使用严格的 Dart SDK
约束（`>=3.9.2 <3.10.0`），让不支持的 SDK 版本在依赖解析阶段直接失败，而不是等到
编译阶段才报错。

第一次启用 AOPD 的构建可能更慢，因为 Flutter tool 需要准备 app 本地 compiler
workspace、解析依赖，并编译本地 frontend-server snapshot。后续构建会在 cache key
不变时复用该 snapshot。

## 快速开始

先把 Flutter tool patch 应用到你的 Flutter SDK：

```shell
cd /path/to/flutter
git apply /path/to/aopd/flutter_tools.patch
rm bin/cache/flutter_tools.stamp
flutter doctor
```

在 Flutter app 中添加 AOPD 依赖：

```yaml
dependencies:
  aopd: ^0.1.0
```

在 app 的 `pubspec.yaml` 中启用 AOPD：

```yaml
aopd:
  enabled: true
```

只有当你的 app 需要 `AopLocation` 或 `AopHasCreationLocation` 时，才需要启用 widget
源码位置追踪：

```yaml
aopd:
  enabled: true
  track_widget_creation: true
```

`track_widget_creation` 默认值是 `false`。

## 最小 Aspect 示例

```dart
import 'package:aopd/aopd.dart';

@Aspect()
@pragma('vm:entry-point')
class DemoAspect {
  const DemoAspect();

  @Call('package:example/main.dart', 'CounterService', '-increment')
  @pragma('vm:entry-point')
  int onIncrement(PointCut pointCut) {
    final int result = pointCut.proceed() as int;
    return result + 1;
  }
}
```

请在 app 中显式 import aspect 所在 library，确保它会进入 kernel 输入。在
release/profile 构建中，对需要保留的 aspect class 和 advice method 使用
`@pragma('vm:entry-point')`。

方法名前缀沿用 AOPD 约定：

- `-methodName` 匹配实例方法。
- `+methodName` 匹配静态方法或顶层函数。

## 示例 App

`example/` 是当前主展示工程。它演示了：

- 基础注解和 pointcut 数据；
- 代码覆盖率和通配覆盖率；
- 自动埋点、网络链路追踪和特性开关；
- 环绕增强、异常保护、参数改写、框架 patch 和 JSON 模型序列化；
- 基于 widget rebuild、frame phase 和 image loading hook 的性能监控。

应用 Flutter tool patch 后运行示例：

```shell
cd example
flutter pub get
flutter run
```

示例工程里的 Android wrapper 文件可以由 Flutter 在正常 `flutter run` /
`flutter build` 过程中重新生成。

## 文档

- [文档入口](doc/README.md)
- [开发维护文档](doc/development.md)
- [剩余优化项](doc/optimization-backlog.md)

## License

AOPD 使用 MIT License 发布。`compiler/pkg/*` 下来自 SDK 的镜像源码保留其上游原始 license header 和 notice。上游来源说明见 [Third-Party Notices](THIRD_PARTY_NOTICES.md)。
