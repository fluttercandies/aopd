// Copyright 2026 AOPD contributors. All rights reserved.
// Use of this source code is governed by the MIT license in the LICENSE file.

library;

import 'dart:io';
import 'server.dart';

void main(List<String> args) async {
  final int exitCode = await starter(args);
  if (exitCode != 0) {
    exit(exitCode);
  }
}
