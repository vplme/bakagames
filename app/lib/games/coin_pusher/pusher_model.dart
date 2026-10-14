import 'dart:math' as math;
import 'package:forge2d/forge2d.dart';

const prizeIds = [
  'bear',
  'bunny',
  'dragon',
  'fox',
  'cat',
  'penguin',
  'frog',
  'otter',
  'elephant',
  'unicorn',
  'axolotl',
];
const prizeNames = [
  'Honey Bear',
  'Clover Bunny',
  'Mint Dragon',
  'Apricot Fox',
  'Peaches Cat',
  'Pebble Penguin',
  'Pistachio Frog',
  'Cocoa Otter',
  'Bluebell Elephant',
  'Starlight Unicorn',
  'Petal Axolotl',
];
const prizeUnlockCoins = [0, 0, 0, 250, 500, 750, 1000, 1250, 1500, 1750, 2000];

enum RareCoin { none, rainbow, heart }

class PusherCoin {
  final Body body;
  final int value;
  static const thickness = .22;
  final int prize;
  final bool isMegaCoin;
  final RareCoin rare;
  bool get isLargeCoin => prize == 0 && value == 10;
  bool get isGoldBar => prize == 0 && value == 25 && !isMegaCoin;
  bool get isSpecial =>
      isLargeCoin || isGoldBar || isMegaCoin || rare != RareCoin.none;
  double get radius => prize > 0
      ? .72
      : isGoldBar || isMegaCoin
      ? .85
      : isLargeCoin
      ? .65
      : .4;
  double get height => prize > 0
      ? 1.1
      : isGoldBar
      ? .38
      : thickness;
  double z, vz;
  PusherCoin(
    this.body,
    this.value,
    this.z,
    this.vz,
    this.prize, [
    this.isMegaCoin = false,
    this.rare = RareCoin.none,
  ]);
}

class _HeightFilter extends ContactFilter {
  @override
  bool shouldCollide(Fixture a, Fixture b) {
    final ca = a.userData, cb = b.userData;
    if (ca is PusherCoin && cb is PusherCoin) {
      return ca.z < cb.z + cb.height - .025 && cb.z < ca.z + ca.height - .025;
    }
    final coin = ca is PusherCoin ? ca : cb;
    return coin is! PusherCoin || coin.z < .6;
  }
}

/// Upright cylinder stacking, planar contacts, and economy. Rendering never decides payouts.
class PusherModel {
  static const maxStackCoins = 3;
  static const maxCoinBase = (maxStackCoins - 1) * PusherCoin.thickness;
  static const dropHeight = 1.8;
  // The central paddle leaves room for coins to spread into the wider bed.
  static const pusherLeft = 2.1;
  static const pusherRight = 7.9;
  static const pusherHalfDepth = .35;
  static const dropMinX = pusherLeft + .4;
  static const dropMaxX = pusherRight - .4;
  String? dropBlockedReason;
  // Gravity acts only on height in _stepHeights; the tabletop is level.
  final World world = World(Vector2.zero());
  final List<PusherCoin> coins = [];
  late final Body pusher;
  final Map<String, int> collection = {};
  // Transient presentation events; never persisted or inferred from balances.
  final List<String> soundEvents = [];
  final List<String> justCollected = [];
  final List<String> justUnlocked = [];
  final List<String> justRewards = [];
  static const boostTarget = 200;
  static const maxBoardCoins = 320;
  int boostCharge = 0, pendingShowerCoins = 0, pendingMegaCoins = 0;
  double turboRemaining = 0, showerCooldown = 0;
  double rainbowRemaining = 0;
  int get earningsMultiplier => rainbowRemaining > 0 ? 2 : 1;
  String? lastPerk;
  double get boostProgress => boostCharge / boostTarget;
  String get boostLabel => turboRemaining > 0
      ? 'Turbo pusher · ${turboRemaining.ceil()}s'
      : pendingShowerCoins > 0
      ? 'Coin shower · $pendingShowerCoins left'
      : 'Boost $boostCharge / $boostTarget';
  int comboCoins = 0, pendingLargeCoins = 0, pendingGoldBars = 0;
  double comboRemaining = 0;
  int get unlockedPrizeCount =>
      prizeUnlockCoins.where((goal) => collected >= goal).length;
  int? get nextPrizeIndex =>
      unlockedPrizeCount < prizeIds.length ? unlockedPrizeCount : null;
  int randomState = DateTime.now().microsecondsSinceEpoch & 0x7fffffff;
  bool prizesIntroduced = false;
  int balance = 40, collected = 0, bonus = 0, drops = 0;
  double phase = 0, accumulator = 0, cooldown = 0;
  int get bonusRemaining => 20 - bonus;
  double get pusherY => 2 + math.sin(phase) * .8;

