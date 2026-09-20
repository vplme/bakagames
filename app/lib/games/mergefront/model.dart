import 'dart:math';

enum Role { rifle, scatter, heavy, support, drone }

extension RoleInfo on Role {
  String get label => ['Rifle', 'Scatter', 'Heavy', 'Support', 'Drone'][index];
  String get description => [
    'Balanced, accurate fire',
    'Short range • hits a crowd',
    'Slow shots • pushes heavies back',
    'Light fire • shields the formation',
    'Long reach • bypasses shields',
  ][index];
}

class UnitCard {
  final int id;
  final Role role;
  final int tier;
  const UnitCard(this.id, this.role, [this.tier = 1]);
  bool matches(UnitCard other) =>
      id != other.id && role == other.role && tier == other.tier && tier < 6;
  Map<String, dynamic> toJson() => {'id': id, 'role': role.index, 'tier': tier};
  factory UnitCard.fromJson(Map<String, dynamic> json) => UnitCard(
    json['id'] as int,
    Role.values[json['role'] as int],
    (json['tier'] as int).clamp(1, 6),
  );
}

/// A single atomic snapshot includes rewards, milestone credit and inventory.
class Profile {
  int coins = 0, power = 0, vitality = 0, nextId = 5, runs = 0;
  bool music = true, effects = true;
  double sensitivity = 1;
  final Set<int> completed = {};
  final Map<int, int> best = {};
  final List<UnitCard> cards = [
    const UnitCard(0, Role.rifle),
    const UnitCard(1, Role.rifle),
    const UnitCard(2, Role.scatter),
    const UnitCard(3, Role.heavy),
    const UnitCard(4, Role.support),
  ];
  final Set<int> equipped = {0, 2, 3};
  int get slots => min(6, 3 + completed.length ~/ 3);
  int get unlocked =>
      min(19, completed.isEmpty ? 0 : completed.reduce(max) + 1);
  int upgradeCost(bool damage) => 45 + 35 * (damage ? power : vitality);
  double get damageBonus => 1 + .16 * sqrt(power);
  double get healthBonus => 1 + .18 * sqrt(vitality);
  List<UnitCard> get loadout =>
      cards.where((c) => equipped.contains(c.id)).toList();

  bool equip(int id) {
    if (!cards.any((c) => c.id == id)) return false;
    if (equipped.contains(id)) {
      if (equipped.length == 1) return false;
      equipped.remove(id);
    } else {
      if (equipped.length >= slots) return false;
      equipped.add(id);
    }
    return true;
  }

  bool merge(int source, int target) {
    final a = cards.where((c) => c.id == source).firstOrNull;
    final b = cards.where((c) => c.id == target).firstOrNull;
    if (a == null || b == null || !a.matches(b)) return false;
    final active = equipped.contains(source) || equipped.contains(target);
    cards.removeWhere((c) => c.id == source || c.id == target);
    equipped.removeAll([source, target]);
    final merged = UnitCard(nextId++, a.role, a.tier + 1);
    cards.add(merged);
    if (active) equipped.add(merged.id);
    return true;
  }

  bool upgrade(bool damage) {
    final cost = upgradeCost(damage);
    if (coins < cost) return false;
    coins -= cost;
    if (damage) {
      power++;
    } else {
      vitality++;
    }
    return true;
  }

  int reward(Run run) {
    if (run.rewarded || !run.finished) return 0;
    run.rewarded = true;
    final first = run.won && completed.add(run.level.index);
    final earned =
        12 +
        run.kills * 2 +
        run.salvage +
        (run.won ? 45 : 0) +
        (first ? 35 : 0);
    coins += earned;
    runs++;
    best[run.level.index] = max(best[run.level.index] ?? 0, run.kills);
    // Deterministic, disclosed cards, never random paid rewards.
    cards.add(UnitCard(nextId++, Role.values[run.level.index % 5]));
    if (run.won) {
      cards.add(UnitCard(nextId++, Role.values[run.level.index % 5]));
    }
    return earned;
  }

