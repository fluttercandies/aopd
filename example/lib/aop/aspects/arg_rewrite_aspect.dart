// ignore_for_file: non_constant_identifier_names

import 'package:aopd/aopd.dart';
import 'package:example/demos/arg_rewrite/arg_rewrite_runtime.dart';

const String _vmEntryPoint = 'vm:entry-point';
const String _targets =
    'package:example/demos/arg_rewrite/arg_rewrite_targets.dart';

/// Demonstrates rewriting a method's ARGUMENTS before it runs -- the one
/// PointCut capability no other demo exercises. The proceed closure reads each
/// argument from `pointCut.positionalParams` at proceed() time, so mutating
/// that list here changes what the original method receives.
///
/// Two real uses: redact PII before it reaches a log sink, and normalize/clamp
/// user input before business logic sees it -- both with zero changes to the
/// target methods.
@Aspect()
@pragma(_vmEntryPoint)
class ArgRewriteAspect {
  @pragma(_vmEntryPoint)
  const ArgRewriteAspect();

  @Execute(_targets, 'AuditLog', '-record')
  @pragma(_vmEntryPoint)
  dynamic AuditLog_record(PointCut pointCut) {
    final List<dynamic>? params = pointCut.positionalParams;
    if (params != null && params.isNotEmpty && params[0] is String) {
      final String original = params[0] as String;
      final String redacted = _redact(original);
      if (redacted != original) {
        params[0] = redacted; // rewrite BEFORE proceed -> body sees redacted
        ArgRewriteRuntime.instance
            .noteRewrite('AuditLog.record', original, redacted);
      }
    }
    return pointCut.proceed();
  }

  @Execute(_targets, 'SignupService', '-register')
  @pragma(_vmEntryPoint)
  dynamic SignupService_register(PointCut pointCut) {
    final List<dynamic>? params = pointCut.positionalParams;
    if (params != null && params.length >= 2) {
      final Object? email = params[0];
      final Object? age = params[1];
      if (email is String) {
        params[0] = email.trim().toLowerCase();
      }
      if (age is int) {
        params[1] = age.clamp(0, 120);
      }
      if (params[0] != email || params[1] != age) {
        ArgRewriteRuntime.instance.noteRewrite(
          'SignupService.register',
          'email="$email", age=$age',
          'email="${params[0]}", age=${params[1]}',
        );
      }
    }
    return pointCut.proceed();
  }

  static final RegExp _phone = RegExp(r'(\d{3})\d{4}(\d{4})');
  static final RegExp _email = RegExp(r'[\w.+-]+@([\w-]+\.[\w.-]+)');

  static String _redact(String input) {
    String out = input.replaceAllMapped(
      _phone,
      (Match m) => '${m[1]}****${m[2]}',
    );
    out = out.replaceAllMapped(_email, (Match m) => '***@${m[1]}');
    return out;
  }
}
