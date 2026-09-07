import 'package:bird_sort/bird_sort.dart';
import 'package:test/test.dart';

void main() {
  test('tierFor picks the right table row', () {
    expect(tierFor(0).params.colours, 3);
    expect(tierFor(9).params.colours, 3);
    expect(tierFor(10).params.colours, 4);
    expect(tierFor(29).params.colours, 5);
    expect(tierFor(30).params.removeBranchOnComplete, isTrue);
    expect(tierFor(30).params.emptyBranches, 1);
    expect(tierFor(500).params.colours, 6);
  });

  test('generated deal shape: full colour branches + empties, sides alternate',
      () {
    final level = levelFor(0);
    final p = tierFor(0).params;
    expect(level.branches, hasLength(p.colours + p.emptyBranches));
    final nonEmpty = level.branches.where((b) => b.birds.isNotEmpty);
    expect(nonEmpty, hasLength(p.colours));
    for (final b in nonEmpty) {
      expect(b.birds, hasLength(p.capacity));
    }
    // Exactly capacity birds of each colour.
    final counts = <int, int>{};
    for (final b in level.branches) {
      for (final c in b.birds) {
        counts[c] = (counts[c] ?? 0) + 1;
      }
    }
    expect(counts.values, everyElement(p.capacity));
    for (var i = 0; i < level.branches.length; i++) {
      expect(level.branches[i].side, i.isEven ? Side.left : Side.right);
    }
  });

  test('same index → identical level across two runs', () {
    for (final i in [0, 5, 17, 42, 100, 199]) {
      expect(levelFor(i), equals(levelFor(i)), reason: 'level $i');
    }
  });

  test('no dealt branch is complete at level start', () {
    for (var i = 0; i < 50; i++) {
      final level = levelFor(i);
      for (final b in level.branches) {
        expect(isComplete(b, level.capacity), isFalse,
            reason: 'level $i dealt a pre-completed branch');
      }
    }
  });

  test(
      'first 200 levels are all solvable within budget; '
      'report rejection rates and node counts per tier', () {
    final byTier = <int, List<GenerationResult>>{};
    for (var i = 0; i < 200; i++) {
      final gen = generationFor(i);
      final check = solveLevel(gen.level);
      expect(check.solvable, isTrue, reason: 'level $i not solvable');
      expect(check.budgetExceeded, isFalse, reason: 'level $i blew budget');
      expect(gen.optimalMoves,
          greaterThanOrEqualTo(tierFor(i).params.minOptimalMoves),
          reason: 'level $i easier than tier minimum');
      byTier.putIfAbsent(tierFor(i).firstLevel, () => []).add(gen);
    }

    // Tuning report (the brief asks for this — read it when editing tiers).
    print('tier      levels  reject-rate  avg-nodes  max-nodes  avg-optimal');
    for (final e in byTier.entries) {
      final g = e.value;
      final tier = tierFor(e.key).params;
      final label =
          '${tier.colours}c/${tier.emptyBranches}e${tier.removeBranchOnComplete ? '/rm' : ''}';
      final rejections = g.fold(0, (a, r) => a + r.rejections);
      final deals = rejections + g.length;
      final avgNodes =
          (g.fold(0, (a, r) => a + r.nodesExpanded) / g.length).round();
      final maxNodes = g.fold(0, (a, r) => a > r.nodesExpanded ? a : r.nodesExpanded);
      final avgOpt =
          (g.fold(0, (a, r) => a + r.optimalMoves) / g.length).toStringAsFixed(1);
      final rate = (100 * rejections / deals).toStringAsFixed(1);
      print('${label.padRight(10)}${'${g.length}'.padRight(8)}'
          '${'$rate%'.padRight(13)}${'$avgNodes'.padRight(11)}'
          '${'$maxNodes'.padRight(11)}$avgOpt');
    }
  }, timeout: const Timeout(Duration(minutes: 5)));
}
