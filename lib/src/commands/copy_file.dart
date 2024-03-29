// @license
// Copyright (c) 2019 - 2024 Dr. Gabriel Gatzsche. All Rights Reserved.
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

import 'dart:io';

import 'package:gg_console_colors/gg_console_colors.dart';
import 'package:gg_kidney/src/commands/command_base.dart';
import 'package:path/path.dart';
import 'package:yaml_edit/yaml_edit.dart';

// #############################################################################
/// Copies a file from one repository to all other repositories.
class CopyFile extends CommandBase {
  /// Constructor
  CopyFile({
    required super.ggLog,
  }) : super(
          name: 'copy-file',
          description:
              'Copies a file from a reference project to all other projects.',
        ) {
    _addArgs();
  }

  // ...........................................................................
  @override
  Future<void> willStart({
    required String inputDir,
  }) async {
    _fileToBeCopied = File(absolute(((argResults?['source'] as String))));
    _outputPath = argResults?['output'] as String;
    _force = argResults?['force'] as bool;

    ggLog('Copying ${basename(_fileToBeCopied.path)} to $_outputPath');
    await super.willStart(inputDir: inputDir);

    if (!_fileToBeCopied.existsSync()) {
      throw ArgumentError('The file to be copied does not exist.');
    }

    if (!_force) {
      final forceStr = red('--force');
      ggLog(
        'Existing files will not be overwritten. Use $forceStr to overwrite.',
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
    required void Function(String p1) ggLog,
  }) async {
    // Define target file path
    final targetFile = File('${dir.path}/$_outputPath');
    final targetDirPath = dirname(targetFile.path);

    // File exists? Skip when not forced
    if (!_force && targetFile.existsSync()) {
      return;
    }

    // Create target directory
    Directory(targetDirPath).createSync(
      recursive: true,
    );

    // Log directory
    late String message = targetFile.path;

    // Log gray when dry-run, blue, when not
    if (dryRun) {
      ggLog('- ${darkGray(message)}');
    } else {
      _fileToBeCopied.copySync(targetFile.path);
      ggLog('- ${blue(message)}');
    }
  }

  // ...........................................................................
  void _addArgs() {
    argParser.addOption(
      'source',
      abbr: 's',
      help: 'The file to be copied to all repos.',
      mandatory: true,
    );

    argParser.addOption(
      'output',
      abbr: 'o',
      help: 'The relative path of the file in the target repos.',
      mandatory: true,
    );

    argParser.addFlag(
      'force',
      abbr: 'f',
      help: 'Overwrite existing files.',
      defaultsTo: false,
    );
  }

  late File _fileToBeCopied;
  late String _outputPath;
  late bool _force;
}
