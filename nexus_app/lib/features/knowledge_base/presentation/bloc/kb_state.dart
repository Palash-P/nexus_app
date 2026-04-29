import 'package:equatable/equatable.dart';
import '../../domain/entities/knowledge_base.dart';

abstract class KBState extends Equatable {
  const KBState();
  @override
  List<Object?> get props => [];
}

class KBInitial extends KBState {
  const KBInitial();
}

class KBLoading extends KBState {
  const KBLoading();
}

class KBLoaded extends KBState {
  final List<KnowledgeBase> knowledgeBases;
  const KBLoaded({required this.knowledgeBases});
  @override
  List<Object?> get props => [knowledgeBases];
}

class KBCreating extends KBState {
  final List<KnowledgeBase> knowledgeBases;
  const KBCreating({required this.knowledgeBases});
  @override
  List<Object?> get props => [knowledgeBases];
}

class KBFailure extends KBState {
  final String message;
  const KBFailure({required this.message});
  @override
  List<Object?> get props => [message];
}