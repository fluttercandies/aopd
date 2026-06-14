# AOPD

[![pub package](https://img.shields.io/pub/v/aopd.svg)](https://pub.dartlang.org/packages/aopd) [![GitHub stars](https://img.shields.io/github/stars/fluttercandies/aopd)](https://github.com/fluttercandies/aopd/stargazers) [![GitHub forks](https://img.shields.io/github/forks/fluttercandies/aopd)](https://github.com/fluttercandies/aopd/network) [![GitHub license](https://img.shields.io/github/license/fluttercandies/aopd)](https://github.com/fluttercandies/aopd/blob/master/LICENSE) [![GitHub issues](https://img.shields.io/github/issues/fluttercandies/aopd)](https://github.com/fluttercandies/aopd/issues) <a href="https://qm.qq.com/q/ZyJbSVjfSU">![FlutterCandies QQ 群](https://img.shields.io/badge/dynamic/yaml?url=https%3A%2F%2Fraw.githubusercontent.com%2Ffluttercandies%2F.github%2Frefs%2Fheads%2Fmain%2Fdata.yml&query=%24.qq_group_number&label=QQ%E7%BE%A4&logo=qq&color=1DACE8)

English | [简体中文](README-CN.md)

AOPD is a Flutter/Dart AOP and compiler-extension framework evolved from
[AspectD](https://github.com/XianyuTech/aspectd),
[Beike_AspectD](https://github.com/LianjiaTech/Beike_AspectD), and other
AspectD-derived projects. It keeps the familiar annotation model while moving
AOP integration out of `compiler/pkg/*`, so the mirrored Dart/Flutter SDK
packages can stay close to upstream sources.

> **Before you start:** AOPD is not a drop-in `flutter pub add`. Like all
> AspectD-style frameworks it weaves at compile time, so it requires a one-time
> **patch to your Flutter SDK checkout** (`git apply flutter_tools.patch`, see
> [Quick Start](#quick-start)) for the supported SDK line declared in
> `pubspec.yaml`. Adding the dependency alone does nothing until the patch is
> applied.

## What It Provides

AOPD transforms Dart kernel output during Flutter compilation. It supports:

- `@Call` for replacing call sites, including constructor call sites.
- `@Execute` for wrapping method execution.
- `@Inject` for inserting statements at stable source locations.
- `@Add` for adding methods to matched classes.
- `@FieldGet` for replacing field reads.
- `AopLocation` and `AopHasCreationLocation` for optional runtime widget
  source-location tracking.

## Why It Is Different

The main architecture change is that
AOP-specific logic is no longer stored as patches inside `compiler/pkg/*`.

- `compiler/pkg/*` is treated as a pristine SDK mirror.
- AOPD installs an AOP-owned Flutter target, `AopdFlutterTarget`, during
  frontend server startup.
- Widget location tracking uses `aopLocation` and
  `$creationLocationAopd_...`, so it can coexist with Flutter Inspector's
  `_location` tracking.
- The frontend server snapshot is generated per app under `.dart_tool/aopd`;
  prebuilt platform-specific snapshots are not committed to this repository.

## Requirements

AOPD targets the Flutter/Dart SDK line declared in `pubspec.yaml`. The package
uses strict Dart SDK constraints so unsupported SDK versions fail during
dependency resolution instead of failing later during compilation. Release
support changes are recorded in `CHANGELOG.md`.

The first AOPD-enabled build may take longer because the Flutter tool prepares
an app-local compiler workspace, resolves dependencies, and compiles a local
frontend-server snapshot. Later builds reuse the snapshot while the cache key is
unchanged.

Keep your project in a short ASCII-only path. Chinese characters or very long
paths may cause frontend-server snapshot compilation to fail.

## Quick Start

Apply the Flutter tool patch to your Flutter SDK checkout:

```shell
cd /path/to/flutter
git apply /path/to/aopd/flutter_tools.patch
rm bin/cache/flutter_tools.stamp
flutter doctor
```

Add AOPD to your Flutter app:

```yaml
dependencies:
  aopd: any
```

Enable AOPD in the app `pubspec.yaml`:

```yaml
aopd:
  enabled: true
```

Enable widget source-location tracking only when your app needs `AopLocation`
or `AopHasCreationLocation`:

```yaml
aopd:
  enabled: true
  track_widget_creation: true
```

`track_widget_creation` defaults to `false`.

## Minimal Aspect

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

Import the aspect library from your app so it is included in the kernel input.
In release/profile builds, use `@pragma('vm:entry-point')` on aspect classes and
advice methods you need to keep.

Method name prefixes follow AOPD conventions:

- `-methodName` matches an instance method.
- `+methodName` matches a static or top-level function.

## Example App

The `example/` app is the main showcase. It demonstrates:

- basic annotations and pointcut data;
- code coverage and wildcard coverage;
- auto analytics, network tracing, and feature flags;
- around advice, exception guards, argument rewriting, framework patching, and
  JSON model serialization;
- performance monitoring with widget rebuild, frame phase, and image loading
  hooks.

Run it after applying the Flutter tool patch:

```shell
cd example
flutter pub get
flutter run
```

Flutter may regenerate Android wrapper files for the example project during
normal `flutter run` / `flutter build` usage.

## Documentation

- [Documentation index](doc/README.md)
- [Development and maintenance](doc/development.md)
- [Optimization backlog](doc/optimization-backlog.md)

## License

AOPD is released under the MIT License. SDK-derived mirror sources under `compiler/pkg/*` keep their original upstream license headers and notices. See [Third-Party Notices](THIRD_PARTY_NOTICES.md) for upstream attribution.
