// @license
// Copyright (c) 2019 - 2024 Dr. Gabriel Gatzsche. All Rights Reserved.
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

import 'package:test/test.dart';

void expectLog(String log, List<String> logMessages) {
  final didFindLog = logMessages.any((element) => element.contains(log));
  expect(didFindLog, isTrue, reason: 'Log message not found: $log');
}
