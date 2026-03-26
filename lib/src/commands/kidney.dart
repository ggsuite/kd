#!/usr/bin/env dart
// @license
// Copyright (c) 2025 Göran Hegenberg. All Rights Reserved.
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

import 'package:args/command_runner.dart';
import 'package:gg_log/gg_log.dart';
import 'package:kidney_core/kidney_core.dart';

import 'kidney_one.dart';
import 'kidney_run.dart';

/// The parent command for Kidney operations.
class Kidney extends Command<void> {
  /// Create the root kidney command and register subcommands.
  Kidney({required this.ggLog}) {
    addSubcommand(KidneyRun(ggLog: ggLog));
    addSubcommand(KidneyOne(ggLog: ggLog));
    KidneyCore(ggLog: ggLog).subcommands.values.forEach(addSubcommand);
  }

  /// The log function.
  final GgLog ggLog;

  @override
  String get name => 'kd';

  @override
  String get description => 'Various maintenance tasks for our repositories.';
}
