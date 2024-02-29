// @license
// Copyright (c) 2019 - 2024 Dr. Gabriel Gatzsche. All Rights Reserved.
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

import 'dart:io';

import 'package:gg_capture_print/gg_capture_print.dart';
import 'package:gg_kidney/src/commands/upgrade_dependencies.dart';
import 'package:path/path.dart';
import 'package:test/test.dart';

import '../test_helpers/init_environment.dart';

void main() {
  // ###########################################################################

  late TestEnvironment env;

  // ...........................................................................
  setUp(() {
    env = TestEnvironment();

    env.addCommand(
      UpgradeDependencies(
        log: env.logMessages.add,
        process: env.process,
      ),
    );
  });

  // ###########################################################################
  group('UpgradeDependencies', () {
    test('should add --dry-run when dryRun is true', () async {
      // Run the command
      await env.runner.run([
        'upgrade-dependencies',
        '--dry-run',
        '--repos',
        env.root,
      ]);

      // Check the result
      final calls = env.process.calls;
      calls.sort((a, b) => a.workingDirectory!.compareTo(b.workingDirectory!));
      expect(env.process.calls, isNotEmpty);

      // For each repo dart pub upgrade should be called
      for (int i = 0; i < calls.length; i++) {
        expect(calls[i].workingDirectory, env.sampleRepos[i].path);
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
      await env.runner.run([
        'upgrade-dependencies',
        '--no-dry-run',
        '--repos',
        env.root,
      ]);

      // For each repo dart pub upgrade should be called
      final calls = env.process.calls;
      for (int i = 0; i < calls.length; i++) {
        expect(calls[i].dryRun, false);
        expect(calls[i].arguments, ['pub', 'upgrade', '--major-versions']);
      }
    });

    // .........................................................................
    test('should log console output when process did not succeed', () async {
      // Define process result
      const error = 5;
      final processResult = ProcessResult(1, error, 'stdout', 'stderror');

      final env = TestEnvironment(processResult: processResult);

      env.addCommand(
        UpgradeDependencies(
          log: env.logMessages.add,
          process: env.process,
        ),
      );

      // Run the command
      await env.runner.run([
        'upgrade-dependencies',
        '--no-dry-run',
        '--repos',
        env.root,
      ]);

      final calls = env.process.calls;
      final logMessages = env.logMessages;

      calls.sort((a, b) => a.workingDirectory!.compareTo(b.workingDirectory!));

      // For each failed command, a log message should be written
      for (int i = 0; i < calls.length; i++) {
        final dir = basename(calls[i].workingDirectory!);
        expect(
          hasLog(
            logMessages,
            'Failed to upgrade dependencies for $dir',
          ),
          isTrue,
        );

        expect(
          hasLog(
            logMessages,
            'stderror',
          ),
          isTrue,
        );

        expect(
          hasLog(
            logMessages,
            'stdout',
          ),
          isTrue,
        );
      }

      // Should set the exit code to 1
      expect(exitCode, error);
    });
  });
}
