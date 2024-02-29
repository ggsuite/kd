// @license
// Copyright (c) 2019 - 2024 Dr. Gabriel Gatzsche. All Rights Reserved.
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:colorize/colorize.dart';
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
      'repos',
      abbr: 'r',
      help: 'The directory to search for dart repositories',
      defaultsTo: '.',
    );

    argParser.addFlag(
      'dry-run',
      abbr: 'd',
      help: 'Do not change any files',
      defaultsTo: true,
      negatable: true,
    );

    argParser.addFlag(
      'verbose',
      abbr: 'v',
      help: 'Print more detailed output',
      defaultsTo: false,
      negatable: true,
    );
  }

  // ...........................................................................
  /// Override this method to do some work before the run method is called.
  Future<void> willStart({
    required String inputDir,
  }) async {
    // Print dry-run hint
    if (argResults?['dry-run'] as bool) {
      log(dryRunHint);
    }
  }

  // ...........................................................................
  /// Override this method to process a project.
  Future<void> processProject({
    required YamlEditor pubspec,
    required Directory dir,
    required bool dryRun,
    required bool verbose,
    required void Function(String) log,
  }) =>
      Future.value();

  // ...........................................................................
  /// A hint that is printed if dry-run is executed.
  String get dryRunHint {
    final msgPart0 =
        Colorize('Dry-run: Nothing will change. ').yellow().toString();
    final msgPart1 = Colorize('Run with ').yellow().toString();
    final msgPart2 = Colorize('--no-dry-run').red().toString();
    final msgPart3 = Colorize(' to apply changes.').yellow().toString();

    return '$msgPart0 $msgPart1$msgPart2$msgPart3';
  }

  // ...........................................................................
  /// Override this method to do some work after the run method is called.
  void didFinish() {}

  // ...........................................................................
  @override
  Future<void> run() async {
    // Read the command line arguments
    final inputDir = argResults?['repos'] as String;
    final dryRun = argResults?['dry-run'] as bool;
    final verbose = argResults?['verbose'] as bool;

    // Anounce the start
    await willStart(inputDir: inputDir);

    // Iterate through all dart repositories found in the current directly
    await pp.processProjects(
      directory: Directory(inputDir),
      process: processProject,
      dryRun: dryRun,
      log: log,
      verbose: verbose,
    );

    // Anounce the end
    didFinish();
  }
}
