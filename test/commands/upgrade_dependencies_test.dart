// @license
// Copyright (c) 2019 - 2024 Dr. Gabriel Gatzsche. All Rights Reserved.
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

import 'dart:io';

import 'package:gg_kidney/src/commands/upgrade_dependencies.dart';
import 'package:gg_test_helpers/gg_test_helpers.dart';
import 'package:path/path.dart';
import 'package:test/test.dart';

import '../test_helpers/init_environment.dart';

void main() {
  // ###########################################################################

  setUp(() {
    resetEnvironment(
      UpgradeDependencies(
        log: logMessages.add,
        processRun: processRun,
      ),
    );
    logMessages.clear();
  });

  // ###########################################################################
  group('UpgradeDependencies', () {
    test('should add --dry-run when dryRun is true', () async {
      // Run the command
      await runner.run([
        'upgrade-dependencies',
        '--dry-run',
        '--input-dir',
        root,
      ]);

      // Check the result
      calls.sort((a, b) => a.workingDirectory!.compareTo(b.workingDirectory!));
      expect(calls, isNotEmpty);

      // For each repo dart pub upgrade should be called
      for (int i = 0; i < calls.length; i++) {
        expect(calls[i].workingDirectory, sampleRepos[i].path);
        expect(calls[i].dryRun, true);
        expect(calls[i].executable, 'dart');
        expect(
          calls[i].arguments,
          [
            'pub',
            'upgrade',
            '--major-versions',
            '--dry-run',
          ],
        );
      }

      // Should set the exit code to 0
      expect(exitCode, 0);
    });

    // .........................................................................
    test('should not add --dry-run when --dry-run is not given', () async {
      // Run the command
      await runner.run([
        'upgrade-dependencies',
        '--no-dry-run',
        '--input-dir',
        root,
      ]);

      // For each repo dart pub upgrade should be called
      for (int i = 0; i < calls.length; i++) {
        expect(calls[i].dryRun, false);
        expect(calls[i].arguments, ['pub', 'upgrade', '--major-versions']);
      }
    });

    // .........................................................................
    test('should log console output when process did not succeed', () async {
      // Define process result
      const error = 5;
      processResult = ProcessResult(1, error, 'stdout', 'stderror');

      // Run the command
      await runner.run([
        'upgrade-dependencies',
        '--no-dry-run',
        '--input-dir',
        root,
      ]);

      calls.sort((a, b) => a.workingDirectory!.compareTo(b.workingDirectory!));

      // For each failed command, a log message should be written
      for (int i = 0; i < calls.length; i++) {
        final dir = basename(calls[i].workingDirectory!);
        expect(
          hasLog(
            'Failed to upgrade dependencies for $dir',
            logMessages,
          ),
          isTrue,
        );

        expect(
          hasLog(
            'stderror',
            logMessages,
          ),
          isTrue,
        );

        expect(
          hasLog(
            'stdout',
            logMessages,
          ),
          isTrue,
        );
      }

      // Should set the exit code to 1
      expect(exitCode, error);
    });
  });
}
