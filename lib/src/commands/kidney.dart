#!/usr/bin/env dart
// @license
// Copyright (c) 2019 - 2024 Dr. Gabriel Gatzsche. All Rights Reserved.
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

import 'package:args/command_runner.dart';
import 'package:gg_log/gg_log.dart';
import 'package:kidney_core/kidney_core.dart';
import 'kidney_bash.dart';
import 'kidney_run.dart'; // Newly added import for the run command

/// The parent command for Kidney operations.
class Kidney extends Command<void> {
  /// Constructor
  Kidney({required this.ggLog}) {
    addSubcommand(KidneyBash(ggLog: ggLog));
    addSubcommand(KidneyRun(ggLog: ggLog));
    KidneyCore(ggLog: ggLog).subcommands.values.forEach(addSubcommand);
  }

  /// The log function
  final GgLog ggLog;

  @override
  String get name => 'kd';

  @override
  String get description => 'Various maintenance tasks for our repositories.';
}
