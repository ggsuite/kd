// @license
// Copyright (c) 2019 - 2024 Dr. Gabriel Gatzsche. All Rights Reserved.
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

// ...........................................................................
import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:gg_process/gg_process.dart';

import 'create_sample_repos.dart';

class TestEnvironment {
  TestEnvironment() : process = MockGgProcessWrapper();
  final List<String> logMessages = [];
  final List<Directory> sampleRepos = createSampleRepos();
  String get root => sampleRepos.first.parent.path;
  final CommandRunner<dynamic> runner = CommandRunner<dynamic>('test', 'test');
  void addCommand(Command<dynamic> command) {
    runner.addCommand(command);
  }

  final MockGgProcessWrapper process;
}
