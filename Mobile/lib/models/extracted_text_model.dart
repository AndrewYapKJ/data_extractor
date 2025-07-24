class ExtractedText {
  String id;
  String sourceFileId;
  String text;
  DateTime extractedDate;
  double confidence;
  Map<String, dynamic>? metadata;

  ExtractedText({
    required this.id,
    required this.sourceFileId,
    required this.text,
    required this.extractedDate,
    this.confidence = 0.0,
    this.metadata,
  });

  factory ExtractedText.fromJson(Map<String, dynamic> json) {
    return ExtractedText(
      id: json['id'],
      sourceFileId: json['sourceFileId'],
      text: json['text'],
      extractedDate: DateTime.parse(json['extractedDate']),
      confidence: json['confidence']?.toDouble() ?? 0.0,
      metadata: json['metadata'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'sourceFileId': sourceFileId,
      'text': text,
      'extractedDate': extractedDate.toIso8601String(),
      'confidence': confidence,
      'metadata': metadata,
    };
  }

  ExtractedText copyWith({
    String? id,
    String? sourceFileId,
    String? text,
    DateTime? extractedDate,
    double? confidence,
    Map<String, dynamic>? metadata,
  }) {
    return ExtractedText(
      id: id ?? this.id,
      sourceFileId: sourceFileId ?? this.sourceFileId,
      text: text ?? this.text,
      extractedDate: extractedDate ?? this.extractedDate,
      confidence: confidence ?? this.confidence,
      metadata: metadata ?? this.metadata,
    );
  }

  bool get hasText => text.trim().isNotEmpty;

  String get formattedDate {
    final now = DateTime.now();
    final difference = now.difference(extractedDate);

    if (difference.inDays == 0) {
      if (difference.inHours == 0) {
        if (difference.inMinutes == 0) {
          return 'Just now';
        }
        return '${difference.inMinutes}m ago';
      }
      return '${difference.inHours}h ago';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${extractedDate.day}/${extractedDate.month}/${extractedDate.year}';
    }
  }

  String get wordCount {
    if (!hasText) return '0 words';
    final words = text.trim().split(RegExp(r'\s+'));
    return '${words.length} words';
  }

  String get characterCount {
    return '${text.length} characters';
  }
}
