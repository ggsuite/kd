#!/usr/bin/env dart
// @license
// Copyright (c) 2019 - 2024 Dr. Gabriel Gatzsche. All Rights Reserved.
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

import 'package:gg_args/gg_args.dart';
import 'package:kd/kd.dart';
import 'package:test/test.dart';
import 'dart:io';

void main() {
  final output = <String>[];
  void ggLog(String msg) => output.add(msg);

  group('KidneyCommand', () {
    late Kidney kidneyCommand;
    late GgCommandRunner runner;

    setUp(() {
      output.clear();
      kidneyCommand = Kidney(ggLog: ggLog);
      runner = GgCommandRunner(ggLog: ggLog, command: kidneyCommand);
    });

    test('should display usage help when no subcommand is provided', () async {
      await runner.run(args: []);
      expect(output.join('\n'), contains('Usage:'));
    });

    test('should delegate to bash subcommand', () async {
      final tempDir = Directory.systemTemp.createTempSync('kidney_test');
      try {
        // Create a dummy pubspec.yaml to simulate a Dart package.
        final Directory projectDir = Directory('${tempDir.path}/project');
        projectDir.createSync();
        File('${projectDir.path}/pubspec.yaml').writeAsStringSync('name: temp');
        await runner.run(
          args: [
            'bash',
            tempDir.path,
            '--apply',
            '--verbose',
            'dart',
            'format',
            '.',
            '-o',
            'write',
            '--set-exit-if-changed',
          ],
        );
        expect(output.join('\n'), contains('✅'));
      } finally {
        tempDir.deleteSync(recursive: true);
      }
    });
  });
}
