import 'package:example/shared/demo_event_log.dart';

class CheckoutDecisionService {
  int loyaltyDiscountPercent(String segment, int cartCents) {
    DemoEventLog.instance.addTarget(
      'Flag target',
      'loyaltyDiscountPercent($segment, $cartCents) returned the legacy rule.',
    );
    if (segment == 'vip') {
      return 10;
    }
    return cartCents >= 10000 ? 4 : 0;
  }

  String paymentGateway(String region) {
    DemoEventLog.instance.addTarget(
      'Flag target',
      'paymentGateway($region) selected the legacy provider.',
    );
    return region == 'EU' ? 'legacy-eu-pay' : 'legacy-pay';
  }
}
