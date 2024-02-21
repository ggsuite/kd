// @license
// Copyright (c) 2019 - 2024 Dr. Gabriel Gatzsche. All Rights Reserved.
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

import 'dart:io';

import 'package:gg_kidney/src/commands/command_base.dart';
import 'package:path/path.dart';
import 'package:pub_semver/pub_semver.dart';
import 'package:yaml_edit/yaml_edit.dart';

/// Works through all repositories and updates the Dart SDK.
class UpdateDartSdk extends CommandBase {
  /// Constructor
  UpdateDartSdk({
    required super.log,
  }) : super(
          name: 'update-dart-sdk',
          description: 'Updates the Dart SDK.',
        ) {
    _addArgs();
  }

  // ...........................................................................
  void _addArgs() {
    argParser.addOption(
      'min-version',
      abbr: 'v',
      help: 'The minium supported Dart SDK',
      valueHelp: '3.3.0',
      mandatory: true,
    );
  }

  // ...........................................................................
  late Version _version;
  @override
  void willStart({
    required String inputDir,
  }) {
    _version = Version.parse(argResults?['min-version'] as String);
    log('Updating the Dart SDK to version $_version in $inputDir');
  }

  // ...........................................................................
  @override
  Future<void> processProject({
    required YamlEditor pubspec,
    required Directory dir,
    required bool dryRun,
    void Function(String p1)? log,
  }) async {
    // Compose the version string
    final majorVersion = _version.major;
    final versionString = '>=$_version<${majorVersion + 1}.0.0';

    // Replace the dart sdk minimum version with next version
    pubspec.update(['environment', 'sdk'], versionString);

    // Write a log message
    final dirName = basename(dir.absolute.path.replaceAll(RegExp(r'/.$'), ''));
    log?.call('Updated the Dart SDK version to "$versionString" in $dirName');

    if (!dryRun) {
      final file = File('${dir.path}/pubspec.yaml');
      file.writeAsStringSync(pubspec.toString());
    }
  }
}
