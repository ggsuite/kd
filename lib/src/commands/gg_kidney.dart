// @license
// Copyright (c) 2019 - 2024 Dr. Gabriel Gatzsche. All Rights Reserved.
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

import 'package:args/command_runner.dart';
import 'package:gg_kidney/src/commands/open_with_vscode.dart';
import 'package:gg_kidney/src/commands/update_dart_sdk.dart';
import 'package:gg_kidney/src/commands/upgrade_dependencies.dart';

/// The command line interface for GgKidney
class GgKidney extends Command<dynamic> {
  /// Constructor
  GgKidney({required this.log}) {
    addSubcommand(UpdateDartSdk(log: log));
    addSubcommand(UpgradeDependencies(log: log));
    addSubcommand(OpenWithVsCode(log: log));
  }

  /// The log function
  final void Function(String message) log;

  // ...........................................................................
  @override
  final name = 'kidney';
  @override
  final description = 'Various maintenance tasks for our repositories.';
}
