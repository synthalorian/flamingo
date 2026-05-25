import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vibration/vibration.dart';
import 'package:audioplayers/audioplayers.dart';

import '../../core/widgets/crt_background.dart';
import '../../core/widgets/animated_background.dart';
import '../../core/utils/audio_generator.dart';

class _Alarm {
  String id;
  TimeOfDay time;
  bool enabled;
  List<int> repeatDays; // 0=Mon, 6=Sun
  String label;
  String ringtone; // 'default', 'gentle', 'alarm'

  _Alarm({
    required this.id,
    required this.time,
    this.enabled = true,
    this.repeatDays = const [],
    this.label = '',
    this.ringtone = 'default',
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'hour': time.hour,
    'minute': time.minute,
    'enabled': enabled,
    'repeatDays': repeatDays,
    'label': label,
    'ringtone': ringtone,
  };

  factory _Alarm.fromJson(Map<String, dynamic> json) => _Alarm(
    id: json['id'] as String,
    time: TimeOfDay(hour: json['hour'] as int, minute: json['minute'] as int),
    enabled: json['enabled'] as bool? ?? true,
    repeatDays: (json['repeatDays'] as List?)?.cast<int>() ?? [],
    label: json['label'] as String? ?? '',
    ringtone: json['ringtone'] as String? ?? 'default',
  );

  String get timeDisplay {
    final hour = time.hourOfPeriod;
    final amPm = time.period == DayPeriod.am ? 'AM' : 'PM';
    return '${hour == 0 ? 12 : hour}:${time.minute.toString().padLeft(2, '0')} $amPm';
  }

  String get repeatDisplay {
    if (repeatDays.isEmpty) return 'Once';
    if (repeatDays.length == 5 && !repeatDays.contains(6) && !repeatDays.contains(0)) return 'Weekdays';
    if (repeatDays.length == 7) return 'Every day';
    const names = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return repeatDays.map((d) => names[d.clamp(0, 6)]).join(' ');
  }
}

class _RingtoneInfo {
  final String id;
  final String name;
  final IconData icon;
  const _RingtoneInfo(this.id, this.name, this.icon);
}

const _ringtones = [
  _RingtoneInfo('default', 'Default', Icons.notifications),
  _RingtoneInfo('gentle', 'Gentle', Icons.music_note),
  _RingtoneInfo('alarm', 'Alarm', Icons.warning_amber),
];

class AlarmClockScreen extends StatefulWidget {
  const AlarmClockScreen({super.key});

  @override
  State<AlarmClockScreen> createState() => _AlarmClockScreenState();
}

class _AlarmClockScreenState extends State<AlarmClockScreen> {
  List<_Alarm> _alarms = [];
  bool _loading = true;

  Timer? _alarmChecker;

  @override
  void initState() {
    super.initState();
    _loadAlarms();
    _alarmChecker = Timer.periodic(const Duration(seconds: 15), (_) => _checkAlarms());
  }

  @override
  void dispose() {
    _alarmChecker?.cancel();
    super.dispose();
  }

  void _checkAlarms() {
    final now = DateTime.now();
    final currentMinute = now.hour * 60 + now.minute;
    final weekday = (now.weekday - 1) % 7; // 0=Mon

    for (final alarm in _alarms) {
      if (!alarm.enabled) continue;

      // Check repeat days (if any days selected, must match today)
      if (alarm.repeatDays.isNotEmpty && !alarm.repeatDays.contains(weekday)) continue;

      final alarmMinute = alarm.time.hour * 60 + alarm.time.minute;
      if (alarmMinute == currentMinute) {
        _onAlarmTriggered(alarm);
      }
    }
  }

