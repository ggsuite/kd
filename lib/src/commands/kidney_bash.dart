// @license
// Copyright (c) 2019 - 2024 Dr. Gabriel Gatzsche. All Rights Reserved.
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

import 'dart:io';

import 'package:args/args.dart';
import 'package:args/command_runner.dart';
import 'package:gg_console_colors/gg_console_colors.dart';
import 'package:gg_local_package_dependencies/gg_local_package_dependencies.dart';
import 'package:gg_log/gg_log.dart';
import 'package:gg_process/gg_process.dart';
import 'package:gg_status_printer/gg_status_printer.dart';
import 'package:mocktail/mocktail.dart';
import 'package:path/path.dart';

/// The command line interface for Kidney
class KidneyBash extends Command<void> {
  /// Constructor
  KidneyBash({
    required this.ggLog,
    GgProcessWrapper? processWrapper,
    ProcessingList? processingList,
  }) : _processWrapper = processWrapper ?? const GgProcessWrapper(),
       _processingList = processingList ?? ProcessingList(ggLog: ggLog) {
    _addParam();
  }

  /// The log function
  final GgLog ggLog;

  @override
  String get name => 'bash';

  @override
  String get description => 'Various maintenance tasks for our repositories.';

  // ...........................................................................
  /// Runs the command
  @override
  Future<void> run() async {
    final args = argResults!.arguments;
    final (directory, _, commandArgs, verbose, apply) = await readArgs(args);

    // Iterate through all dart repositories found in the current directory
    final processingList = await _processingList.get(
      directory: directory,
      ggLog: ggLog,
    );

    if (processingList.isEmpty) {
      final dir = basename(directory.path);
      throw Exception(yellow('No dart packages found in ${red(dir)}.'));
    }

    for (final node in processingList) {
      await _processProject(
        dir: node.directory,
        apply: apply,
        verbose: verbose,
        commandArgs: commandArgs,
        ggLog: ggLog,
      );
    }

    if (!apply) {
      ggLog(missingApplyHelp);
    } else if (!verbose) {
      ggLog(missingVerboseHelp);
    }
  }

  // ...........................................................................
  /// This help is printed, when no command arguments are given
  final commandArgumentsMissingHelp = darkGray(
    'usage: ${yellow('kidney')} ${green('[-av] [directory]')} '
    '${blue('<command>')}',
  );

