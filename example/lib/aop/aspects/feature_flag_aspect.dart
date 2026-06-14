// ignore_for_file: non_constant_identifier_names

import 'package:aopd/aopd.dart';
import 'package:example/demos/feature_flag/feature_flag_runtime.dart';
import 'package:example/shared/demo_event_log.dart';

const String _vmEntryPoint = 'vm:entry-point';
const String _targets =
    'package:example/demos/feature_flag/feature_flag_targets.dart';

@Aspect()
@pragma(_vmEntryPoint)
class FeatureFlagAspect {
  @pragma(_vmEntryPoint)
  const FeatureFlagAspect();

  @Execute(_targets, 'CheckoutDecisionService', '-loyaltyDiscountPercent')
  @pragma(_vmEntryPoint)
  dynamic CheckoutDecisionService_loyaltyDiscountPercent(PointCut pointCut) {
    final FeatureFlagRuntime runtime = FeatureFlagRuntime.instance;
    final int legacy = pointCut.proceed() as int;
    final List<dynamic>? params = pointCut.positionalParams;
    final String segment = params != null && params.isNotEmpty
        ? params[0] as String
        : 'guest';
    final int cartCents = params != null && params.length > 1
        ? params[1] as int
        : 0;

    if (!runtime.checkoutV2Enabled.value) {
      runtime.record(
        FlagDecision(
          flag: 'checkout_v2',
          enabled: false,
          result: '$legacy%',
          note: 'proceed() returned the legacy discount for $segment.',
        ),
      );
      return legacy;
    }

    final int boosted = segment == 'vip'
        ? legacy + 5
        : cartCents >= 10000
        ? legacy + 3
        : legacy;
    runtime.record(
      FlagDecision(
        flag: 'checkout_v2',
        enabled: true,
        result: '$boosted%',
        note: 'AOP advice layered the experiment over the legacy method.',
      ),
    );
    DemoEventLog.instance.addAspect(
      'Feature flag decision',
      'checkout_v2 ON: $legacy% -> $boosted%',
    );
    return boosted;
  }

  @Execute(_targets, 'CheckoutDecisionService', '-paymentGateway')
  @pragma(_vmEntryPoint)
  dynamic CheckoutDecisionService_paymentGateway(PointCut pointCut) {
    final FeatureFlagRuntime runtime = FeatureFlagRuntime.instance;
    final List<dynamic>? params = pointCut.positionalParams;
    final String region = params != null && params.isNotEmpty
        ? params[0] as String
        : 'US';

    if (runtime.gatewayV2Enabled.value && region != 'US') {
      const String gateway = 'aopd-pay-v2';
      runtime.record(
        const FlagDecision(
          flag: 'gateway_v2',
          enabled: true,
          result: gateway,
          note: 'Advice returned the experiment gateway without proceed().',
        ),
      );
      DemoEventLog.instance.addAspect(
        'Feature flag short-circuit',
        'gateway_v2 ON returned $gateway for $region without target execution.',
      );
      return gateway;
    }

    final String gateway = pointCut.proceed() as String;
    runtime.record(
      FlagDecision(
        flag: 'gateway_v2',
        enabled: runtime.gatewayV2Enabled.value,
        result: gateway,
        note: 'proceed() selected the legacy gateway.',
      ),
    );
    return gateway;
  }
}
