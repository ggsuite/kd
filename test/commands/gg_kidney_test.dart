// @license
// Copyright (c) 2019 - 2024 Dr. Gabriel Gatzsche. All Rights Reserved.
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

import 'package:args/command_runner.dart';
import 'package:gg_kidney/gg_kidney.dart';
import 'package:test/test.dart';

void main() {
  final messages = <String>[];

  // #########################################################################
  group('GgKidney', () {
    test('should print a help if no param is given', () async {
      final ggKidney = GgKidney(log: (msg) => messages.add(msg));

      final CommandRunner<void> runner = CommandRunner<void>(
        'ggKidney',
        'Description goes here.',
      )..addCommand(ggKidney);

      expect(
        runner.usage,
        contains('kidney   Various maintenance tasks for our repositories.'),
      );
    });
  });
}
