// Copyright 2026 AOPD contributors. All rights reserved.
// Use of this source code is governed by the MIT license in the LICENSE file.

// Regression test for M1.3: AOPD source markers must match on CRLF sources.

import '../transformer/rewriters/aop_transform_utils.dart';
import '_harness.dart';

void main() {
  const String ignore = '//AOPD Ignore';
  const String replaceThis = '//AOPD Replace This';

  group('marker matches across line endings (M1.3 CRLF fix)', () {
    // The source line as sliced by lineStarts includes the trailing newline.
    check(AopUtils.lineEndsWithMarker('var x = 1; $ignore\n', ignore),
        'LF line with Ignore marker');
    check(AopUtils.lineEndsWithMarker('var x = 1; $ignore\r\n', ignore),
        'CRLF line with Ignore marker (the bug)');
    check(AopUtils.lineEndsWithMarker('foo(); $replaceThis\r\n', replaceThis),
        'CRLF line with Replace-This marker');
    check(AopUtils.lineEndsWithMarker('var x = 1; $ignore  \r\n', ignore),
        'trailing spaces before CRLF still match');
    check(AopUtils.lineEndsWithMarker('var x = 1; $ignore', ignore),
        'no trailing newline still matches');
  });

  group('non-markers do not match', () {
    check(!AopUtils.lineEndsWithMarker('var x = 1;\r\n', ignore),
        'plain line without marker');
    check(!AopUtils.lineEndsWithMarker('// not the marker\r\n', ignore),
        'comment that is not the marker');
    check(!AopUtils.lineEndsWithMarker('$ignore = trailing code;\r\n', ignore),
        'marker not at end-of-line does not match');
  });

  finish();
}