  PusherModel({Map<String, dynamic>? saved, int lifetimeCollected = 0}) {
    collected = lifetimeCollected;
    world.setContactFilter(_HeightFilter());
    pusher = world.createBody(
      BodyDef(type: BodyType.kinematic, position: Vector2(5, 2)),
    );
    pusher.createFixture(
      FixtureDef(
        PolygonShape()
          ..setAsBoxXY((pusherRight - pusherLeft) / 2, pusherHalfDepth),
        friction: .3,
      ),
    );
    // Solid rear shoulders open diagonally onto the wider front bed.
    final shoulders = world.createBody(BodyDef());
    for (final right in [false, true]) {
      Vector2 point(double x, double y) => Vector2(right ? 10 - x : x, y);
      shoulders.createFixture(
        FixtureDef(
          PolygonShape()..set([
            point(-.1, 0),
            point(1.85, 0),
            point(1.85, 3.6),
            point(-.1, 5.2),
          ]),
          friction: .3,
        ),
      );
    }
    if (saved != null) {
      if (saved['version'] != 1 &&
          saved['version'] != 2 &&
          saved['version'] != 3) {
        throw const FormatException('Unsupported save');
      }
      if (saved['version'] == 3) {
        randomState = saved['randomState'] as int;
        prizesIntroduced = saved['prizesIntroduced'] as bool;
        for (final entry
            in (saved['collection'] as Map<String, dynamic>).entries) {
          if (!prizeIds.contains(entry.key) ||
              entry.value is! int ||
              (entry.value as int) < 0) {
            throw const FormatException('Invalid collection');
          }
          collection[entry.key] = entry.value as int;
        }
      }
      boostCharge = (saved['boostCharge'] as int?) ?? 0;
      pendingShowerCoins = (saved['pendingShowerCoins'] as int?) ?? 0;
      pendingMegaCoins = (saved['pendingMegaCoins'] as int?) ?? 0;
      turboRemaining = (saved['turboRemaining'] as num?)?.toDouble() ?? 0;
      showerCooldown = (saved['showerCooldown'] as num?)?.toDouble() ?? 0;
      lastPerk = saved['lastPerk'] as String?;
      rainbowRemaining = (saved['rainbowRemaining'] as num?)?.toDouble() ?? 0;
      if (!rainbowRemaining.isFinite ||
          rainbowRemaining < 0 ||
          rainbowRemaining > 60) {
        throw const FormatException('Invalid rainbow duration');
      }
      if (boostCharge < 0 ||
          boostCharge >= boostTarget ||
          pendingShowerCoins < 0 ||
          pendingMegaCoins < 0 ||
          !turboRemaining.isFinite ||
          turboRemaining < 0 ||
          !showerCooldown.isFinite ||
          showerCooldown < 0 ||
          (lastPerk != null &&
              ![
                'Coin shower',
                'Turbo pusher',
                'Mega coin',
              ].contains(lastPerk))) {
        throw const FormatException('Invalid boost progress');
      }
      comboCoins = (saved['comboCoins'] as int?) ?? 0;
      comboRemaining = (saved['comboRemaining'] as num?)?.toDouble() ?? 0;
      pendingLargeCoins = (saved['pendingLargeCoins'] as int?) ?? 0;
      pendingGoldBars = (saved['pendingGoldBars'] as int?) ?? 0;
      if (comboCoins < 0 ||
          !comboRemaining.isFinite ||
          comboRemaining < 0 ||
          comboRemaining > 1 ||
          pendingLargeCoins < 0 ||
          pendingGoldBars < 0) {
        throw const FormatException('Invalid combo progress');
      }
      balance = saved['balance'] as int;
      collected = saved['collected'] as int;
      bonus = saved['bonus'] as int;
      drops = saved['drops'] as int;
      phase = (saved['phase'] as num).toDouble();
      if (balance < 0 ||
          collected < 0 ||
          bonus < 0 ||
          bonus >= 20 ||
          drops < 0 ||
          !phase.isFinite) {
        throw const FormatException('Invalid economy');
      }
      final rows = saved['coins'] as List;
      if (rows.length > maxBoardCoins) {
        throw const FormatException('Too many coins');
      }
      for (final row in rows) {
        final r = (row as List).cast<num>();
        if ((r.length !=
                    (saved['version'] == 1
                        ? 5
                        : saved['version'] == 2
                        ? 7
                        : 8) &&
                !(saved['version'] == 3 && r.length == 9)) ||
            r.any((n) => !n.toDouble().isFinite) ||
            (![1, 5, 10, 25].contains(r[4])) ||
            (r.length >= 7 && r[5] < 0) ||
            (r.length >= 8 &&
                (r[7] < 0 || r[7] > prizeIds.length || r[7] != r[7].toInt())) ||
            (r.length == 9 &&
                (r[7] != 0 ||
                    ![1, 2, 3].contains(r[8]) ||
                    (r[8] == 1 ? r[4] != 25 : r[4] != 1)))) {
          throw const FormatException('Invalid coin');
        }
        _coin(
          r[0].toDouble(),
          r[1].toDouble(),
          r[4].toInt(),
          vx: r[2].toDouble(),
          vy: r[3].toDouble(),
          z: r.length >= 7 ? r[5].toDouble() : 0,
          vz: r.length >= 7 ? r[6].toDouble() : 0,
          prize: r.length >= 8 ? r[7].toInt() : 0,
          mega: r.length == 9 && r[8] == 1,
          rare: r.length == 9 && r[8] >= 2
              ? RareCoin.values[r[8].toInt() - 1]
              : RareCoin.none,
        );
      }
    } else {
      for (var row = 0; row < 10; row++) {
        for (var col = 0; col < 11; col++) {
          _coin(.8 + col * .83 + (row.isOdd ? .12 : 0), 4 + row * .73, 1);
        }
      }
      for (var i = 0; i < 8; i++) {
        _coin(
          2.46 + (i % 4) * 1.66,
          6.19 + (i ~/ 4) * 2.19,
          1,
          z: PusherCoin.thickness,
        );
      }
    }
    if (saved == null) introducePrizes();
    pusher.setTransform(Vector2(5, pusherY), 0);
  }

