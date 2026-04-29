import 'package:equatable/equatable.dart';
import 'message.dart';

class Conversation extends Equatable {
  final String id;
  final String knowledgeBaseId;
  final String title;
  final List<Message> messages;
  final DateTime createdAt;

  const Conversation({
    required this.id,
    required this.knowledgeBaseId,
    required this.title,
    required this.messages,
    required this.createdAt,
  });

  @override
  List<Object?> get props => [id, knowledgeBaseId, title, messages, createdAt];
}