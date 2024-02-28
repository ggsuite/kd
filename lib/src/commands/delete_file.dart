// @license
// Copyright (c) 2019 - 2024 Dr. Gabriel Gatzsche. All Rights Reserved.
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:gg_kidney/src/tools/process_files.dart';
import 'package:gg_process/gg_process.dart';
import 'package:path/path.dart';

// #############################################################################
/// Delets a file from one repository to all other repositories.
class DeleteFile extends Command<dynamic> {
  /// Constructor
  DeleteFile({
    required this.log,
    this.process = const GgProcessWrapper(),
  }) {
    _addArgs();
  }

  /// The log function
  final void Function(String message) log;
  @override
  final String name = 'delete-file';

  @override
  final String description =
      'Deletes a file from a reference project and all other projects.';

  // ...........................................................................
  @override
  Future<void> run() async {
    // Get apply flag
    final apply = argResults?['apply'] as bool;
    if (!apply) {
      log(
        'Dry-run: No files will be deleted. Run with --apply to apply changes.',
      );
    }

    // Read file path from args
    final referenceFile = File(absolute(((argResults?['file'] as String))));

    log('Deleting ${basename(referenceFile.path)} from');
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
        log(Directory.current.path);
        if (fileToBeProcessed.existsSync()) {
          if (!dryRun) {
            fileToBeProcessed.deleteSync();
          }

          log('- ${basename(projectRoot.path)}');
        }
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
      help: 'The file to be deleted in all repos.',
      mandatory: true,
    );

    argParser.addFlag(
      'apply',
      help: 'Really apply the changes. By default only dry-run is preformed',
      defaultsTo: false,
    );
  }
}
