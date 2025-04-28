import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:file_picker/file_picker.dart';

// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

class OrganizationFormScreen extends StatefulWidget {
  final String? orgId;
  final Map<String, dynamic>? initialData;

  const OrganizationFormScreen({
    Key? key,
    this.orgId,
    this.initialData,
  }) : super(key: key);

  @override
  State<OrganizationFormScreen> createState() => _OrganizationFormScreenState();
}

class _OrganizationFormScreenState extends State<OrganizationFormScreen> {
  final _nameCtl = TextEditingController();
  final _descCtl = TextEditingController();
  String? _initialBannerUrl;
  PlatformFile? _pickedFile;

  bool _loading = false;
  double _progress = 0.0;

  @override
  void initState() {
    super.initState();
    if (widget.initialData != null) {
      final d = widget.initialData!;
      _nameCtl.text = d['name'] ?? '';
      _descCtl.text = d['description'] ?? '';
      _initialBannerUrl = d['banner'] as String?;
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
      setState(() {
        _pickedFile = PlatformFile(
          name: file.name,
          size: file.size,
          bytes: bytes,
        );
      });
    } else {
      final res = await FilePicker.platform.pickFiles(
        type: FileType.image,
        withData: true,
      );
      if (res != null && res.files.isNotEmpty) {
        setState(() {
          _pickedFile = res.files.first;
        });
      }
    }
  }

  Future<void> _save() async {
    final name = _nameCtl.text.trim();
    final desc = _descCtl.text.trim();
    if (name.isEmpty || desc.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill name and description')),
      );
      return;
    }

    setState(() {
      _loading = true;
      _progress = 0.0;
    });

    try {
      final coll = FirebaseFirestore.instance.collection('organizations');
      final docId = widget.orgId ?? coll.doc().id;

      // 1) Upsert metadata (without banner)
      await coll.doc(docId).set({
        'name':        name,
        'description': desc,
        'createdAt':   FieldValue.serverTimestamp(),
        if (widget.initialData?['banner'] != null)
          'banner': widget.initialData!['banner'],
      }, SetOptions(merge: true));

      // 2) Upload new banner if picked
      if (_pickedFile != null) {
        final ref = FirebaseStorage.instance
            .ref('organizations/$docId/${_pickedFile!.name}');
        final task = _pickedFile!.bytes != null
            ? ref.putData(_pickedFile!.bytes!)
            : ref.putFile(File(_pickedFile!.path!));

        task.snapshotEvents.listen((snap) {
          setState(() {
            _progress = snap.bytesTransferred / snap.totalBytes;
          });
        });
        final snap = await task;
        final url = await snap.ref.getDownloadURL();

        // 3) Write banner URL into the doc
        await coll.doc(docId).update({'banner': url});
      }

      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed: $e')),
      );
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.orgId != null;
    return Scaffold(
      appBar: AppBar(
        title: Text(isEdit ? 'Edit Organization' : 'New Organization'),
        backgroundColor: const Color(0xFF2E318F),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _nameCtl,
              decoration: const InputDecoration(labelText: 'Name'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _descCtl,
              decoration: const InputDecoration(labelText: 'Description'),
              maxLines: 3,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Text(
                    _pickedFile?.name ??
                        _initialBannerUrl?.split('/').last ??
                        'No banner selected',
                  ),
                ),
                TextButton(
                  onPressed: _pickImage,
                  child: const Text('Pick Banner'),
                ),
              ],
            ),
            if (_loading) ...[
              const SizedBox(height: 16),
              LinearProgressIndicator(value: _progress),
              Text('${(_progress * 100).toStringAsFixed(0)}%'),
            ],
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _loading ? null : _save,
              style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
                backgroundColor: const Color(0xFF2E318F),
              ),
              child: Text(isEdit
                  ? 'Save Changes'
                  : 'Create Organization'),
            ),
          ],
        ),
      ),
    );
  }
}