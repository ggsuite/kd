// @license
// Copyright (c) 2019 - 2024 Dr. Gabriel Gatzsche. All Rights Reserved.
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

import 'dart:io';

import 'package:gg_kidney/src/commands/command_base.dart';
import 'package:gg_local_package_dependencies/gg_local_package_dependencies.dart';
import 'package:gg_process/gg_process.dart';
import 'package:path/path.dart';

// #############################################################################
/// Works through all repositories and updates the Dart SDK.
class OpenWithVscode extends CommandBase {
  /// Constructor
  OpenWithVscode({
    required super.ggLog,
    this.process = const GgProcessWrapper(),
    ProcessingList? processingList,
  })  : _processingList = processingList ?? ProcessingList(ggLog: ggLog),
        super(
          name: 'open-with-vscode',
          description: 'Edit project files with vscode.',
        ) {
    _addArgs();
  }

  @override
  Future<void> willStart({
    required Directory inputDir,
  }) async {
    // Read file option from args
    final fileToBeOpened = argResults?['file'] as String;
    // Get a list of all projects in inputDir
    final dartRepos = await _processingList.get(
      directory: inputDir,
      ggLog: ggLog,
    );

    final fileList = <String>[];
    for (final repo in dartRepos) {
      final filePath = join(repo.directory.path, fileToBeOpened);
      final file = File(filePath);
      if (file.existsSync()) {
        fileList.add(file.path);
      }
    }

    // Log if no file has found
    if (fileList.isEmpty) {
      ggLog('No $fileToBeOpened found.');
      return;
    }

    // Open the files with vscode
    await process.run('code', fileList, workingDirectory: inputDir.path);
  }

  // ...........................................................................
  /// The method
  final GgProcessWrapper process;

  // ######################
  // Private
  // ######################

  // ...........................................................................
  void _addArgs() {
    argParser.addOption(
      'file',
      abbr: 'f',
      help: 'The file to be opened with vscode.',
      mandatory: true,
    );
  }

  // ...........................................................................
  final ProcessingList _processingList;
}
