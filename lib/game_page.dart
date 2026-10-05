import 'dart:math';

import 'package:flutter/material.dart';

class GamePage extends StatefulWidget {
  const GamePage({
    super.key,
    required this.onLogout,
    this.isLoggingOut = false,
    this.rollDice,
  });

  final VoidCallback onLogout;
  final bool isLoggingOut;
  final int Function()? rollDice;

  @override
  State<GamePage> createState() => _GamePageState();
}

class _GamePageState extends State<GamePage>
    with SingleTickerProviderStateMixin {
  final _random = Random();
  final _scores = [0, 0];
  final _faces = [1, 1];
  late final _animation = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 650),
  );
  int _turn = 0;
  int? _winner;
  bool _rolling = false;

  @override
  void dispose() {
    _animation.dispose();
    super.dispose();
  }

  Future<void> _roll(int player) async {
    if (_rolling || _winner != null || _turn != player) return;
    setState(() => _rolling = true);
    final result = widget.rollDice?.call() ?? _random.nextInt(6) + 1;
    assert(result >= 1 && result <= 6);
    if (!MediaQuery.disableAnimationsOf(context)) {
      try {
        await _animation.forward(from: 0).orCancel;
      } on TickerCanceled {
        return;
      }
    }
    if (!mounted) return;
    setState(() {
      _faces[player] = result;
      _scores[player] += result;
      _rolling = false;
      if (_scores[player] >= 30) {
        _winner = player;
      } else {
        _turn = 1 - player;
      }
    });
  }

  void _restart() {
    setState(() {
      _scores.fillRange(0, 2, 0);
      _faces.fillRange(0, 2, 1);
      _turn = 0;
      _winner = null;
      _rolling = false;
    });
    _animation.reset();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dice Roll'),
        actions: [
          IconButton(
            tooltip: 'Log out',
            onPressed: widget.isLoggingOut ? null : widget.onLogout,
            icon: const Icon(Icons.logout),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            Semantics(
              liveRegion: true,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                child: Text(
                  _winner == null
                      ? 'First to 30 wins'
                      : 'Player ${_winner! + 1} wins!',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
            ),
            Expanded(child: _playerPanel(1)),
            const Divider(height: 1),
            Expanded(child: _playerPanel(0)),
          ],
        ),
      ),
    );
  }

  Widget _playerPanel(int player) {
    final theme = Theme.of(context);
    final active = _winner == null && _turn == player;
    final status = _winner == player
        ? 'Winner'
        : _winner != null
        ? 'Game over'
        : active
        ? (_rolling ? 'Rolling…' : 'Your turn')
        : 'Waiting';

    return ColoredBox(
      color: player == 1
          ? const Color(0xFFEAF0E7)
          : theme.scaffoldBackgroundColor,
      child: LayoutBuilder(
        builder: (context, constraints) => SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 520),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: max(0.0, constraints.maxHeight - 40),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                'Player ${player + 1}',
                                style: theme.textTheme.titleLarge,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Flexible(
                              child: Semantics(
                                liveRegion: true,
                                child: Text(
                                  status,
                                  textAlign: TextAlign.end,
                                  style: TextStyle(
                                    color: active || _winner == player
                                        ? theme.colorScheme.primary
                                        : theme.colorScheme.onSurfaceVariant,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        Row(
                          children: [
                            Expanded(
                              child: Semantics(
                                label:
                                    'Player ${player + 1} score: ${_scores[player]} of 30',
                                excludeSemantics: true,
                                child: Container(
                                  key: ValueKey('score-$player'),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 20,
                                    vertical: 12,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: const Color(0xFFDDE2DA),
                                    ),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text('Total points'),
                                      const SizedBox(height: 4),
                                      Text(
                                        '${_scores[player]} / 30',
                                        style: theme.textTheme.headlineSmall
                                            ?.copyWith(
                                              fontWeight: FontWeight.w700,
                                            ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 24),
                            AnimatedBuilder(
                              animation: _animation,
                              builder: (context, _) {
                                final rolling = _rolling && _turn == player;
                                final wobble = rolling
                                    ? sin(_animation.value * pi * 8)
                                    : 0.0;
                                return Transform.rotate(
                                  angle: wobble * 0.18,
                                  child: Transform.translate(
                                    offset: Offset(0, wobble * 4),
                                    child: DiceFace(
                                      value: rolling
                                          ? 1 +
                                                (_animation.value * 18)
                                                        .floor() %
                                                    6
                                          : _faces[player],
                                      isRolling: rolling,
                                    ),
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton(
                            key: ValueKey('roll-$player'),
                            onPressed: widget.isLoggingOut || _rolling
                                ? null
                                : _winner != null
                                ? _restart
                                : active
                                ? () => _roll(player)
                                : null,
                            child: Text(
                              _winner != null
                                  ? 'Roll again'
                                  : active && _rolling
                                  ? 'Rolling…'
                                  : 'Roll dice',
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class DiceFace extends StatelessWidget {
  const DiceFace({super.key, required this.value, this.isRolling = false});

  final int value;
  final bool isRolling;

  static const _pips = <int, List<int>>{
    1: [4],
    2: [0, 8],
    3: [0, 4, 8],
    4: [0, 2, 6, 8],
    5: [0, 2, 4, 6, 8],
    6: [0, 2, 3, 5, 6, 8],
  };

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.primary;
    return Semantics(
      label: isRolling ? 'Dice rolling' : 'Dice shows $value',
      child: Container(
        width: 80,
        height: 80,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Stack(
          children: [
            for (final pip in _pips[value]!)
              Align(
                alignment: Alignment((pip % 3) - 1.0, (pip ~/ 3) - 1.0),
                child: Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.onPrimary,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
