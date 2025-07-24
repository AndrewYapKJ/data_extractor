import 'dart:io';

enum FileType { image, pdf }

class FileItem {
  String id;
  String name;
  String path;
  FileType type;
  DateTime uploadDate;
  int size;

  FileItem({
    required this.id,
    required this.name,
    required this.path,
    required this.type,
    required this.uploadDate,
    required this.size,
  });

  factory FileItem.fromJson(Map<String, dynamic> json) {
    return FileItem(
      id: json['id'],
      name: json['name'],
      path: json['path'],
      type: FileType.values[json['type']],
      uploadDate: DateTime.parse(json['uploadDate']),
      size: json['size'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'path': path,
      'type': type.index,
      'uploadDate': uploadDate.toIso8601String(),
      'size': size,
    };
  }

  File get file => File(path);

  String get formattedSize {
    if (size < 1024) return '${size}B';
    if (size < 1024 * 1024) return '${(size / 1024).toStringAsFixed(1)}KB';
    return '${(size / (1024 * 1024)).toStringAsFixed(1)}MB';
  }
}
