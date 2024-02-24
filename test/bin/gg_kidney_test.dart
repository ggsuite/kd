// @license
// Copyright (c) 2019 - 2024 Dr. Gabriel Gatzsche. All Rights Reserved.
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

import 'package:test/test.dart';

import '../../bin/gg_kidney.dart';
import '../test_helpers/capture_print.dart';
import '../test_helpers/expect_log.dart';

void main() {
  group('runGgKidney(args, log)', () {
    // #########################################################################

    test('should allow to execute all commands of ggKidney', () async {
      final messages = <String>[];
      capturePrint(
        log: messages.add,
        code: () async {
          final args = <String>['--help'];
          await runGgKidney(args: args, log: messages.add);
          expectLog('update-dart-sdk', messages);
          expectLog('upgrade-dependencies', messages);
          expectLog('vscode', messages);
        },
      );
    });
  });
}
