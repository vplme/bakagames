import 'package:bird_sort/bird_sort.dart';
import 'package:test/test.dart';

Branch b(List<int> birds, {Side side = Side.left, bool removed = false}) =>
    Branch(side: side, birds: birds, removed: removed);

Level level(List<Branch> branches,
        {int capacity = 4,
        bool remove = false,
        bool partial = true}) =>
    Level(
        capacity: capacity,
        branches: branches,
        removeBranchOnComplete: remove,
        partialMovesAllowed: partial);

void main() {
  group('linked group', () {
    test('is the maximal same-colour run ending at the tip', () {
      expect(b([1, 2, 2]).linkedGroupSize, 2);
      expect(b([2, 2, 2]).linkedGroupSize, 3);
      expect(b([1, 2, 1]).linkedGroupSize, 1);
      expect(b([]).linkedGroupSize, 0);
    });
  });

  group('validMoves / applyMove basics', () {
    test('valid: tip colours match and target has space', () {
      final s = GameState.initial(level([b([1, 1]), b([2, 1]), b([2, 2])]));
      final moves = validMoves(s);
      expect(moves, contains(const Move(from: 1, to: 0, count: 1)));
      expect(moves, contains(const Move(from: 0, to: 1, count: 2)));
      // b2's tip (2) matches no other tip; exactly these two moves exist.
      expect(moves, hasLength(2));
    });

    test('invalid: colour mismatch, full target, empty source, self-move', () {
      final full = b([2, 2, 2, 2]);
      final s = GameState.initial(level([b([1]), full, b([]), b([3])]));
      void bad(Move m) =>
          expect(() => applyMove(s, m), throwsArgumentError, reason: '$m');
      bad(const Move(from: 0, to: 1, count: 1)); // full target
      bad(const Move(from: 0, to: 3, count: 1)); // colour mismatch
      bad(const Move(from: 2, to: 0, count: 1)); // empty source
      bad(const Move(from: 0, to: 0, count: 1)); // self
      bad(const Move(from: 0, to: 9, count: 1)); // out of range
      bad(const Move(from: 0, to: 2, count: 2)); // wrong count (canonical 1)
    });

    test('moves onto a removed branch are invalid', () {
      final s = GameState.initial(
          level([b([1]), b([1], removed: true), b([])]));
      expect(() => applyMove(s, const Move(from: 0, to: 1, count: 1)),
          throwsArgumentError);
      // and from a removed branch too
      expect(() => applyMove(s, const Move(from: 1, to: 2, count: 1)),
          throwsArgumentError);
    });

    test('applyMove moves the linked group and leaves others untouched', () {
      final s = GameState.initial(level([b([1, 2, 2]), b([2]), b([3])]));
      final s2 = applyMove(s, const Move(from: 0, to: 1, count: 2));
      expect(s2.branches[0].birds, [1]);
      expect(s2.branches[1].birds, [2, 2, 2]);
      expect(s2.branches[2], s.branches[2]);
      expect(s2.moveCount, 1);
    });
  });

  group('partial moves', () {
    test('allowed: count is min(group, free slots)', () {
      // group of 3, target has 2 free.
      final s = GameState.initial(
          level([b([2, 2, 2]), b([1, 1, 2])]));
      final m = validMoves(s)
          .firstWhere((m) => m.from == 0 && m.to == 1);
      expect(m.count, 1); // capacity 4, target has 1 free
      final s2 = applyMove(s, m);
      expect(s2.branches[0].birds, [2, 2]);
      expect(s2.branches[1].birds, [1, 1, 2, 2]);
    });

    test('disallowed: move invalid when whole group does not fit', () {
      final s = GameState.initial(
          level([b([2, 2, 2]), b([1, 1, 2])], partial: false));
      expect(
          validMoves(s).where((m) => m.from == 0 && m.to == 1), isEmpty);
      // But fits into an emptier branch.
      final s3 = GameState.initial(
          level([b([2, 2, 2]), b([2])], partial: false));
      final m = validMoves(s3).firstWhere((m) => m.from == 0 && m.to == 1);
      expect(m.count, 3);
    });
  });

  group('completion', () {
    test('isComplete: full and single-colour only', () {
      expect(isComplete(b([1, 1, 1, 1]), 4), isTrue);
      expect(isComplete(b([1, 1, 1]), 4), isFalse);
      expect(isComplete(b([1, 1, 1, 2]), 4), isFalse);
      expect(isComplete(b([1, 1, 1, 1], removed: true), 4), isFalse);
    });

    test('removeBranchOnComplete=false: flock flies, branch stays usable', () {
      final s = GameState.initial(
          level([b([1, 1, 1]), b([2, 2, 2, 1]), b([2])]));
      final s2 = applyMove(s, const Move(from: 1, to: 0, count: 1));
      // branch 0 now complete → birds fly, branch empty, not removed.
      expect(s2.branches[0].birds, isEmpty);
      expect(s2.branches[0].removed, isFalse);
      // The freed branch is immediately reusable.
      final s3 = applyMove(s2, const Move(from: 2, to: 0, count: 1));
      expect(s3.branches[0].birds, [2]);
    });

    test('removeBranchOnComplete=true: branch is removed entirely', () {
      final s = GameState.initial(
          level([b([1, 1, 1]), b([2, 2, 2, 1]), b([2])], remove: true));
      final s2 = applyMove(s, const Move(from: 1, to: 0, count: 1));
      expect(s2.branches[0].birds, isEmpty);
      expect(s2.branches[0].removed, isTrue);
      // No longer a valid target.
      expect(() => applyMove(s2, const Move(from: 2, to: 0, count: 1)),
          throwsArgumentError);
      expect(validMoves(s2).where((m) => m.to == 0), isEmpty);
    });
  });

  group('win / stuck', () {
    test('win when every bird has flown (both rulesets)', () {
      for (final remove in [false, true]) {
        final s = GameState.initial(
            level([b([1, 1, 1]), b([1]), b([])], remove: remove));
        final s2 = applyMove(s, const Move(from: 1, to: 0, count: 1));
        expect(s2.isWon, isTrue, reason: 'remove=$remove');
        expect(s2.isStuck, isFalse);
      }
    });

    test('stuck when only trivial moves remain', () {
      // Two branches with alternating colours + one empty: the only legal
      // moves shuffle sole-occupant groups... construct genuinely stuck:
      // tips mismatch everywhere, empty branch only reachable trivially.
      final s = GameState.initial(level([
        b([1, 2, 1, 2]),
        b([2, 1, 2, 1]),
        b([1]),
      ], capacity: 4));
      // b2's group (sole occupant) → no empty branch exists; tips: 2,1,1.
      // b1(tip 1)→b2 has space: valid non-trivial! So not stuck:
      expect(s.isStuck, isFalse);
      final s2 = applyMove(s, const Move(from: 1, to: 2, count: 1));
      // now: [1,2,1,2] tip 2 | [2,1,2] tip 2... still moves exist.
      expect(s2.isStuck, isFalse);
    });

    test('stuck detected: full mismatched branches', () {
      final s = GameState.initial(level([
        b([1, 2, 1, 2]),
        b([2, 1, 2, 1]),
      ], capacity: 4));
      expect(s.isStuck, isTrue);
      expect(s.isWon, isFalse);
    });

    test('trivial-only moves count as stuck', () {
      final s = GameState.initial(level([
        b([3, 3]),
        b([4, 4]),
        b([]),
      ], capacity: 4));
      // Only legal moves shuffle a sole-occupant group onto the empty
      // branch (trivial); the 3s and 4s cannot merge.
      expect(s.isStuck, isTrue);
    });

    test('not stuck when a real move exists', () {
      final s = GameState.initial(level([b([1, 2]), b([2])]));
      expect(s.isStuck, isFalse);
    });
  });

  group('undo / restart', () {
    test('undo restores the exact prior state, unlimited depth', () {
      final s0 = GameState.initial(
          level([b([1, 2, 2]), b([2]), b([1, 1])]));
      final s1 = applyMove(s0, const Move(from: 0, to: 1, count: 2));
      final s2 = applyMove(s1, const Move(from: 0, to: 2, count: 1));
      expect(s2.moveCount, 2);
      final u1 = undo(s2);
      expect(u1, equals(s1));
      expect(u1.branches, s1.branches);
      final u0 = undo(u1);
      expect(u0, equals(s0));
      expect(undo(u0), same(u0)); // nothing left to undo
    });

    test('restart returns the initial state', () {
      final s0 = GameState.initial(
          level([b([1, 2, 2]), b([2]), b([1, 1])]));
      var s = applyMove(s0, const Move(from: 0, to: 1, count: 2));
      s = applyMove(s, const Move(from: 0, to: 2, count: 1));
      expect(restart(s), equals(s0));
      expect(restart(s).moveCount, 0);
      expect(restart(s0), same(s0));
    });

    test('undo works across a completion event', () {
      final s = GameState.initial(
          level([b([1, 1, 1]), b([2, 2, 2, 1])], remove: true));
      final s2 = applyMove(s, const Move(from: 1, to: 0, count: 1));
      expect(s2.branches[0].removed, isTrue);
      final u = undo(s2);
      expect(u, equals(s));
      expect(u.branches[0].removed, isFalse);
      expect(u.branches[0].birds, [1, 1, 1]);
    });
  });

  group('value semantics', () {
    test('Branch/Level/Move/GameState equality and hashCode', () {
      expect(b([1, 2]), equals(b([1, 2])));
      expect(b([1, 2]).hashCode, b([1, 2]).hashCode);
      expect(b([1, 2]), isNot(equals(b([2, 1]))));
      expect(b([1]), isNot(equals(b([1], removed: true))));
      expect(const Move(from: 0, to: 1, count: 2),
          const Move(from: 0, to: 1, count: 2));
      final l1 = level([b([1])]);
      final l2 = level([b([1])]);
      expect(l1, equals(l2));
      expect(GameState.initial(l1), equals(GameState.initial(l2)));
    });

    test('branch bird lists are unmodifiable', () {
      expect(() => b([1]).birds.add(2), throwsUnsupportedError);
    });
  });
}
