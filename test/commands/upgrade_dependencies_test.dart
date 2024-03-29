// @license
// Copyright (c) 2019 - 2024 Dr. Gabriel Gatzsche. All Rights Reserved.
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

import 'dart:io';

import 'package:gg_console_colors/gg_console_colors.dart';
import 'package:gg_kidney/src/commands/upgrade_dependencies.dart';
import 'package:mocktail/mocktail.dart';
import 'package:path/path.dart';
import 'package:test/test.dart';

import '../test_helpers/init_environment.dart';

void main() {
  // ###########################################################################

  late TestEnvironment env;

  // ...........................................................................
  void mockDartPubUpgrade({
    int exitCode = 0,
    bool dryRun = true,
    String stdout = '',
    String stderr = '',
  }) {
    for (final repo in env.sampleRepos) {
      when(
        () => env.process.run(
          'dart',
          [
            'pub',
            'upgrade',
            '--major-versions',
            if (dryRun) '--dry-run',
          ],
          workingDirectory: repo.path,
        ),
      ).thenAnswer((invocation) {
        return Future.value(ProcessResult(0, exitCode, stdout, stderr));
      });
    }
  }

  // ...........................................................................
  void veriyDartPubUpgrade({bool dryRun = true}) {
    for (final repo in env.sampleRepos) {
      verify(
        () => env.process.run(
          'dart',
          [
            'pub',
            'upgrade',
            '--major-versions',
            if (dryRun) '--dry-run',
          ],
          workingDirectory: repo.path,
        ),
      ).called(1);
    }
  }

  // ...........................................................................
  setUp(() {
    env = TestEnvironment();

    env.addCommand(
      UpgradeDependencies(
        ggLog: env.logMessages.add,
        process: env.process,
      ),
    );
  });

  // ###########################################################################
  group('UpgradeDependencies', () {
    test('should add --dry-run when dryRun is true', () async {
      mockDartPubUpgrade(exitCode: 0, dryRun: true);

      // Run the command
      await env.runner.run([
        'upgrade-dependencies',
        '--dry-run',
        '--repos',
        env.root,
      ]);

      // Check if »dart pub upgrade« was called

      // Check the result
      veriyDartPubUpgrade(dryRun: true);

      // Should set the exit code to 0
      expect(exitCode, 0);
    });

    // .........................................................................
    test('should not add --dry-run when --dry-run is not given', () async {
      mockDartPubUpgrade(exitCode: 0, dryRun: false);

      // Run the command
      await env.runner.run([
        'upgrade-dependencies',
        '--no-dry-run',
        '--repos',
        env.root,
      ]);

      // For each repo dart pub upgrade should be called
      veriyDartPubUpgrade(dryRun: false);
    });

    // .........................................................................
    test('should log console output when process did not succeed', () async {
      // Define process result
      const error = 5;
      mockDartPubUpgrade(
        exitCode: 5,
        dryRun: false,
        stdout: 'stdout',
        stderr: 'stderror',
      );

      // Run the command
      await env.runner.run([
        'upgrade-dependencies',
        '--no-dry-run',
        '--repos',
        env.root,
      ]);

      // Verify that the process was called
      veriyDartPubUpgrade(dryRun: false);

      final logMessages = env.logMessages;
      const prefix0 = 'Upgrade package dependencies of';
      const prefix1 = 'Failed to upgrade dependencies for';
      expect(
        logMessages[1],
        '$prefix0 ${basename(env.sampleRepos[0].path)}.',
      );

      expect(
        logMessages[2],
        red('$prefix1 ${basename(env.sampleRepos[0].path)}.'),
      );

      // Should set the exit code to 1
      expect(exitCode, error);
    });
  });
}
