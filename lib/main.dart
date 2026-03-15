import 'dart:async';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';

void main() {
  runApp(const WorkoutTimerApp());
}

class WorkoutTimerApp extends StatelessWidget {
  const WorkoutTimerApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Workout Timer',
      theme: ThemeData.dark(),
      home: const BuilderScreen(),
    );
  }
}

class WorkoutBlock {
  String type;
  int duration;
  int rounds;
  int work;
  int rest;

  WorkoutBlock({
    required this.type,
    this.duration = 60,
    this.rounds = 1,
    this.work = 20,
    this.rest = 10,
  });
}

class BuilderScreen extends StatefulWidget {
  const BuilderScreen({super.key});

  @override
  State<BuilderScreen> createState() => _BuilderScreenState();


}

class TimerReadyScreen extends StatelessWidget {
  final List<WorkoutBlock> blocks;

  const TimerReadyScreen({super.key, required this.blocks});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Timer Ready")),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const Text(
              "Workout Overview",
              style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),

            Expanded(
              child: ListView.builder(
                itemCount: blocks.length,
                itemBuilder: (context, i) {
                  final b = blocks[i];

                  String description = "";

                  if (b.type == "AMRAP") {
                    description = "${b.duration}s";
                  }

                  if (b.type == "For Time") {
                    description = "Count up";
                  }

                  if (b.type == "EMOM") {
                    description = "${b.rounds} rounds";
                  }

                  if (b.type == "TABATA") {
                    description =
                        "${b.work}s / ${b.rest}s x ${b.rounds}";
                  }

                  return ListTile(
                    title: Text("Block ${i + 1} - ${b.type}"),
                    subtitle: Text(description),
                  );
                },
              ),
            ),

            ElevatedButton(
              child: const Text("Tap to Start"),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => TimerScreen(blocks: blocks),
                  ),
                );
              },
            )
          ],
        ),
      ),
    );
  }
}

class _BuilderScreenState extends State<BuilderScreen> {
  void goToConfig(String type) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BlockConfigScreen(block: WorkoutBlock(type: type)),
      ),
    );
  }

  void goToMix() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const MixBuilderScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("WOD Timer")),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text("Select a Timer", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 32),
            ElevatedButton(onPressed: () => goToConfig("AMRAP"), child: const Text("AMRAP")),
            const SizedBox(height: 12),
            ElevatedButton(onPressed: () => goToConfig("For Time"), child: const Text("For Time")),
            const SizedBox(height: 12),
            ElevatedButton(onPressed: () => goToConfig("EMOM"), child: const Text("EMOM")),
            const SizedBox(height: 12),
            ElevatedButton(onPressed: () => goToConfig("TABATA"), child: const Text("TABATA")),
            const SizedBox(height: 12),
            ElevatedButton(onPressed: goToMix, child: const Text("Mix")),
          ],
        ),
      ),
    );
  }
}

class MixBuilderScreen extends StatefulWidget {
  const MixBuilderScreen({super.key});

  @override
  State<MixBuilderScreen> createState() => _MixBuilderScreenState();
}

class _MixBuilderScreenState extends State<MixBuilderScreen> {
    String? expandedPickerKey;
  final List<WorkoutBlock> blocks = [];

  void addBlock(String type) {
    setState(() {
      blocks.add(WorkoutBlock(type: type));
    });
  }

  void removeBlock(int index) {
    setState(() {
      blocks.removeAt(index);
    });
  }

