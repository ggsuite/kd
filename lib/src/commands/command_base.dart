// @license
// Copyright (c) 2019 - 2024 Dr. Gabriel Gatzsche. All Rights Reserved.
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:gg_kidney/src/tools/process_projects.dart' as pp;
import 'package:yaml_edit/yaml_edit.dart';

/// Works through all repositories and updates the Dart SDK.
abstract class CommandBase extends Command<dynamic> {
  /// Constructor
  CommandBase({
    required this.log,
    required this.name,
    required this.description,
  }) {
    _addArgs();
  }

  /// The log function
  final void Function(String message) log;

  @override
  final String name;

  @override
  final String description;

  // ...........................................................................
  void _addArgs() {
    argParser.addOption(
      'input-dir',
      abbr: 'i',
      help: 'The directory to search for dart repositories',
      defaultsTo: '.',
    );

    argParser.addFlag(
      'dry-run',
      abbr: 'd',
      help: 'Do not change any files',
      defaultsTo: false,
      negatable: true,
    );
  }

  // ...........................................................................
  /// Override this method to do some work before the run method is called.
  void willStart({
    required String inputDir,
  }) {}

  // ...........................................................................
  /// Override this method to process a project.
  Future<void> processProject({
    required YamlEditor pubspec,
    required Directory dir,
    required bool dryRun,
    void Function(String)? log,
  }) =>
      Future.value();

  // ...........................................................................
  /// Override this method to do some work after the run method is called.
  void didFinish() {}

  // ...........................................................................
  @override
  Future<void> run() async {
    // Read the command line arguments
    final inputDir = argResults?['input-dir'] as String;
    final dryRun = argResults?['dry-run'] as bool;

    // Anounce the start
    willStart(inputDir: inputDir);

    // Iterate through all dart repositories found in the current directly
    await pp.processProjects(
      directory: Directory(inputDir),
      process: processProject,
      dryRun: dryRun,
      log: log,
    );

    // Anounce the end
    didFinish();
  }
}
