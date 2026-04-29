import 'package:equatable/equatable.dart';

abstract class ChatEvent extends Equatable {
  const ChatEvent();
  @override
  List<Object> get props => [];
}

class ChatStarted extends ChatEvent {
  final String knowledgeBaseId;
  const ChatStarted({required this.knowledgeBaseId});
  @override
  List<Object> get props => [knowledgeBaseId];
}

class ChatMessageSent extends ChatEvent {
  final String message;
  const ChatMessageSent({required this.message});
  @override
  List<Object> get props => [message];
}

class ChatNewConversation extends ChatEvent {
  final String knowledgeBaseId;
  const ChatNewConversation({required this.knowledgeBaseId});
  @override
  List<Object> get props => [knowledgeBaseId];
}