  void _coin(
    double x,
    double y,
    int value, {
    double vx = 0,
    double vy = 0,
    double z = 0,
    double vz = 0,
    int prize = 0,
    bool mega = false,
    RareCoin rare = RareCoin.none,
  }) {
    final body = world.createBody(
      BodyDef(
        type: BodyType.dynamic,
        position: Vector2(x, y),
        linearVelocity: Vector2(vx, vy),
        linearDamping: 2.4,
        fixedRotation: true,
      ),
    );
    final coin = PusherCoin(body, value, z, vz, prize, mega, rare);
    body.createFixture(
      FixtureDef(
        coin.isGoldBar
            ? (PolygonShape()..setAsBoxXY(.8, .4))
            : (CircleShape()..radius = coin.radius),
        userData: coin,
        density: 1,
        friction: .3,
        restitution: .08,
      ),
    );
    coins.add(coin);
  }

  bool drop(double x) {
    dropBlockedReason = null;
    if (balance == 0 || coins.length >= maxBoardCoins || cooldown > 0) {
      dropBlockedReason = balance == 0
          ? 'Refill your coins to keep playing.'
          : 'Wait for room on the board.';
      return false;
    }
    final target = x.clamp(dropMinX, dropMaxX).toDouble();
    final y = pusherY + 1;
    final spot = Vector2(target, y);
    for (final c in coins) {
      if ((c.body.position - spot).length >= c.radius + .4) continue;
      if (c.prize > 0 || c.z + c.height > maxCoinBase + .01) {
        dropBlockedReason = c.prize > 0
            ? 'A toy is below the chute. Try another spot.'
            : 'Three coins high is the limit. Try another spot.';
        return false;
      }
    }
    balance--;
    drops++;
    // The chute does not rise with the pile. Airborne coins reserve their spot.
    // One rare roll per paid drop: heart 0.2%, rainbow 1%.
    final roll = _random();
    final rare = roll < .002
        ? RareCoin.heart
        : roll < .012
        ? RareCoin.rainbow
        : RareCoin.none;
    _coin(
      target,
      y,
      rare == RareCoin.none && drops % 12 == 0 ? 5 : 1,
      z: dropHeight,
      rare: rare,
    );
    soundEvents.add('insert');
    if (drops % 12 == 0) _spawnPrize();
    cooldown = .18;
    return true;
  }

