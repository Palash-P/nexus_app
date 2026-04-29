import 'package:equatable/equatable.dart';
import '../../domain/entities/conversation.dart';
import '../../domain/entities/message.dart';

abstract class ChatState extends Equatable {
  const ChatState();
  @override
  List<Object?> get props => [];
}

class ChatInitial extends ChatState {
  const ChatInitial();
}

class ChatLoading extends ChatState {
  const ChatLoading();
}

class ChatReady extends ChatState {
  final Conversation conversation;
  final List<Message> messages;
  final bool isSending;

  const ChatReady({
    required this.conversation,
    required this.messages,
    this.isSending = false,
  });

  ChatReady copyWith({
    Conversation? conversation,
    List<Message>? messages,
    bool? isSending,
  }) {
    return ChatReady(
      conversation: conversation ?? this.conversation,
      messages: messages ?? this.messages,
      isSending: isSending ?? this.isSending,
    );
  }

  @override
  List<Object?> get props => [conversation, messages, isSending];
}

class ChatFailure extends ChatState {
  final String message;
  final List<Message> previousMessages;

  const ChatFailure({
    required this.message,
    this.previousMessages = const [],
  });

  @override
  List<Object?> get props => [message, previousMessages];
}