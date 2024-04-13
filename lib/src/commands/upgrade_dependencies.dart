// @license
// Copyright (c) 2019 - 2024 Dr. Gabriel Gatzsche. All Rights Reserved.
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

import 'dart:io';

import 'package:gg_console_colors/gg_console_colors.dart';
import 'package:kidney/src/commands/command_base.dart';
import 'package:gg_process/gg_process.dart';
import 'package:path/path.dart';
import 'package:yaml_edit/yaml_edit.dart';

// #############################################################################
/// Works through all repositories and updates the Dart SDK.
class UpgradeDependencies extends CommandBase {
  /// Constructor
  UpgradeDependencies({
    required super.ggLog,
    this.process = const GgProcessWrapper(),
  }) : super(
          name: 'upgrade-dependencies',
          description: 'Upgrades package dependencies.',
        );

  @override
  Future<void> willStart({
    required Directory inputDir,
  }) async {
    ggLog('Upgrading package dependencies in $inputDir');
  }

  // ...........................................................................
  /// This method is used to run processes
  final GgProcessWrapper process;

  // ...........................................................................
  @override
  Future<void> processProject({
    required YamlEditor pubspec,
    required Directory dir,
    required bool dryRun,
    required bool verbose,
    void Function(String p1)? ggLog,
  }) async {
    // Write a log message
    final dirName = basename(dir.absolute.path.replaceAll(RegExp(r'/.$'), ''));
    ggLog?.call('Upgrade package dependencies of $dirName.');

    // Execute dart pub upgrade
    final result = await process.run(
      'dart',
      ['pub', 'upgrade', '--major-versions', if (dryRun) '--dry-run'],
      workingDirectory: dir.path,
    );

    if (result.exitCode != 0) {
      final details =
          result.stderr.toString().trim() + result.stdout.toString().trim();

      ggLog?.call(
        red('Failed to upgrade dependencies for $dirName.'),
      );

      ggLog?.call(
        darkGray(details),
      );
    }

    exitCode = result.exitCode;
  }
}
