import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nexus_app/features/chat/data/models/message_model.dart';
import '../../domain/entities/conversation.dart';
import '../../domain/entities/message.dart';
import '../../domain/usecases/send_message_usecase.dart';
import '../../domain/usecases/start_conversation_usecase.dart';
import 'chat_event.dart';
import 'chat_state.dart';

class ChatBloc extends Bloc<ChatEvent, ChatState> {
  final SendMessageUsecase sendMessageUsecase;
  final StartConversationUsecase startConversationUsecase;

  ChatBloc({
    required this.sendMessageUsecase,
    required this.startConversationUsecase,
  }) : super(const ChatInitial()) {
    on<ChatStarted>(_onStarted);
    on<ChatMessageSent>(_onMessageSent);
    on<ChatNewConversation>(_onNewConversation);
  }

  Future<void> _onStarted(
      ChatStarted event, Emitter<ChatState> emit) async {
    emit(const ChatLoading());
    final result =
        await startConversationUsecase(event.knowledgeBaseId);
    result.fold(
      (failure) => emit(ChatFailure(message: failure.message)),
      (conv) => emit(ChatReady(conversation: conv, messages: const [])),
    );
  }

  Future<void> _onNewConversation(
      ChatNewConversation event, Emitter<ChatState> emit) async {
    emit(const ChatLoading());
    final result =
        await startConversationUsecase(event.knowledgeBaseId);
    result.fold(
      (failure) => emit(ChatFailure(message: failure.message)),
      (conv) => emit(ChatReady(conversation: conv, messages: const [])),
    );
  }

  Future<void> _onMessageSent(ChatMessageSent event, Emitter<ChatState> emit) async {
    final current = state;
    if (current is! ChatReady) return;

    final userMessage = Message(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      role: MessageRole.user,
      content: event.message,
      createdAt: DateTime.now(),
    );

    final typingMessage = Message(
      id: 'typing',
      role: MessageRole.assistant,
      content: '',
      createdAt: DateTime.now(),
      isStreaming: true,
    );

    emit(current.copyWith(
      messages: [...current.messages, userMessage, typingMessage],
      isSending: true,
    ));

    final result = await sendMessageUsecase(SendMessageParams(
      conversationId: current.conversation.id,
      message: event.message,
      knowledgeBaseId: current.conversation.knowledgeBaseId,
    ));

    result.fold(
      (failure) {
        final msgs = current.messages
            .where((m) => m.id != 'typing')
            .toList();
        emit(ChatFailure(
          message: failure.message,
          previousMessages: [...msgs, userMessage],
        ));
      },
      (response) {
        final msgs = [...current.messages, userMessage]
            .where((m) => m.id != 'typing')
            .toList();

        // If backend returned a real conversation_id, update the conversation
        Conversation updatedConversation = current.conversation;
        if (response is MessageModel &&
            response.realConversationId != null &&
            current.conversation.id.startsWith('new_')) {
          updatedConversation = Conversation(
            id: response.realConversationId!,
            knowledgeBaseId: current.conversation.knowledgeBaseId,
            title: event.message.length > 40
                ? '${event.message.substring(0, 40)}...'
                : event.message,
            messages: const [],
            createdAt: current.conversation.createdAt,
          );
        }

        emit(current.copyWith(
          conversation: updatedConversation,
          messages: [...msgs, response],
          isSending: false,
        ));
      },
    );
  }
}