  double _random() {
    randomState = (1664525 * randomState + 1013904223) & 0x7fffffff;
    return randomState / 0x80000000;
  }

  /// Old sessions receive their first toys once, preserving their coin balance.
  void introducePrizes() {
    if (prizesIntroduced) return;
    prizesIntroduced = true;
    for (var i = 0; i < 3; i++) {
      _spawnPrize(initialSlot: i);
    }
  }

  void _spawnPrize({int? initialSlot}) {
    if (coins.length >= maxBoardCoins ||
        coins.where((c) => c.prize > 0).length >= 3) {
      return;
    }
    final x = initialSlot == null
        ? 1.5 + _random() * 7
        : 1.6 + initialSlot * 3.3 + _random() * .3;
    final y = 5.5 + _random() * 3.5;
    final eligible = unlockedPrizeCount;
    // Give a newly unlocked friend its first appearance when a toy slot opens.
    final unseen = [
      for (var i = 3; i < eligible; i++)
        if ((collection[prizeIds[i]] ?? 0) == 0 &&
            !coins.any((coin) => coin.prize == i + 1))
          i + 1,
    ];
    final kind = unseen.isNotEmpty
        ? unseen.first
        : 1 + (_random() * eligible).floor();
    final top = coins
        .where((c) => (c.body.position - Vector2(x, y)).length < c.radius + .72)
        .fold<double>(0, (h, c) => math.max(h, c.z + c.height));
    _coin(x, y, 5, z: top + 1.5, prize: kind);
    if (initialSlot == null) soundEvents.add('toy_spawn');
  }

  /// Start a fresh machine while retaining lifetime earnings and toy collection.
  void resetBoard() {
    soundEvents.clear();
    final fresh = PusherModel(lifetimeCollected: collected);
    for (final c in coins) {
      world.destroyBody(c.body);
    }
    coins.clear();
    for (final c in fresh.coins) {
      _coin(
        c.body.position.x,
        c.body.position.y,
        c.value,
        z: c.z,
        prize: c.prize,
      );
    }
    balance = 40;
    bonus = 0;
    drops = 0;
    phase = 0;
    accumulator = 0;
    cooldown = 0;
    randomState = fresh.randomState;
    prizesIntroduced = true;
    justCollected.clear();
    justUnlocked.clear();
    justRewards.clear();
    comboCoins = 0;
    comboRemaining = 0;
    pendingLargeCoins = 0;
    pendingGoldBars = 0;
    boostCharge = pendingShowerCoins = pendingMegaCoins = 0;
    turboRemaining = showerCooldown = rainbowRemaining = 0;
    lastPerk = null;
    dropBlockedReason = null;
    pusher.setTransform(Vector2(5, pusherY), 0);
    pusher.linearVelocity = Vector2.zero();
  }

  bool refill() {
    if (balance != 0) return false;
    balance = 40;
    return true;
  }

