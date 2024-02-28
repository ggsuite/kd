// @license
// Copyright (c) 2019 - 2024 Dr. Gabriel Gatzsche. All Rights Reserved.
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

import 'dart:io';

import 'package:gg_kidney/src/tools/get_dart_repos.dart';
import 'package:gg_project_root/gg_project_root.dart';
import 'package:path/path.dart';

/// A function that processes a pubspec.yaml file.
typedef FileProcessor = Future<void> Function({
  required File referenceFile,
  required File fileToBeProcessed,
  required Directory projectRoot,
  required bool dryRun,
});

/// Processes a given file in all projects
Future<void> processFiles({
  required File referenceFile,
  required FileProcessor process,
  bool dryRun = false,
  void Function(String)? log,
}) async {
  final filePath = referenceFile.path;
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

  // Repo directory
  final repoDir = Directory(projectRootAbsolute).parent;

  final dartRepos = getDartRepos(root: repoDir)
    ..sort(
      (a, b) => a.path.compareTo(b.path),
    );

  for (final project in dartRepos) {
    final file = File(join(project.path, releativePath));

    await process(
      referenceFile: referenceFile,
      fileToBeProcessed: file,
      dryRun: dryRun,
      projectRoot: project,
    );
  }
}
