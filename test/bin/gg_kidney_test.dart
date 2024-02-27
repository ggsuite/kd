// @license
// Copyright (c) 2019 - 2024 Dr. Gabriel Gatzsche. All Rights Reserved.
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

import 'package:gg_capture_print/gg_capture_print.dart';
import 'package:test/test.dart';

import '../../bin/gg_kidney.dart';

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
          expect(hasLog('update-dart-sdk', messages), isTrue);
          expect(hasLog('upgrade-dependencies', messages), isTrue);
          expect(hasLog('open-with-vscode', messages), isTrue);
        },
      );
    });
  });
}
