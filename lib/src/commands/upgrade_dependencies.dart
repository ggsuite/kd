// @license
// Copyright (c) 2019 - 2024 Dr. Gabriel Gatzsche. All Rights Reserved.
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

import 'dart:io';

import 'package:colorize/colorize.dart';
import 'package:gg_kidney/src/commands/command_base.dart';
import 'package:gg_kidney/src/tools/process_run.dart';
import 'package:path/path.dart';
import 'package:yaml_edit/yaml_edit.dart';

// #############################################################################
/// Works through all repositories and updates the Dart SDK.
class UpgradeDependencies extends CommandBase {
  /// Constructor
  UpgradeDependencies({
    required super.log,
    this.processRun = Process.run,
  }) : super(
          name: 'upgrade-dependencies',
          description: 'Upgrades package dependencies.',
        );

  @override
  void willStart({
    required String inputDir,
  }) {
    log('Upgrading package dependencies in $inputDir');
  }

  // ...........................................................................
  /// The method
  final ProcessRun processRun;

  // ...........................................................................
  @override
  Future<void> processProject({
    required YamlEditor pubspec,
    required Directory dir,
    required bool dryRun,
    void Function(String p1)? log,
  }) async {
    // Write a log message
    final dirName = basename(dir.absolute.path.replaceAll(RegExp(r'/.$'), ''));
    log?.call('Upgraded package dependencies of $dirName');

    // Execute dart pub upgrade
    final result = await processRun(
      'dart',
      ['pub', 'upgrade', if (dryRun) '--dry-run'],
      workingDirectory: dir.path,
    );

    if (result.exitCode != 0) {
      final details =
          result.stderr.toString().trim() + result.stdout.toString().trim();

      log?.call(
        Colorize('Failed to upgrade dependencies for $dirName.')
            .red()
            .toString(),
      );

      log?.call(
        Colorize(details).darkGray().toString(),
      );
    }

    exitCode = result.exitCode;
  }
}
