// @license
// Copyright (c) 2019 - 2024 Dr. Gabriel Gatzsche. All Rights Reserved.
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

import 'package:args/command_runner.dart';
import 'package:gg_kidney/src/commands/maintain.dart';
import 'package:gg_kidney/src/commands/copy_file.dart';
import 'package:gg_kidney/src/commands/delete_file.dart';
import 'package:gg_kidney/src/commands/open_with_vscode.dart';
import 'package:gg_kidney/src/commands/run_shell_command.dart';
import 'package:gg_kidney/src/commands/update_dart_sdk.dart';
import 'package:gg_kidney/src/commands/upgrade_dependencies.dart';
import 'package:gg_local_package_dependencies/gg_local_package_dependencies.dart';
import 'package:gg_log/gg_log.dart';

/// The command line interface for GgKidney
class GgKidney extends Command<dynamic> {
  /// Constructor
  GgKidney({required this.ggLog}) {
    addSubcommand(UpdateDartSdk(ggLog: ggLog));
    addSubcommand(UpgradeDependencies(ggLog: ggLog));
    addSubcommand(OpenWithVscode(ggLog: ggLog));
    addSubcommand(CopyFile(ggLog: ggLog));
    addSubcommand(DeleteFile(ggLog: ggLog));
    addSubcommand(Maintain(ggLog: ggLog));
    addSubcommand(RunShellCommand(ggLog: ggLog));
    addSubcommand(Graph(ggLog: ggLog));
  }

  /// The log function
  final GgLog ggLog;

  // ...........................................................................
  @override
  final name = 'ggKidney';
  @override
  final description = 'Various maintenance tasks for our repositories.';
}
