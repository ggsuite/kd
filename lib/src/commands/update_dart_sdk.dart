// @license
// Copyright (c) 2019 - 2024 Dr. Gabriel Gatzsche. All Rights Reserved.
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:gg_kidney/src/tools/process_pubspecs.dart';
import 'package:path/path.dart';
import 'package:pub_semver/pub_semver.dart';
import 'package:yaml_edit/yaml_edit.dart';

/// Works through all repositories and updates the Dart SDK.
class UpdateDartSdk extends Command<dynamic> {
  /// Constructor
  UpdateDartSdk({required this.log}) {
    _addArgs();
  }

  /// The log function
  final void Function(String message) log;

  @override
  final name = 'update-dart-sdk';

  @override
  final description = 'Updates the Dart SDK.';

  // ...........................................................................
  void _addArgs() {
    argParser.addOption(
      'min-version',
      abbr: 'v',
      help: 'The minium supported Dart SDK',
      valueHelp: '3.3.0',
      mandatory: true,
    );

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
    );
  }

  @override
  Future<void> run() async {
    // Read the command line arguments
    final version = Version.parse(argResults?['min-version'] as String);
    final inputDir = argResults?['input-dir'] as String;
    final dryRun = argResults?['dry-run'] as bool;

    // Write a log message
    log('Updating the Dart SDK to version $version in $inputDir');

    // Iterate through all dart repositories found in the current directly
    processProject(
      directory: Directory(inputDir),
      process: ({
        required dir,
        required dryRun,
        required log,
        required pubspec,
      }) =>
          _updateDartSdk(
        pubspec,
        dir,
        version,
        dryRun,
      ),
      dryRun: dryRun,
      log: log,
    );
  }

  // ...........................................................................
  YamlEditor _updateDartSdk(
    YamlEditor doc,
    Directory dir,
    Version version,
    dryRun,
  ) {
    // Compose the version string
    final majorVersion = version.major;
    final versionString = '>=$version<${majorVersion + 1}.0.0';

    // Replace the dart sdk minimum version with next version
    doc.update(['environment', 'sdk'], versionString);

    // Write a log message
    final dirName = basename(dir.absolute.path.replaceAll(RegExp(r'/.$'), ''));
    log('Updated the Dart SDK version to "$versionString" in $dirName');

    return doc;
  }
}
