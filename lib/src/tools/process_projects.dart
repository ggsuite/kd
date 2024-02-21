// @license
// Copyright (c) 2019 - 2024 Dr. Gabriel Gatzsche. All Rights Reserved.
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

import 'dart:io';

import 'package:gg_kidney/src/tools/get_dart_repos.dart';
import 'package:path/path.dart';
import 'package:yaml_edit/yaml_edit.dart';

/// A function that processes a pubspec.yaml file.
typedef ProjectProcessor = YamlEditor Function({
  required YamlEditor pubspec,
  required Directory dir,
  required bool dryRun,
  required void Function(String)? log,
});

/// Processes all pubspec.yaml files in the given directory.
void processProjects({
  required Directory directory,
  required ProjectProcessor process,
  bool dryRun = false,
  void Function(String)? log,
}) {
  final dartRepos = getDartRepos(root: directory);

  if (log != null && dartRepos.isEmpty) {
    final dir = basename(directory.path);
    log('No dart repositories found in $dir');
  }

  for (final dir in dartRepos) {
    final file = File('${dir.path}/pubspec.yaml');
    final pubspec = YamlEditor(file.readAsStringSync());
    final newContent = process(
      pubspec: pubspec,
      dir: dir,
      log: log,
      dryRun: dryRun,
    );
    if (!dryRun) {
      file.writeAsStringSync(newContent.toString());
    }
  }
}
