// @license
// Copyright (c) 2019 - 2024 Dr. Gabriel Gatzsche. All Rights Reserved.
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:gg_kidney/src/commands/update_dart_sdk.dart';
import 'package:test/test.dart';

import '../tools/create_sample_folders.dart';

void main() {
  late Directory tmp;
  late Directory dir0;
  late Directory dir1;
  late Directory dir2;
  late List<Directory> dartRepos;
  late CommandRunner<dynamic> runner;
  late List<String> messages;
  final emptyDir = Directory.systemTemp.createTempSync();

  // ...........................................................................
  void initDirectories() {
    [dir0, dir1, dir2] = createSampleRepos();
    dartRepos = [dir0, dir1, dir2];
    tmp = dir0.parent;
  }

  // ...........................................................................
  void initRunner() {
    messages = <String>[];
    final updateDartSdk = UpdateDartSdk(log: messages.add);

    runner = CommandRunner<void>(
      'ggKidney',
      'Description goes here.',
    )..addCommand(updateDartSdk);
  }

  // ...........................................................................
  setUp(() {
    initDirectories();
    initRunner();
  });

  // ...........................................................................
  tearDown(() {
    for (final dir in dartRepos) {
      dir.deleteSync(recursive: true);
    }
  });

  // ...........................................................................
  void expectMessage(String message) {
    for (final msg in messages) {
      if (msg.contains(message)) {
        return;
      }
    }

    fail('Message not found: $message');
  }

  // ...........................................................................
  group('GgUpdateDartSdkTest()', () {
    // .........................................................................
    group('run()', () {
      // .......................................................................
      test('should complain if no dart repository is found in current dir',
          () async {
        // Run in empty directory
        await runner.run(
          ['update-dart-sdk', '-i', emptyDir.path, '--min-version', '3.3.0'],
        );

        // An error message should be printed
        expectMessage('No dart repositories found in');
      });

      // .......................................................................
      test('should update the dart sdk in the current project', () async {
        await runner.run(['update-dart-sdk', '--min-version', '3.3.0', '-d']);
        expectMessage(
          'Updated the Dart SDK version to ">=3.3.0<4.0.0" in gg_kidney',
        );
      });

      // .......................................................................
      test('should update the dart sdk in a given project', () async {
        await runner.run([
          'update-dart-sdk',
          '--min-version',
          '3.3.0',
          '-i',
          dir0.path,
        ]);
        expectMessage(
          'Updated the Dart SDK version to ">=3.3.0<4.0.0" in dir0',
        );

        final pubspec = File('${dir0.path}/pubspec.yaml').readAsStringSync();
        expect(pubspec.contains('sdk: ">=3.3.0<4.0.0"'), isTrue);
      });

      // .......................................................................
      test('should update all dart repositories in the current directory',
          () async {
        await runner.run([
          'update-dart-sdk',
          '--min-version',
          '3.3.0',
          '-i',
          tmp.path,
        ]);

        expectMessage(
          'Updated the Dart SDK version to ">=3.3.0<4.0.0" in dir0',
        );
        expectMessage(
          'Updated the Dart SDK version to ">=3.3.0<4.0.0" in dir1',
        );
        expectMessage(
          'Updated the Dart SDK version to ">=3.3.0<4.0.0" in dir2',
        );
      });
    });
  });
}