  Map<String, dynamic> toJson() => {
    'version': 1,
    'coins': coins,
    'power': power,
    'vitality': vitality,
    'nextId': nextId,
    'runs': runs,
    'music': music,
    'effects': effects,
    'sensitivity': sensitivity,
    'completed': completed.toList(),
    'best': best.map((k, v) => MapEntry('$k', v)),
    'cards': cards.map((c) => c.toJson()).toList(),
    'equipped': equipped.toList(),
  };
  factory Profile.fromJson(Map<String, dynamic> json) {
    if (json['version'] != 1) {
      throw const FormatException('Unknown save version');
    }
    final p = Profile();
    p.coins = json['coins'] as int;
    p.power = json['power'] as int;
    p.vitality = json['vitality'] as int;
    p.nextId = json['nextId'] as int;
    p.runs = json['runs'] as int;
    p.music = json['music'] as bool;
    p.effects = json['effects'] as bool;
    p.sensitivity = (json['sensitivity'] as num).toDouble();
    p.completed.addAll((json['completed'] as List).cast<int>());
    p.best.addAll(
      (json['best'] as Map<String, dynamic>).map(
        (k, v) => MapEntry(int.parse(k), v as int),
      ),
    );
    p.cards
      ..clear()
      ..addAll(
        (json['cards'] as List).map(
          (c) => UnitCard.fromJson(c as Map<String, dynamic>),
        ),
      );
    p.equipped
      ..clear()
      ..addAll((json['equipped'] as List).cast<int>());
    if (p.cards.isEmpty || p.loadout.isEmpty || p.equipped.length > p.slots) {
      throw const FormatException('Invalid formation');
    }
    return p;
  }
  Profile();
}

enum GateKind {
  recruits,
  multiply,
  rate,
  damage,
  spread,
  pierce,
  heal,
  armor,
  sacrifice,
  elite,
}

class Gate {
  final GateKind kind;
  final int value;
  const Gate(this.kind, this.value);
  bool get risky =>
      kind == GateKind.sacrifice ||
      kind == GateKind.elite ||
      kind == GateKind.rate;
  String get headline => switch (kind) {
    GateKind.recruits => '+$value',
    GateKind.multiply => '×$value',
    GateKind.rate || GateKind.damage => '+$value%',
    GateKind.heal => '$value%',
    GateKind.sacrifice => '−$value / 2×',
    GateKind.elite => 'RANK 4',
    _ => symbol,
  };
  String get caption => switch (kind) {
    GateKind.recruits => 'RECRUITS',
    GateKind.multiply => 'SQUAD',
    GateKind.rate => 'RATE / −15% DAMAGE',
    GateKind.damage => 'DAMAGE',
    GateKind.heal => 'HEAL',
    GateKind.sacrifice => 'UNITS / DAMAGE',
    GateKind.elite => 'HEAVY / −25% RATE',
    _ => label,
  };
  String get symbol =>
      ['+', '×', '»', '✦', '⋔', '↑', '♥', '⬡', '−', '★'][kind.index];
  String get label => switch (kind) {
    GateKind.recruits => '+$value RECRUITS',
    GateKind.multiply => '×$value SQUAD',
    GateKind.rate => '+$value% RATE • −15% DAMAGE',
    GateKind.damage => '+$value% DAMAGE',
    GateKind.spread => 'SPREAD SHOT',
    GateKind.pierce => 'PIERCING ROUNDS',
    GateKind.heal => 'HEAL $value%',
    GateKind.armor => 'ARMORED UNITS',
    GateKind.sacrifice => '−$value • 2× DAMAGE',
    GateKind.elite => 'ELITE • −25% RATE',
  };
  String preview(Run run) => switch (kind) {
    GateKind.recruits => '${min(Run.capacity, run.squad.length + value)} units',
    GateKind.multiply => '${min(Run.capacity, run.squad.length * value)} units',
    GateKind.heal =>
      '+${run.squad.fold<double>(0, (sum, s) => sum + min(s.maxHp - s.hp, s.maxHp * value / 100)).round()} health',
    GateKind.rate =>
      '${(run.rate * (1 + value / 100) * 100).round()}% rate • ${(run.damage * .85 * 100).round()}% damage',
    GateKind.damage =>
      '${(run.damage * (1 + value / 100) * 100).round()}% shot damage',
    GateKind.spread => 'Hits up to 3 nearby enemies',
    GateKind.pierce => 'Bypass shields • hit enemies behind',
    GateKind.armor => '35% less incoming damage',
    GateKind.sacrifice =>
      '${max(1, run.squad.length - value)} units • double damage',
    GateKind.elite => 'Tier 4 heavy • slower squad',
  };
}

