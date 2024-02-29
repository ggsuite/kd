// @license
// Copyright (c) 2019 - 2024 Dr. Gabriel Gatzsche. All Rights Reserved.
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

import 'dart:io';

import 'package:colorize/colorize.dart';
import 'package:gg_capture_print/gg_capture_print.dart';
import 'package:gg_kidney/src/commands/run_shell_command.dart';
import 'package:gg_process/gg_process.dart';
import 'package:test/test.dart';

import '../test_helpers/init_environment.dart';

void main() {
  late TestEnvironment env;
  late RunShellCommand runShellCommand;

  // ...........................................................................
  void init({GgProcessWrapper? processWrapper}) {
    env = TestEnvironment();
    runShellCommand = RunShellCommand(
      log: env.logMessages.add,
      processWrapper: processWrapper,
    );
    env.addCommand(runShellCommand);
  }

  group('RunShellCommand', () {
    for (final verbose in ['', '--verbose', '--no-verbose']) {
      for (final dryRun in ['', '--dry-run', '--no-dry-run']) {
        group('should allow to run a command on each repo', () {
          final isDryRun = dryRun == '--dry-run' || dryRun == '';
          final isVerbose = verbose == '--verbose';

          // ...................................................................
          test('eg. "ls -la" $dryRun $verbose', () async {
            init(processWrapper: const GgProcessWrapper());

            // Run the command
            await env.runner.run([
              'run-shell-command',
              '--repos=${env.root}',
              '--command=ls -la',
              dryRun,
              verbose,
            ]);

            final m = env.logMessages;

            // Did print an success message? No matter if dry-run or not.
            expect(hasLog(m, 'Executing "ls -la" in all repos.'), isTrue);
            expect(hasLog(m, RegExp(r'- ✅.+dir0')), isTrue);
            expect(hasLog(m, RegExp(r'- ✅.+dir1')), isTrue);
            expect(hasLog(m, RegExp(r'- ✅.+dir2')), isTrue);

            // Did print the result, when verbose?
            expect(hasLog(m, 'pubspec.yaml'), isVerbose && !isDryRun);
            expect(hasLog(m, 'test.txt'), isVerbose && !isDryRun);

            // Did print right colors?
            final colorize = Colorize();
            final darkGray = colorize.buildEscSeq(Styles.DARK_GRAY);
            final defaultStyle = colorize.buildEscSeq(Styles.DEFAULT);

            expect(hasLog(m, darkGray), isDryRun || isVerbose);
            expect(hasLog(m, defaultStyle), !isDryRun);
          });

          // ...................................................................
          test(
              'and print an error summary if something went wrong '
              '$dryRun $verbose', () async {
            init(
              processWrapper: GgProcessWrapperMock(
                runResult:
                    ProcessResult(0, 1, 'stdout result', 'stderr result'),
              ),
            );

            // Run the command
            await env.runner.run([
              'run-shell-command',
              '--repos=${env.root}',
              '--command=xyz',
              dryRun,
              verbose,
            ]);

            final m = env.logMessages;

            // Process result above was defined 1.
            // Did print an faile message? No matter if dry-run or not.
            expect(hasLog(m, 'Executing "xyz" in all repos.'), isTrue);
            expect(hasLog(m, RegExp(r'- ❌.+dir0')), !isDryRun);
            expect(hasLog(m, RegExp(r'- ❌.+dir1')), !isDryRun);
            expect(hasLog(m, RegExp(r'- ❌.+dir2')), !isDryRun);

            // Did print the result, when verbose?
            expect(hasLog(m, 'stdout result'), isVerbose && !isDryRun);
            expect(hasLog(m, 'stderr result'), isVerbose && !isDryRun);

            // Did print right colors?
            final colorize = Colorize();
            final darkGray = colorize.buildEscSeq(Styles.DARK_GRAY);
            final defaultStyle = colorize.buildEscSeq(Styles.DEFAULT);

            expect(hasLog(m, darkGray), isDryRun || isVerbose);
            expect(hasLog(m, defaultStyle), !isDryRun);
          });
        });
      }
    }

    // #########################################################################
    group('should throw', () {
      test('when --"command" is not set', () async {
        init();
        await expectLater(
          env.runner.run([
            'run-shell-command',
            // '--command=${'./test.txt'}',
            '--repos=${env.root}',
            '--dry-run',
          ]),
          throwsA(
            isA<ArgumentError>().having(
              (ArgumentError e) => e.message,
              'message',
              contains('Option command is mandatory.'),
            ),
          ),
        );
      });
    });
  });
}
