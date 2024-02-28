// @license
// Copyright (c) 2019 - 2024 Dr. Gabriel Gatzsche. All Rights Reserved.
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:gg_kidney/src/commands/command_base.dart';
import 'package:test/test.dart';
import 'package:yaml_edit/src/editor.dart';

import '../test_helpers/create_sample_repos.dart';

// #############################################################################
class MyCommand extends CommandBase {
  // ...........................................................................
  MyCommand({
    required super.log,
  }) : super(
          name: 'my-command',
          description: 'description',
        );

  // ...........................................................................
  String? startInpurtDir;

  @override
  Future<void> willStart({required String inputDir}) async {
    startInpurtDir = inputDir;
    super.willStart(inputDir: inputDir);
  }

  // ...........................................................................
  List<(YamlEditor, Directory, bool, dynamic)> processedProjects = [];

  @override
  Future<void> processProject({
    required YamlEditor pubspec,
    required Directory dir,
    required bool dryRun,
    void Function(String p1)? log,
  }) async {
    processedProjects.add((pubspec, dir, dryRun, log));
    super.processProject(
      pubspec: pubspec,
      dir: dir,
      dryRun: dryRun,
      log: log,
    );
  }

  // ...........................................................................
  bool didFinishCalled = false;
  @override
  void didFinish() {
    didFinishCalled = true;
    super.didFinish();
  }
}

// #############################################################################
void main() {
  group('CommandBase', () {
    test('should allow to create custom project processors', () async {
      // Create a custom directory structure
      final repos = createSampleRepos();
      final root = repos[0].parent;

      // Create instance
      final myCommand = MyCommand(log: print);

      // Create a command runner
      final runner = CommandRunner<void>(
        'command-base',
        'Description goes here.',
      )..addCommand(myCommand);

      // Run the command
      await runner.run(['my-command', '--input-dir', root.path]);

      // Sort the results
      myCommand.processedProjects
          .sort((a, b) => a.$2.path.compareTo(b.$2.path));

      // Check the results
      expect(myCommand.startInpurtDir, root.path);
      expect(myCommand.processedProjects.length, repos.length);
      expect(myCommand.didFinishCalled, isTrue);

      // Were all projects processed?
      expect(myCommand.processedProjects[0].$2.path, repos[0].path);
      expect(myCommand.processedProjects[1].$2.path, repos[1].path);
      expect(myCommand.processedProjects[2].$2.path, repos[2].path);

      // const CommandBase();
      expect(true, isNotNull);
    });
  });
}
