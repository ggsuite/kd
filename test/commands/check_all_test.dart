// @license
// Copyright (c) 2019 - 2024 Dr. Gabriel Gatzsche. All Rights Reserved.
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

// import 'package:gg_kidney/src/commands/check_all.dart';
import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:fake_async/fake_async.dart';
import 'package:gg_kidney/src/commands/check_all.dart';
import 'package:gg_process/gg_process.dart';
import 'package:path/path.dart';
import 'package:test/test.dart';

import '../test_helpers/create_sample_repos.dart';

void main() {
  group('CheckAll', () {
    final cwd = Directory.current.path;
    late GgProcessMock lastProcess;
    late CallArguments lastCallArgs;
    late CommandRunner<void> runner;
    late Directory root;
    late List<String> messages = [];

    // .........................................................................
    tearDown(() {
      Directory.current = cwd;
    });

    // .........................................................................
    void init() {
      // Clear messages
      messages.clear();

      // Create folders
      final repos = createSampleRepos();
      root = repos.first.parent;

      // Create a process fake result
      final wrapper = GgProcessWrapperMock(
        onStart: (call) {
          lastProcess = GgProcessMock();
          lastCallArgs = call;
          return lastProcess;
        },
      );

      // Create command
      final checkAll = CheckAll(
        log: messages.add,
        processWrapper: wrapper,
      );

      runner = CommandRunner('test', 'test')..addCommand(checkAll);
    }

    tearDown(() {
      Directory.current = cwd;
    });

    test('should log result', () {
      fakeAsync((fake) {
        init();

        // Run the command
        var finished = false;

        runner.run([
          'check-all',
          '--repos',
          root.path,
          '--no-dry-run',
          '--verbose',
        ]).then((value) => finished = true);

        // Wait a little bit
        fake.flushMicrotasks();

        // .............
        // Process dir 0

        var i = 0;

        // gg_check all should be called for the first folder
        expect(lastCallArgs.executable, 'ggCheck');
        expect(lastCallArgs.arguments, ['all']);
        expect(basename(lastCallArgs.workingDirectory!), 'dir0');

        // Start message should be logged
        expect(messages[i++], '⌛️ dir0');

        // stdout and stderr should be logged
        lastProcess.pushToStdout.add('dir0 is ok.');
        fake.flushMicrotasks();
        expect(messages[i++], 'dir0 is ok.');
        lastProcess.pushToStderr.add('dir0 has some error.');
        expect(messages[i++], 'dir0 has some error.');

        // Finish the process for dir0
        lastProcess.exit(0);
        fake.flushMicrotasks();

        // Success should be logged
        expect(messages[i++], contains('✅ dir0'));

        // .............
        // Process dir 1
        expect(lastCallArgs.executable, 'ggCheck');
        expect(lastCallArgs.arguments, ['all']);
        expect(basename(lastCallArgs.workingDirectory!), 'dir1');

        // Start message should be logged
        expect(messages[i++], '⌛️ dir1');

        // stdout and stderr should be logged
        lastProcess.pushToStdout.add('dir1 is ok.');
        fake.flushMicrotasks();
        expect(messages[i++], 'dir1 is ok.');
        lastProcess.pushToStderr.add('dir1 has some error.');
        expect(messages[i++], 'dir1 has some error.');

        // Finish the process for dir1 with fail
        lastProcess.exit(1);
        fake.flushMicrotasks();

        // Faile should be logged
        expect(messages[i++], contains('❌ dir1'));

        // .............
        // Process dir 2
        fake.flushMicrotasks();
        expect(lastCallArgs.executable, 'ggCheck');
        expect(lastCallArgs.arguments, ['all']);
        expect(basename(lastCallArgs.workingDirectory!), 'dir2');

        // Start message should be logged
        expect(messages[i++], contains('⌛️ dir2'));

        // stdout and stderr should be logged
        lastProcess.pushToStdout.add('dir2 is ok.');
        fake.flushMicrotasks();
        expect(messages[i++], 'dir2 is ok.');
        lastProcess.pushToStderr.add('dir2 has some error.');
        expect(messages[i++], 'dir2 has some error.');

        // Finish the process for dir2
        lastProcess.exit(0);
        fake.flushMicrotasks();

        // Success should be logged
        expect(messages[i++], contains('✅ dir2'));

        // .............
        // After all processes have finished
        fake.flushMicrotasks();
        expect(finished, isTrue);
      });
    });
  });
}
