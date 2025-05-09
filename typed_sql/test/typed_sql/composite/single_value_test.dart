// Copyright 2025 Google LLC
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     https://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

import 'package:typed_sql/typed_sql.dart';

import '../testrunner.dart';

final epoch = DateTime.fromMicrosecondsSinceEpoch(0).toUtc();
final yesterday = DateTime.parse('2025-03-09T11:34:36.000000Z');
final today = DateTime.parse('2025-03-10T11:34:36.000000Z');
final tomorrow = DateTime.parse('2025-03-11T11:34:36.000000Z');

/// Test cases with a single value in each column.
final _cases = [
  // Test with single character strings
  (
    nameA: 'A, B, C',
    nameB: 'A, B, D',
    valuesA: [toExpr('A'), toExpr('B'), toExpr('C')],
    valuesB: [toExpr('A'), toExpr('B'), toExpr('D')],
    union: {'A', 'B', 'C', 'D'},
    unionAll: ['A', 'B', 'C', 'A', 'B', 'D'],
    intersect: {'A', 'B'},
    except: ['C'],
  ),
  // Test with simple numbers
  (
    nameA: '1, 2, 3',
    nameB: '1, 2, 4',
    valuesA: [toExpr(1), toExpr(2), toExpr(3)],
    valuesB: [toExpr(1), toExpr(2), toExpr(4)],
    union: {1, 2, 3, 4},
    unionAll: [1, 2, 3, 1, 2, 4],
    intersect: {1, 2},
    except: [3],
  ),
  // Test with double
  (
    nameA: '3.14, 2.71, 1.61',
    nameB: '3.14, 2.71, 1.41',
    valuesA: [toExpr(3.14), toExpr(2.71), toExpr(1.61)],
    valuesB: [toExpr(3.14), toExpr(2.71), toExpr(1.41)],
    union: {3.14, 2.71, 1.61, 1.41},
    unionAll: [3.14, 2.71, 1.61, 3.14, 2.71, 1.41],
    intersect: {3.14, 2.71},
    except: [1.61],
  ),
  // Test with longer strings
  (
    nameA: 'hello, world, dart',
    nameB: 'hello, world, flutter',
    valuesA: [toExpr('hello'), toExpr('world'), toExpr('dart')],
    valuesB: [toExpr('hello'), toExpr('world'), toExpr('flutter')],
    union: {'hello', 'world', 'dart', 'flutter'},
    unionAll: ['hello', 'world', 'dart', 'hello', 'world', 'flutter'],
    intersect: {'hello', 'world'},
    except: ['dart'],
  ),
  // Test with DateTime
  (
    nameA: 'epoch, yesterday, today',
    nameB: 'epoch, yesterday, tomorrow',
    valuesA: [toExpr(epoch), toExpr(yesterday), toExpr(today)],
    valuesB: [toExpr(epoch), toExpr(yesterday), toExpr(tomorrow)],
    union: {epoch, yesterday, today, tomorrow},
    unionAll: [epoch, yesterday, today, epoch, yesterday, tomorrow],
    intersect: {epoch, yesterday},
    except: [today],
  ),
  // Test with bool
  (
    nameA: 'true, false, true',
    nameB: 'true, false, false',
    valuesA: [toExpr(true), toExpr(false), toExpr(true)],
    valuesB: [toExpr(true), toExpr(false), toExpr(false)],
    union: {true, false},
    unionAll: [true, false, true, true, false, false],
    intersect: {true, false},
    except: <bool>[],
  ),
];

void main() {
  final r = TestRunner<Schema>(resetDatabaseForEachTest: false);

  for (final c in _cases) {
    r.addTest('(${c.nameA}).union(${c.nameB})', (db) async {
      final qA = c.valuesA
          .map((v) => db.select((v,)).asQuery)
          .reduce((q1, q2) => q1.unionAll(q2));

      final qB = c.valuesB
          .map((v) => db.select((v,)).asQuery)
          .reduce((q1, q2) => q1.unionAll(q2));

      final result = await qA.union(qB).fetch();
      check(result).unorderedEquals(c.union);
    });

    r.addTest('(${c.nameA}).unionAll(${c.nameB})', (db) async {
      final qA = c.valuesA
          .map((v) => db.select((v,)).asQuery)
          .reduce((q1, q2) => q1.unionAll(q2));

      final qB = c.valuesB
          .map((v) => db.select((v,)).asQuery)
          .reduce((q1, q2) => q1.unionAll(q2));

      final result = await qA.unionAll(qB).fetch();
      check(result).deepEquals(c.unionAll);
    });

    r.addTest('(${c.nameA}).intersect(${c.nameB})', (db) async {
      final qA = c.valuesA
          .map((v) => db.select((v,)).asQuery)
          .reduce((q1, q2) => q1.unionAll(q2));

      final qB = c.valuesB
          .map((v) => db.select((v,)).asQuery)
          .reduce((q1, q2) => q1.unionAll(q2));

      final result = await qA.intersect(qB).fetch();
      check(result).unorderedEquals(c.intersect);
    });

    r.addTest('(${c.nameA}).except(${c.nameB})', (db) async {
      final qA = c.valuesA
          .map((v) => db.select((v,)).asQuery)
          .reduce((q1, q2) => q1.unionAll(q2));

      final qB = c.valuesB
          .map((v) => db.select((v,)).asQuery)
          .reduce((q1, q2) => q1.unionAll(q2));

      final result = await qA.except(qB).fetch();
      check(result).deepEquals(c.except);
    });
  }

  r.run();
}
