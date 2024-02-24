#!/usr/bin/env dart
// @license
// Copyright (c) 2019 - 2024 Dr. Gabriel Gatzsche. All Rights Reserved.
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

import 'package:args/command_runner.dart';
import 'package:colorize/colorize.dart';
import 'package:gg_kidney/gg_kidney.dart';

// .............................................................................
Future<void> runGgKidney({
  required List<String> args,
  required void Function(String msg) log,
}) async {
  try {
    // Create command
    final ggKidney = GgKidney(log: log);

    // Create a command runner
    final CommandRunner<void> runner = CommandRunner<void>(
      'ggKidney',
      ggKidney.description,
    );

    // If no subcommands are defined, add the main command
    if (ggKidney.subcommands.isEmpty) {
      runner.addCommand(ggKidney);
    }
    // Otherwise, add the subcommands
    else {
      for (final subCommand in ggKidney.subcommands.values) {
        runner.addCommand(subCommand);
      }
    }

    // Run the command
    await runner.run(args);
  }

  // Print errors in red
  catch (e) {
    final msg = e.toString().replaceAll('Exception: ', '');
    log(Colorize(msg).red().toString());
    log('Error: $e');
  }
}

// .............................................................................
Future<void> main(List<String> args) async {
  await runGgKidney(
    args: args,
    log: (msg) => print(msg),
  );
}
