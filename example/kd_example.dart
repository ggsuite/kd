#!/usr/bin/env dart
// @license
// Copyright (c) 2019 - 2024 Dr. Gabriel Gatzsche. All Rights Reserved.
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

import '../bin/kd.dart';

Future<void> main() async {
  print('Executing');
  await runKidney(
    args: ['bash', '--verbose', 'ls', '-l', '-a'],
    ggLog: (String message) {
      print(message);
    },
  );

  print('Done.');
}
