// @license
// Copyright (c) 2019 - 2024 Dr. Gabriel Gatzsche. All Rights Reserved.
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

import 'dart:convert';
import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:gg_kidney/src/commands/upgrade_dependencies.dart';
import 'package:path/path.dart';
import 'package:test/test.dart';

import '../tools/create_sample_repos.dart';
import '../tools/expect_log.dart';

void main() {
  // ###########################################################################

  // ...........................................................................
  late List<
      ({
        String executable,
        List<String> arguments,
        String? workingDirectory,
        bool dryRun
      })> calls = [];

  final List<Directory> sampleRepos = createSampleRepos();
  final String root = sampleRepos.first.parent.path;
  late ProcessResult processResult;
  late CommandRunner<dynamic> runner;
  late List<String> logMessages = [];

  // ...........................................................................
  Future<ProcessResult> processRun(
    String executable,
    List<String> arguments, {
    String? workingDirectory,
    Map<String, String>? environment,
    bool includeParentEnvironment = true,
    bool runInShell = false,
    Encoding? stdoutEncoding,
    Encoding? stderrEncoding,
  }) async {
    calls.add(
      (
        executable: executable,
        arguments: arguments,
        workingDirectory: workingDirectory,
        dryRun: arguments.contains('--dry-run')
      ),
    );

    return processResult;
  }

  // ...........................................................................
  void initCommand() {
    // Create the the command
    final upgradeDependencies = UpgradeDependencies(
      log: logMessages.add,
      processRun: processRun,
    );

    // Create a command runner
    runner = CommandRunner<dynamic>('test', 'test')
      ..addCommand(upgradeDependencies);
  }

  // ...........................................................................
  setUp(() {
    processResult = ProcessResult(0, 0, '', '');
    calls.clear();
    initCommand();
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
        expect(calls[i].arguments, ['pub', 'upgrade', '--dry-run']);
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
        expect(calls[i].arguments, ['pub', 'upgrade']);
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
        expectLog(
          'Failed to upgrade dependencies for $dir',
          logMessages,
        );

        expectLog(
          'stderror',
          logMessages,
        );

        expectLog(
          'stdout',
          logMessages,
        );
      }

      // Should set the exit code to 1
      expect(exitCode, error);
    });
  });
}
