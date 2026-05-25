import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/widgets/crt_background.dart';

class NotePadScreen extends StatefulWidget {
  const NotePadScreen({super.key});

  @override
  State<NotePadScreen> createState() => _NotePadScreenState();
}

class _NotePadScreenState extends State<NotePadScreen>
    with SingleTickerProviderStateMixin {
  final _storageKey = 'flamingo_notes';
  List<Map<String, dynamic>> _notes = [];
  bool _loading = true;
  late AnimationController _fadeCtrl;

  int _idCounter = 0;
  int _nextId() => ++_idCounter;

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _loadNotes();
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadNotes() async {
    final prefs = await SharedPreferences.getInstance();
    final json = prefs.getString(_storageKey);
    if (json != null) {
      try {
        final data = jsonDecode(json) as List;
        setState(() => _notes = List<Map<String, dynamic>>.from(data));
        _idCounter = _notes.isNotEmpty
            ? (_notes.map((n) => n['id'] as int).reduce(math.max))
            : 0;
      } catch (_) {
        setState(() => _notes = []);
      }
    }
    setState(() => _loading = false);
    _fadeCtrl.forward();
  }

  Future<void> _saveNotes() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_storageKey, jsonEncode(_notes));
  }

  void _addNote() {
    setState(() {
      _notes.insert(0, {
        'id': _nextId(),
        'title': 'New Note',
        'body': '',
        'created': DateTime.now().toIso8601String(),
      });
      _saveNotes();
    });
  }

  void _deleteNote(int id) {
    setState(() {
      _notes.removeWhere((n) => n['id'] == id);
      _saveNotes();
    });
  }

  void _updateNote(int id, String field, dynamic value) {
    for (var note in _notes) {
      if (note['id'] == id) {
        note[field] = value;
        break;
      }
    }
    _saveNotes();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: cs.surface,
      body: CrtBackground(
        child: SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.note_alt_outlined, size: 14, color: cs.primary),
                  const SizedBox(width: 8),
                  Text(
                    'NOTE PAD',
                    style: TextStyle(
                      color: cs.onSurfaceVariant,
                      fontSize: 12,
                      letterSpacing: 4,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              if (_loading)
                Expanded(
                  child: Center(
                    child: CircularProgressIndicator(
                      color: cs.primary,
                      strokeWidth: 2,
                    ),
                  ),
                )
              else if (_notes.isEmpty)
                Expanded(
                  child: FadeTransition(
                    opacity: _fadeCtrl,
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              color: cs.primary.withValues(alpha: 0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.note_alt,
                              size: 36,
                              color: cs.primary.withValues(alpha: 0.5),
                            ),
                          ),
                          const SizedBox(height: 20),
                          Text(
                            'No notes yet',
                            style: TextStyle(
                              color: cs.onSurfaceVariant,
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Tap + to create your first note',
                            style: TextStyle(
                              color: cs.onSurfaceVariant.withValues(alpha: 0.6),
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 24),
                          _actionButton(
                            'CREATE NOTE',
                            Icons.add,
                            cs.primary,
                            _addNote,
                            cs,
                          ),
                        ],
                      ),
                    ),
                  ),
                )
              else
                Expanded(
                  child: FadeTransition(
                    opacity: _fadeCtrl,
                    child: ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _notes.length,
                      itemBuilder: (context, i) {
                        final note = _notes[i];
                        return _noteCard(note, cs);
                      },
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: cs.primary,
        foregroundColor: cs.onPrimary,
        elevation: 4,
        onPressed: _addNote,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _actionButton(
    String label,
    IconData icon,
    Color color,
    VoidCallback onTap,
    ColorScheme cs,
  ) {
    return Material(
      color: color.withValues(alpha: 0.15),
      surfaceTintColor: Colors.transparent,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 2,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _noteCard(Map<String, dynamic> note, ColorScheme cs) {
    final created = DateTime.tryParse(note['created'] as String? ?? '');
    final timeStr = created != null
        ? '${created.month}/${created.day} ${created.hour.toString().padLeft(2, '0')}:${created.minute.toString().padLeft(2, '0')}'
        : '';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: cs.primary.withValues(alpha: 0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            color: cs.surfaceContainerLow,
            border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.2)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header bar with accent line
              Container(
                height: 3,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      cs.primary.withValues(alpha: 0.6),
                      cs.secondary.withValues(alpha: 0.3),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 8, 0),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: TextEditingController(
                          text: note['title'] as String? ?? '',
                        ),
                        style: TextStyle(
                          color: cs.onSurface,
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Note title',
                          hintStyle: TextStyle(
                            color: cs.onSurfaceVariant.withValues(alpha: 0.5),
                          ),
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: EdgeInsets.zero,
                        ),
                        onChanged: (v) => _updateNote(note['id'], 'title', v),
                      ),
                    ),
                    if (timeStr.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: Text(
                          timeStr,
                          style: TextStyle(
                            color: cs.onSurfaceVariant.withValues(alpha: 0.5),
                            fontSize: 11,
                            fontFamily: 'monospace',
                          ),
                        ),
                      ),
                    IconButton(
                      icon: Icon(Icons.delete_outline, size: 20),
                      color: cs.onSurfaceVariant.withValues(alpha: 0.6),
                      onPressed: () => _deleteNote(note['id']),
                      splashRadius: 20,
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                child: TextField(
                  maxLines: null,
                  decoration: InputDecoration(
                    hintText: 'Type your note here...',
                    hintStyle: TextStyle(
                      color: cs.onSurfaceVariant.withValues(alpha: 0.4),
                      fontSize: 14,
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.only(top: 4),
                  ),
                  style: TextStyle(
                    color: cs.onSurface.withValues(alpha: 0.85),
                    fontSize: 14,
                    height: 1.5,
                  ),
                  onChanged: (v) => _updateNote(note['id'], 'body', v),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
