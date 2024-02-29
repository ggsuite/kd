// @license
// Copyright (c) 2019 - 2024 Dr. Gabriel Gatzsche. All Rights Reserved.
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

import 'dart:convert';
import 'dart:io';

import 'package:colorize/colorize.dart';
import 'package:gg_kidney/src/commands/command_base.dart';
import 'package:gg_process/gg_process.dart';
import 'package:path/path.dart';
import 'package:yaml_edit/yaml_edit.dart';

// #############################################################################
/// Delets a file from one repository to all other repositories.
class RunShellCommand extends CommandBase {
  /// Constructor
  RunShellCommand({
    required super.log,
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

    log('Executing "$commandStr" in all repos.');
    super.willStart(inputDir: inputDir);
  }

  // ...........................................................................
  @override
  Future<void> processProject({
    required YamlEditor pubspec,
    required Directory dir,
    required bool dryRun,
    required bool verbose,
    required void Function(String p1) log,
  }) async {
    // Log file to be deleted
    final message = Colorize(basename(dir.path));

    // File does not exists? Print file in dark gray
    if (dryRun) {
      log('- ✅ ${message.darkGray()}');
    } else {
      final result = await _processWrapper.run(
        _executable,
        _arguments,
        workingDirectory: dir.path,
        stdoutEncoding: utf8,
        stderrEncoding: utf8,
      );

      final symbol = result.exitCode == 0 ? '✅' : '❌';
      log('- $symbol ${message.default_slyle()}');
      _logResult(result, verbose);
    }
  }

  // ...........................................................................
  void _logResult(ProcessResult result, bool verbose) {
    if (verbose) {
      final stdErr = result.stderr as String;
      final stdOut = result.stdout as String;

      if (stdErr.isNotEmpty) {
        log(Colorize(stdErr).darkGray().toString());
      }

      if (stdOut.isNotEmpty) {
        log(Colorize(stdOut).darkGray().toString());
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
