// @license
// Copyright (c) 2019 - 2024 Dr. Gabriel Gatzsche. All Rights Reserved.
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

import 'dart:io';

import 'package:gg_kidney/src/tools/get_dart_repos.dart';
import 'package:test/test.dart';

import 'create_sample_folders.dart';

void main() {
  late Directory tmp;
  late Directory dir0;
  late Directory dir1;
  late Directory dir2;
  late List<Directory> dartRepos;
  late List<String> repoPathes;

  // ...........................................................................
  setUp(() {
    [dir0, dir1, dir2] = createSampleRepos();
    dartRepos = [dir0, dir1, dir2];
    repoPathes = dartRepos.map((e) => e.path).toList();
    tmp = dir0.parent;
  });

  // ...........................................................................
  tearDown(() {
    dir0.deleteSync(recursive: true);
    dir1.deleteSync(recursive: true);
    dir2.deleteSync(recursive: true);
  });

  // ...........................................................................
  group('getDartRepos()', () {
    // .........................................................................
    test(
        'should return only the current directory '
        'if this directory a dart package', () {
      final dartRepos = getDartRepos(root: Directory.current);
      expect(dartRepos.length, 1);
      expect(dartRepos[0].path, endsWith('gg_kidney'));
      expect(true, isNotNull);
    });

    // .........................................................................
    test(
        'should return all directories with a pubspec.yaml file '
        'if the current directory is not a dart package', () {
      createSampleRepos();

      final dartRepos = getDartRepos(root: tmp);
      expect(dartRepos.length, 3);
      expect(repoPathes, contains(dartRepos[0].path));
      expect(repoPathes, contains(dartRepos[1].path));
      expect(repoPathes, contains(dartRepos[2].path));
    });
  });
}