enum BattlefieldStyle {
  coast('Sunlit coast'),
  garden('Overgrown gardens'),
  desert('Desert ruins'),
  foundry('Copper foundry'),
  harbor('Moonlit harbor');

  final String label;
  const BattlefieldStyle(this.label);
}

class Level {
  final int index, seed;
  final String name, lesson;
  const Level(this.index, this.seed, this.name, this.lesson);
  BattlefieldStyle get style => const [
    BattlefieldStyle.coast,
    BattlefieldStyle.harbor,
    BattlefieldStyle.desert,
    BattlefieldStyle.garden,
    BattlefieldStyle.foundry,
    BattlefieldStyle.coast,
    BattlefieldStyle.desert,
    BattlefieldStyle.foundry,
    BattlefieldStyle.garden,
    BattlefieldStyle.harbor,
    BattlefieldStyle.coast,
    BattlefieldStyle.foundry,
    BattlefieldStyle.desert,
    BattlefieldStyle.garden,
    BattlefieldStyle.harbor,
    BattlefieldStyle.garden,
    BattlefieldStyle.foundry,
    BattlefieldStyle.desert,
    BattlefieldStyle.harbor,
    BattlefieldStyle.coast,
  ][index];

  double get bossAt => 116 + min(index, 4) * 3;
  double get duration => bossAt + 48;
  static const all = [
    Level(0, 173, 'Sunbreak Landing', 'Drag below to steer. Cross one gate.'),
    Level(
      1,
      829,
      'Glasswater Bridge',
      'Drones and piercing rounds beat shields.',
    ),
    Level(2, 451, 'Coral Switchback', 'Amber stripes warn of incoming fire.'),
    Level(3, 1103, 'Pylon Gardens', 'Support shields absorb incoming damage.'),
    Level(4, 2027, 'The Brass Bastion', 'Watch the boss lanes. Keep moving.'),
    Level(5, 3019, 'Tidepool Relay', 'Build a balanced formation.'),
    Level(6, 4021, 'Shellstone Rise', 'Spread shots clear swarms.'),
    Level(7, 5011, 'Copper Causeway', 'Trade safety for firepower.'),
    Level(8, 6011, 'Limewater Locks', 'Heavy shots buy breathing room.'),
    Level(9, 7013, 'Harbor of Bells', 'Leave room to dodge.'),
    Level(10, 8017, 'Foamlight Pass', 'Read the next gate early.'),
    Level(11, 9011, 'Suncoil Foundry', 'Protect your specialists.'),
    Level(12, 10007, 'Sandglass Point', 'Healing can save a small squad.'),
    Level(13, 11003, 'Turquoise Steps', 'Drones reach distant targets.'),
    Level(14, 12007, 'Golden Breakwater', 'Pierce the shield wall.'),
    Level(15, 13001, 'Palmwheel Pier', 'Multiply a healthy formation.'),
    Level(16, 14009, 'Seabreeze Engine', 'Aim for supply crates.'),
    Level(17, 15013, 'Brightstone Bay', 'Choose your power spike.'),
    Level(18, 16001, 'The Last Jetty', 'Keep an escape lane open.'),
    Level(19, 17011, 'Crown of the Coast', 'Bring the whole squad home.'),
  ];
}

enum EnemyKind {
  rusher,
  shield,
  ranged,
  swarm,
  heavy,
  barricade,
  barrel,
  pylon,
  crate,
  boss,
}

class Enemy {
  bool active = false;
  EnemyKind kind = EnemyKind.rusher;
  double x = 0, y = 0, hp = 0, maxHp = 0, clock = 0;
  int pattern = 0;
}

class Shot {
  bool active = false;
  double x = 0, y = 0, tx = 0, ty = 0, life = 0;
  Role role = Role.rifle;
}

class Spark {
  bool active = false;
  double x = 0, y = 0, life = 0;
  bool gold = false;
}

class Soldier {
  final Role role;
  final int tier;
  double hp, cooldown = 0;
  final double maxHp;
  double formationX = .5, formationY = .95, recoil = 0;
  Soldier(this.role, this.tier, this.hp) : maxHp = hp;
}

