import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:file_picker/file_picker.dart';

// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html; 

class EventFormScreen extends StatefulWidget {
  final String? eventId;
  final Map<String, dynamic>? initialData;
  const EventFormScreen({
    Key? key,
    this.eventId,
    this.initialData,
  }) : super(key: key);

  @override
  State<EventFormScreen> createState() => _EventFormScreenState();
}

class _EventFormScreenState extends State<EventFormScreen> {
  final _titleCtl = TextEditingController();
  final _descCtl  = TextEditingController();
  DateTime? _start, _end;
  PlatformFile? _picked;
  bool _loading = false;
  double _progress = 0;

  @override
  void initState() {
    super.initState();
    if (widget.initialData != null) {
      final d = widget.initialData!;
      _titleCtl.text = d['title'] ?? '';
      _descCtl.text  = d['description'] ?? '';
      _start = DateTime.tryParse(d['startDate'] ?? '');
      _end   = DateTime.tryParse(d['endDate']   ?? '');
    }
  }

  Future<void> _pickDate(bool isStart) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: isStart ? (_start ?? now) : (_end ?? (_start ?? now)),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        if (isStart) _start = picked;
        else         _end   = picked;
      });
    }
  }

  Future<void> _pickImage() async {
    if (kIsWeb) {
      // Use dart:html APIs on the web
      final input = html.FileUploadInputElement()..accept = 'image/*';
      input.click();
      await input.onChange.first;
      final file = input.files?.first;
      if (file == null) return;

      final reader = html.FileReader();
      reader.readAsArrayBuffer(file);
      await reader.onLoad.first;

      final bytes = reader.result as Uint8List;
      setState(() {
        _picked = PlatformFile(name: file.name, size: file.size, bytes: bytes);
      });
    } else {
      // Native platforms: use file_picker
      final res = await FilePicker.platform.pickFiles(
        type: FileType.image,
        withData: true,
      );
      if (res != null && res.files.isNotEmpty) {
        setState(() => _picked = res.files.first);
      }
    }
  }

  Future<void> _save() async {
    final title = _titleCtl.text.trim();
    final desc  = _descCtl.text.trim();
    if (title.isEmpty || desc.isEmpty || _start == null || _end == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all fields')),
      );
      return;
    }

    setState(() {
      _loading = true;
      _progress = 0;
    });

    try {
      final coll = FirebaseFirestore.instance.collection('events');
      final docId = widget.eventId ?? coll.doc().id;

      // 1) Upsert the metadata
      await coll.doc(docId).set({
        'title':     title,
        'description': desc,
        'startDate': _start!.toIso8601String(),
        'endDate':   _end!.toIso8601String(),
        'createdAt': FieldValue.serverTimestamp(),
        'imageUrls': widget.initialData?['imageUrls'] ?? <String>[],
      }, SetOptions(merge: true));

      // 2) If a new image was picked, upload it
      if (_picked != null) {
        final ref = FirebaseStorage.instance
            .ref()
            .child('events/$docId/${_picked!.name}');
        final task = _picked!.bytes != null
            ? ref.putData(_picked!.bytes!)
            : ref.putFile(File(_picked!.path!));

        task.snapshotEvents.listen((snap) {
          setState(() {
            _progress = snap.bytesTransferred / snap.totalBytes;
          });
        });
        final snap = await task;
        final url = await snap.ref.getDownloadURL();

        // 3) Append the new URL to the event document
        await coll.doc(docId).update({
          'imageUrls': FieldValue.arrayUnion([url]),
        });
      }

      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Save failed: $e')),
      );
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.eventId != null;
    return Scaffold(
      appBar: AppBar(
        title: Text(isEdit ? 'Edit Event' : 'New Event'),
        backgroundColor: const Color(0xFF2E318F),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _titleCtl,
              decoration: const InputDecoration(labelText: 'Title'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _descCtl,
              decoration: const InputDecoration(labelText: 'Description'),
              maxLines: 3,
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Text(
                    _start == null
                        ? 'No start date chosen'
                        : 'Start: ${_start!.toLocal().toString().split(' ')[0]}',
                  ),
                ),
                TextButton(
                  onPressed: () => _pickDate(true),
                  child: const Text('Pick Start Date'),
                ),
              ],
            ),
            Row(
              children: [
                Expanded(
                  child: Text(
                    _end == null
                        ? 'No end date chosen'
                        : 'End:   ${_end!.toLocal().toString().split(' ')[0]}',
                  ),
                ),
                TextButton(
                  onPressed: _start == null ? null : () => _pickDate(false),
                  child: const Text('Pick End Date'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Text(_picked?.name ?? 'No image selected'),
                ),
                TextButton(
                  onPressed: _pickImage,
                  child: const Text('Pick Image'),
                ),
              ],
            ),
            if (_loading) ...[
              const SizedBox(height: 16),
              LinearProgressIndicator(value: _progress),
              Text('${(_progress * 100).toStringAsFixed(0)}%'),
            ],
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loading ? null : _save,
              style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
                backgroundColor: const Color(0xFF2E318F),
              ),
              child: Text(isEdit ? 'Save Changes' : 'Create Event'),
            ),
          ],
        ),
      ),
    );
  }
}