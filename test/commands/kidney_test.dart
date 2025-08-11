// @license
// Copyright (c) 2019 - 2024 Dr. Gabriel Gatzsche. All Rights Reserved.
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

import 'dart:io';

import 'package:gg_console_colors/gg_console_colors.dart';
import 'package:kidney/kidney.dart';
import 'package:test/test.dart';

void main() {
  late Directory dRoot;
  late Directory d0;
  late Directory d1;
  late Directory d2;

  final messages = <String>[];
  final ggLog = messages.add;
  late Kidney kidney;
  late List<String> arguments;

  // ...........................................................................
  Future<void> initDartPackages() async {
    // Create a pubspec.yaml file in each directory, except dir2
    await File('${d0.path}/pubspec.yaml').writeAsString('name: dir0');
    await File(
      '${d1.path}/pubspec.yaml',
    ).writeAsString('name: dir1\ndependencies: \n  dir0: any');

    // Create a textfile in each directory
    await File('${d0.path}/file0.txt').writeAsString('file0');
    await File('${d1.path}/file1.txt').writeAsString('file1');
    await File('${d2.path}/file2.txt').writeAsString('file2');
  }

  // ...........................................................................
  setUp(() async {
    messages.clear();

    dRoot = await Directory.systemTemp.createTemp('kidney_test');
    d0 = await Directory('${dRoot.path}/dir0').create();
    d1 = await Directory('${dRoot.path}/dir1').create();
    d2 = await Directory('${dRoot.path}/dir2').create();
    await initDartPackages();

    kidney = Kidney(ggLog: ggLog);
    arguments = [dRoot.path, '--apply', '--verbose', 'dart', '--help'];
  });

  tearDown(() async {
    await dRoot.delete(recursive: true);
  });

  // #########################################################################
  group('Kidney', () {
    group('run(args)', () {
      group('- main case', () {
        void checkMessages({required bool verbose, required bool apply}) {
          var i = 0;

          if (apply) {
            expect(messages[i++], contains('⌛️ dir0'));
          }
          expect(messages[i++], contains('✅ dir0'));
          if (apply && verbose) {
            expect(
              messages[i++],
              contains('A command-line utility for Dart development.'),
            );
          }

          if (apply) {
            expect(messages[i++], contains('⌛️ dir1'));
          }
          expect(messages[i++], contains('✅ dir1'));
          if (apply && verbose) {
            expect(
              messages[i++],
              contains('A command-line utility for Dart development.'),
            );
          }

          if (!apply) {
            expect(messages[i++], kidney.missingApplyHelp);
          }

          if (apply && !verbose) {
            expect(messages[i++], kidney.missingVerboseHelp);
          }

          expect(messages, hasLength(i));
        }

        group(
          '- should apply cli commands to all dart packages in a folder',
          () {
            test('with --apply and --verbose', () async {
              await kidney.run([dRoot.path, '-av', 'dart', '--help']);
              checkMessages(apply: true, verbose: true);
            });

            test('with --apply only', () async {
              await kidney.run([dRoot.path, '-a', 'dart', '--help']);
              checkMessages(apply: true, verbose: false);
            });

            test('with --verbose only', () async {
              await kidney.run([dRoot.path, '-v', 'dart', '--help']);
              checkMessages(apply: false, verbose: true);
            });
          },
        );
      });

      group('- edge cases', () {
        test('- should do nothing if --apply is not set', () async {
          Future<void> check({required bool didCreate}) async {
            final file0 = File('${d0.path}/file.txt');
            final file1 = File('${d1.path}/file.txt');
            expect(await file0.exists(), didCreate);
            expect(await file1.exists(), didCreate);
          }

          // Run without -a -> Nothing is done
          if (Platform.isWindows) {
            // coverage:ignore-start
            await kidney.run([
              dRoot.path,
              '-v',
              'fsutil',
              'file',
              'createnew',
              'file.txt',
              '100',
            ]);

            await check(didCreate: false);

            // Run with -a -> File is created
            await kidney.run([
              dRoot.path,
              '-av',
              'fsutil',
              'file',
              'createnew',
              'file.txt',
              '100',
            ]);
            await check(didCreate: true);
            // coverage:ignore-end
          } else {
            await kidney.run([dRoot.path, '-v', 'touch', 'file.txt']);
            await check(didCreate: false);

            // Run with -a -> File is created
            await kidney.run([dRoot.path, '-av', 'touch', 'file.txt']);
            await check(didCreate: true);
          }
        });

        test('- should throw, if no packages are found', () async {
          await File('${d0.path}/pubspec.yaml').delete();
          await File('${d1.path}/pubspec.yaml').delete();

          late String exception;
          try {
            await kidney.run([dRoot.path, '-av', 'dart', '--help']);
          } catch (e) {
            exception = e.toString();
          }
          expect(exception, contains('No dart packages found'));
        });
      });
    });

    group('readArgs(args)', () {
      group('- main case', () {
        test(
          '- reads kidney args, command args, directory, verbose and apply',
          () async {
            final (directory, kidneyArgs, commandArgs, verbose, apply) =
                await kidney.readArgs(arguments);

            expect(directory.path, dRoot.path);
            expect(kidneyArgs, ['--apply', '--verbose']);
            expect(commandArgs, ['dart', '--help']);
            expect(verbose, true);
            expect(apply, true);
          },
        );

        group('- throws an exception with help', () {
          test('- when the list of command arguments is empty', () async {
            late String exception;
            arguments.remove('dart');
            arguments.remove('--help');
            try {
              await kidney.readArgs(arguments);
            } on ArgumentError catch (e) {
              exception = e.message.toString();
            }
            expect(exception, kidney.commandArgumentsMissingHelp);
          });

          test('- when there is an unknown kidney argument', () async {
            late String exception;
            try {
              arguments.insert(2, '--xyz');
              arguments.insert(3, '--abc');
              await kidney.readArgs(arguments);
            } on ArgumentError catch (e) {
              exception = e.message.toString();
            }
            expect(exception, contains(red('--xyz, --abc')));
          });
        });
      });

      group('- edge cases', () {
        group('- interpretes the first argument', () {
          test('- as a folder, when it is a folder', () async {
            final (directory, _, _, _, _) = await kidney.readArgs(arguments);
            expect(directory.path, dRoot.path);
          });
          test('- as part of the command, if it is not a folder', () async {
            final (_, _, commandArgs, _, _) = await kidney.readArgs(['x', 'y']);
            expect(commandArgs, ['x', 'y']);
          });
        });

        group('- returns current directory', () {
          test('if the first argument is not a folder', () async {
            final (directory, _, _, _, _) = await kidney.readArgs(['x', 'y']);
            expect(directory.path, Directory.current.path);
          });
        });

        group('- removes the first argument, when it ends with', () {
          test('- kidney', () async {
            arguments = ['kidney', ...arguments];

            final (_, kidneyArgs, _, _, _) = await kidney.readArgs(arguments);
            expect(kidneyArgs, ['--apply', '--verbose']);
          });
          test('- /kidney', () async {
            arguments = ['/x/y/kidney', ...arguments];
            final (_, kidneyArgs, _, _, _) = await kidney.readArgs(arguments);
            expect(kidneyArgs, ['--apply', '--verbose']);
          });
        });

        group('- interpreates - a as --apply and -v as --verbose', () {
          test('- when they are the first arguments', () async {
            final (_, kidneyArgs, _, verbose, apply) = await kidney.readArgs([
              '-a',
              '-v',
              'x',
              'y',
            ]);
            expect(kidneyArgs, ['--apply', '--verbose']);
            expect(verbose, true);
            expect(apply, true);
          });

          test('- when they are written together', () async {
            final (_, kidneyArgs, _, verbose, apply) = await kidney.readArgs([
              '-av',
              'x',
              'y',
            ]);
            expect(kidneyArgs, ['--apply', '--verbose']);
            expect(verbose, true);
            expect(apply, true);
          });
        });
      });
    });
  });
}
