// @license
// Copyright (c) 2019 - 2024 Dr. Gabriel Gatzsche. All Rights Reserved.
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

import 'dart:io';

import 'package:gg_kidney/src/tools/process_pubspecs.dart';
import 'package:test/test.dart';

import 'create_sample_folders.dart';

void main() {
  group('processPubSpecs(root, processor)', () {
    test('should process all pubspec files in a given directory', () {
      final repos = createSampleRepos();
      final tmp = repos[0].parent;
      final messages = <String>[];
      processProject(
        directory: tmp,
        process: ({
          required dir,
          required dryRun,
          required log,
          required pubspec,
        }) =>
            pubspec..update(['dependencies', 'args'], '^4.5.6'),
        log: messages.add,
      );

      for (final dir in repos) {
        final file = File('${dir.path}/pubspec.yaml');
        final content = file.readAsStringSync();
        expect(content.contains('args: ^4.5.6'), isTrue);
      }
    });

    test('should log a message if no dart repositories are found', () {
      final tmp = Directory.systemTemp.createTempSync();
      final messages = <String>[];
      processProject(
        directory: tmp,
        process: ({
          required dir,
          required dryRun,
          required log,
          required pubspec,
        }) =>
            pubspec,
        log: messages.add,
      );
      expect(messages.first, contains('No dart repositories found in '));
    });
  });
}
