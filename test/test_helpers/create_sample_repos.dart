// @license
// Copyright (c) 2019 - 2024 Dr. Gabriel Gatzsche. All Rights Reserved.
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

// .............................................................................
import 'dart:io';

import 'package:path/path.dart';
import 'package:yaml_edit/yaml_edit.dart';

// .............................................................................
YamlEditor createSamplePubSpec({required Directory dir}) {
  final name = basename(dir.path);

  final pubspec = <String, dynamic>{};
  pubspec['name'] = name;
  pubspec['environment'] = <String, dynamic>{};
  pubspec['environment']['sdk'] = '>=2.12.0 <3.0.0';
  pubspec['version'] = '0.0.1';
  pubspec['description'] = 'Nice description.';
  pubspec['dependencies'] = {
    'args': '^2.2.1',
  };
  pubspec['dev_dependencies'] = {
    'test': '^1.15.3',
  };

  final yaml = YamlEditor('');
  yaml.update([], pubspec);
  return yaml;
}

// .............................................................................
List<Directory> createSampleRepos() {
  /// Create three sample directories within the tmp directory
  final tmp = Directory.systemTemp.createTempSync();
  final dir0 = Directory('${tmp.path}/dir0')..createSync();
  final dir1 = Directory('${tmp.path}/dir1')..createSync();
  final dir2 = Directory('${tmp.path}/dir2')..createSync();
  final dartRepos = [dir0, dir1, dir2];

  /// Create a pubspec.yaml and a test.txt file in each dir
  for (final dir in dartRepos) {
    final file = File('${dir.path}/pubspec.yaml');
    final content = createSamplePubSpec(dir: dir);
    file.writeAsStringSync(content.toString());

    final testFile = File('${dir.path}/test.txt');
    testFile.writeAsStringSync('Test file for $dir');
  }

  return dartRepos;
}
