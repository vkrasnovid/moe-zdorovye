import 'dart:io';
import 'package:flutter/material.dart';
import '../models/record.dart';
import '../utils/formatters.dart';
import '../services/file_service.dart';

class RecordListItem extends StatelessWidget {
  final MedicalRecord record;
  final VoidCallback onTap;
  final VoidCallback? onDelete;

  const RecordListItem({
    super.key,
    required this.record,
    required this.onTap,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final color = record.category.color;
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: color.withAlpha(25),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(record.category.icon, color: color, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      record.title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Icon(Icons.calendar_today_outlined,
                            size: 12, color: Colors.grey[500]),
                        const SizedBox(width: 4),
                        Text(
                          AppFormatters.formatDate(record.date),
                          style:
                              TextStyle(fontSize: 12, color: Colors.grey[500]),
                        ),
                        if (record.attachments.isNotEmpty) ...[
                          const SizedBox(width: 8),
                          Icon(Icons.attach_file,
                              size: 12, color: Colors.grey[500]),
                          Text(
                            '${record.attachments.length}',
                            style: TextStyle(
                                fontSize: 12, color: Colors.grey[500]),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              if (record.attachments.isNotEmpty) ...[
                const SizedBox(width: 8),
                _buildThumbnail(record.attachments.first),
              ],
              const SizedBox(width: 4),
              if (onDelete != null)
                IconButton(
                  icon: Icon(Icons.delete_outline,
                      color: Colors.grey[400], size: 20),
                  onPressed: onDelete,
                  padding: EdgeInsets.zero,
                  constraints:
                      const BoxConstraints(minWidth: 32, minHeight: 32),
                )
              else
                Icon(Icons.chevron_right, color: Colors.grey[400]),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildThumbnail(String path) {
    if (FileService.isImage(path)) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(6),
        child: Image.file(
          File(path),
          width: 40,
          height: 40,
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) => Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(Icons.image, size: 20, color: Colors.grey[400]),
          ),
        ),
      );
    } else if (FileService.isPdf(path)) {
      return Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Colors.red[50],
          borderRadius: BorderRadius.circular(6),
        ),
        child: Icon(Icons.picture_as_pdf, color: Colors.red[400], size: 20),
      );
    } else {
      return Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(6),
        ),
        child: Icon(Icons.insert_drive_file, color: Colors.grey[500], size: 20),
      );
    }
  }
}
