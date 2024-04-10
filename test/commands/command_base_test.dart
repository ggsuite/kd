// @license
// Copyright (c) 2019 - 2024 Dr. Gabriel Gatzsche. All Rights Reserved.
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:gg_capture_print/gg_capture_print.dart';
import 'package:gg_kidney/src/commands/command_base.dart';
import 'package:test/test.dart';
import 'package:yaml_edit/src/editor.dart';

import '../test_helpers/create_sample_repos.dart';

// #############################################################################
class MyCommand extends CommandBase {
  // ...........................................................................
  MyCommand({
    required super.ggLog,
  }) : super(
          name: 'my-command',
          description: 'description',
        );

  // ...........................................................................
  Directory? startInputDir;

  @override
  Future<void> willStart({required Directory inputDir}) async {
    startInputDir = inputDir;
    await super.willStart(inputDir: inputDir);
  }

  // ...........................................................................
  List<(YamlEditor, Directory, bool, dynamic)> processedProjects = [];

  @override
  Future<void> processProject({
    required YamlEditor pubspec,
    required Directory dir,
    required bool dryRun,
    required bool verbose,
    required void Function(String p1) ggLog,
  }) async {
    this.dryRun = dryRun;
    processedProjects.add((pubspec, dir, dryRun, ggLog));
    await super.processProject(
      pubspec: pubspec,
      dir: dir,
      dryRun: dryRun,
      verbose: verbose,
      ggLog: ggLog,
    );
  }

  // ...........................................................................
  bool didFinishCalled = false;
  bool? dryRun;
  @override
  void didFinish() {
    didFinishCalled = true;
    super.didFinish();
  }
}

// #############################################################################
void main() {
  late CommandRunner<void> runner;
  late MyCommand myCommand;
  final messages = <String>[];
  late List<Directory> repos;
  late Directory root;

  setUp(() {
    messages.clear();

    // Create instance
    myCommand = MyCommand(ggLog: messages.add);

    // Create a command runner
    runner = CommandRunner<void>(
      'command-base',
      'Description goes here.',
    )..addCommand(myCommand);

    // Create a custom directory structure
    repos = createSampleRepos();
    root = repos[0].parent;
  });

  group('CommandBase', () {
    for (final dryRun in ['', '--dry-run', '--no-dry-run']) {
      test('should allow to create custom project processors $dryRun',
          () async {
        final isDryRun = dryRun == '--dry-run' || dryRun == '';

        // Run the command
        await runner.run(['my-command', '--repos', root.path, dryRun]);

        // Sort the results
        myCommand.processedProjects
            .sort((a, b) => a.$2.path.compareTo(b.$2.path));

        // Check the results
        expect(myCommand.startInputDir?.path, root.path);
        expect(myCommand.processedProjects.length, repos.length);
        expect(myCommand.didFinishCalled, isTrue);
        expect(myCommand.dryRun, isDryRun);

        // Were all projects processed?
        expect(myCommand.processedProjects[0].$2.path, repos[0].path);
        expect(myCommand.processedProjects[1].$2.path, repos[1].path);
        expect(myCommand.processedProjects[2].$2.path, repos[2].path);

        // Was dry run hint printed?
        expect(hasLog(messages, myCommand.dryRunHint), isDryRun);

        // const CommandBase();
        expect(true, isNotNull);
      });
    }

    group('special cases', () {
      test('directory does not contain packages', () async {
        // Create an empty dir
        final emptyDir = Directory('${root.path}/empty');
        await emptyDir.create();

        // Run the command
        await runner.run([
          'my-command',
          '--repos',
          emptyDir.path,
        ]);

        // Check the results
        expect(messages.last, 'No dart packages found in empty.');

        await emptyDir.delete();
      });
    });
  });
}
