// @license
// Copyright (c) 2019 - 2024 Dr. Gabriel Gatzsche. All Rights Reserved.
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

import 'dart:io';

import 'package:gg_console_colors/gg_console_colors.dart';
import 'package:gg_kidney/src/commands/command_base.dart';
import 'package:gg_process/gg_process.dart';
import 'package:path/path.dart';
import 'package:yaml_edit/yaml_edit.dart';

// #############################################################################
/// Delets a file from one repository to all other repositories.
class RunShellCommand extends CommandBase {
  /// Constructor
  RunShellCommand({
    required super.ggLog,
    GgProcessWrapper? processWrapper,
  })  : _processWrapper = processWrapper ?? const GgProcessWrapper(),
        super(
          name: 'run-shell-command',
          description: 'Run the specified shell command '
              'in the root of all repositories.',
        ) {
    _addArgs();
  }

  // ...........................................................................
  @override
  Future<void> willStart({
    required String inputDir,
  }) async {
    final commandStr = argResults?['command'] as String;
    final parts = commandStr.split(' ');
    _executable = parts.first;
    _arguments = parts.sublist(1);

    ggLog('Executing "$commandStr" in all repos.');
    await super.willStart(inputDir: inputDir);
  }

  // ...........................................................................
  @override
  Future<void> processProject({
    required YamlEditor pubspec,
    required Directory dir,
    required bool dryRun,
    required bool verbose,
    required void Function(String p1) ggLog,
  }) async {
    // Log file to be deleted
    final message = basename(dir.path);

    // File does not exists? Print file in dark gray
    if (dryRun) {
      ggLog('- ✅ ${darkGray(message)}');
    } else {
      final result = await _processWrapper.run(
        _executable,
        _arguments,
        workingDirectory: dir.path,
      );

      final symbol = result.exitCode == 0 ? '✅' : '❌';
      ggLog('- $symbol $message');
      _logResult(result, verbose);
    }
  }

  // ...........................................................................
  void _logResult(ProcessResult result, bool verbose) {
    if (verbose) {
      final stdErr = result.stderr as String;
      final stdOut = result.stdout as String;

      if (stdErr.isNotEmpty) {
        ggLog(darkGray(stdErr));
      }

      if (stdOut.isNotEmpty) {
        ggLog(darkGray(stdOut));
      }
    }
  }

  // ...........................................................................
  void _addArgs() {
    argParser.addOption(
      'command',
      abbr: 'c',
      help: 'The shell command to be executed.',
      mandatory: true,
    );
  }

  late String _executable;
  late List<String> _arguments;
  final GgProcessWrapper _processWrapper;
}
