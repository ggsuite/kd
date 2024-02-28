// @license
// Copyright (c) 2019 - 2024 Dr. Gabriel Gatzsche. All Rights Reserved.
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

import 'dart:io';

/// Returns a list of all dart repos
List<Directory> getDartRepos({required Directory root}) {
  // If the current directory is a dart directory, process just this directory
  if (root.existsSync() &&
      root.listSync().any((e) => e.path.endsWith('pubspec.yaml'))) {
    return [root];
  }

  // Get all directories
  final dirs = root.listSync().whereType<Directory>().toList();

  // Get all directories with a pubspec.yaml file
  final dartRepos = dirs.where((d) {
    final pubspec = File('${d.path}/pubspec.yaml');
    return pubspec.existsSync();
  }).toList()
    ..sort((a, b) => a.path.compareTo(b.path));

  return dartRepos;
}
