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
  final cwd = Directory.current.path;
  const String fileToBeDeleted = './test.txt';
  late DeleteFile deleteCmd;

  // ...........................................................................
  setUp(() {
    env = TestEnvironment();
    deleteCmd = DeleteFile(
      ggLog: env.logMessages.add,
    );
    env.addCommand(deleteCmd);
  });

  tearDown(() {
    Directory.current = cwd;
  });

  // ...........................................................................
  group('DeleteFile', () {
    for (final dryRun in ['', '--dry-run', '--no-dry-run']) {
      final isDryRun = dryRun == '--dry-run' || dryRun == '';

      test('should copy a file to repos${isDryRun ? ' --dry-run' : ''}',
          () async {
        // Let file exist already in dir0
        final dir0 = env.sampleRepos[0];
        final existingFilePath = join(dir0.path, 'lib', 'a', 'b', 'test.txt');
        final existingFile = File(existingFilePath);
        Directory(dirname(existingFilePath)).createSync(recursive: true);
        existingFile.writeAsStringSync('test');

        // Run the command
        await env.runner.run([
          'delete-file',
          '--source=$fileToBeDeleted',
          '--repos=${env.root}',
          dryRun,
        ]);

        // Did delete file in all repos? But only when not dry-run
        for (final repo in env.sampleRepos) {
          final deleteFilePath = join(repo.path, 'test.txt');
          final file = File(deleteFilePath);
          expect(file.existsSync(), isDryRun ? isTrue : isFalse);
        }

        // Did print dry-run hint?
        expect(
          hasLog(env.logMessages, deleteCmd.dryRunHint),
          isDryRun ? isTrue : isFalse,
        );

        // Did write right log message?
        expect(
          hasLog(env.logMessages, 'Deleting ./test.txt from all repositories'),
          isTrue,
        );

        // Did log copied file pathes?
        expect(hasLog(env.logMessages, 'dir0/test.txt'), isTrue);
        expect(hasLog(env.logMessages, 'dir1/test.txt'), isTrue);
        expect(hasLog(env.logMessages, 'dir2/test.txt'), isTrue);
      });
    }

    // #########################################################################
    group('should throw', () {
      for (final missing in ['source']) {
        test('when --"$missing" is not set', () async {
          await expectLater(
            env.runner.run([
              'delete-file',
              if (missing != 'source') '--source=${'./test.txt'}',
              '--repos=${env.root}',
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
