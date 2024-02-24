// @license
// Copyright (c) 2019 - 2024 Dr. Gabriel Gatzsche. All Rights Reserved.
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

import 'dart:async';

void capturePrint({
  required void Function(String msg) log,
  required void Function() code,
}) {
  // Capture the print statements
  var spec = ZoneSpecification(
    print: (_, __, ___, String msg) {
      log(msg);
    },
  );
  Zone.current.fork(specification: spec).run(code);
}
