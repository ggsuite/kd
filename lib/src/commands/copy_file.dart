// @license
// Copyright (c) 2019 - 2024 Dr. Gabriel Gatzsche. All Rights Reserved.
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:colorize/colorize.dart';
import 'package:gg_kidney/src/tools/process_files.dart';
import 'package:gg_process/gg_process.dart';
import 'package:path/path.dart';

// #############################################################################
/// Copies a file from one repository to all other repositories.
class CopyFile extends Command<dynamic> {
  /// Constructor
  CopyFile({
    required this.log,
    this.process = const GgProcessWrapper(),
  }) {
    _addArgs();
  }

  /// The log function
  final void Function(String message) log;
  @override
  final String name = 'copy-file';

  @override
  final String description =
      'Copies a file from a reference project to all other projects.';

  // ...........................................................................
  /// A hint that is printed if dry-run is executed.
  static String get dryRunHint {
    final msgPart0 =
        Colorize('Dry-run: No files will be copied. ').yellow().toString();
    final msgPart1 = Colorize('Run with ').yellow().toString();
    final msgPart2 = Colorize('--apply').red().toString();
    final msgPart3 = Colorize(' to apply changes.').yellow().toString();

    return '$msgPart0 $msgPart1$msgPart2$msgPart3';
  }

  // ...........................................................................
  @override
  Future<void> run() async {
    // Get apply flag
    final apply = argResults?['apply'] as bool;
    if (!apply) {
      log(dryRunHint);
    }

    // Read file path from args
    final referenceFile = File(absolute(((argResults?['file'] as String))));

    log('Copying ${basename(referenceFile.path)} to ');
    await processFiles(
      referenceFile: referenceFile,
      dryRun: !apply,
      log: log,
      process: ({
        required dryRun,
        required fileToBeProcessed,
        required referenceFile,
        required projectRoot,
      }) async {
        // Don't copy reference file itself
        if (fileToBeProcessed.path == referenceFile.path) {
          return;
        }

        // Create target directory
        final targetDirPath = dirname(fileToBeProcessed.path);
        Directory(targetDirPath).createSync(
          recursive: true,
        );

        if (!dryRun) {
          final newFilePath = fileToBeProcessed.path;
          referenceFile.copySync(newFilePath);
        }

        // Log message
        log('- ${basename(projectRoot.path)}');
      },
    );
  }

  // ...........................................................................
  /// The method
  final GgProcessWrapper process;

  // ...........................................................................
  void _addArgs() {
    argParser.addOption(
      'file',
      abbr: 'f',
      help: 'The file to be copied to all other repos.',
      mandatory: true,
    );

    argParser.addFlag(
      'apply',
      help: 'Really apply the changes. By default only dry-run is preformed',
      defaultsTo: false,
    );
  }
}
