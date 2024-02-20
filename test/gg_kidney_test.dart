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

  group('GgKidney()', () {
    // #########################################################################
    group('exec()', () {
      test('description of the test ', () async {
        final ggKidney =
            GgKidney(param: 'foo', log: (msg) => messages.add(msg));

        await ggKidney.exec();
      });
    });

    // #########################################################################
    group('Command', () {
      test('should allow to run the code from command line', () async {
        final ggKidney = GgKidneyCmd(log: (msg) => messages.add(msg));

        final CommandRunner<void> runner = CommandRunner<void>(
          'ggKidney',
          'Description goes here.',
        )..addCommand(ggKidney);

        await runner.run(['ggKidney', '--param', 'foo']);
      });
    });
  });
}
