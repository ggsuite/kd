// @license
// Copyright (c) 2019 - 2024 Dr. Gabriel Gatzsche. All Rights Reserved.
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

import 'package:gg_kidney/src/commands/open_with_vscode.dart';
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
        log: env.logMessages.add,
        process: env.process,
      ),
    );
  });

  group('OpenWithVscode', () {
    test('should open all desired files with vscode', () {
      // Create sample repos
      final sampleRepos = createSampleRepos();
      final root = sampleRepos[0].parent.absolute.path;

      // Run the command
      env.runner
          .run(['open-with-vscode', '-r', root, '--file', 'pubspec.yaml']);

      // Onle one call should be executed
      expect(env.process.calls.length, 1);
      final call = env.process.calls.first;

      // The working directory should be the root
      expect(call.workingDirectory, root);

      // The executable should be open-with-vscode
      expect(call.executable, 'code');

      // The arguments should be the pubspec.yaml files in the repos
      final files =
          sampleRepos.map((repo) => join(repo.path, 'pubspec.yaml')).toList();
      call.arguments.sort();
      expect(call.arguments, files);
    });

    test('should write a log message if file has not been found', () {
      // Create sample repos
      final sampleRepos = createSampleRepos();
      final root = sampleRepos[0].parent.absolute.path;

      // Run the command
      env.runner.run(['open-with-vscode', '-r', root, '--file', 'xyzabc']);

      // Nothing should be called
      expect(env.process.calls.length, 0);

      // The working directory should be the root
      expect(env.logMessages, ['No xyzabc found.']);
    });
  });
}