class GatePair {
  Gate left, right;
  final double at;
  bool crossed = false, prepared = false;
  GatePair(this.at, this.left, this.right);
}

class Warning {
  final double x;
  double remaining;
  final double width;
  Warning(this.x, this.remaining, [this.width = .19]);
}

/// Fixed-step, bounded simulation. No Flutter, individual pathfinding, or async
/// randomness. Pools bound both work per tick and retained effect allocations.
class Run {
  static const capacity = 24;
  static const maxBaseHealth = 100;
  int baseHealth = maxBaseHealth, escaped = 0;
  String damageNotice = '', defeatReason = '';
  double damageNoticeRemaining = 0;

  void reportDamage(String message) {
    damageNotice = message;
    damageNoticeRemaining = 2.5;
    announce(message, 'hurt');
  }

  void breach(EnemyKind kind) {
    if (finished) return;
    final damage = switch (kind) {
      EnemyKind.swarm => 2,
      EnemyKind.heavy => 12,
      EnemyKind.rusher || EnemyKind.shield || EnemyKind.ranged => 5,
      _ => 0,
    };
    if (damage == 0) return;
    escaped++;
    final loss = min(baseHealth, damage);
    baseHealth -= loss;
    reportDamage('BASE HIT −$loss • enemy escaped');
    if (baseHealth == 0) {
      defeatReason = 'Base overrun • intercept enemies in every lane.';
      end(false);
    }
  }

  final Level level;
  final Random random;
  final List<Soldier> squad = [];
  final enemies = List.generate(48, (_) => Enemy());
  final shots = List.generate(72, (_) => Shot());
  final sparks = List.generate(36, (_) => Spark());
  final List<GatePair> gates = [];
  final List<Warning> warnings = [];
  double time = 0, x = .5, targetX = .5, damage = 1, rate = 1, shield = 0;
  double _accumulator = 0, _spawn = 5, _support = 0;
  int _wave = 0;
  bool spread = false, pierce = false, armor = false;
  bool finished = false, won = false, rewarded = false, bossSpawned = false;
  int kills = 0, salvage = 0, gateCount = 0;
  String event = 'Drag below to steer', eventKind = 'start';
  int eventSerial = 0;
  Run(
    this.level,
    List<UnitCard> loadout, {
    double damageBonus = 1,
    double healthBonus = 1,
  }) : random = Random(level.seed),
       damage = damageBonus {
    for (final card in loadout.take(6)) {
      squad.add(
        Soldier(card.role, card.tier, (30 + card.tier * 10) * healthBonus),
      );
    }
    gates.add(
      GatePair(
        4,
        const Gate(GateKind.recruits, 8),
        const Gate(GateKind.multiply, 2),
      ),
    );
    gates.add(
      GatePair(
        13,
        const Gate(GateKind.rate, 40),
        const Gate(GateKind.damage, 20),
      ),
    );
    for (var i = 0; i < 6; i++) {
      final pairs = [
        [const Gate(GateKind.heal, 35), const Gate(GateKind.damage, 40)],
        [const Gate(GateKind.recruits, 6), const Gate(GateKind.multiply, 2)],
        [const Gate(GateKind.spread, 1), const Gate(GateKind.pierce, 1)],
        [const Gate(GateKind.armor, 1), const Gate(GateKind.sacrifice, 6)],
        [const Gate(GateKind.heal, 35), const Gate(GateKind.elite, 1)],
      ];
      final pair = pairs[(i + level.index.clamp(0, 4)) % pairs.length];
      gates.add(GatePair(29 + i * 15, pair[0], pair[1]));
    }
  }
  double get strength => squad.fold(0.0, (sum, s) => sum + s.hp);
  Enemy? get boss =>
      enemies.where((e) => e.active && e.kind == EnemyKind.boss).firstOrNull;
  GatePair? get approaching =>
      gates.where((g) => !g.crossed && g.at - time < 7).firstOrNull;
  void announce(String text, String kind) {
    event = text;
    eventKind = kind;
    eventSerial++;
  }

  void steer(double position) => targetX = position.clamp(.22, .78);

