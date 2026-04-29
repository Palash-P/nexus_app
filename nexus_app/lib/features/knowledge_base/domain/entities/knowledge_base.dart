import 'package:equatable/equatable.dart';

class KnowledgeBase extends Equatable {
  final String id;
  final String name;
  final String description;
  final int documentCount;
  final int totalChunks;
  final DateTime createdAt;

  const KnowledgeBase({
    required this.id,
    required this.name,
    required this.description,
    required this.documentCount,
    required this.totalChunks,
    required this.createdAt,
  });

  @override
  List<Object> get props => [id, name, description, documentCount, totalChunks, createdAt];
}