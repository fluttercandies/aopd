import 'package:example/demos/arg_rewrite/arg_rewrite_runtime.dart';

// Targets for the argument-rewriting demo. Each method simply REPORTS the value
// it actually received and returns it. The methods do no cleaning of their own
// -- the arg_rewrite aspect mutates pointCut.positionalParams BEFORE proceed(),
// so what these bodies see is already redacted / sanitized. That "received"
// value is the proof the advice changed the inputs, not just the outputs.

class AuditLog {
  /// Records a log line. The aspect redacts PII in [message] before this runs,
  /// so a leaked phone/email never reaches the (hypothetical) log sink.
  String record(String message) {
    ArgRewriteRuntime.instance.noteReceived('AuditLog.record', message);
    return message;
  }
}

class SignupService {
  /// Registers a user. The aspect trims+lowercases [email] and clamps [age]
  /// before this runs, so downstream code always sees normalized inputs.
  String register(String email, int age) {
    ArgRewriteRuntime.instance
        .noteReceived('SignupService.register', 'email="$email", age=$age');
    return 'registered:$email:$age';
  }
}
