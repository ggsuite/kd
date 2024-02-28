// @license
// Copyright (c) 2019 - 2024 Dr. Gabriel Gatzsche. All Rights Reserved.
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

import 'dart:io';

import 'package:gg_kidney/src/commands/command_base.dart';
import 'package:gg_kidney/src/tools/get_dart_repos.dart';
import 'package:gg_process/gg_process.dart';
import 'package:path/path.dart';

// #############################################################################
/// Works through all repositories and updates the Dart SDK.
class OpenWithVscode extends CommandBase {
  /// Constructor
  OpenWithVscode({
    required super.log,
    this.process = const GgProcessWrapper(),
  }) : super(
          name: 'open-with-vscode',
          description: 'Edit project files with vscode.',
        ) {
    _addArgs();
  }

  @override
  Future<void> willStart({
    required String inputDir,
  }) async {
    // Read file option from args
    final fileToBeOpened = argResults?['file'] as String;
    // Get a list of all projects in inputDir
    final dartRepos = getDartRepos(root: Directory(inputDir));
    final fileList = <String>[];
    for (final dir in dartRepos) {
      final filePath = join(dir.path, fileToBeOpened);
      final file = File(filePath);
      if (file.existsSync()) {
        fileList.add(file.path);
      }
    }

    // Log if no file has found
    if (fileList.isEmpty) {
      log('No $fileToBeOpened found.');
      return;
    }

    // Open the files with vscode
    process.run('code', fileList, workingDirectory: inputDir);
  }

  // ...........................................................................
  /// The method
  final GgProcessWrapper process;

  // ...........................................................................
  void _addArgs() {
    argParser.addOption(
      'file',
      abbr: 'f',
      help: 'The file to be opened with vscode.',
      mandatory: true,
    );
  }
}
