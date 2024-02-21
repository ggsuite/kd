// @license
// Copyright (c) 2019 - 2024 Dr. Gabriel Gatzsche. All Rights Reserved.
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

import 'dart:io';

import 'package:gg_kidney/src/tools/process_run.dart';
import 'package:test/test.dart';

void main() {
  group('ProcessRun', () {
    test('should work fine', () {
      foo();
      ProcessRun processRun = Process.run;
      expect(processRun, isNotNull);
    });
  });
}
