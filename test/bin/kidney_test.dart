// @license
// Copyright (c) 2019 - 2024 Dr. Gabriel Gatzsche. All Rights Reserved.
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

import 'dart:io';

import 'package:kidney/kidney.dart';
import 'package:test/test.dart';

import '../../bin/kidney.dart';

void main() {
  late Directory dRoot;
  late Directory d0;
  final messages = <String>[];
  final ggLog = messages.add;
  final kidney = Kidney(ggLog: ggLog);

  // ...........................................................................
  Future<void> initDartPackages() async {
    // Create a pubspec.yaml file in each directory, except dir2
    await File('${d0.path}/pubspec.yaml').writeAsString('name: dir0');

    // Create a textfile in each directory
    await File('${d0.path}/file0.txt').writeAsString('file0');
  }

  // ...........................................................................
  setUp(() async {
    messages.clear();

    dRoot = await Directory.systemTemp.createTemp('kidney_test');
    d0 = await Directory('${dRoot.path}/dir0').create();
    await initDartPackages();
  });

  tearDown(() async {
    await dRoot.delete(recursive: true);
  });

  group('runKidney(args, ggLog)', () {
    test('should runKidney', () async {
      await runKidney(
        args: [dRoot.path, '--apply', '--verbose', 'dart', '--help'],
        ggLog: ggLog,
      );
      expect(messages[0], contains('⌛️ dir0'));
      expect(messages[1], contains('✅ dir0'));
      expect(
        messages[2],
        contains(' A command-line utility for Dart development.'),
      );
    });
  });

  group('main(args)', () {
    group('should runKidney', () {
      test('- main case', () async {
        await runKidney(
          args: [dRoot.path, '--apply', '--verbose', 'dart', '--help'],
          ggLog: ggLog,
        );
        expect(messages[0], contains('⌛️ dir0'));
        expect(messages[1], contains('✅ dir0'));
        expect(
          messages[2],
          contains('A command-line utility for Dart development.'),
        );
      });

      group('- edge cases', () {
        group('should catch and print errors', () {
          test('- no arguments', () async {
            await runKidney(
              args: [],
              ggLog: ggLog,
            );
            expect(messages[0], contains(kidney.commandArgumentsMissingHelp));
          });

          test('- unknown argument', () async {
            await runKidney(
              args: [dRoot.path, '--unknown'],
              ggLog: ggLog,
            );
            expect(messages[0], contains('Invalid argument(s):'));
            expect(messages[0], contains(kidney.commandArgumentsMissingHelp));
          });
        });
      });
    });
  });
}
