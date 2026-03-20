import 'dart:io';
import 'package:flutter/material.dart';
import 'package:photo_view/photo_view.dart';

class FileAttachmentList extends StatelessWidget {
  final List<String> paths;
  final bool editable;
  final VoidCallback? onAdd;
  final Function(String)? onRemove;

  const FileAttachmentList({
    super.key,
    required this.paths,
    this.editable = false,
    this.onAdd,
    this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (paths.isEmpty && !editable)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Text('Нет вложений', style: TextStyle(color: Colors.grey, fontSize: 14)),
          ),
        if (paths.isNotEmpty)
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ...paths.map((path) => _AttachmentChip(
                    path: path,
                    onRemove: editable && onRemove != null ? () => onRemove!(path) : null,
                  )),
            ],
          ),
        if (editable)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: OutlinedButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.attach_file, size: 18),
              label: const Text('Прикрепить файл'),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF00897B),
                side: const BorderSide(color: Color(0xFF00897B)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ),
      ],
    );
  }
}

class _AttachmentChip extends StatelessWidget {
  final String path;
  final VoidCallback? onRemove;

  const _AttachmentChip({required this.path, this.onRemove});

  bool get _isImage {
    final lower = path.toLowerCase();
    return lower.endsWith('.jpg') ||
        lower.endsWith('.jpeg') ||
        lower.endsWith('.png') ||
        lower.endsWith('.gif') ||
        lower.endsWith('.webp');
  }

  bool get _isPdf => path.toLowerCase().endsWith('.pdf');

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _openFile(context),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: _isImage
                  ? Image.file(File(path), fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _fileIcon())
                  : _fileIcon(),
            ),
          ),
          if (onRemove != null)
            Positioned(
              top: -6,
              right: -6,
              child: GestureDetector(
                onTap: onRemove,
                child: Container(
                  width: 20,
                  height: 20,
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.close, size: 12, color: Colors.white),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _fileIcon() {
    return Center(
      child: Icon(
        _isPdf ? Icons.picture_as_pdf : Icons.insert_drive_file,
        color: _isPdf ? Colors.red[400] : Colors.grey[500],
        size: 30,
      ),
    );
  }

  void _openFile(BuildContext context) {
    if (_isImage) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => _ImageViewer(path: path),
        ),
      );
    }
  }
}

class _ImageViewer extends StatelessWidget {
  final String path;
  const _ImageViewer({required this.path});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: const Text('Просмотр'),
      ),
      body: PhotoView(
        imageProvider: FileImage(File(path)),
        minScale: PhotoViewComputedScale.contained,
        maxScale: PhotoViewComputedScale.covered * 3,
      ),
    );
  }
}
