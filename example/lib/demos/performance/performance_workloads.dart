import 'dart:math' as math;

import 'package:flutter/material.dart';

class SlowBuildDemoCard extends StatefulWidget {
  const SlowBuildDemoCard({super.key});

  @override
  State<SlowBuildDemoCard> createState() => _SlowBuildDemoCardState();
}

class _SlowBuildDemoCardState extends State<SlowBuildDemoCard> {
  bool _injectSlowBuild = false;
  int _runs = 0;
  int _checksum = 0;

  @override
  Widget build(BuildContext context) {
    if (_injectSlowBuild) {
      _checksum = runExpensiveCalculation(42000);
      _injectSlowBuild = false;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        FilledButton.icon(
          onPressed: () {
            setState(() {
              _runs += 1;
              _injectSlowBuild = true;
            });
          },
          icon: const Icon(Icons.bolt_rounded),
          label: Text('Trigger slow build #$_runs'),
        ),
        const SizedBox(height: 10),
        Text('Last checksum: $_checksum'),
      ],
    );
  }
}

class FramePressureDemoCard extends StatefulWidget {
  const FramePressureDemoCard({super.key});

  @override
  State<FramePressureDemoCard> createState() => _FramePressureDemoCardState();
}

class _FramePressureDemoCardState extends State<FramePressureDemoCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  bool _running = false;
  int _samples = 0;
  int _checksum = 0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2600),
    )
      ..addListener(() {
        if (!_running || !mounted) {
          return;
        }
        setState(() {
          _samples += 1;
        });
      })
      ..addStatusListener((AnimationStatus status) {
        if (status == AnimationStatus.completed && mounted) {
          setState(() {
            _running = false;
          });
        }
      });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_running) {
      _checksum = runExpensiveCalculation(34000);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        FilledButton.tonalIcon(
          onPressed: _running
              ? null
              : () {
                  setState(() {
                    _samples = 0;
                    _checksum = 0;
                    _running = true;
                  });
                  _controller.forward(from: 0);
                },
          icon: const Icon(Icons.play_arrow_rounded),
          label: Text(
              _running ? 'Frame pressure running...' : 'Run frame pressure'),
        ),
        const SizedBox(height: 12),
        LinearProgressIndicator(value: _running ? _controller.value : 0),
        const SizedBox(height: 10),
        Text('samples=$_samples checksum=$_checksum'),
      ],
    );
  }
}

class ImageLoadingDemoCard extends StatefulWidget {
  const ImageLoadingDemoCard({super.key});

  @override
  State<ImageLoadingDemoCard> createState() => _ImageLoadingDemoCardState();
}

class _ImageLoadingDemoCardState extends State<ImageLoadingDemoCard> {
  static const List<int> _cacheWidths = <int>[64, 96, 128, 192, 256];

  int _index = 0;
  int _evictions = 0;

  Future<void> _forceCacheMiss() async {
    const AssetImage image = AssetImage('assets/images/performance_tile.png');
    await image.evict();
    if (!mounted) {
      return;
    }
    setState(() {
      _evictions += 1;
      _index = (_index + 1) % _cacheWidths.length;
    });
  }

  @override
  Widget build(BuildContext context) {
    final int cacheWidth = _cacheWidths[_index];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        FilledButton.tonalIcon(
          onPressed: _forceCacheMiss,
          icon: const Icon(Icons.cached_rounded),
          label: Text('Force image cache miss #$_evictions'),
        ),
        const SizedBox(height: 12),
        ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: Image(
            image: ResizeImage(
              const AssetImage('assets/images/performance_tile.png'),
              width: cacheWidth,
            ),
            width: double.infinity,
            height: 150,
            fit: BoxFit.cover,
          ),
        ),
        const SizedBox(height: 8),
        Text('cacheWidth=$cacheWidth'),
      ],
    );
  }
}

int runExpensiveCalculation(int iterations) {
  int checksum = 0;
  for (int i = 1; i < iterations; i++) {
    checksum = (checksum + math.sqrt(i * 31).round() * i) & 0x3fffffff;
  }
  return checksum;
}
