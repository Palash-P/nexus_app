import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nexus_app/features/knowledge_base/domain/entities/knowledge_base.dart';
import '../../domain/usecases/get_knowledge_bases_usecase.dart';
import '../../domain/usecases/create_kb_usecase.dart';
import 'kb_event.dart';
import 'kb_state.dart';

class KBBloc extends Bloc<KBEvent, KBState> {
  final GetKnowledgeBasesUsecase getKnowledgeBasesUsecase;
  final CreateKBUsecase createKBUsecase;

  KBBloc({
    required this.getKnowledgeBasesUsecase,
    required this.createKBUsecase,
  }) : super(const KBInitial()) {
    on<KBLoadRequested>(_onLoad);
    on<KBCreateRequested>(_onCreate);
  }

  Future<void> _onLoad(KBLoadRequested event, Emitter<KBState> emit) async {
    emit(const KBLoading());
    final result = await getKnowledgeBasesUsecase();
    result.fold(
      (failure) => emit(KBFailure(message: failure.message)),
      (kbs) => emit(KBLoaded(knowledgeBases: kbs)),
    );
  }

  Future<void> _onCreate(
      KBCreateRequested event, Emitter<KBState> emit) async {
    final currentKBs = state is KBLoaded
        ? (state as KBLoaded).knowledgeBases
        : <KnowledgeBase>[];
    emit(KBCreating(knowledgeBases: currentKBs));
    final result = await createKBUsecase(
      CreateKBParams(name: event.name, description: event.description),
    );
    result.fold(
      (failure) => emit(KBFailure(message: failure.message)),
      (kb) => emit(KBLoaded(knowledgeBases: [...currentKBs, kb])),
    );
  }
}