  void apply(Gate gate) {
    switch (gate.kind) {
      case GateKind.recruits:
        recruit(gate.value);
      case GateKind.multiply:
        recruit(squad.length * (gate.value - 1));
      case GateKind.rate:
        rate *= 1 + gate.value / 100;
        damage *= .85;
      case GateKind.damage:
        damage *= 1 + gate.value / 100;
      case GateKind.spread:
        spread = true;
      case GateKind.pierce:
        pierce = true;
      case GateKind.heal:
        for (final s in squad) {
          s.hp = min(s.maxHp, s.hp + s.maxHp * gate.value / 100);
        }
      case GateKind.armor:
        armor = true;
      case GateKind.sacrifice:
        final count = min(gate.value, squad.length - 1);
        if (count > 0) squad.removeRange(squad.length - count, squad.length);
        damage *= 2;
      case GateKind.elite:
        if (squad.length >= capacity) squad.removeLast();
        squad.add(Soldier(Role.heavy, 4, 190));
        rate *= .75;
    }
    announce(
      gate.label,
      gate.risky
          ? 'risk'
          : gate.kind == GateKind.recruits || gate.kind == GateKind.multiply
          ? 'recruit'
          : 'gate',
    );
  }

  void recruit(int count) {
    for (var i = 0; i < count && squad.length < capacity; i++) {
      squad.add(Soldier(Role.rifle, 1, 40)..cooldown = i * .035);
    }
  }

  void hurt(double amount) {
    if (finished || amount <= 0) return;
    final before = strength;
    final unitsBefore = squad.length;
    if (armor) amount *= .65;
    final absorbed = min(shield, amount);
    shield -= absorbed;
    amount -= absorbed;
    while (amount > 0 && squad.isNotEmpty) {
      final s = squad.last;
      final hit = min(s.hp, amount);
      s.hp -= hit;
      amount -= hit;
      if (s.hp <= 0) squad.removeLast();
    }
    final lost = unitsBefore - squad.length;
    reportDamage(
      'SQUAD −${(before - strength).ceil()} HP'
      '${absorbed > 0 ? ' • shield −${absorbed.ceil()}' : ''}'
      '${lost > 0 ? ' • $lost units lost' : ''}',
    );
    if (squad.isEmpty) {
      defeatReason = 'Squad eliminated • all units lost.';
      end(false);
    }
  }

  void end(bool victory) {
    if (finished) return;
    finished = true;
    won = victory;
    announce(
      victory ? 'Coast clear!' : 'Regroup and return',
      victory ? 'victory' : 'defeat',
    );
  }

  void step(double elapsed) {
    if (finished) return;
    _accumulator += elapsed.clamp(0, .25);
    while (_accumulator >= 1 / 60 && !finished) {
      _tick(1 / 60);
      _accumulator -= 1 / 60;
    }
  }

