import 'package:equatable/equatable.dart';

enum MessageRole { user, assistant }

class Citation extends Equatable {
  final String sourceTitle;
  final int? pageNumber;
  final double? confidence;

  const Citation({
    required this.sourceTitle,
    this.pageNumber,
    this.confidence,
  });

  @override
  List<Object?> get props => [sourceTitle, pageNumber, confidence];
}

class Message extends Equatable {
  final String id;
  final MessageRole role;
  final String content;
  final List<Citation> citations;
  final DateTime createdAt;
  final bool isStreaming;

  const Message({
    required this.id,
    required this.role,
    required this.content,
    this.citations = const [],
    required this.createdAt,
    this.isStreaming = false,
  });

  Message copyWith({
    String? content,
    bool? isStreaming,
    List<Citation>? citations,
  }) {
    return Message(
      id: id,
      role: role,
      content: content ?? this.content,
      citations: citations ?? this.citations,
      createdAt: createdAt,
      isStreaming: isStreaming ?? this.isStreaming,
    );
  }

  @override
  List<Object?> get props => [id, role, content, citations, createdAt, isStreaming];
}