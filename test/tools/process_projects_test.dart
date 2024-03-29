// @license
// Copyright (c) 2019 - 2024 Dr. Gabriel Gatzsche. All Rights Reserved.
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

import 'dart:io';

import 'package:gg_kidney/src/tools/process_projects.dart';
import 'package:test/test.dart';

import '../test_helpers/create_sample_repos.dart';

void main() {
  group('processProject(root, processor)', () {
    test('should process all pubspec files in a given directory', () async {
      final repos = createSampleRepos();
      final tmp = repos[0].parent;
      final messages = <String>[];
      await processProjects(
        directory: tmp,
        verbose: false,
        process: ({
          required dir,
          required dryRun,
          required verbose,
          required ggLog,
          required pubspec,
        }) async {
          pubspec.update(['dependencies', 'args'], '^4.5.6');
          final file = File('${dir.path}/pubspec.yaml');
          await file.writeAsString(pubspec.toString());
        },
        ggLog: messages.add,
      );

      for (final dir in repos) {
        final file = File('${dir.path}/pubspec.yaml');
        final content = file.readAsStringSync();
        expect(content.contains('args: ^4.5.6'), isTrue);
      }
    });

    test('should log a message if no dart repositories are found', () async {
      final tmp = Directory.systemTemp.createTempSync();
      final messages = <String>[];
      await processProjects(
        directory: tmp,
        verbose: false,
        process: ({
          required dir,
          required dryRun,
          required verbose,
          required ggLog,
          required pubspec,
        }) async {},
        ggLog: messages.add,
      );
      expect(messages.first, contains('No dart repositories found in '));
    });
  });
}
