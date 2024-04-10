// @license
// Copyright (c) 2019 - 2024 Dr. Gabriel Gatzsche. All Rights Reserved.
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

import 'dart:io';

import 'package:gg_console_colors/gg_console_colors.dart';
import 'package:gg_kidney/src/commands/command_base.dart';
import 'package:path/path.dart';
import 'package:yaml_edit/yaml_edit.dart';

// #############################################################################
/// Delets a file from one repository to all other repositories.
class DeleteFile extends CommandBase {
  /// Constructor
  DeleteFile({
    required super.ggLog,
  }) : super(
          name: 'delete-file',
          description:
              'Deletes a file from a reference project and all other projects.',
        ) {
    _addArgs();
  }

  // ...........................................................................
  @override
  Future<void> willStart({
    required Directory inputDir,
  }) async {
    _fileToBeDeleted = argResults?['source'] as String;

    ggLog('Deleting $_fileToBeDeleted from all repositories');
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
    // Define target file path
    final targetFilePath = canonicalize(join(dir.path, _fileToBeDeleted));
    final targetFile = File(targetFilePath);

    // Log file to be deleted
    final message = targetFile.path;

    // File does not exists? Print file in dark gray
    if (!targetFile.existsSync() || dryRun) {
      ggLog('- ${darkGray(message)}');
    } else {
      targetFile.deleteSync();
      ggLog('- ${red(message)}');
    }
  }

  // ...........................................................................
  void _addArgs() {
    argParser.addOption(
      'source',
      abbr: 's',
      help: 'The file to be deleted from all repos.',
      mandatory: true,
    );
  }

  late String _fileToBeDeleted;
}
