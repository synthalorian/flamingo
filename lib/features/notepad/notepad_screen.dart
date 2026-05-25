import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/theme/flamingo_theme.dart';
import '../../core/widgets/crt_background.dart';

class NotePadScreen extends StatefulWidget {
  const NotePadScreen({super.key});

  @override
  State<NotePadScreen> createState() => _NotePadScreenState();
}

class _NotePadScreenState extends State<NotePadScreen> {
  final _storageKey = 'flamingo_notes';
  List<Map<String, dynamic>> _notes = [];
  bool _loading = true;

  int _idCounter = 0;
  int _nextId() => ++_idCounter;

  @override
  void initState() {
    super.initState();
    _loadNotes();
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
    return Scaffold(
      backgroundColor: FlamingoColors.scaffoldBg,
      body: CrtBackground(
        child: SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 24),
              Text('NOTE PAD',
                  style: TextStyle(color: FlamingoColors.muted, fontSize: 12, letterSpacing: 4)),
              const SizedBox(height: 16),

              if (_loading)
                Expanded(child: Center(child: CircularProgressIndicator(color: FlamingoColors.primary)))
              else if (_notes.isEmpty)
                Expanded(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.note_alt, size: 64, color: FlamingoColors.muted),
                        const SizedBox(height: 16),
                        Text('No notes yet', style: TextStyle(color: FlamingoColors.muted)),
                        const SizedBox(height: 8),
                        Material(
                          color: FlamingoColors.primary.withValues(alpha: 0.15),
                          surfaceTintColor: Colors.transparent,
                          borderRadius: BorderRadius.circular(16),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(16),
                            onTap: _addNote,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                              child: Text('ADD NOTE',
                                  style: TextStyle(color: FlamingoColors.primary, fontWeight: FontWeight.w600, letterSpacing: 2)),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _notes.length,
                    itemBuilder: (context, i) {
                      final note = _notes[i];
                      return _noteCard(note);
                    },
                  ),
                ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: FlamingoColors.primary.withValues(alpha: 0.2),
        foregroundColor: FlamingoColors.primary,
        onPressed: _addNote,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _noteCard(Map<String, dynamic> note) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: Card(
        color: FlamingoColors.card,
        surfaceTintColor: Colors.transparent,
        child: Column(
          children: [
            ListTile(
              title: Text(note['title'] as String,
                  style: TextStyle(color: FlamingoColors.text, fontWeight: FontWeight.w600)),
              subtitle: Text('Created: ${note['created']}',
                  style: TextStyle(color: FlamingoColors.muted)),
              trailing: IconButton(
                icon: const Icon(Icons.delete, size: 20),
                color: FlamingoColors.muted,
                onPressed: () => _deleteNote(note['id']),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: TextField(
                maxLines: null,
                decoration: InputDecoration(
                  hintText: 'Type your note here...',
                  hintStyle: TextStyle(color: FlamingoColors.muted),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.all(8),
                ),
                style: TextStyle(color: FlamingoColors.text),
                onSubmitted: (v) => _updateNote(note['id'], 'body', v),
                onChanged: (v) => _updateNote(note['id'], 'body', v),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
