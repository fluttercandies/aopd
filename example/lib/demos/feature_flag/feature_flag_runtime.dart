import 'package:flutter/foundation.dart';

class FlagDecision {
  const FlagDecision({
    required this.flag,
    required this.enabled,
    required this.result,
    required this.note,
  });

  final String flag;
  final bool enabled;
  final String result;
  final String note;
}

class FeatureFlagRuntime {
  FeatureFlagRuntime._();

  static final FeatureFlagRuntime instance = FeatureFlagRuntime._();

  final ValueNotifier<bool> checkoutV2Enabled = ValueNotifier<bool>(false);
  final ValueNotifier<bool> gatewayV2Enabled = ValueNotifier<bool>(false);
  final ValueNotifier<List<FlagDecision>> decisions =
      ValueNotifier<List<FlagDecision>>(<FlagDecision>[]);

  void setCheckoutV2(bool value) {
    checkoutV2Enabled.value = value;
  }

  void setGatewayV2(bool value) {
    gatewayV2Enabled.value = value;
  }

  void record(FlagDecision decision) {
    decisions.value = <FlagDecision>[
      decision,
      ...decisions.value,
    ].take(12).toList();
  }

  void reset() {
    checkoutV2Enabled.value = false;
    gatewayV2Enabled.value = false;
    decisions.value = <FlagDecision>[];
  }
}
