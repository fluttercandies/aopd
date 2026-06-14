// ignore_for_file: non_constant_identifier_names

import 'package:aopd/aopd.dart';
import 'package:example/demos/json_model/json_models.dart';

const String _vmEntryPoint = 'vm:entry-point';
const String _targets = 'package:example/demos/json_model/json_models.dart';

/// AOP-driven JSON serialization -- the classic AspectD use case: replace
/// `dart:mirrors` (forbidden in Flutter) with a compile-time weave.
///
/// One regex pointcut weaves every `toJson` in the models library. Each woven
/// call reads its own class fields from `pointCut.members` (live instance
/// values the compiler captured) and builds the map -- so the model's toJson
/// stub needs ZERO field code, no codegen, no reflection. Nested models and
/// lists are encoded recursively.
@Aspect()
@pragma(_vmEntryPoint)
class JsonModelAspect {
  @pragma(_vmEntryPoint)
  const JsonModelAspect();

  // The class pattern excludes the JsonModel interface itself (negative
  // lookahead): its toJson is abstract/bodyless, so weaving it would both emit
  // a "no patch member with a body" skip diagnostic AND add a synthetic stub to
  // the interface that implementers would be required to provide. Concrete
  // models match and are woven.
  @Execute(_targets, r'^(?!JsonModel$).*', '-^toJson\$', isRegex: true)
  @pragma(_vmEntryPoint)
  dynamic any_toJson(PointCut pointCut) {
    final Map<dynamic, dynamic> members =
        pointCut.members ?? <dynamic, dynamic>{};
    final Map<String, dynamic> json = <String, dynamic>{};
    members.forEach((dynamic key, dynamic value) {
      json['$key'] = _encode(value);
    });
    return json;
  }

  static dynamic _encode(dynamic value) {
    if (value is JsonModel) {
      // Nested model: its own toJson is woven by this same aspect. Typed call —
      // JsonModel declares toJson, so subclasses are compile-forced to have it.
      return value.toJson();
    }
    if (value is List) {
      return value.map<dynamic>(_encode).toList();
    }
    if (value is Map) {
      return value.map<String, dynamic>(
        (dynamic k, dynamic v) => MapEntry<String, dynamic>('$k', _encode(v)),
      );
    }
    // Primitives (String, num, bool, null) are already JSON-encodable.
    return value;
  }
}