  Future<void> _loadAlarms() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString('alarms');
    if (data != null) {
      final list = jsonDecode(data) as List;
      _alarms = list.map((e) => _Alarm.fromJson(e as Map<String, dynamic>)).toList();
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _saveAlarms() async {
    final prefs = await SharedPreferences.getInstance();
    final data = jsonEncode(_alarms.map((a) => a.toJson()).toList());
    await prefs.setString('alarms', data);
  }

  Future<void> _addAlarm() async {
    final result = await _showAlarmEditor();
    if (result != null) {
      setState(() => _alarms.add(result));
      await _saveAlarms();
    }
  }

  Future<void> _editAlarm(int index) async {
    final result = await _showAlarmEditor(existing: _alarms[index]);
    if (result != null) {
      setState(() => _alarms[index] = result);
      await _saveAlarms();
    }
  }

  Future<_Alarm?> _showAlarmEditor({_Alarm? existing}) async {
    var time = existing?.time ?? TimeOfDay(hour: 8, minute: 0);
    var label = existing?.label ?? '';
    var ringtone = existing?.ringtone ?? 'default';
    var repeatDays = List<int>.from(existing?.repeatDays ?? []);
    final isNew = existing == null;

    return showModalBottomSheet<_Alarm>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) {
          return Container(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(ctx).viewInsets.bottom,
            ),
            decoration: BoxDecoration(
              color: Theme.of(ctx).colorScheme.surface,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 12),
                Container(width: 36, height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  isNew ? 'New Alarm' : 'Edit Alarm',
                  style: TextStyle(
                    color: Theme.of(ctx).colorScheme.primary,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 24),

                // Time picker
                Text(
                  time.format(ctx),
                  style: const TextStyle(fontSize: 48, fontWeight: FontWeight.w200, fontFamily: 'monospace'),
                ),
                const SizedBox(height: 8),
                TextButton.icon(
                  onPressed: () async {
                    final picked = await showTimePicker(
                      context: ctx,
                      initialTime: time,
                    );
                    if (picked != null) setSheetState(() => time = picked);
                  },
                  icon: Icon(Icons.access_time, size: 16),
                  label: const Text('Change time'),
                ),

                const SizedBox(height: 16),

                // Label
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: TextField(
                    controller: TextEditingController(text: label),
                    decoration: InputDecoration(
                      hintText: 'Label (e.g., Wake up)',
                      hintStyle: TextStyle(color: Colors.white24),
                      filled: true,
                      fillColor: Colors.white.withValues(alpha: 0.05),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    ),
                    style: const TextStyle(color: Colors.white),
                    onChanged: (v) => label = v,
                  ),
                ),
                const SizedBox(height: 12),

                // Ringtone selector
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: DropdownButtonFormField<String>(
                    value: ringtone,
                    dropdownColor: const Color(0xFF1A1A2E),
                    decoration: InputDecoration(
                      labelText: 'Ringtone',
                      labelStyle: TextStyle(color: Colors.white38),
                      filled: true,
                      fillColor: Colors.white.withValues(alpha: 0.05),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    items: _ringtones.map((r) => DropdownMenuItem(
                      value: r.id,
                      child: Row(
                        children: [
                          Icon(r.icon, size: 18, color: Colors.white54),
                          const SizedBox(width: 8),
                          Text(r.name, style: const TextStyle(color: Colors.white)),
                        ],
                      ),
                    )).toList(),
                    onChanged: (v) {
                      if (v != null) setSheetState(() => ringtone = v);
                    },
                  ),
                ),
                const SizedBox(height: 12),

                // Repeat days
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Repeat', style: TextStyle(color: Colors.white38, fontSize: 12)),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: List.generate(7, (i) {
                          final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
                          final active = repeatDays.contains(i);
                          return GestureDetector(
                            onTap: () {
                              setSheetState(() {
                                if (active) repeatDays.remove(i);
                                else repeatDays.add(i);
                              });
                            },
                            child: Container(
                              width: 40, height: 40,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: active
                                    ? Theme.of(ctx).colorScheme.primary.withValues(alpha: 0.2)
                                    : Colors.white.withValues(alpha: 0.08),
                                border: Border.all(
                                  color: active
                                      ? Theme.of(ctx).colorScheme.primary.withValues(alpha: 0.5)
                                      : Colors.white.withValues(alpha: 0.1),
                                ),
                              ),
                              child: Center(
                                child: Text(
                                  days[i][0],
                                  style: TextStyle(
                                    color: active
                                        ? Theme.of(ctx).colorScheme.primary
                                        : Colors.white54,
                                    fontSize: 12,
                                    fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                                  ),
                                ),
                              ),
                            ),
                          );
                        }),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Save / Cancel
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextButton(
                          onPressed: () => Navigator.pop(ctx),
                          child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: ElevatedButton(
                          onPressed: () => Navigator.pop(ctx, _Alarm(
                            id: existing?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
                            time: time,
                            label: label,
                            ringtone: ringtone,
                            repeatDays: repeatDays,
                          )),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Theme.of(ctx).colorScheme.primary,
                            foregroundColor: Colors.black,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          child: Text(isNew ? 'Add Alarm' : 'Save', style: TextStyle(fontWeight: FontWeight.w700)),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _deleteAlarm(int index) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        title: const Text('Delete Alarm', style: TextStyle(color: Colors.white)),
        content: const Text('Are you sure?', style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete', style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
    if (confirm == true && mounted) {
      setState(() => _alarms.removeAt(index));
      await _saveAlarms();
    }
  }

  Future<void> _onAlarmTriggered(_Alarm alarm) async {
    // Disable the alarm so it doesn't re-fire this minute
    setState(() => alarm.enabled = false);
    _saveAlarms();

    if (!mounted) return;
    final cs = Theme.of(context).colorScheme;

    // Play ringtone
    final player = AudioPlayer();
    final bytes = switch (alarm.ringtone) {
      'gentle' => AudioGenerator.generateGentle(5),
      'alarm' => AudioGenerator.generateAlarm(5),
      _ => AudioGenerator.generateWhiteNoise(5),
    };
    await player.setSource(BytesSource(bytes));
    await player.setVolume(0.8);
    await player.setReleaseMode(ReleaseMode.loop);
    await player.resume();

    // Vibrate
    await Vibration.vibrate(duration: 500);

    if (!mounted) return;

    // Show alarm dialog
    final action = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.alarm, size: 48, color: cs.primary),
            const SizedBox(height: 12),
            Text(alarm.label.isNotEmpty ? alarm.label : 'Alarm', style: const TextStyle(
              color: Colors.white, fontSize: 22, fontWeight: FontWeight.w700,
            )),
            const SizedBox(height: 4),
            Text(alarm.timeDisplay, style: TextStyle(color: Colors.white54, fontSize: 14)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, 'snooze'),
            child: const Text('Snooze (5 min)'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, 'dismiss'),
            style: ElevatedButton.styleFrom(
              backgroundColor: cs.primary,
              foregroundColor: Colors.black,
            ),
            child: const Text('Dismiss'),
          ),
        ],
      ),
    );

    await player.stop();
    await player.dispose();

    if (action == 'snooze') {
      // Re-enable the alarm after snooze (schedules 5 min later)
      Future.delayed(const Duration(minutes: 5), () {
        if (mounted) {
          setState(() => alarm.enabled = true);
          _saveAlarms();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Snoozed for 5 minutes'), behavior: SnackBarBehavior.floating),
          );
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Scaffold(
      backgroundColor: cs.surface,
      body: CrtBackground(
        child: AnimatedBackground(
          particleCount: 2,
          colors: [cs.primary, cs.secondary],
          child: SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                  child: Row(
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('ALARM CLOCK', style: TextStyle(
                            color: cs.onSurfaceVariant, fontSize: 12, letterSpacing: 4,
                          )),
                          Text('${_alarms.length} alarm${_alarms.length == 1 ? '' : 's'}',
                            style: TextStyle(color: cs.onSurfaceVariant.withValues(alpha: 0.6), fontSize: 11),
                          ),
                        ],
                      ),
                      const Spacer(),
                      GestureDetector(
                        onTap: _addAlarm,
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: cs.primary.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: cs.primary.withValues(alpha: 0.3)),
                          ),
                          child: Icon(Icons.add_rounded, color: cs.primary, size: 22),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 8),

                // Alarm list
                Expanded(
                  child: _loading
                      ? const Center(child: CircularProgressIndicator())
                      : _alarms.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.alarm_add, size: 64, color: cs.onSurfaceVariant.withValues(alpha: 0.3)),
                                  const SizedBox(height: 12),
                                  Text('No alarms', style: TextStyle(color: cs.onSurfaceVariant, fontSize: 16)),
                                  const SizedBox(height: 4),
                                  Text('Tap + to add one', style: TextStyle(
                                    color: cs.onSurfaceVariant.withValues(alpha: 0.5), fontSize: 12,
                                  )),
                                ],
                              ),
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              itemCount: _alarms.length,
                              itemBuilder: (ctx, i) {
                                final alarm = _alarms[i];
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 8),
                                  child: GestureDetector(
                                    onTap: () => _editAlarm(i),
                                    child: AnimatedContainer(
                                      duration: const Duration(milliseconds: 200),
                                      padding: const EdgeInsets.all(16),
                                      decoration: BoxDecoration(
                                        color: alarm.enabled
                                            ? cs.surfaceContainerHigh.withValues(alpha: 0.5)
                                            : Colors.transparent,
                                        borderRadius: BorderRadius.circular(16),
                                        border: Border.all(
                                          color: alarm.enabled
                                              ? cs.primary.withValues(alpha: 0.15)
                                              : cs.outlineVariant.withValues(alpha: 0.08),
                                        ),
                                      ),
                                      child: Row(
                                        children: [
                                          // Time
                                          Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                alarm.timeDisplay,
                                                style: TextStyle(
                                                  color: alarm.enabled ? cs.onSurface : cs.onSurface.withValues(alpha: 0.4),
                                                  fontSize: 28,
                                                  fontWeight: FontWeight.w300,
                                                  fontFamily: 'monospace',
                                                ),
                                              ),
                                              const SizedBox(height: 2),
                                              Row(
                                                children: [
                                                  if (alarm.label.isNotEmpty) ...[
                                                    Text(alarm.label, style: TextStyle(
                                                      color: alarm.enabled ? cs.onSurfaceVariant : cs.onSurfaceVariant.withValues(alpha: 0.4),
                                                      fontSize: 12,
                                                    )),
                                                    const SizedBox(width: 8),
                                                  ],
                                                  Text(alarm.repeatDisplay, style: TextStyle(
                                                    color: alarm.enabled
                                                        ? cs.primary.withValues(alpha: 0.7)
                                                        : cs.onSurfaceVariant.withValues(alpha: 0.3),
                                                    fontSize: 11,
                                                  )),
                                                ],
                                              ),
                                            ],
                                          ),
                                          const Spacer(),
                                          // Toggle + delete
                                          Column(
                                            children: [
                                              Switch(
                                                value: alarm.enabled,
                                                activeColor: cs.primary,
                                                onChanged: (v) {
                                                  setState(() => alarm.enabled = v);
                                                  _saveAlarms();
                                                },
                                              ),
                                              GestureDetector(
                                                onTap: () => _deleteAlarm(i),
                                                child: Icon(Icons.delete_outline, size: 16,
                                                  color: cs.onSurfaceVariant.withValues(alpha: 0.3)),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
