// @license
// Copyright (c) 2019 - 2024 Dr. Gabriel Gatzsche. All Rights Reserved.
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

import 'dart:io';

import 'package:gg_capture_print/gg_capture_print.dart';
import 'package:gg_kidney/src/commands/copy_file.dart';
import 'package:path/path.dart';
import 'package:test/test.dart';

import '../test_helpers/init_environment.dart';

void main() {
  late TestEnvironment env;
  final cwd = Directory.current.path;
  // ...........................................................................
  setUp(() {
    env = TestEnvironment();
    env.addCommand(
      CopyFile(
        log: env.logMessages.add,
        process: env.process,
      ),
    );
  });

  tearDown(() {
    Directory.current = cwd;
  });

  // ...........................................................................
  group('CopyFile', () {
    test('should copy a file from one repo to all others', () async {
      // Create sample repos

      // Create a test file within first repo
      final originalDir = env.sampleRepos.first.path;
      final testFileDir = join(originalDir, 'lib', 'a', 'b');
      Directory(testFileDir).createSync(recursive: true);
      final testFilePath = join(testFileDir, 'test.txt');
      File(testFilePath).writeAsStringSync('test');

      // Run the command
      await env.runner.run([
        'copy-file',
        '--file',
        testFilePath,
        '--apply',
      ]);

      // Check if the file has been copied to all other repos
      for (final repo in env.sampleRepos) {
        final newFilePath = join(repo.path, 'lib', 'a', 'b', 'test.txt');
        final file = File(newFilePath);
        expect(file.existsSync(), true);
        expect(file.readAsStringSync(), 'test');
      }

      // Check if right log messages have been written
      expect(
        hasLog('Copying test.txt to', env.logMessages),
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
    test('should copy also when file path is relative to repo', () async {
      // Create sample repos

      // Create a test file within first repo
      final originalRepo = env.sampleRepos.first.path;
      final testFileDir = join(originalRepo, 'lib', '.', 'a', 'b', '.');
      Directory(testFileDir).createSync(recursive: true);
      final testFilePath = join(testFileDir, 'test.txt');
      File(testFilePath).writeAsStringSync('test');

      // Create relative test file path
      final relativeTestFilePath = relative(testFilePath, from: originalRepo);

      // Run the command from the original repo
      Directory.current = originalRepo;
      await env.runner.run([
        'copy-file',
        '--file',
        relativeTestFilePath,
        '--apply',
      ]);

      // Check if the file has been copied to all other repos
      for (final repo in env.sampleRepos) {
        final newFilePath = join(repo.path, 'lib', 'a', 'b', 'test.txt');
        final file = File(newFilePath);
        expect(file.existsSync(), true);
        expect(file.readAsStringSync(), 'test');
      }

      // Check if right log messages have been written
      expect(
        hasLog('Copying test.txt to', env.logMessages),
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

      expect(
        hasLog('- dir0', env.logMessages),
        isFalse,
      );
    });

    // .........................................................................
    test('should not copy when --apply flag is not set', () async {
      // Create sample repos

      // Create a test file within first repo
      final originalDir = env.sampleRepos.first.path;
      final testFileDir = join(originalDir, 'lib', 'a', 'b');
      Directory(testFileDir).createSync(recursive: true);
      final testFilePath = join(testFileDir, 'test.txt');
      File(testFilePath).writeAsStringSync('test');

      // Run the command
      await env.runner.run([
        'copy-file',
        '--file',
        testFilePath,
      ]);

      // Should have performed dry-run
      expect(
        hasLog(
          'Dry-run: No files will be copied. '
          'Run with --apply to apply changes.',
          env.logMessages,
        ),
        isTrue,
      );

      // Check if the file has been copied to all other repos
      for (final repo in env.sampleRepos) {
        final isOriginal = repo.path == originalDir;
        final newFilePath = join(repo.path, 'lib', 'a', 'b', 'test.txt');
        final file = File(newFilePath);
        expect(file.existsSync(), isOriginal ? true : false);
      }

      // Check if right log messages have been written
      expect(
        hasLog('Copying test.txt to', env.logMessages),
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
    test('should throw if the file to copy does not exist', () async {
      await expectLater(
        () => env.runner.run([
          'copy-file',
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
    test('should throw if the file to copy is not part of a flutter project',
        () async {
      // Create a file within a non-dart/flutter project
      final tmpDir = Directory.systemTemp.createTempSync();
      final subdir = Directory(join(tmpDir.path, 'a/b/c'))
        ..createSync(recursive: true);
      final filePath = join(subdir.path, 'test.txt');
      File(filePath).writeAsStringSync('test');

      // Run copy file
      await expectLater(
        () => env.runner.run([
          'copy-file',
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

    // .........................................................................
    test('should work with this repos', () async {
      // Create sample repos
      final check = File('./check');
      expect(check.existsSync(), isTrue);

      // Run the command from the original repo
      await env.runner.run([
        'copy-file',
        '--file',
        './check',
      ]);

      // Check if right log messages have been written
      expect(
        hasLog('Copying check to', env.logMessages),
        isTrue,
      );

      expect(
        hasLog('- gg_cache', env.logMessages),
        isTrue,
      );
    });
  });
}
