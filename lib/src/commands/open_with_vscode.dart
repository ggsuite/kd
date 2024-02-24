// @license
// Copyright (c) 2019 - 2024 Dr. Gabriel Gatzsche. All Rights Reserved.
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

import 'dart:io';

import 'package:gg_kidney/src/commands/command_base.dart';
import 'package:gg_kidney/src/tools/get_dart_repos.dart';
import 'package:path/path.dart';
import 'package:gg_test_helpers/gg_test_helpers.dart';

// #############################################################################
/// Works through all repositories and updates the Dart SDK.
class OpenWithVscode extends CommandBase {
  /// Constructor
  OpenWithVscode({
    required super.log,
    this.runProcess = Process.run,
  }) : super(
          name: 'open-with-vscode',
          description: 'Edit project files with vscode.',
        ) {
    _addArgs();
  }

  @override
  void willStart({
    required String inputDir,
  }) {
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
    runProcess('code', fileList, workingDirectory: inputDir);
  }

  // ...........................................................................
  /// The method
  final RunProcess runProcess;

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
