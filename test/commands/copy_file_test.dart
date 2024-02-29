// @license
// Copyright (c) 2019 - 2024 Dr. Gabriel Gatzsche. All Rights Reserved.
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

import 'dart:io';

import 'package:colorize/colorize.dart';
import 'package:gg_capture_print/gg_capture_print.dart';
import 'package:gg_kidney/src/commands/copy_file.dart';
import 'package:path/path.dart';
import 'package:test/test.dart';

import '../test_helpers/init_environment.dart';

void main() {
  late TestEnvironment env;
  final cwd = Directory.current.path;
  late File testFile;
  late CopyFile copyFile;

  // ...........................................................................
  void initTestFile() {
    final tmpDir = Directory.systemTemp.createTempSync();
    final testFilePath = join(tmpDir.path, 'test.txt');
    testFile = File(testFilePath)..writeAsString('test');
  }

  initTestFile();

  // ...........................................................................
  setUp(() {
    env = TestEnvironment();
    copyFile = CopyFile(
      log: env.logMessages.add,
    );
    env.addCommand(copyFile);
  });

  tearDown(() {
    Directory.current = cwd;
  });

  // ...........................................................................
  group('CopyFile', () {
    for (final dryRun in [true, false]) {
      for (final force in [true, false]) {
        test(
            'should copy a file to repos${dryRun ? ' --dry-run' : ''}'
            '${force ? ' --force' : ''}', () async {
          // Let file exist already in dir0
          final dir0 = env.sampleRepos[0];
          final existingFilePath = join(dir0.path, 'lib', 'a', 'b', 'test.txt');
          final existingFile = File(existingFilePath);
          Directory(dirname(existingFilePath)).createSync(recursive: true);
          existingFile.writeAsStringSync('test');

          // Run the command
          await env.runner.run([
            'copy-file',
            '--source=${testFile.path}',
            '--repos=${env.root}',
            '--output=${'lib/a/b/test.txt'}',
            if (force) '--force',
            dryRun ? '--dry-run' : '--no-dry-run',
          ]);

          // Did copy file to all repos?
          for (final repo in env.sampleRepos) {
            final newFilePath = join(repo.path, 'lib', 'a', 'b', 'test.txt');
            final file = File(newFilePath);
            final isExisting = file.path == existingFile.path;
            expect(file.existsSync(), dryRun && !isExisting ? false : true);

            if (!dryRun) {
              expect(file.readAsStringSync(), 'test');
            }
          }

          // Did print dry-run hint?
          expect(
            hasLog(env.logMessages, copyFile.dryRunHint),
            dryRun ? isTrue : isFalse,
          );

          // Did write right log message?
          expect(hasLog(env.logMessages, 'Copying test.txt to'), isTrue);
          expect(
            hasLog(env.logMessages, 'Existing files will not be overwritten'),
            force ? isFalse : isTrue,
          );

          // Did log copied file pathes?
          expect(
            hasLog(env.logMessages, 'dir0/lib/a/b/test.txt'),
            force ? isTrue : isFalse,
          );
          expect(hasLog(env.logMessages, 'dir1/lib/a/b/test.txt'), isTrue);
          expect(hasLog(env.logMessages, 'dir2/lib/a/b/test.txt'), isTrue);

          // Did print right colors?
          final darkGray = Colorize().buildEscSeq(Styles.DARK_GRAY);
          final blue = Colorize().buildEscSeq(Styles.BLUE);
          final color = dryRun ? darkGray : blue;
          expect(hasLog(env.logMessages, color), isTrue);
          expect(hasLog(env.logMessages, color), isTrue);
          expect(hasLog(env.logMessages, color), isTrue);
        });
      }
    }

    // #########################################################################
    group('should throw', () {
      // .......................................................................
      test('when source file does not exist', () async {
        await expectLater(
          () => env.runner.run([
            'copy-file',
            '--source=not-existing.txt',
            '--repos=${env.root}',
            '--output=lib/a/b/test.txt',
          ]),
          throwsA(
            isA<ArgumentError>().having(
              (e) => e.message,
              'path',
              contains('The file to be copied does not exist.'),
            ),
          ),
        );
      });

      for (final missing in ['source', 'output']) {
        test('when "$missing" is not set', () async {
          await expectLater(
            env.runner.run([
              'copy-file',
              if (missing != 'source') '--source=${testFile.path}',
              '--repos=${env.root}',
              if (missing != 'output') '--output=${'lib/a/b/test.txt'}',
              '--force',
              '--dry-run',
            ]),
            throwsA(
              isA<ArgumentError>().having(
                (ArgumentError e) => e.message,
                'message',
                contains('Option $missing is mandatory.'),
              ),
            ),
          );
        });
      }
    });
  });
}