  void _tick(double dt) {
    time += dt;
    damageNoticeRemaining = max(0, damageNoticeRemaining - dt);
    x += (targetX - x) * min(1, dt * 10);
    final columns = min(5, max(1, squad.length));
    for (var i = 0; i < squad.length; i++) {
      final s = squad[i];
      s.formationX +=
          (x + ((i % columns) - (columns - 1) / 2) * .075 - s.formationX) *
          dt *
          12;
      s.formationY += (.80 + (i ~/ columns) * .035 - s.formationY) * dt * 10;
      s.recoil = max(0, s.recoil - dt * 12);
    }
    for (final g in gates) {
      if (!g.prepared && time >= g.at - 7) {
        g.prepared = true;
        Gate useful(Gate gate) {
          if (gate.kind == GateKind.heal &&
              squad.every((s) => s.hp >= s.maxHp)) {
            return armor
                ? const Gate(GateKind.elite, 1)
                : const Gate(GateKind.armor, 1);
          }
          final redundant = switch (gate.kind) {
            GateKind.spread => spread,
            GateKind.pierce => pierce,
            GateKind.armor => armor,
            _ => false,
          };
          return redundant ? const Gate(GateKind.damage, 30) : gate;
        }

        // Do not offer two capacity-capped recruitment outcomes. Lock the
        // replacement before its preview appears so choices never move late.
        if (g.left.kind == GateKind.recruits &&
            g.right.kind == GateKind.multiply &&
            min(capacity, squad.length + g.left.value) ==
                min(capacity, squad.length * g.right.value)) {
          g.left = const Gate(GateKind.heal, 35);
          g.right = const Gate(GateKind.damage, 25);
        }
        g.left = useful(g.left);
        g.right = useful(g.right);
        if (g.left.kind == g.right.kind) {
          g.right = g.left.kind == GateKind.elite
              ? const Gate(GateKind.rate, 40)
              : const Gate(GateKind.elite, 1);
        }
      }
      if (!g.crossed && time >= g.at) {
        g.crossed = true;
        if (x > .48 && x < .52) {
          announce('Gate missed • steer fully into a lane', 'miss');
        } else {
          gateCount++;
          apply(x < .5 ? g.left : g.right);
        }
      }
    }
    for (final s in shots) {
      if (s.active) {
        s.life -= dt;
        if (s.life <= 0) s.active = false;
      }
    }
    for (final s in sparks) {
      if (s.active) {
        s.life -= dt;
        if (s.life <= 0) s.active = false;
      }
    }
    for (final w in warnings) {
      w.remaining -= dt;
      if (w.remaining <= 0 && (x - w.x).abs() < w.width) {
        hurt(38 + level.index * 2.5);
      }
    }
    warnings.removeWhere((w) => w.remaining <= 0);
    if (finished) return;
    _support -= dt;
    if (_support <= 0) {
      final supports = squad.where((s) => s.role == Role.support).length;
      if (supports > 0) shield = min(100, shield + supports * 24);
      _support = 5;
    }
    _spawn -= dt;
    if (_spawn <= 0 && (time < level.bossAt - 5 || bossSpawned)) {
      // Authored pressure groups give crowd control and piercing distinct jobs.
      final recovery = time % 30 > 25;
      _spawn = bossSpawned
          ? 5.5
          : recovery
          ? 3.2
          : max(.85, 2.1 - level.index * .035 - time * .005);
      final lane = .20 + random.nextInt(3) * .30;
      final phase = _wave++ % 5;
      final kind = switch (phase) {
        1 => time > 35 ? EnemyKind.shield : EnemyKind.rusher,
        2 => EnemyKind.swarm,
        3 => time > 45 ? EnemyKind.ranged : EnemyKind.rusher,
        4 => time > 60 ? EnemyKind.heavy : EnemyKind.swarm,
        _ => EnemyKind.rusher,
      };
      final count = kind == EnemyKind.swarm ? 5 : (time > 30 ? 3 : 2);
      for (var i = 0; i < count; i++) {
        spawn(kind, (lane + (i - (count - 1) / 2) * .085).clamp(.12, .88));
      }
      if (!bossSpawned && _wave % 6 == 0) {
        spawn(EnemyKind.crate, .2 + random.nextInt(3) * .3);
      }
      if (time > 50 && _wave % 4 == 0) {
        spawn(EnemyKind.barrel, (.95 - lane).clamp(.15, .85));
      }
      if (level.index >= 3 && _wave % 7 == 0) {
        spawn(EnemyKind.pylon, .5);
      }
    }

    if (!bossSpawned && time >= level.bossAt) {
      bossSpawned = true;
      spawn(EnemyKind.boss, .5);
      announce(
        level.index.isEven
            ? 'BELLCRAB • watch the stripes'
            : 'KITE ENGINE • keep moving',
        'boss',
      );
    }
    for (final e in enemies) {
      if (!e.active) continue;
      e.clock += dt;
      if (e.kind == EnemyKind.boss) {
        e.y = min(.23, e.y + dt * .12);
        e.x = .5 + sin(time * .6) * .23;
        if (e.clock > 2.8 && warnings.length < 6) {
          e.clock = 0;
          e.pattern++;
          if (e.pattern % 3 == 0) {
            warnings.add(Warning(.22, 1.5, .18));
            warnings.add(Warning(.78, 1.5, .18));
          } else {
            warnings.add(Warning(e.pattern.isEven ? .5 : x, 1.4, .18));
          }
        }
      } else {
        e.y +=
            dt * (e.kind == EnemyKind.rusher ? .12 : .060 + level.index * .001);
        if ((e.kind == EnemyKind.ranged || e.kind == EnemyKind.pylon) &&
            e.clock > 4 &&
            warnings.length < 6) {
          e.clock = 0;
          warnings.add(Warning(x, 1.5));
        }
        if (e.y > .79) {
          if ((e.x - x).abs() < .19) {
            if (e.kind == EnemyKind.crate) {
              recruit(2);
              salvage += 5;
              announce('+2 recruits • supply recovered', 'gate');
            } else {
              hurt(e.kind == EnemyKind.heavy ? 40 : 18);
            }
          } else {
            breach(e.kind);
          }
          e.active = false;
          if (finished) return;
        }
      }
    }
    for (var i = 0; i < squad.length; i++) {
      final s = squad[i];
      s.cooldown -= dt;
      if (s.cooldown > 0) continue;
      final target = targetFor(s);
      if (target == null) continue;
      s.cooldown = [.7, 1.05, 1.7, 1.3, .85][s.role.index] / rate.clamp(.25, 4);
      s.recoil = 1;
      final base =
          [7.0, 5.0, 27.0, 4.0, 8.0][s.role.index] *
          pow(1.65, s.tier - 1) *
          damage;
      hit(target, base, s.role);
      if (s.role == Role.scatter || spread || pierce) {
        var extras = 0;
        for (final other in enemies) {
          if (other != target &&
              other.active &&
              (other.x - target.x).abs() < (pierce ? .10 : .22) &&
              (other.y - target.y).abs() < .25) {
            hit(other, base * .6, s.role);
            if (++extras == 3) break;
          }
        }
      }
      final shot = shots.where((b) => !b.active).firstOrNull;
      if (shot != null) {
        shot
          ..active = true
          ..x = x + ((i % 5) - 2) * .025
          ..y = .81 + (i ~/ 5) * .018
          ..tx = target.x
          ..ty = target.y
          ..life = .16
          ..role = s.role;
      }
    }
    if (time >= level.duration) {
      defeatReason = 'Time expired • the boss is still standing.';
      end(false);
    }
  }

