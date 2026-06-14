## 0.1.0

- Initial AOPD release.
- Introduces the `aopd` package identity and `package:aopd/aopd.dart` entrypoint.
- Adds app-local frontend server snapshot generation for AOPD compiler transforms.
- Keeps AOP logic outside `compiler/pkg/*`, which remains an upstream SDK mirror.
- Supports AspectD-style `Call`, `Execute`, `Inject`, `Add`, and `FieldGet` transforms.
- Support Flutter 3.35.7
