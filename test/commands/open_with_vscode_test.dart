// @license
// Copyright (c) 2019 - 2024 Dr. Gabriel Gatzsche. All Rights Reserved.
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

import 'dart:io';

import 'package:gg_kidney/src/commands/open_with_vscode.dart';
import 'package:mocktail/mocktail.dart';
import 'package:path/path.dart';
import 'package:test/test.dart';

import '../test_helpers/create_sample_repos.dart';
import '../test_helpers/init_environment.dart';

void main() {
  late TestEnvironment env;

  // ...........................................................................
  setUp(() {
    env = TestEnvironment();
    env.addCommand(
      OpenWithVscode(
        ggLog: env.logMessages.add,
        process: env.process,
      ),
    );
  });

  group('OpenWithVscode', () {
    test('should open all desired files with vscode', () {
      // Create sample repos
      final repos = createSampleRepos();
      final root = repos[0].parent.absolute.path;
      final pubspecFiles = [
        join(repos[0].path, 'pubspec.yaml'),
        join(repos[1].path, 'pubspec.yaml'),
        join(repos[2].path, 'pubspec.yaml'),
      ];

      // Mock opening vscode
      when(
        () => env.process.run(
          'code',
          pubspecFiles,
          workingDirectory: root,
        ),
      ).thenAnswer((invocation) {
        return Future.value(ProcessResult(0, 0, '', ''));
      });

      // Run the command
      env.runner
          .run(['open-with-vscode', '-r', root, '--file', 'pubspec.yaml']);

      // Only one call should be executed
      verify(
        () => env.process.run(
          'code',
          pubspecFiles,
          workingDirectory: root,
        ),
      ).called(1);
    });

    test('should write a log message if file has not been found', () {
      // Create sample repos
      final sampleRepos = createSampleRepos();
      final root = sampleRepos[0].parent.absolute.path;

      // Run the command
      env.runner.run(['open-with-vscode', '-r', root, '--file', 'xyzabc']);

      // Nothing should be called
      verifyNever(
        () => env.process.run(
          'code',
          any<List<String>>(),
          workingDirectory: root,
        ),
      );

      // The working directory should be the root
      expect(env.logMessages, ['No xyzabc found.']);
    });
  });
}
