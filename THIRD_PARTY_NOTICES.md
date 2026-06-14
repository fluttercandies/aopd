# Third-Party Notices

AOPD is released under the MIT License. This document records upstream projects
and source mirrors that are relevant to AOPD's implementation.

## AspectD

AOPD's annotation model and AOP transformer design evolved from
[AspectD](https://github.com/XianyuTech/aspectd).

AspectD is released under the MIT License.

## Beike_AspectD

AOPD also incorporates ideas and implementation experience from
[Beike_AspectD](https://github.com/LianjiaTech/Beike_AspectD), an
AspectD-derived fork.

Beike_AspectD is released under the MIT License.

## Dart And Flutter SDK Sources

Files under `compiler/pkg/*` are mirrored from Dart and Flutter SDK package
sources so AOPD can build a frontend server snapshot against the target Flutter
SDK baseline. These mirrored files keep their upstream license headers and
notices.

Some AOPD compiler entrypoints and helpers are adapted from Flutter/Dart SDK
tooling files. Where a file is derived from upstream SDK code, its original
copyright and BSD-style license header is retained.
