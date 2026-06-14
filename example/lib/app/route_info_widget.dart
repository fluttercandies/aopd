import 'package:ff_annotation_route_library/ff_annotation_route_library.dart';
import 'package:flutter/widgets.dart';

class RouteInfoWidget extends StatelessWidget {
  const RouteInfoWidget({
    super.key,
    required this.settings,
    required this.child,
  });

  final FFRouteSettings settings;
  final Widget child;

  @override
  Widget build(BuildContext context) => child;
}
