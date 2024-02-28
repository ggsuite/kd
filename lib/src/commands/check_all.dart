// @license
// Copyright (c) 2019 - 2024 Dr. Gabriel Gatzsche. All Rights Reserved.
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

import 'dart:convert';
import 'dart:io';

import 'package:gg_kidney/src/commands/command_base.dart';
import 'package:gg_process/gg_process.dart';
import 'package:path/path.dart';
import 'package:yaml_edit/yaml_edit.dart';

// #############################################################################
/// Works through all repositories and updates the Dart SDK.
class CheckAll extends CommandBase {
  /// Constructor
  CheckAll({
    required super.log,
    this.processWrapper = const GgProcessWrapper(),
  }) : super(
          name: 'check-all',
          description: 'Run gg_check all on all repos.',
        ) {
    _addArgs();
  }

  // ...........................................................................
  @override
  Future<void> willStart({required String inputDir}) async {
    // Check if ggCheck is installed
    // coverage:ignore-start
    final result = await processWrapper.run('ggCheck', ['--version']);
    if (result.exitCode != 0) {
      throw Exception('ggCheck is not installed.');
    }
    // coverage:ignore-end
  }

  // ...........................................................................
  @override
  Future<void> processProject({
    required YamlEditor pubspec,
    required Directory dir,
    required bool dryRun,
    void Function(String p1)? log,
  }) async {
    final dirName = basename(dir.path);
    final verbose = argResults?['verbose'] as bool;

    if (dryRun) {
      return;
    }

    log?.call('⌛️ $dirName');

    final p = await processWrapper.start(
      'ggCheck',
      ['all'],
      workingDirectory: dir.path,
    );

    if (verbose) {
      p.stdout.listen((event) {
        final message = utf8.decode(event);
        log?.call(message);
      });

      p.stderr.listen((event) {
        final message = utf8.decode(event);
        log?.call(message);
      });
    }

    final result = await p.exitCode;
    const cr = '\x1b[1A\x1b[2K';
    if (result != 0) {
      log?.call('$cr❌ $dirName');
      exitCode = result;
    } else {
      log?.call('$cr✅ $dirName');
    }
  }

  // ...........................................................................
  // verbose flag
  void _addArgs() {
    argParser.addFlag(
      'verbose',
      abbr: 'v',
      negatable: false,
      help: 'Prints additional information.',
      defaultsTo: false,
    );
  }

  // ...........................................................................
  /// The method
  final GgProcessWrapper processWrapper;
}