  int update(double dt) {
    justCollected.clear();
    justUnlocked.clear();
    justRewards.clear();
    final previousUnlockCount = unlockedPrizeCount;
    accumulator += dt.clamp(0, .1);
    var earned = 0;
    while (accumulator >= 1 / 60) {
      const step = 1 / 60;
      accumulator -= step;
      comboRemaining = math.max(0, comboRemaining - step);
      if (comboRemaining == 0) comboCoins = 0;
      cooldown = math.max(0, cooldown - step);
      rainbowRemaining = math.max(0, rainbowRemaining - step);
      turboRemaining = math.max(0, turboRemaining - step);
      showerCooldown = math.max(0, showerCooldown - step);
      phase = (phase + step * (turboRemaining > 0 ? 3.2 : 1.6)) % (2 * math.pi);
      pusher.linearVelocity = Vector2(0, (pusherY - pusher.position.y) / step);
      _stepHeights(step);
      world.stepDt(step);
      for (final c in coins.toList()) {
        final p = c.body.position;
        final side = p.x < .25 || p.x > 9.75;
        if (side || p.y > 11.5) {
          soundEvents.add(
            side
                ? (c.prize > 0 ? 'toy_side' : 'side')
                : c.prize > 0
                ? 'toy_collect'
                : c.isSpecial || c.value > 1
                ? 'valuable'
                : 'collect',
          );
          if (!side) {
            if (c.rare == RareCoin.rainbow) {
              rainbowRemaining = 60;
              justRewards.add('Rainbow coin! Double earnings for 60 seconds');
            }
            if (c.rare == RareCoin.heart) {
              // Filling the meter immediately spends it on the normal perk.
              boostCharge = boostTarget - 1;
              justRewards.add('Heart coin! Boost filled');
            }
            if (c.prize > 0) {
              final id = prizeIds[c.prize - 1];
              collection[id] = (collection[id] ?? 0) + 1;
              justCollected.add(prizeNames[c.prize - 1]);
            }
            // Count physical regular/blue coins, not their monetary value,
            // toys, or special rewards. Each tier triggers once per window.
            if (c.prize == 0 && !c.isSpecial) {
              if (comboCoins == 0) comboRemaining = 1;
              comboCoins++;
              if (comboCoins == 5) {
                pendingLargeCoins++;
                justRewards.add('5-coin combo! Large coin worth 10 earned');
              }
              if (comboCoins == 10) {
                pendingGoldBars++;
                justRewards.add('10-coin combo! Gold bar worth 25 earned');
              }
            }
            final payout = c.value * earningsMultiplier;
            balance += payout;
            collected += payout;
            earned += payout;
            bonus++;
            if (bonus == 20) {
              bonus = 0;
              balance += 10 * earningsMultiplier;
              earned += 10 * earningsMultiplier;
              soundEvents.add('bonus');
            }
          }
          boostCharge += c.prize > 0 ? 4 : 1;
          while (boostCharge >= boostTarget) {
            boostCharge -= boostTarget;
            _triggerPerk();
          }
          world.destroyBody(c.body);
          coins.remove(c);
        }
      }
      _spawnSpecialRewards();
      _spawnBoostRewards();
    }
    justUnlocked.addAll(
      prizeNames.sublist(previousUnlockCount, unlockedPrizeCount),
    );
    if (justUnlocked.isNotEmpty) soundEvents.add('unlock');
    return earned;
  }

