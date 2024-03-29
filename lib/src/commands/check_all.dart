// @license
// Copyright (c) 2019 - 2024 Dr. Gabriel Gatzsche. All Rights Reserved.
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

import 'dart:convert';
import 'dart:io';

import 'package:gg_console_colors/gg_console_colors.dart';
import 'package:gg_kidney/src/commands/command_base.dart';
import 'package:gg_log/gg_log.dart';
import 'package:gg_process/gg_process.dart';
import 'package:path/path.dart';
import 'package:yaml_edit/yaml_edit.dart';

// #############################################################################
/// Works through all repositories and updates the Dart SDK.
class CheckAll extends CommandBase {
  /// Constructor
  CheckAll({
    required super.ggLog,
    this.processWrapper = const GgProcessWrapper(),
  }) : super(
          name: 'check-all',
          description: 'Run gg_check all on all repos.',
        );

  // ...........................................................................
  @override
  Future<void> willStart({required String inputDir}) async {
    await super.willStart(inputDir: inputDir);

    // Check if ggCheck is installed
    final result = await processWrapper.run('gg', ['--version']);
    if (result.exitCode != 0) {
      throw Exception(
        '${red('gg is not installed. Run ')}'
        '${blue('»dart pub global activate gg«')}',
      );
    }
  }

  // ...........................................................................
  @override
  Future<void> processProject({
    required YamlEditor pubspec,
    required Directory dir,
    required bool dryRun,
    required bool verbose,
    GgLog? ggLog,
  }) async {
    final dirName = basename(dir.path);
    final verbose = argResults?['verbose'] as bool;

    if (dryRun) {
      return;
    }

    ggLog?.call('⌛️ $dirName');

    final p = await processWrapper.start(
      'gg',
      ['can', 'commit'],
      workingDirectory: dir.path,
    );

    if (verbose) {
      p.stdout.listen((event) {
        final message = utf8.decode(event);
        ggLog?.call(message);
      });

      p.stderr.listen((event) {
        final message = utf8.decode(event);
        ggLog?.call(message);
      });
    }

    // Todo: Don't print carriage return when running on github

    final result = await p.exitCode;
    const cr = '\x1b[1A\x1b[2K';
    if (result != 0) {
      ggLog?.call('$cr❌ $dirName');
      exitCode = result;
    } else {
      ggLog?.call('$cr✅ $dirName');
    }
  }

  // ...........................................................................
  /// The method
  final GgProcessWrapper processWrapper;
}
