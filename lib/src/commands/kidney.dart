// @license
// Copyright (c) 2019 - 2024 Dr. Gabriel Gatzsche. All Rights Reserved.
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

import 'package:args/command_runner.dart';
import 'package:kidney/src/commands/run_shell_command.dart';
import 'package:gg_local_package_dependencies/gg_local_package_dependencies.dart';
import 'package:gg_log/gg_log.dart';

/// The command line interface for Kidney
class Kidney extends Command<dynamic> {
  /// Constructor
  Kidney({required this.ggLog}) {
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