  /// This help is printed, when no --apply option is given
  final missingApplyHelp =
      '\n${yellow('Dry run. Please run '
      '${blue('kidney -a ...')} to apply the changes.\n')}';

  /// This help is printed, when no --verbose option is given
  final missingVerboseHelp =
      '\n${yellow('Non-verbose run. Please run '
      '${blue('kidney -v ...')} to see more details.\n')}';

  // ...........................................................................
  @override
  ArgParser get argParser => _argParser;
  final _argParser = ArgParser(allowTrailingOptions: false);

  /// Reads the arguments
  Future<
    (
      Directory,
      List<String> kidneyArgs,
      List<String> commandArgs,
      bool verbose,
      bool apply,
    )
  >
  readArgs(List<String> args) async {
    args = args.where((e) => e.trim().isNotEmpty).toList();

    late Directory directory = Directory.current;
    final kidneyArgs = <String>[];
    final commandArgs = <String>[];
    bool verbose = false;
    bool apply = false;

    bool didRemoveKidneyFirstArg = false;
    bool didRemoveBashFirstArg = false;
    bool didRemoveBashSecondArg = false;
    bool didFindDirectory = false;
    bool isKidneyArg = true;

    for (final arg in args.map((e) => (e.trim()))) {
      // Ignore the first arg if it is the kidney command
      if (!didRemoveKidneyFirstArg) {
        didRemoveKidneyFirstArg = true;
        if (arg.endsWith('kidney') || arg.endsWith('/kidney')) {
          continue;
        }
      }

      // Ignore the first arg if it is the bash command
      if (!didRemoveBashFirstArg) {
        didRemoveBashFirstArg = true;
        if (arg == 'bash') {
          continue;
        }
      }

      // Ignore the second arg if it is the bash command
      if (didRemoveKidneyFirstArg) {
        if (!didRemoveBashSecondArg) {
          didRemoveBashSecondArg = true;
          if (arg == 'bash') {
            continue;
          }
        }
      }

      // Check if the next argument is a directory
      if (isKidneyArg && !didFindDirectory) {
        final d = Directory(arg);
        if (await d.exists()) {
          didFindDirectory = true;
          directory = d;
          continue;
        }
      }

      // Read kidney args
      if (isKidneyArg && (arg.startsWith('--') || arg.startsWith('-'))) {
        var didMatch = false;
        if (arg == '--verbose' || RegExp(r'^-\w?v').hasMatch(arg)) {
          kidneyArgs.add('--verbose');
          verbose = true;
          didMatch = true;
        }

        if (arg == '--apply' || RegExp(r'^-\w?a').hasMatch(arg)) {
          kidneyArgs.add('--apply');
          apply = true;
          didMatch = true;
        }

        if (!didMatch) {
          kidneyArgs.add(arg);
        }

        continue;
      } else {
        isKidneyArg = false;
      }

      // Put the rest of args to the command args
      commandArgs.add(arg);
    }

    // ............................
    // Are command arguments given?
    if (commandArgs.isEmpty) {
      throw ArgumentError(commandArgumentsMissingHelp);
    }

    // ...................................
    // Are there unknown kidney arguments?
    final unknownArguments = kidneyArgs.where((arg) {
      if (arg == '--verbose' || arg == '--apply') {
        return false;
      }
      return true;
    }).toList();
    if (unknownArguments.isNotEmpty) {
      throw ArgumentError(red(unknownArguments.join(', ')));
    }

    kidneyArgs.sort();
    return (directory, kidneyArgs, commandArgs, verbose, apply);
  }

  // ######################
  // Private
  // ######################

  final GgProcessWrapper _processWrapper;
  final ProcessingList _processingList;

  // ...........................................................................
  void _addParam() {
    argParser.addFlag(
      'verbose',
      abbr: 'v',
      help: 'Prints more details.',
      negatable: false,
      defaultsTo: false,
    );
    argParser.addFlag(
      'apply',
      abbr: 'a',
      help: 'Applies the changes.',
      negatable: false,
      defaultsTo: false,
    );
  }

  // ...........................................................................
  Future<void> _processProject({
    required Directory dir,
    required bool apply,
    required bool verbose,
    required List<String> commandArgs,
    required void Function(String p1) ggLog,
  }) async {
    // Log file to be deleted
    final message = basename(dir.path);

    final executable = commandArgs.first;
    final arguments = commandArgs.sublist(1);

    // No apply? Print file dark.
    if (!apply) {
      ggLog(darkGray('✅ $message'));
    } else {
      final printer = GgStatusPrinter<ProcessResult>(
        ggLog: ggLog,
        message: message,
      );

      printer.logStatus(GgStatusPrinterStatus.running);
      final result = await _processWrapper.run(
        executable,
        arguments,
        workingDirectory: dir.path,
      );

      printer.logStatus(
        result.exitCode == 0
            ? GgStatusPrinterStatus.success
            : GgStatusPrinterStatus.error,
      );

      _logResult(result, verbose);
    }
  }

  // ...........................................................................
  void _logResult(ProcessResult result, bool verbose) {
    if (verbose) {
      final stdErr = result.stderr as String;
      final stdOut = result.stdout as String;

      final newLine = stdOut.isNotEmpty && stdErr.isNotEmpty ? '\n' : '';
      var msg = '$stdOut$newLine$stdErr'
          .replaceAll('✅', '✓')
          .replaceAll('❌', '✗');

      final trimmedMessage = msg.trim();
      if (trimmedMessage.isEmpty) {
        return;
      }

      final lines = msg.split('\n');
      msg = lines
          .map((e) {
            final indentation =
                '${e.contains('✓') || e.contains('✗') ? '' : '  '}   ';

            return '$indentation$e';
          })
          .join('\n');

      if (msg.isNotEmpty) {
        ggLog(darkGray('\n$msg'));
      }
    }
  }
}

/// The mock for [KidneyBash]
class MockKidneyBash extends Mock implements KidneyBash {}
