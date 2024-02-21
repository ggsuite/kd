// @license
// Copyright (c) 2019 - 2024 Dr. Gabriel Gatzsche. All Rights Reserved.
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

// ...........................................................................
import 'dart:convert';
import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:gg_kidney/src/commands/command_base.dart';

import 'create_sample_repos.dart';

// #############################################################################
// Log & Sample Repos
List<String> logMessages = [];
final List<Directory> sampleRepos = createSampleRepos();
final String root = sampleRepos.first.parent.path;

// #############################################################################
// Process

/// Overwrite this function to mock the process run.
ProcessResult processResult = ProcessResult(0, 0, '', '');

// ...........................................................................
/// These list will be filled with the calls to processRun.
List<
    ({
      String executable,
      List<String> arguments,
      String? workingDirectory,
      bool dryRun
    })> calls = [];

// .............................................................................
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

// .............................................................................
void resetEnvironment(CommandBase command) {
  processResult = ProcessResult(0, 0, '', '');
  logMessages.clear();
  calls.clear();
  initCommand(command);
}

// #############################################################################
// Command Runner
late CommandRunner<dynamic> runner;

// ...........................................................................
void initCommand(CommandBase command) {
  // Create a command runner
  runner = CommandRunner<dynamic>('test', 'test');
  runner.addCommand(command);
}
