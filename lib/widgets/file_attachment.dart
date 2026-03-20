import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:photo_view/photo_view.dart';
import 'package:share_plus/share_plus.dart';
import '../services/file_service.dart';

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
    if (editable) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (paths.isNotEmpty)
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: paths
                  .map((path) => _AttachmentChip(
                        path: path,
                        onRemove:
                            onRemove != null ? () => onRemove!(path) : null,
                      ))
                  .toList(),
            ),
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: OutlinedButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.attach_file, size: 18),
              label: const Text('Прикрепить файл'),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF00897B),
                side: const BorderSide(color: Color(0xFF00897B)),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ),
        ],
      );
    } else {
      if (paths.isEmpty) {
        return const Padding(
          padding: EdgeInsets.symmetric(vertical: 8),
          child: Text('Нет вложений',
              style: TextStyle(color: Colors.grey, fontSize: 14)),
        );
      }
      return Column(
        children: paths
            .map((path) => _AttachmentListTile(
                  path: path,
                  onRemove: onRemove != null ? () => onRemove!(path) : null,
                ))
            .toList(),
      );
    }
  }
}

class _AttachmentChip extends StatelessWidget {
  final String path;
  final VoidCallback? onRemove;

  const _AttachmentChip({required this.path, this.onRemove});

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
              child: FileService.isImage(path)
                  ? Image.file(
                      File(path),
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => _fileIcon(),
                    )
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
        FileService.isPdf(path) ? Icons.picture_as_pdf : Icons.insert_drive_file,
        color: FileService.isPdf(path) ? Colors.red[400] : Colors.grey[500],
        size: 30,
      ),
    );
  }

  void _openFile(BuildContext context) {
    if (FileService.isImage(path)) {
      Navigator.push(
          context, MaterialPageRoute(builder: (_) => _ImageViewer(path: path)));
    } else if (FileService.isPdf(path)) {
      Navigator.push(
          context, MaterialPageRoute(builder: (_) => _PdfViewer(path: path)));
    }
  }
}

class _AttachmentListTile extends StatelessWidget {
  final String path;
  final VoidCallback? onRemove;

  const _AttachmentListTile({required this.path, this.onRemove});

  String _formatSize(int bytes) {
    if (bytes < 1024) return '$bytes Б';
    if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} КБ';
    }
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} МБ';
  }

  String get _sizeStr {
    try {
      final f = File(path);
      if (f.existsSync()) return _formatSize(f.lengthSync());
    } catch (_) {}
    return '';
  }

  String get _typeStr {
    if (!path.contains('.')) return '?';
    return path.split('.').last.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        leading: _buildThumbnail(),
        title: Text(
          FileService.fileName(path),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
        ),
        subtitle: Text(
          '$_typeStr${_sizeStr.isNotEmpty ? " • $_sizeStr" : ""}',
          style: TextStyle(fontSize: 11, color: Colors.grey[500]),
        ),
        onTap: () => _openFile(context),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: Icon(Icons.share_outlined, size: 20, color: Colors.grey[600]),
              onPressed: () => Share.shareXFiles([XFile(path)]),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
            ),
            if (onRemove != null)
              IconButton(
                icon: Icon(Icons.delete_outline,
                    size: 20, color: Colors.red[400]),
                onPressed: onRemove,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildThumbnail() {
    if (FileService.isImage(path)) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(6),
        child: Image.file(
          File(path),
          width: 48,
          height: 48,
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) => Container(
            width: 48,
            height: 48,
            color: Colors.grey[200],
            child: const Icon(Icons.image_not_supported, size: 24),
          ),
        ),
      );
    } else if (FileService.isPdf(path)) {
      return Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: Colors.red[50],
          borderRadius: BorderRadius.circular(6),
        ),
        child: Icon(Icons.picture_as_pdf, color: Colors.red[400], size: 28),
      );
    } else {
      return Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(6),
        ),
        child: Icon(Icons.insert_drive_file, color: Colors.grey[500], size: 28),
      );
    }
  }

  void _openFile(BuildContext context) {
    if (FileService.isImage(path)) {
      Navigator.push(
          context, MaterialPageRoute(builder: (_) => _ImageViewer(path: path)));
    } else if (FileService.isPdf(path)) {
      Navigator.push(
          context, MaterialPageRoute(builder: (_) => _PdfViewer(path: path)));
    }
  }
}

class _ImageViewer extends StatefulWidget {
  final String path;
  const _ImageViewer({required this.path});

  @override
  State<_ImageViewer> createState() => _ImageViewerState();
}

class _ImageViewerState extends State<_ImageViewer> {
  double _verticalOffset = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: const Text('Просмотр'),
      ),
      body: GestureDetector(
        onVerticalDragUpdate: (details) {
          setState(() => _verticalOffset += details.delta.dy);
        },
        onVerticalDragEnd: (details) {
          if (_verticalOffset.abs() > 100 ||
              details.velocity.pixelsPerSecond.dy.abs() > 400) {
            Navigator.pop(context);
          } else {
            setState(() => _verticalOffset = 0);
          }
        },
        child: Transform.translate(
          offset: Offset(0, _verticalOffset),
          child: PhotoView(
            imageProvider: FileImage(File(widget.path)),
            minScale: PhotoViewComputedScale.contained,
            maxScale: PhotoViewComputedScale.covered * 3,
          ),
        ),
      ),
    );
  }
}

class _PdfViewer extends StatefulWidget {
  final String path;
  const _PdfViewer({required this.path});

  @override
  State<_PdfViewer> createState() => _PdfViewerState();
}

class _PdfViewerState extends State<_PdfViewer> {
  int _currentPage = 0;
  int _totalPages = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[900],
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text(
          _totalPages > 0
              ? 'Страница ${_currentPage + 1} из $_totalPages'
              : 'PDF',
        ),
      ),
      body: PDFView(
        filePath: widget.path,
        enableSwipe: true,
        swipeHorizontal: false,
        autoSpacing: true,
        pageFling: true,
        onRender: (pages) {
          if (mounted) setState(() => _totalPages = pages ?? 0);
        },
        onPageChanged: (page, total) {
          if (mounted) {
            setState(() {
              _currentPage = page ?? 0;
              if (total != null) _totalPages = total;
            });
          }
        },
        onError: (error) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Ошибка открытия PDF: $error')),
            );
          }
        },
      ),
    );
  }
}
