// Models for the JSON-via-AOP demo.
//
// The headline: none of the toJson() methods below contain any field code.
// They are STUBS that return an empty map. A single @Execute aspect
// (json_model_aspect.dart) fills them at compile time by reading the class's
// fields from PointCut.members -- the AOP replacement for dart:mirrors, which
// Flutter forbids. No reflection, no build_runner, no generated *.g.dart.

/// Contract for serializable models. `toJson` is ABSTRACT so every model is
/// forced (at compile time) to declare its own — that per-class declaration is
/// also what the aspect needs as its weave anchor (it reads THAT class's
/// fields). The aspect's pointcut excludes JsonModel itself, so this bodyless
/// interface method is never woven (no stub added to the interface).
abstract class JsonModel {
  Map<String, dynamic> toJson();
}

class Address implements JsonModel {
  const Address({required this.city, required this.zip});

  final String city;
  final String zip;

  // Stub. The @Execute aspect replaces this with a real map built from the
  // fields above. Left as an empty map so the un-woven value is obviously wrong.
  @override
  Map<String, dynamic> toJson() => <String, dynamic>{};
}

class User implements JsonModel {
  const User({
    required this.name,
    required this.age,
    required this.premium,
    required this.tags,
    required this.address,
  });

  final String name;
  final int age;
  final bool premium;
  final List<String> tags;
  final Address address;

  // Stub — filled by AOP, including the nested Address and the tags list.
  @override
  Map<String, dynamic> toJson() => <String, dynamic>{};
}

/// A sample graph the page and tests serialize.
const User sampleUser = User(
  name: 'Ada Lovelace',
  age: 36,
  premium: true,
  tags: <String>['compiler', 'aop', 'kernel'],
  address: Address(city: 'London', zip: 'NW1'),
);
