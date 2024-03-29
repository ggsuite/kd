// @license
// Copyright (c) 2019 - 2024 Dr. Gabriel Gatzsche. All Rights Reserved.
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

// import 'package:gg_kidney/src/commands/check_all.dart';
import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:fake_async/fake_async.dart';
import 'package:gg_console_colors/gg_console_colors.dart';
import 'package:gg_kidney/src/commands/check_all.dart';
import 'package:gg_process/gg_process.dart';
import 'package:test/test.dart';
import 'package:mocktail/mocktail.dart';

import '../test_helpers/create_sample_repos.dart';

void main() {
  group('CheckAll', () {
    final cwd = Directory.current.path;
    late GgProcessWrapper processWrapper;
    final ggCanCommit = <GgFakeProcess>[];
    late CommandRunner<void> runner;
    late List<Directory> repos;
    late Directory root;
    late List<String> messages = [];

    // .........................................................................
    tearDown(() {
      Directory.current = cwd;
    });

    // .........................................................................
    void mockGgVersionResult({int exitCode = 0}) {
      when(
        () => processWrapper.run(
          'gg',
          ['--version'],
        ),
      ).thenAnswer(
        (_) => Future.value(ProcessResult(0, exitCode, 'gg 1.2.3', '')),
      );
    }

    // .........................................................................
    void mockGgCanCommit() {
      for (final repo in repos) {
        final process = GgFakeProcess();
        ggCanCommit.add(process);

        when(
          () => processWrapper.start(
            'gg',
            ['can', 'commit'],
            workingDirectory: repo.path,
          ),
        ).thenAnswer((_) => Future.value(process));
      }
    }

    // .........................................................................
    void init() {
      // Clear messages
      messages.clear();
      ggCanCommit.clear();

      // Create folders
      repos = createSampleRepos();
      root = repos.first.parent;

      // Init process wrapper
      processWrapper = MockGgProcessWrapper();

      // Create a process fake result
      mockGgCanCommit();

      // Create command
      final checkAll = CheckAll(
        ggLog: messages.add,
        processWrapper: processWrapper,
      );

      runner = CommandRunner('test', 'test')..addCommand(checkAll);
    }

    tearDown(() {
      Directory.current = cwd;
    });

    // .........................................................................
    test('should log result', () {
      fakeAsync((fake) {
        init();
        mockGgVersionResult(exitCode: 0);

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
        verify(
          () => processWrapper.start(
            'gg',
            ['can', 'commit'],
            workingDirectory: repos[0].path,
          ),
        ).called(1);

        // Start message should be logged
        expect(messages[i++], '⌛️ dir0');

        // stdout and stderr should be logged
        ggCanCommit[0].pushToStdout.add('dir0 is ok.');
        fake.flushMicrotasks();
        expect(messages[i++], 'dir0 is ok.');
        ggCanCommit[0].pushToStderr.add('dir0 has some error.');
        expect(messages[i++], 'dir0 has some error.');

        // Finish the process for dir0
        ggCanCommit[0].exit(0);
        fake.flushMicrotasks();

        // Success should be logged
        expect(messages[i++], contains('✅ dir0'));

        // .............
        // Process dir 1
        verify(
          () => processWrapper.start(
            'gg',
            ['can', 'commit'],
            workingDirectory: repos[1].path,
          ),
        ).called(1);

        // Start message should be logged
        expect(messages[i++], '⌛️ dir1');

        // stdout and stderr should be logged
        ggCanCommit[1].pushToStdout.add('dir1 is ok.');
        fake.flushMicrotasks();
        expect(messages[i++], 'dir1 is ok.');
        ggCanCommit[1].pushToStderr.add('dir1 has some error.');
        expect(messages[i++], 'dir1 has some error.');

        // Finish the process for dir1 with fail
        ggCanCommit[1].exit(1);
        fake.flushMicrotasks();

        // Faile should be logged
        expect(messages[i++], contains('❌ dir1'));

        // .............
        // Process dir 2
        fake.flushMicrotasks();
        verify(
          () => processWrapper.start(
            'gg',
            ['can', 'commit'],
            workingDirectory: repos[2].path,
          ),
        ).called(1);

        // Start message should be logged
        expect(messages[i++], contains('⌛️ dir2'));

        // stdout and stderr should be logged
        ggCanCommit[2].pushToStdout.add('dir2 is ok.');
        fake.flushMicrotasks();
        expect(messages[i++], 'dir2 is ok.');
        ggCanCommit[2].pushToStderr.add('dir2 has some error.');
        expect(messages[i++], 'dir2 has some error.');

        // Finish the process for dir2
        ggCanCommit[2].exit(0);
        fake.flushMicrotasks();

        // Success should be logged
        expect(messages[i++], contains('✅ dir2'));

        // .............
        // After all processes have finished
        fake.flushMicrotasks();
        expect(finished, isTrue);
      });
    });

    test('should install gg when not already done', () {
      fakeAsync((fake) {
        init();
        mockGgVersionResult(exitCode: 1);

        late String exception;

        runner.run([
          'check-all',
          '--repos',
          root.path,
          '--no-dry-run',
          '--verbose',
        ]).catchError((Object e) {
          exception = e.toString();
        });

        fake.flushMicrotasks();

        expect(
            exception,
            'Exception: '
            '${red('gg is not installed. Run ')}'
            '${blue('»dart pub global activate gg«')}');
      });
    });
  });
}