  Enemy? targetFor(Soldier s) {
    Enemy? nearest;
    var score = double.infinity;
    final reach = s.role == Role.drone
        ? .95
        : s.role == Role.scatter
        ? .40
        : .75;
    for (final e in enemies) {
      if (!e.active || .82 - e.y > reach) continue;
      final dx = (e.x - x).abs();
      if (dx > (s.role == Role.drone ? 1 : .25)) continue;
      final distance = (.82 - e.y) + dx * .6;
      if (distance < score) {
        score = distance;
        nearest = e;
      }
    }
    return nearest;
  }

  void hit(Enemy e, double amount, Role role) {
    if (!e.active || finished) return;
    if (e.kind == EnemyKind.shield && !pierce && role != Role.drone) {
      amount *= .3;
    }
    e.hp -= amount;
    if (role == Role.heavy && e.kind != EnemyKind.boss) {
      e.y = max(.02, e.y - .035);
    }
    if (e.hp > 0) return;
    e.active = false;
    final spark = sparks.where((s) => !s.active).firstOrNull;
    if (spark != null) {
      spark
        ..active = true
        ..x = e.x
        ..y = e.y
        ..life = .35
        ..gold = e.kind == EnemyKind.crate;
    }
    if (e.kind == EnemyKind.crate) {
      salvage += 10;
      recruit(2);
      announce('Supply +2 • 10 coins', 'coin');
    } else {
      kills++;
    }
    if (e.kind == EnemyKind.barrel) {
      for (final other in enemies) {
        if (other.active &&
            (other.x - e.x).abs() < .24 &&
            (other.y - e.y).abs() < .22) {
          hit(other, 70, Role.drone);
        }
      }
    }
    if (e.kind == EnemyKind.boss) end(true);
  }

  void spawn(EnemyKind kind, double lane) {
    final e = enemies.where((e) => !e.active).firstOrNull;
    if (e == null) return;
    final hp =
        [
          28.0,
          55.0,
          38.0,
          12.0,
          150.0,
          65.0,
          25.0,
          80.0,
          25.0,
          2000.0,
        ][kind.index] *
        (1 + level.index * .065) *
        (kind == EnemyKind.crate || kind == EnemyKind.barrel
            ? 1
            : 1 + min(time, level.bossAt) / 180);
    e
      ..active = true
      ..kind = kind
      ..x = lane
      ..y = -.04
      ..hp = hp
      ..maxHp = hp
      ..clock = 0
      ..pattern = 0;
  }
}
