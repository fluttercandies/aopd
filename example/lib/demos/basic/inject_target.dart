import 'package:example/shared/demo_event_log.dart';

String runInjectTarget() {
  DemoEventLog.instance.addTarget(
    'Inject target entered',
    'The target function started normally.',
  );
  // AOPD inject marker: injected statements should appear on this line.
  DemoEventLog.instance.addTarget(
    'Inject target completed',
    'The original function continued after the marker.',
  );
  return 'inject-target-result';
}
