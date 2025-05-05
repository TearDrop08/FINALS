import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:file_picker/file_picker.dart';
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
  final _descCtl = TextEditingController();
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
      _descCtl.text = d['description'] ?? '';
      _start = DateTime.tryParse(d['startDate'] ?? '');
      _end = DateTime.tryParse(d['endDate'] ?? '');
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
        else _end = picked;
      });
    }
  }

  Future<void> _pickImage() async {
    if (kIsWeb) {
      final input = html.FileUploadInputElement()..accept = 'image/*';
      input.click();
      await input.onChange.first;
      final file = input.files?.first;
      if (file == null) return;
      final reader = html.FileReader();
      reader.readAsArrayBuffer(file);
      await reader.onLoad.first;
      final bytes = reader.result as Uint8List;
      setState(() => _picked = PlatformFile(name: file.name, size: file.size, bytes: bytes));
    } else {
      final res = await FilePicker.platform.pickFiles(type: FileType.image, withData: true);
      if (res != null && res.files.isNotEmpty) setState(() => _picked = res.files.first);
    }
  }

  Future<void> _save() async {
    final title = _titleCtl.text.trim();
    final desc = _descCtl.text.trim();
    if (title.isEmpty || desc.isEmpty || _start == null || _end == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please fill all fields')));
      return;
    }
    setState(() { _loading = true; _progress = 0; });
    try {
      final coll = FirebaseFirestore.instance.collection('events');
      final docId = widget.eventId ?? coll.doc().id;
      await coll.doc(docId).set({
        'title': title,
        'description': desc,
        'startDate': _start!.toIso8601String(),
        'endDate': _end!.toIso8601String(),
        'createdAt': FieldValue.serverTimestamp(),
        'imageUrls': widget.initialData?['imageUrls'] ?? <String>[],
      }, SetOptions(merge: true));
      if (_picked != null) {
        final ref = FirebaseStorage.instance.ref().child('events/$docId/${_picked!.name}');
        final task = _picked!.bytes != null ? ref.putData(_picked!.bytes!) : ref.putFile(File(_picked!.path!));
        task.snapshotEvents.listen((snap) => setState(() => _progress = snap.bytesTransferred / snap.totalBytes));
        final snap = await task; final url = await snap.ref.getDownloadURL();
        await coll.doc(docId).update({'imageUrls': FieldValue.arrayUnion([url])});
      }
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Save failed: \$e')));
    } finally { setState(() => _loading = false); }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.eventId != null;
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          color: Color(0xFF0B0C69), // Ateneo default
          image: DecorationImage(
            image: AssetImage('assets/bagobo_pattern.png'),
            repeat: ImageRepeat.repeat,
            fit: BoxFit.cover,
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Card(
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    AppBar(
                      title: Text(isEdit ? 'Edit Event' : 'New Event'),
                      backgroundColor: Colors.transparent,
                      elevation: 0,
                      centerTitle: true,
                    ),
                    const SizedBox(height: 16),
                    TextField(controller: _titleCtl, decoration: const InputDecoration(labelText: 'Title')),
                    const SizedBox(height: 16),
                    TextField(controller: _descCtl, decoration: const InputDecoration(labelText: 'Description'), maxLines: 4),
                    const SizedBox(height: 16),
                    const Text('Start Date'),
                    const SizedBox(height: 8),
                    ElevatedButton(onPressed: () => _pickDate(true), child: Text(_start == null ? 'Pick Start Date' : _start!.toLocal().toString().split(' ')[0])),
                    const SizedBox(height: 16),
                    const Text('End Date'),
                    const SizedBox(height: 8),
                    ElevatedButton(onPressed: _start == null ? null : () => _pickDate(false), child: Text(_end == null ? 'Pick End Date' : _end!.toLocal().toString().split(' ')[0])),
                    const SizedBox(height: 16),
                    const Text('Event Image'),
                    const SizedBox(height: 8),
                    if (_picked != null)
                      SizedBox(height: 150, child: kIsWeb ? Image.memory(_picked!.bytes!, fit: BoxFit.cover) : Image.file(File(_picked!.path!), fit: BoxFit.cover)),
                    const SizedBox(height: 8),
                    ElevatedButton(onPressed: _pickImage, child: const Text('Select Image')),
                    if (_loading) ...[
                      const SizedBox(height: 16),
                      LinearProgressIndicator(value: _progress),
                      const SizedBox(height: 8),
                      Text('\${(_progress * 100).toStringAsFixed(0)}%', textAlign: TextAlign.center),
                    ],
                    const Spacer(),
                    ElevatedButton(
                      onPressed: _loading ? null : _save,
                      style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(56), backgroundColor: const Color(0xFF0B0C69)),
                      child: Text(isEdit ? 'Save Changes' : 'Create Event'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
