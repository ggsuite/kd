// @license
// Copyright (c) 2019 - 2024 Dr. Gabriel Gatzsche. All Rights Reserved.
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

import 'dart:io';

import 'package:gg_capture_print/gg_capture_print.dart';
import 'package:gg_kidney/src/commands/delete_file.dart';
import 'package:path/path.dart';
import 'package:test/test.dart';

import '../test_helpers/init_environment.dart';

void main() {
  late TestEnvironment env;
  final cwd = Directory.current;
  // ...........................................................................
  setUp(() {
    env = TestEnvironment();
    env.addCommand(
      DeleteFile(
        log: env.logMessages.add,
        process: env.process,
      ),
    );
  });

  tearDown(() {
    Directory.current = cwd;
  });

  // ...........................................................................
  group('DeleteFile', () {
    test('should delete a file from one repo and all others', () async {
      // Pubspec.yaml should exist before
      for (final repo in env.sampleRepos) {
        final file = File(join(repo.path, 'test.txt'));
        expect(file.existsSync(), true);
      }

      // Change into first repo
      Directory.current = env.sampleRepos.first;

      // Run the command
      await env.runner.run([
        'delete-file',
        '--file',
        './test.txt',
        '--apply',
      ]);

      // File should have been deleted
      for (final repo in env.sampleRepos) {
        final file = File(join(repo.path, 'test.txt'));
        expect(file.existsSync(), false);
      }

      // Check if right log messages have been written
      expect(
        hasLog('Deleting test.txt from', env.logMessages),
        isTrue,
      );

      expect(
        hasLog('- dir0', env.logMessages),
        isTrue,
      );

      expect(
        hasLog('- dir2', env.logMessages),
        isTrue,
      );

      expect(
        hasLog('- dir1', env.logMessages),
        isTrue,
      );
    });

    // .........................................................................
    test('should not delete when --apply flag is not set', () async {
      // Pubspec.yaml should exist before
      for (final repo in env.sampleRepos) {
        final file = File(join(repo.path, 'test.txt'));
        expect(file.existsSync(), true);
      }

      // Change into first repo
      Directory.current = env.sampleRepos.first;

      // Run the command
      await env.runner.run([
        'delete-file',
        '--file',
        './test.txt',
      ]);

      // File should have been deleted
      for (final repo in env.sampleRepos) {
        final file = File(join(repo.path, 'test.txt'));
        expect(file.existsSync(), true);
      }

      // Check if right log messages have been written
      expect(
        hasLog('Deleting test.txt from', env.logMessages),
        isTrue,
      );

      expect(
        hasLog('- dir0', env.logMessages),
        isTrue,
      );

      expect(
        hasLog('- dir2', env.logMessages),
        isTrue,
      );

      expect(
        hasLog('- dir1', env.logMessages),
        isTrue,
      );
    });

    // .........................................................................
    test('should throw if the file to delete does not exist', () async {
      await expectLater(
        () => env.runner.run([
          'delete-file',
          '--file',
          '/xy/zk/ab.txt',
          '--apply',
        ]),
        throwsA(
          isA<ArgumentError>().having(
            (e) => e.message,
            'message',
            'The file /xy/zk/ab.txt does not exist.',
          ),
        ),
      );
    });

    // .........................................................................
    test('should throw if the file to delete is not part of a flutter project',
        () async {
      // Create a file within a non-dart/flutter project
      final tmpDir = Directory.systemTemp.createTempSync();
      final subdir = Directory(join(tmpDir.path, 'a/b/c'))
        ..createSync(recursive: true);
      final filePath = join(subdir.path, 'test.txt');
      File(filePath).writeAsStringSync('test');

      // Run delete file
      await expectLater(
        () => env.runner.run([
          'delete-file',
          '--file',
          filePath,
          '--apply',
        ]),
        throwsA(
          isA<ArgumentError>().having(
            (e) => e.message,
            'message',
            'The file test.txt is not part of a dart or flutter project.',
          ),
        ),
      );
    });
  });
}