  void startTimer() {
    if (blocks.isEmpty) return;
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => TimerScreen(blocks: blocks)),
    );
  }

  Widget buildBlockEditor(int index) {
    final block = blocks[index];
    String keyPrefix = 'block-$index';
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("Block ${index + 1} — ${block.type}",
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                IconButton(
                  icon: const Icon(Icons.delete_outline),
                  onPressed: () => removeBlock(index),
                ),
              ],
            ),
            if (block.type != "TABATA" && block.type != "For Time") ...[
              const SizedBox(height: 8),
              TappablePicker(
                values: durationValues,
                formatter: formatDuration,
                initialValue: block.duration,
                label: block.type == "Rest" ? "Rest Duration (sec)" : "Duration (sec)",
                onChanged: (val) { block.duration = val; },
                expanded: expandedPickerKey == '$keyPrefix-duration',
                onExpand: () {
                  setState(() {
                    expandedPickerKey = expandedPickerKey == '$keyPrefix-duration' ? null : '$keyPrefix-duration';
                  });
                },
              ),
            ],
            if (block.type == "EMOM") ...[
              const SizedBox(height: 8),
              TappablePicker(
                values: roundValues,
                initialValue: block.rounds,
                label: "Rounds",
                onChanged: (val) { block.rounds = val; },
                expanded: expandedPickerKey == '$keyPrefix-rounds',
                onExpand: () {
                  setState(() {
                    expandedPickerKey = expandedPickerKey == '$keyPrefix-rounds' ? null : '$keyPrefix-rounds';
                  });
                },
              ),
            ],
            if (block.type == "TABATA") ...[
              const SizedBox(height: 8),
              TappablePicker(
                values: durationValues,
                formatter: formatDuration,
                initialValue: block.work,
                label: "Work (sec)",
                onChanged: (val) { block.work = val; },
                expanded: expandedPickerKey == '$keyPrefix-work',
                onExpand: () {
                  setState(() {
                    expandedPickerKey = expandedPickerKey == '$keyPrefix-work' ? null : '$keyPrefix-work';
                  });
                },
              ),
              const SizedBox(height: 8),
              TappablePicker(
                values: durationValues,
                formatter: formatDuration,
                initialValue: block.rest,
                label: "Rest (sec)",
                onChanged: (val) { block.rest = val; },
                expanded: expandedPickerKey == '$keyPrefix-rest',
                onExpand: () {
                  setState(() {
                    expandedPickerKey = expandedPickerKey == '$keyPrefix-rest' ? null : '$keyPrefix-rest';
                  });
                },
              ),
              const SizedBox(height: 8),
              TappablePicker(
                values: roundValues,
                initialValue: block.rounds,
                label: "Rounds",
                onChanged: (val) { block.rounds = val; },
                expanded: expandedPickerKey == '$keyPrefix-rounds',
                onExpand: () {
                  setState(() {
                    expandedPickerKey = expandedPickerKey == '$keyPrefix-rounds' ? null : '$keyPrefix-rounds';
                  });
                },
              ),
            ],
            if (block.type == "For Time")
              const Padding(
                padding: EdgeInsets.only(top: 8),
                child: Text("Count-up timer — tap Done when finished.",
                    style: TextStyle(color: Colors.white70)),
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Mix")),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              children: [
                ...blocks.asMap().entries.map((e) => buildBlockEditor(e.key)),
                const SizedBox(height: 16),
                Center(
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    alignment: WrapAlignment.center,
                    children: [
                      for (final type in ["AMRAP", "For Time", "EMOM", "TABATA", "Rest"])
                        OutlinedButton(
                          onPressed: () => addBlock(type),
                          child: Text("+ $type"),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: blocks.isEmpty ? null : startTimer,
                style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
                child: const Text("Start Timer", style: TextStyle(fontSize: 18)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}


// Add an enum to identify pickers (must be top-level in Dart)
enum PickerType { duration, rounds, work, rest }

class BlockConfigScreen extends StatefulWidget {
  final WorkoutBlock block;

  const BlockConfigScreen({super.key, required this.block});

  @override
  State<BlockConfigScreen> createState() => _BlockConfigScreenState();
}

class _BlockConfigScreenState extends State<BlockConfigScreen> {
  PickerType? expandedPicker;
  late WorkoutBlock block;

  @override
  void initState() {
    super.initState();
    block = widget.block;
  }

  void startTimer() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => TimerScreen(blocks: [block]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(block.type)),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (block.type != "TABATA" && block.type != "For Time") ...[
              TappablePicker(
                values: durationValues,
                formatter: formatDuration,
                initialValue: block.duration,
                label: "Duration (sec)",
                onChanged: (val) { block.duration = val; },
                expanded: expandedPicker == PickerType.duration,
                onExpand: () {
                  setState(() {
                    expandedPicker = expandedPicker == PickerType.duration ? null : PickerType.duration;
                  });
                },
              ),
              const SizedBox(height: 24),
            ],
            if (block.type == "EMOM") ...[
              TappablePicker(
                values: roundValues,
                initialValue: block.rounds,
                label: "Rounds",
                onChanged: (val) { block.rounds = val; },
                expanded: expandedPicker == PickerType.rounds,
                onExpand: () {
                  setState(() {
                    expandedPicker = expandedPicker == PickerType.rounds ? null : PickerType.rounds;
                  });
                },
              ),
              const SizedBox(height: 24),
            ],
            if (block.type == "TABATA") ...[
              TappablePicker(
                values: durationValues,
                formatter: formatDuration,
                initialValue: block.work,
                label: "Work (sec)",
                onChanged: (val) { block.work = val; },
                expanded: expandedPicker == PickerType.work,
                onExpand: () {
                  setState(() {
                    expandedPicker = expandedPicker == PickerType.work ? null : PickerType.work;
                  });
                },
              ),
              const SizedBox(height: 16),
              TappablePicker(
                values: durationValues,
                formatter: formatDuration,
                initialValue: block.rest,
                label: "Rest (sec)",
                onChanged: (val) { block.rest = val; },
                expanded: expandedPicker == PickerType.rest,
                onExpand: () {
                  setState(() {
                    expandedPicker = expandedPicker == PickerType.rest ? null : PickerType.rest;
                  });
                },
              ),
              const SizedBox(height: 16),
              TappablePicker(
                values: roundValues,
                initialValue: block.rounds,
                label: "Rounds",
                onChanged: (val) { block.rounds = val; },
                expanded: expandedPicker == PickerType.rounds,
                onExpand: () {
                  setState(() {
                    expandedPicker = expandedPicker == PickerType.rounds ? null : PickerType.rounds;
                  });
                },
              ),
              const SizedBox(height: 24),
            ],
            if (block.type == "For Time")
              const Text(
                "Count-up timer — tap Done when you finish.",
                style: TextStyle(fontSize: 16, color: Colors.white70),
              ),
            const Spacer(),
            ElevatedButton(
              onPressed: startTimer,
              style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
              child: const Text("Start Timer", style: TextStyle(fontSize: 18)),
            ),
          ],
        ),
      ),
    );
  }
}

