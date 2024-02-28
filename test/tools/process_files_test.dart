// @license
// Copyright (c) 2019 - 2024 Dr. Gabriel Gatzsche. All Rights Reserved.
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

import 'dart:io';

import 'package:gg_kidney/src/tools/process_files.dart';
import 'package:path/path.dart';
import 'package:test/test.dart';

import '../test_helpers/create_sample_repos.dart';

void main() {
  group('ProcessFiles', () {
    test('should process a files matching the reference file', () async {
      final sampleRepos = createSampleRepos();
      final referenceFile = File(join(sampleRepos[0].path, 'pubspec.yaml'));

      final calls = <(bool, File, File, Directory)>[];

      // Is tested with copy_files.dart
      await processFiles(
        referenceFile: referenceFile,
        dryRun: true,
        process: ({
          required dryRun,
          required fileToBeProcessed,
          required referenceFile,
          required projectRoot,
        }) async {
          // Create target directory
          calls.add((dryRun, fileToBeProcessed, referenceFile, projectRoot));
        },
      );

      expect(calls.length, 3);

      // Expect dir0
      expect(calls[0].$1, true);
      expect(calls[0].$2.path, contains('dir0'));
      expect(calls[0].$3, referenceFile);
      expect(calls[0].$4.path, endsWith('dir0'));

      // Expect dir1
      expect(calls[1].$1, true);
      expect(calls[1].$2.path, contains('dir1'));
      expect(calls[1].$3, referenceFile);
      expect(calls[1].$4.path, endsWith('dir1'));

      // Expect dir2
      expect(calls[2].$1, true);
      expect(calls[2].$2.path, contains('dir2'));
      expect(calls[2].$3, referenceFile);
      expect(calls[2].$4.path, endsWith('dir2'));
    });

    // .........................................................................
    test('should throw when reference file does not exist', () async {
      await expectLater(
        () => // Is tested with copy_files.dart
            processFiles(
          referenceFile: File('/not/existing/file.yaml'),
          dryRun: true,
          process: ({
            required dryRun,
            required fileToBeProcessed,
            required referenceFile,
            required projectRoot,
          }) async {},
        ),
        throwsA(
          isA<ArgumentError>().having(
            (e) => e.message,
            'message',
            'The file /not/existing/file.yaml does not exist.',
          ),
        ),
      );
    });

    // .........................................................................
    test('should throw when reference file is not part of a dart project',
        () async {
      final tmp = Directory.systemTemp.createTempSync();
      final file = File(join(tmp.path, 'xyz'));
      file.writeAsStringSync('name: test');

      await expectLater(
        () => // Is tested with copy_files.dart
            processFiles(
          referenceFile: file,
          dryRun: true,
          process: ({
            required dryRun,
            required fileToBeProcessed,
            required referenceFile,
            required projectRoot,
          }) async {},
        ),
        throwsA(
          isA<ArgumentError>().having(
            (e) => e.message,
            'message',
            'The file xyz is not part of a dart or flutter project.',
          ),
        ),
      );
    });
  });
}
