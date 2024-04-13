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
class Maintain extends CommandBase {
  /// Constructor
  Maintain({
    required super.ggLog,
    super.processingList,
    this.processWrapper = const GgProcessWrapper(),
  }) : super(
          name: 'maintain',
          description: 'Run »gg do maintain« all on all repos.',
        ) {
    _addArgs();
  }

  // ...........................................................................
  @override
  Future<void> willStart({required Directory inputDir}) async {
    await super.willStart(inputDir: inputDir);

    // Check if ggCheck is installed
    final result = await processWrapper.run('gg', ['--help']);
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
    bool? exitOnError,
    GgLog? ggLog,
  }) async {
    exitOnError ??= argResults?['exit-on-error'] as bool? ?? true;

    final dirName = basename(dir.path);
    final verbose = argResults?['verbose'] as bool;

    if (dryRun) {
      return;
    }

    ggLog?.call('⌛️ $dirName');

    final p = await processWrapper.start(
      'gg',
      ['do', 'maintain'],
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

    final result = await p.exitCode;
    const cr = '\x1b[1A\x1b[2K';
    if (result != 0) {
      final message = '❌ $dirName';
      if (exitOnError) {
        throw Exception(message);
      } else {
        ggLog?.call(message);
      }
    } else {
      ggLog?.call('$cr✅ $dirName');
    }
  }

  // ...........................................................................
  /// The method
  final GgProcessWrapper processWrapper;

  // ...........................................................................
  void _addArgs() {
    argParser.addFlag(
      'exit-on-error',
      abbr: 'x',
      help: 'Makes command exit on first error.',
      defaultsTo: true,
      negatable: true,
    );
  }
}
