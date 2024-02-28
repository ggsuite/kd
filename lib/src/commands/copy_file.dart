// @license
// Copyright (c) 2019 - 2024 Dr. Gabriel Gatzsche. All Rights Reserved.
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:gg_kidney/src/tools/get_dart_repos.dart';
import 'package:gg_process/gg_process.dart';
import 'package:gg_project_root/gg_project_root.dart';
import 'package:path/path.dart';

// #############################################################################
/// Works through all repositories and updates the Dart SDK.
class CopyFile extends Command<dynamic> {
  /// Constructor
  CopyFile({
    required this.log,
    this.process = const GgProcess(),
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
  @override
  Future<void> run() async {
    // Get apply flag
    final apply = argResults?['apply'] as bool;
    if (!apply) {
      log(
        'Dry-run: No files will be copied. Run with --apply to apply changes.',
      );
    }

    // Read file path from args
    final filePath = absolute(((argResults?['file'] as String)));

    final fileName = basename(filePath);

    // If file does not exist, throw an error
    final file = File(filePath);
    if (!file.existsSync()) {
      throw ArgumentError('The file $filePath does not exist.');
    }

    // Project root
    final projectRoot = GgProjectRoot.getSync(filePath);

    // Throw if project root isnull
    if (projectRoot == null) {
      throw ArgumentError(
        'The file $fileName is not part of a dart or flutter project.',
      );
    }

    final projectRootAbsolute = absolute(canonicalize(projectRoot));

    // Get the relative path
    final releativePath = relative(filePath, from: projectRoot);
    final relativeDir = dirname(releativePath);

    // Repo directory
    final repoDir = Directory(projectRootAbsolute).parent;

    // Copy the file to all other repositories
    final dartRepos =
        getDartRepos(root: repoDir).where((d) => d.path != projectRoot);

    if (dartRepos.isNotEmpty) {
      log('Copying $fileName to ');
    }

    for (final dir in dartRepos) {
      // Create target directory
      final targetDirPath = join(dir.path, relativeDir);
      Directory(targetDirPath).createSync(
        recursive: true,
      );

      // Target directory, relative to repo dir
      final repoName = relative(dir.path, from: repoDir.path);

      // Copy the file
      final newFilePath = join(dir.path, releativePath);
      if (apply) {
        file.copySync(newFilePath);
      }

      // Log message
      log('- $repoName');
    }
  }

  // ...........................................................................
  /// The method
  final GgProcess process;

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