  void _triggerPerk() {
    final choice = (_random() * 3).floor();
    switch (choice) {
      case 0:
        pendingShowerCoins += 40;
        lastPerk = 'Coin shower';
      case 1:
        turboRemaining += 10;
        lastPerk = 'Turbo pusher';
      case 2:
        pendingMegaCoins++;
        lastPerk = 'Mega coin';
    }
    justRewards.add(
      '$lastPerk! ${choice == 2
          ? 'Worth 25 in the tray'
          : choice == 1
          ? '10 seconds of double-speed pushing'
          : '40 free coins'}',
    );
    soundEvents.add('bonus');
  }

  void _spawnBoostRewards() {
    if (coins.length >= maxBoardCoins) return;
    final mega = pendingMegaCoins > 0;
    if (!mega && (pendingShowerCoins == 0 || showerCooldown > 0)) return;
    final x = 1.5 + _random() * 7;
    final y = 4.5 + _random() * 3;
    final radius = mega ? .85 : .4;
    final top = coins
        .where(
          (c) => (c.body.position - Vector2(x, y)).length < c.radius + radius,
        )
        .fold<double>(0, (h, c) => math.max(h, c.z + c.height));
    _coin(x, y, mega ? 25 : 1, z: top + dropHeight, mega: mega);
    if (mega) {
      pendingMegaCoins--;
    } else {
      pendingShowerCoins--;
      showerCooldown = .10;
    }
    soundEvents.add('reward_spawn');
  }

  void _spawnSpecialRewards() {
    while (coins.length < maxBoardCoins &&
        coins.where((c) => c.isSpecial).length < 10 &&
        (pendingGoldBars > 0 || pendingLargeCoins > 0)) {
      final bar = pendingGoldBars > 0;
      if (bar) {
        pendingGoldBars--;
      } else {
        pendingLargeCoins--;
      }
      final x = 2.8 + _random() * 4.4;
      const y = 4.8;
      final top = coins
          .where(
            (c) => (c.body.position - Vector2(x, y)).length < c.radius + .85,
          )
          .fold<double>(0, (height, c) => math.max(height, c.z + c.height));
      _coin(x, y, bar ? 25 : 10, z: top + 1.5);
      soundEvents.add('reward_spawn');
    }
  }

  void _stepHeights(double dt) {
    const gravity = 18.0;
    final ordered = [...coins]..sort((a, b) => a.z.compareTo(b.z));
    for (final c in ordered) {
      c.vz -= gravity * dt;
      final next = c.z + c.vz * dt;
      var floor = 0.0;
      final supports = <PusherCoin>[];
      for (final other in ordered) {
        if (identical(c, other) || other.z >= c.z - .1) continue;
        final top = other.z + other.height;
        if (top > c.z + .025 ||
            (c.body.position - other.body.position).length >=
                other.radius + c.radius - .025) {
          continue;
        }
        if (top > floor + .025) {
          floor = top;
          supports.clear();
        }
        if ((top - floor).abs() < .025) supports.add(other);
      }
      if (next <= floor) {
        c.z = floor;
        c.vz = 0;
        c.body.linearDamping = supports.isEmpty ? 3.2 : .4;
        if (supports.isNotEmpty) {
          final center = Vector2.zero();
          var totalWeight = 0.0;
          PusherCoin nearest = supports.first;
          var nearestDistance = double.infinity;
          for (final support in supports) {
            final distance = (c.body.position - support.body.position).length;
            final weight = support.radius + c.radius - distance;
            center.add(support.body.position * weight);
            totalWeight += weight;
            if (distance < nearestDistance) {
              nearest = support;
              nearestDistance = distance;
            }
          }
          center.scale(1 / totalWeight);
          final offset = c.body.position - center;
          final overLimit =
              c.prize == 0 &&
              (floor > maxCoinBase + .01 || supports.any((s) => s.prize > 0));
          final balanced =
              nearestDistance < nearest.radius * .8 ||
              (supports.length > 1 && offset.length < .16);
          if (!balanced || overLimit) {
            // A coin hanging off an edge slips sideways, then falls once clear.
            // Old over-height saves settle this way too; no coins are deleted.
            final direction = offset.length > .001
                ? offset.normalized()
                : Vector2(1, 0);
            c.body.applyLinearImpulse(
              direction * (c.body.mass * gravity * .3 * dt),
            );
          } else {
            // Coulomb friction: capped impulse, with equal reaction on support.
            // This transfers motion without copying velocities or adding energy.
            final relative =
                nearest.body.linearVelocity - c.body.linearVelocity;
            final mass = 1 / (1 / c.body.mass + 1 / nearest.body.mass);
            final impulse = relative * mass;
            final limit = .35 * c.body.mass * gravity * dt;
            if (impulse.length > limit) impulse.scale(limit / impulse.length);
            if (impulse.length2 > 1e-10) {
              c.body.applyLinearImpulse(impulse);
              nearest.body.applyLinearImpulse(-impulse);
            }
          }
        }
      } else {
        c.z = next;
        c.body.linearDamping = .08;
      }
      for (final fixture in c.body.fixtures) {
        fixture.refilter();
      }
    }
  }

  Map<String, dynamic> toJson() => {
    'version': 3,
    'randomState': randomState,
    'prizesIntroduced': prizesIntroduced,
    'collection': Map<String, int>.of(collection),
    'balance': balance,
    'collected': collected,
    'bonus': bonus,
    'drops': drops,
    'phase': phase,
    'boostCharge': boostCharge,
    'pendingShowerCoins': pendingShowerCoins,
    'pendingMegaCoins': pendingMegaCoins,
    'turboRemaining': turboRemaining,
    'rainbowRemaining': rainbowRemaining,
    'showerCooldown': showerCooldown,
    'lastPerk': lastPerk,
    'comboCoins': comboCoins,
    'comboRemaining': comboRemaining,
    'pendingLargeCoins': pendingLargeCoins,
    'pendingGoldBars': pendingGoldBars,
    'coins': [
      for (final c in coins)
        [
          c.body.position.x,
          c.body.position.y,
          c.body.linearVelocity.x,
          c.body.linearVelocity.y,
          c.value,
          c.z,
          c.vz,
          c.prize,
          if (c.isMegaCoin)
            1
          else if (c.rare != RareCoin.none)
            c.rare.index + 1,
        ],
    ],
  };
}
