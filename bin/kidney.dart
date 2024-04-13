#!/usr/bin/env dart
// @license
// Copyright (c) 2019 - 2024 Dr. Gabriel Gatzsche. All Rights Reserved.
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

import 'package:kidney/kidney.dart';
import 'package:gg_log/gg_log.dart';

// .............................................................................
Future<void> runKidney({
  required List<String> args,
  required GgLog ggLog,
}) async {
  try {
    await Kidney(ggLog: ggLog).run(args);
  } catch (e) {
    ggLog(e.toString());
  }
}

// .............................................................................
// coverage:ignore-start
Future<void> main(List<String> args) => runKidney(args: args, ggLog: print);
// coverage:ignore-end
