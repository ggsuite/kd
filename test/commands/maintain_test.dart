// @license
// Copyright (c) 2019 - 2024 Dr. Gabriel Gatzsche. All Rights Reserved.
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

// import 'package:kidney/src/commands/check_all.dart';
import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:fake_async/fake_async.dart';
import 'package:gg_console_colors/gg_console_colors.dart';
import 'package:kidney/src/commands/maintain.dart';
import 'package:gg_local_package_dependencies/gg_local_package_dependencies.dart';
import 'package:gg_process/gg_process.dart';
import 'package:path/path.dart';
import 'package:pubspec_parse/pubspec_parse.dart';
import 'package:test/test.dart';
import 'package:mocktail/mocktail.dart';

import '../test_helpers/create_sample_repos.dart';

void main() {
  group('Maintain', () {
    final cwd = Directory.current.path;
    late GgProcessWrapper processWrapper;
    final ggDoMaintain = <GgFakeProcess>[];
    late CommandRunner<void> runner;
    late List<Directory> repos;
    late Directory root;
    late List<String> messages = [];
    late ProcessingList processingList;

    // .........................................................................
    tearDown(() {
      Directory.current = cwd;
    });

    // .........................................................................
    void mockGgVersionResult({int exitCode = 0}) {
      when(
        () => processWrapper.run(
          'gg',
          ['--help'],
        ),
      ).thenAnswer(
        (_) => Future.value(ProcessResult(0, exitCode, 'gg 1.2.3', '')),
      );
    }

    // .........................................................................
    void mockGgCanCommit() {
      for (final repo in repos) {
        final process = GgFakeProcess();
        ggDoMaintain.add(process);

        when(
          () => processWrapper.start(
            'gg',
            ['do', 'maintain'],
            workingDirectory: repo.path,
          ),
        ).thenAnswer((_) => Future.value(process));
      }
    }

    // .........................................................................
    void mockProcessingList() {
      final nodes = repos.map((e) {
        final pubspecString = File('${e.path}/pubspec.yaml').readAsStringSync();
        final pubspec = Pubspec.parse(pubspecString);

        return Node(
          name: basename(e.path),
          directory: e.absolute,
          pubspec: pubspec,
        );
      }).toList();

      when(
        () => processingList.get(
          ggLog: any(named: 'ggLog'),
          directory: any(named: 'directory'),
        ),
      ).thenAnswer((_) => Future.value(nodes));
    }

    // .........................................................................
    void init() {
      registerFallbackValue(Directory(''));

      // Clear messages
      messages.clear();
      ggDoMaintain.clear();

      // Create folders
      repos = createSampleRepos();
      root = repos.first.parent;

      // Init processing list
      processingList = MockProcessingList();
      mockProcessingList();

      // Init process wrapper
      processWrapper = MockGgProcessWrapper();

      // Create a process fake result
      mockGgCanCommit();

      // Create command
      final maintain = Maintain(
        ggLog: messages.add,
        processWrapper: processWrapper,
        processingList: processingList,
      );

      runner = CommandRunner('test', 'test')..addCommand(maintain);
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
          'maintain',
          '--repos',
          root.path,
          '--no-dry-run',
          '--verbose',
          '--no-exit-on-error',
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
            ['do', 'maintain'],
            workingDirectory: any(
              named: 'workingDirectory',
            ),
          ),
        ).called(1);

        // Start message should be logged
        expect(messages[i++], '⌛️ dir0');

        // stdout and stderr should be logged
        ggDoMaintain[0].pushToStdout.add('dir0 is ok.');
        fake.flushMicrotasks();
        expect(messages[i++], 'dir0 is ok.');
        ggDoMaintain[0].pushToStderr.add('dir0 has some error.');
        expect(messages[i++], 'dir0 has some error.');

        // Finish the process for dir0
        ggDoMaintain[0].exit(0);
        fake.flushMicrotasks();

        // Success should be logged
        expect(messages[i++], contains('✅ dir0'));

        // .............
        // Process dir 1
        verify(
          () => processWrapper.start(
            'gg',
            ['do', 'maintain'],
            workingDirectory: repos[1].path,
          ),
        ).called(1);

        // Start message should be logged
        expect(messages[i++], '⌛️ dir1');

        // stdout and stderr should be logged
        ggDoMaintain[1].pushToStdout.add('dir1 is ok.');
        fake.flushMicrotasks();
        expect(messages[i++], 'dir1 is ok.');
        ggDoMaintain[1].pushToStderr.add('dir1 has some error.');
        expect(messages[i++], 'dir1 has some error.');

        // Finish the process for dir1 with fail
        ggDoMaintain[1].exit(1);
        fake.flushMicrotasks();

        // Fail should be logged
        expect(messages[i++], contains('❌ dir1'));

        // .............
        // Process dir 2
        fake.flushMicrotasks();
        verify(
          () => processWrapper.start(
            'gg',
            ['do', 'maintain'],
            workingDirectory: repos[2].path,
          ),
        ).called(1);

        // Start message should be logged
        expect(messages[i++], contains('⌛️ dir2'));

        // stdout and stderr should be logged
        ggDoMaintain[2].pushToStdout.add('dir2 is ok.');
        fake.flushMicrotasks();
        expect(messages[i++], 'dir2 is ok.');
        ggDoMaintain[2].pushToStderr.add('dir2 has some error.');
        expect(messages[i++], 'dir2 has some error.');

        // Finish the process for dir2
        ggDoMaintain[2].exit(0);
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
          'maintain',
          '--repos',
          root.path,
          '--no-dry-run',
          '--verbose',
          '--no-exit-on-error',
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

    group('should exit on the first error', () {
      void runTest([List<String> extraOptions = const []]) {
        fakeAsync((fake) {
          init();
          mockGgVersionResult(exitCode: 0);

          // Run the command

          late String exception;

          runner.run([
            'maintain',
            '--repos',
            root.path,
            '--no-dry-run',
            '--verbose',
            ...extraOptions,
          ]).onError((error, stackTrace) {
            exception = error.toString();
          });

          // Wait a little bit
          fake.flushMicrotasks();

          ggDoMaintain[0].exit(1);
          fake.flushMicrotasks();

          expect(exception, contains('❌ dir0'));
        });
      }

      test('when called without --exit-on-error', () async {
        runTest([]);
      });

      test('when called with --exit-on-error', () async {
        runTest(['--exit-on-error']);
      });
    });
  });
}