List<int> get durationValues {
  final values = <int>[];
  for (int i = 5; i <= 60; i += 5) { values.add(i); }
  for (int i = 70; i <= 600; i += 10) { values.add(i); }
  return values;
}

List<int> get roundValues => List.generate(30, (i) => i + 1);

String formatDuration(int sec) {
  if (sec <= 60) return '${sec}s';
  final m = sec ~/ 60;
  final s = sec % 60;
  return s == 0 ? '${m}m' : '${m}m ${s}s';
}

class TappablePicker extends StatefulWidget {
    final bool expanded;
    final VoidCallback? onExpand;
  final List<int> values;
  final int initialValue;
  final String label;
  final String suffix;
  final String Function(int)? formatter;
  final void Function(int) onChanged;

  const TappablePicker({
    super.key,
    required this.values,
    required this.initialValue,
    required this.label,
    this.suffix = '',
    this.formatter,
    required this.onChanged,
    this.expanded = false,
    this.onExpand,
  });

  @override
  State<TappablePicker> createState() => _TappablePickerState();
}

class _TappablePickerState extends State<TappablePicker> {
    Timer? _collapseTimer;
  // _expanded is now controlled by parent
  late int _current;
  late int _selectedIndex;
  late final FixedExtentScrollController _controller;

  @override
  void initState() {
    super.initState();
    _current = widget.initialValue;
    final idx = widget.values.indexOf(_current);
    _selectedIndex = idx >= 0 ? idx : 0;
    _controller = FixedExtentScrollController(initialItem: _selectedIndex);
    // Sync parent with the actual initial value immediately
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.onChanged(widget.values[_selectedIndex]);
    });
  }

  @override
  void dispose() {
    _collapseTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        GestureDetector(
          onTap: widget.onExpand,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.white10,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                Text(widget.label, style: const TextStyle(fontSize: 13, color: Colors.white70)),
                const SizedBox(height: 4),
                Text(
                  widget.formatter != null ? widget.formatter!(_current) : '$_current${widget.suffix.isNotEmpty ? ' ${widget.suffix}' : ''}',
                  style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
        if (widget.expanded)
          Container(
            height: 200,
            margin: const EdgeInsets.only(top: 4),
            decoration: BoxDecoration(
              color: Colors.white10,
              borderRadius: BorderRadius.circular(12),
            ),
            child: NotificationListener<ScrollEndNotification>(
              onNotification: (_) {
                // Cancel any previous timer and start a new one
                _collapseTimer?.cancel();
                _collapseTimer = Timer(const Duration(seconds: 1), () {
                  if (mounted && widget.expanded && widget.onExpand != null) {
                    widget.onExpand!();
                    widget.onChanged(widget.values[_selectedIndex]);
                  }
                });
                return false;
              },
              child: ListWheelScrollView.useDelegate(
                controller: _controller,
                itemExtent: 56,
                physics: const FixedExtentScrollPhysics(),
                overAndUnderCenterOpacity: 1.0,
                onSelectedItemChanged: (i) {
                  setState(() {
                    _current = widget.values[i];
                    _selectedIndex = i;
                  });
                  // Cancel any existing collapse timer
                  _collapseTimer?.cancel();
                },
                childDelegate: ListWheelChildBuilderDelegate(
                  childCount: widget.values.length,
                  builder: (context, i) {
                    final dist = (i - _selectedIndex).abs();
                    final opacity = dist == 0 ? 1.0 : dist == 1 ? 0.55 : dist == 2 ? 0.3 : 0.15;
                    final fontSize = dist == 0 ? 28.0 : dist == 1 ? 21.0 : dist == 2 ? 17.0 : 14.0;
                    final weight = dist == 0 ? FontWeight.bold : FontWeight.normal;
                    return Center(
                      child: Text(
                        widget.formatter != null ? widget.formatter!(widget.values[i]) : '${widget.values[i]}${widget.suffix.isNotEmpty ? ' ${widget.suffix}' : ''}',
                        style: TextStyle(
                          fontSize: fontSize,
                          fontWeight: weight,
                          color: Colors.white.withValues(alpha: opacity),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class TimerScreen extends StatefulWidget {
  final List<WorkoutBlock> blocks;

  const TimerScreen({super.key, required this.blocks});

  @override
  State<TimerScreen> createState() => _TimerScreenState();
}

class _TimerScreenState extends State<TimerScreen> {
    void nextPhase() {
      playBeep();
      if (currentBlock == null) return;
      WorkoutBlock block = currentBlock!;

      if (block.type == "AMRAP" || block.type == "Rest") {
        nextBlock();
        return;
      }

      if (block.type == "EMOM") {
        round++;
        if (round > block.rounds) {
          nextBlock();
        } else {
          seconds = block.duration;
        }
      }

      if (block.type == "TABATA") {
        if (workPhase) {
          seconds = block.rest;
          workPhase = false;
        } else {
          round++;
          if (round > block.rounds) {
            // Only end workout if this is the last block
            if (blockIndex >= widget.blocks.length - 1) {
              nextBlock();
            } else {
              // Go to next block as usual
              timer?.cancel();
              blockIndex++;
              startBlock();
            }
            return;
          }
          seconds = block.work;
          workPhase = true;
        }
      }
    }
  int blockIndex = 0;
  int seconds = 0;
  int round = 1;
  bool workPhase = true;
  bool prepPhase = true;
  int prepSeconds = 10;
  bool paused = false;

  Timer? timer;
  final player = AudioPlayer();

  WorkoutBlock? get currentBlock =>
      (widget.blocks.isNotEmpty && blockIndex < widget.blocks.length)
          ? widget.blocks[blockIndex]
          : null;

  void startPrepCountdown() {
    prepPhase = true;
    prepSeconds = 10;

    timer = Timer.periodic(const Duration(seconds: 1), (t) {
      setState(() {
        prepSeconds--;

        if (prepSeconds <= 3) {
          playBeep();
        }
        
        if (prepSeconds <= 0) {
          timer?.cancel();
          prepPhase = false;
          startBlock();
        }
      });
    });
  }

  void playBeep() async {
    await player.play(AssetSource('beep.mp3'));
  }

  void startBlock() {
    if (currentBlock == null) return;
    WorkoutBlock block = currentBlock!;

        if (block.type == "AMRAP" || block.type == "Rest") {
          seconds = block.duration;
        }

    if (block.type == "For Time") {
      seconds = 0;
    }

    if (block.type == "EMOM") {
      seconds = block.duration;
      round = 1;
    }

    if (block.type == "TABATA") {
          seconds = block.work; // Ensure latest work value
      round = 1;
      workPhase = true;
    }

    timer = Timer.periodic(const Duration(seconds: 1), (t) {
      setState(() {
        if (!paused) {
          if (currentBlock!.type == "For Time") {
            seconds++;
          } else {
            seconds--;
          }
        }
        if (seconds > 0 && seconds <= 3 && currentBlock!.type != "For Time") playBeep();
        if (seconds <= 0 && currentBlock!.type != "For Time") nextPhase();
      });
    });
  }

  void nextBlock() {
    timer?.cancel();
    blockIndex++;

    if (blockIndex >= widget.blocks.length) {

      playBeep();

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => const WorkoutCompleteScreen(),
        ),
      );

      return;
    }

    startBlock();
  }

  String formatTime(int sec) {
    int min = sec ~/ 60;
    int rem = sec % 60;

    return "${min.toString().padLeft(2, '0')}:${rem.toString().padLeft(2, '0')}";
  }

 @override
  void initState() {
    super.initState();
    startPrepCountdown();
  }

        // (removed misplaced code)

  @override
  Widget build(BuildContext context) {
    if (currentBlock == null) {
      return Scaffold(
        appBar: AppBar(title: const Text("No Blocks")),
        body: const Center(
          child: Text(
            "No workout blocks to display. Please add at least one block.",
            style: TextStyle(fontSize: 20),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    String phase = "";
    if (currentBlock!.type == "TABATA") {
      phase = workPhase ? "WORK" : "REST";
    }

    return Scaffold(
      appBar: AppBar(title: Text("Block ${blockIndex + 1}")),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              currentBlock!.type,
              style: const TextStyle(fontSize: 28),
            ),
            const SizedBox(height: 20),
            Text(
              prepPhase ? prepSeconds.toString() : formatTime(seconds),
              style: const TextStyle(
                fontSize: 80,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (prepPhase)
              const Text(
                "GET READY",
                style: TextStyle(fontSize: 28),
              ),
            const SizedBox(height: 20),
            Text("Round $round"),
            const SizedBox(height: 10),
            Text(phase),
            const SizedBox(height: 40),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  ElevatedButton(
                    onPressed: () => setState(() => paused = !paused),
                    child: Text(paused ? "Resume" : "Pause"),
                  ),
                  if (!prepPhase && currentBlock!.type == "For Time")
                    ElevatedButton(
                      onPressed: nextBlock,
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                      child: const Text("Done"),
                    ),
                  ElevatedButton(
                    onPressed: () {
                      timer?.cancel();
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (_) => const WorkoutCompleteScreen()),
                      );
                    },
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                    child: const Text("End"),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
class WorkoutCompleteScreen extends StatelessWidget {
  const WorkoutCompleteScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Workout Complete")),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              "Workout Complete!",
              style: TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 30),
            const Icon(
              Icons.emoji_events,
              size: 80,
            ),
            const SizedBox(height: 40),
            ElevatedButton(
              child: const Text("New Workout"),
              onPressed: () {
                Navigator.popUntil(context, (route) => route.isFirst);
              },
            ),
          ],
        ),
      ),
    );
    
  }
}