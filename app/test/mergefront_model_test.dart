import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:baka_games/games/mergefront/model.dart';

Run fresh([int level = 0]) => Run(Level.all[level], Profile().loadout);
void advance(Run run, double seconds) {
  for (var i = 0; i < (seconds * 60).ceil(); i++) {
    run.step(1 / 60);
  }
}

void main() {
  Run shooterScenario(int level) {
    final r = fresh(level);
    r.gates.clear();
    for (final soldier in r.squad) {
      soldier.cooldown = 100;
    }
    r.spawn(EnemyKind.ranged, .5);
    r.enemies.first
      ..y = .2
      ..clock = 2.99
      ..hp = 10000;
    return r;
  }

  test('mission six shooters lock aim and launch dodgeable bullets', () {
    for (final dodge in [false, true]) {
      final r = shooterScenario(5);
      final hp = r.strength;
      advance(r, .05);
      expect(r.enemies.first.aiming, isTrue);
      expect(r.enemies.first.aimX, .5);
      if (dodge) r.steer(.78);
      advance(r, .8);
      expect(r.enemyBullets.where((b) => b.active), hasLength(1));
      expect(r.warnings, isEmpty);
      advance(r, 1.3);
      expect(r.strength, closeTo(hp - (dodge ? 0 : 22), .001));
      advance(r, 1);
      expect(r.enemyBullets.where((b) => b.active), isEmpty);
    }
  });

  test('early ranged enemies keep lane attacks and killing cancels windup', () {
    final early = shooterScenario(4);
    advance(early, 1.1);
    expect(early.enemyBullets.any((b) => b.active), isFalse);
    expect(early.warnings, isNotEmpty);
    final later = shooterScenario(5);
    advance(later, .05);
    later.enemies.first.active = false;
    advance(later, 1);
    expect(later.enemyBullets.any((b) => b.active), isFalse);
  });

  test('enemy bullets use troop armor and cannot damage twice', () {
    final r = shooterScenario(5)..squad.last.armored = true;
    final hp = r.strength;
    advance(r, 2.1);
    expect(r.strength, closeTo(hp - 22 * .65, .001));
    advance(r, .3);
    expect(r.strength, closeTo(hp - 22 * .65, .001));
  });

  test('lane impact reports shield absorption and troop health separately', () {
    final r = fresh()..shield = 24;
    r.warnings.add(Warning(r.x, .02));
    advance(r, .05);
    expect(r.laneStrikes.single.shieldLost, 24);
    expect(r.laneStrikes.single.hpLost, 36);
    expect(r.squad.last.hp, 4);
    expect(r.damageNotice, contains('SQUAD −36 HP'));
    expect(r.damageNotice, contains('shield −24'));
  });

  test('armor pickups equip one new troop and recruits start unarmored', () {
    final r = fresh();
    r.apply(const Gate(GateKind.armor, 1));
    expect(r.squad.map((s) => s.armored), [true, false, false]);
    r.apply(const Gate(GateKind.armor, 1));
    expect(r.squad.map((s) => s.armored), [true, true, false]);
    r.apply(const Gate(GateKind.armor, 1));
    expect(r.fullyArmored, isTrue);
    r.apply(const Gate(GateKind.armor, 1));
    expect(r.armoredCount, 3);
    r.recruit(1);
    expect(r.squad.last.armored, isFalse);
    expect(r.fullyArmored, isFalse);
    r.apply(const Gate(GateKind.armor, 1));
    expect(r.armoredCount, 4);
  });

  test('armor reduces only its troop damage including lethal spillover', () {
    final r = fresh();
    r.apply(const Gate(GateKind.armor, 1));
    r.hurt(10);
    expect(r.squad.last.hp, 30); // Unarmored troop takes full damage.
    r.squad.last.armored = true;
    r.hurt(30 / .65 + 10);
    expect(r.squad.length, 2);
    expect(r.squad.last.hp, closeTo(30, .001));
    expect(r.armoredCount, 1); // Armor stays with the surviving first troop.
  });

  test('repeat armor gates remain available until all troops are armored', () {
    final r = fresh()..apply(const Gate(GateKind.armor, 1));
    r.gates.clear();
    r.gates.add(
      GatePair(
        7,
        const Gate(GateKind.armor, 1),
        const Gate(GateKind.damage, 30),
      ),
    );
    r.step(1 / 60);
    expect(r.gates.single.left.kind, GateKind.armor);
  });

  test(
    'attack lanes resolve once and retain hit or dodge feedback briefly',
    () {
      for (final inLane in [true, false]) {
        final r = fresh()..squad.last.armored = true;
        final hp = r.strength;
        r.warnings.add(Warning(inLane ? .5 : .15, .02, .1));
        advance(r, .05);
        expect(r.warnings, isEmpty);
        expect(r.laneStrikes.single.hit, inLane);
        expect(r.strength, closeTo(hp - (inLane ? 60 * .65 : 0), .001));
        advance(r, .7);
        expect(r.laneStrikes, isEmpty);
        expect(r.strength, closeTo(hp - (inLane ? 60 * .65 : 0), .001));
      }
    },
  );

  test('escaped enemies damage the base once and bypass squad defenses', () {
    final r = fresh()
      ..squad.last.armored = true
      ..shield = 100;
    final hp = r.strength;
    r.spawn(EnemyKind.rusher, .88);
    r.enemies.first.y = .80;
    advance(r, .1);
    expect(r.baseHealth, 95);
    expect(r.escaped, 1);
    expect(r.strength, hp);
    expect(r.shield, 100);
    expect(r.damageNotice, contains('BASE HIT −5'));
    advance(r, .1);
    expect(r.baseHealth, 95);
  });
  test('obstacles and supplies do not damage the base when passed', () {
    final r = fresh();
    for (final kind in [
      EnemyKind.crate,
      EnemyKind.barrel,
      EnemyKind.barricade,
      EnemyKind.pylon,
    ]) {
      r.spawn(kind, .88);
    }
    for (final e in r.enemies.where((e) => e.active)) {
      e.y = .80;
    }
    advance(r, .1);
    expect(r.baseHealth, Run.maxBaseHealth);
    expect(r.escaped, 0);
  });
  test('base destruction ends the run even with a healthy squad', () {
    final r = fresh()..baseHealth = 10;
    r.spawn(EnemyKind.heavy, .88);
    r.enemies.first.y = .80;
    advance(r, .1);
    expect(r.baseHealth, 0);
    expect(r.finished, isTrue);
    expect(r.won, isFalse);
    expect(r.strength, greaterThan(0));
    expect(r.defeatReason, contains('Base overrun'));
    r.breach(EnemyKind.rusher);
    expect(r.escaped, 1);
    expect(fresh().baseHealth, Run.maxBaseHealth);
  });
  test('squad collisions report shield, health and unit loss separately', () {
    final r = fresh()..shield = 8;
    r.spawn(EnemyKind.heavy, .5);
    r.enemies.first.y = .80;
    advance(r, .1);
    expect(r.baseHealth, Run.maxBaseHealth);
    expect(r.damageNotice, contains('SQUAD −32 HP'));
    expect(r.damageNotice, contains('shield −8'));
    r.hurt(10);
    expect(r.damageNotice, contains('1 units lost'));
    advance(r, 2.6);
    expect(r.damageNoticeRemaining, 0);
  });
  test('additive then multiplicative gates and modifier ordering', () {
    final r = fresh();
    r.apply(const Gate(GateKind.recruits, 8));
    expect(r.squad.length, 11);
    r.apply(const Gate(GateKind.multiply, 2));
    expect(r.squad.length, 22);
    r.apply(const Gate(GateKind.damage, 25));
    r.apply(const Gate(GateKind.sacrifice, 6));
    expect(r.squad.length, 16);
    expect(r.damage, 2.5);
    r.apply(const Gate(GateKind.rate, 40));
    r.apply(const Gate(GateKind.elite, 1));
    expect(r.rate, closeTo(1.05, .0001));
    expect(r.squad.last.tier, 4);
  });
  test('capacity is bounded and sacrifice leaves one combat unit', () {
    final r = fresh();
    r.recruit(10000);
    expect(r.squad.length, Run.capacity);
    r.apply(const Gate(GateKind.elite, 1));
    expect(r.squad.length, Run.capacity);
    r.apply(const Gate(GateKind.sacrifice, 100));
    expect(r.squad.length, 1);
  });
  test('gate crossing selects one side once', () {
    final r = fresh()..steer(.75);
    advance(r, 4.1);
    expect(r.gateCount, 1);
    expect(r.squad.length, 6);
    r.steer(.12);
    advance(r, 1);
    expect(r.gateCount, 1);
    expect(r.squad.length, 6);
  });
  test('center divider grants neither gate; unattended play is not a win', () {
    final r = fresh();
    advance(r, 4.1);
    expect(r.gateCount, 0);
    expect(r.squad.length, 3);
    advance(r, 180);
    expect(r.won, isFalse);
  });
  test('full healthy squads get protection versus power at capped gates', () {
    final r = fresh()..recruit(21);
    advance(r, .1);
    expect(r.gates.first.left.kind, GateKind.armor);
    expect(r.gates.first.right.kind, GateKind.damage);
  });
  test('healing retains permanent maximum health boosts', () {
    final r = Run(Level.all.first, Profile().loadout, healthBonus: 2);
    final maximum = r.strength;
    r.apply(const Gate(GateKind.heal, 35));
    expect(r.strength, maximum);
    r.hurt(10);
    r.apply(const Gate(GateKind.heal, 35));
    expect(r.strength, maximum);
  });
  test('rapid fire pays its disclosed damage cost', () {
    final r = fresh();
    r.apply(const Gate(GateKind.rate, 40));
    expect(r.rate, closeTo(1.4, .0001));
    expect(r.damage, closeTo(.85, .0001));
    expect(const Gate(GateKind.rate, 40).caption, contains('−15%'));
  });
  test('two owned abilities still offer distinct outcomes', () {
    final r = fresh()
      ..spread = true
      ..pierce = true;
    r.gates
      ..clear()
      ..add(
        GatePair(
          8,
          const Gate(GateKind.spread, 1),
          const Gate(GateKind.pierce, 1),
        ),
      );
    advance(r, 1.1);
    expect(r.gates.single.left.kind, GateKind.damage);
    expect(r.gates.single.right.kind, GateKind.elite);
  });
  test('owned abilities are replaced before preview and remain locked', () {
    final r = fresh()..spread = true;
    r.gates
      ..clear()
      ..add(
        GatePair(
          8,
          const Gate(GateKind.spread, 1),
          const Gate(GateKind.pierce, 1),
        ),
      );
    advance(r, 1.1);
    expect(r.gates.single.left.kind, GateKind.damage);
    r.pierce = true;
    advance(r, 1);
    expect(r.gates.single.right.kind, GateKind.pierce);
  });
  test(
    'opening encounter contains a group and bosses receive reinforcements',
    () {
      final r = fresh();
      advance(r, 5.1);
      expect(r.enemies.where((e) => e.active).length, greaterThanOrEqualTo(2));
      final bossRun = fresh()..time = Level.all.first.bossAt;
      advance(bossRun, 6);
      expect(bossRun.boss, isNotNull);
      expect(
        bossRun.enemies.where((e) => e.active && e.kind != EnemyKind.boss),
        isNotEmpty,
      );
    },
  );
  test('only identical role and tier merge, with six rank cap', () {
    final p = Profile();
    expect(p.merge(0, 0), isFalse);
    expect(p.merge(0, 2), isFalse);
    expect(p.merge(0, 1), isTrue);
    expect(p.cards.last.tier, 2);
    expect(p.equipped.contains(p.cards.last.id), isTrue);
    expect(p.cards.length, 4);
    expect(
      const UnitCard(
        100,
        Role.drone,
        6,
      ).matches(const UnitCard(101, Role.drone, 6)),
      isFalse,
    );
    expect(
      const UnitCard(
        100,
        Role.drone,
        2,
      ).matches(const UnitCard(101, Role.drone, 1)),
      isFalse,
    );
  });
  test('equipment capacity, milestone slots and minimum loadout', () {
    final p = Profile();
    expect(p.equip(4), isFalse);
    expect(p.equip(0), isTrue);
    expect(p.equip(2), isTrue);
    expect(p.equip(3), isFalse);
    p.completed.addAll([0, 1, 2]);
    expect(p.slots, 4);
  });
  test('shields resist frontal damage; drone and piercing bypass', () {
    final r = fresh();
    r.spawn(EnemyKind.shield, .5);
    final e = r.enemies.first;
    r.hit(e, 10, Role.rifle);
    expect(e.hp, e.maxHp - 3);
    r.hit(e, 10, Role.drone);
    expect(e.hp, e.maxHp - 13);
    r.pierce = true;
    r.hit(e, 10, Role.rifle);
    expect(e.hp, e.maxHp - 23);
  });
  test(
    'role ranges, lateral targeting, heavy knockback and support shields',
    () {
      final r = fresh();
      r.spawn(EnemyKind.heavy, .88);
      final e = r.enemies.first..y = .3;
      expect(r.targetFor(Soldier(Role.rifle, 1, 40)), isNull);
      expect(r.targetFor(Soldier(Role.drone, 1, 40)), same(e));
      e.x = .5;
      expect(r.targetFor(Soldier(Role.scatter, 1, 40)), isNull);
      r.hit(e, 1, Role.heavy);
      expect(e.y, lessThan(.3));
      r.squad.add(Soldier(Role.support, 1, 40));
      advance(r, .1);
      expect(r.shield, greaterThan(0));
      final hp = r.strength;
      r.hurt(10);
      expect(r.strength, hp);
    },
  );
  test('armor reduces damage; no units ends the run', () {
    final r = fresh()..squad.last.armored = true;
    final hp = r.strength;
    r.hurt(10);
    expect(r.strength, hp - 6.5);
    r.hurt(10000);
    expect(r.finished, isTrue);
    expect(r.won, isFalse);
  });
  test(
    'rewards are idempotent, milestones unique, losses still earn a card',
    () {
      final p = Profile();
      final r = fresh()
        ..kills = 5
        ..salvage = 10;
      r.end(true);
      expect(p.reward(r), 112);
      expect(p.reward(r), 0);
      expect(p.completed.length, 1);
      final replay = fresh()
        ..kills = 5
        ..salvage = 10;
      replay.end(true);
      expect(p.reward(replay), 77);
      expect(p.completed.length, 1);
      final loss = fresh()..end(false);
      final count = p.cards.length;
      expect(p.reward(loss), 12);
      expect(p.cards.length, count + 1);
    },
  );
  test(
    'saved inventory, settings, best results and upgrades restore exactly',
    () {
      final p = Profile()..coins = 300;
      p.merge(0, 1);
      p.upgrade(true);
      p.upgrade(false);
      p.completed.add(0);
      p.best[0] = 12;
      p.music = false;
      final restored = Profile.fromJson(
        jsonDecode(jsonEncode(p.toJson())) as Map<String, dynamic>,
      );
      expect(restored.toJson(), p.toJson());
      expect(restored.damageBonus, p.damageBonus);
      expect(() => Profile.fromJson({'version': 99}), throwsFormatException);
    },
  );
  test('twenty distinct seeds reproduce identical waves and outcomes', () {
    expect(Level.all.map((l) => l.seed).toSet().length, 20);
    final a = fresh(4), b = fresh(4);
    advance(a, 45);
    advance(b, 45);
    expect(a.kills, b.kills);
    expect(a.strength, b.strength);
    expect(
      a.enemies.map((e) => [e.active, e.kind, e.x, e.y, e.hp]),
      b.enemies.map((e) => [e.active, e.kind, e.x, e.y, e.hp]),
    );
  });
  test('first five coasts can be won by steering a starter squad', () {
    for (var level = 0; level < 5; level++) {
      final r = fresh(level);
      for (var tick = 0; tick < 180 * 60 && !r.finished; tick++) {
        final gate = r.approaching;
        if (gate != null && gate.at - r.time < 1) {
          // Defend lanes until the last second, then commit to a gate.
          r.steer(
            gate.left.kind == GateKind.recruits ||
                    gate.left.kind == GateKind.spread
                ? .25
                : .75,
          );
        } else if (r.warnings.any((w) => (w.x - r.x).abs() < w.width + .03)) {
          r.steer(
            [.15, .5, .85].firstWhere(
              (x) => r.warnings.every((w) => (w.x - x).abs() > w.width + .03),
              orElse: () => .5,
            ),
          );
        } else if (r.boss != null) {
          r.steer(r.boss!.x);
        } else {
          final threats =
              r.enemies
                  .where(
                    (e) => e.active && e.kind.index <= EnemyKind.heavy.index,
                  )
                  .toList()
                ..sort((a, b) => b.y.compareTo(a.y));
          r.steer(threats.isEmpty ? .5 : threats.first.x);
        }
        r.step(1 / 60);
      }
      expect(
        r.won,
        isTrue,
        reason:
            'Level ${level + 1}: ${r.time}s, ${r.squad.length} units, base ${r.baseHealth}, boss ${r.boss?.hp}',
      );
      expect(r.time, inInclusiveRange(116, 180));
    }
  });
}
