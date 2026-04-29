import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/utils/constants.dart';
import '../../domain/entities/document.dart';
import '../../domain/usecases/get_documents_usecase.dart';
import '../../domain/usecases/upload_document_usecase.dart';
import '../../domain/repositories/document_repository.dart';
import 'document_event.dart';
import 'document_state.dart';

class DocumentBloc extends Bloc<DocumentEvent, DocumentState> {
  final GetDocumentsUsecase getDocumentsUsecase;
  final UploadDocumentUsecase uploadDocumentUsecase;
  final DocumentRepository documentRepository;

  Timer? _pollingTimer;
  int _pollAttempts = 0;

  DocumentBloc({
    required this.getDocumentsUsecase,
    required this.uploadDocumentUsecase,
    required this.documentRepository,
  }) : super(const DocumentInitial()) {
    on<DocumentsLoadRequested>(_onLoad);
    on<DocumentUploadRequested>(_onUpload);
    on<DocumentPollingTick>(_onPollTick);
    on<DocumentReprocessRequested>(_onReprocess);
  }

  Future<void> _onLoad(
      DocumentsLoadRequested event, Emitter<DocumentState> emit) async {
    emit(const DocumentLoading());
    final result = await getDocumentsUsecase(event.knowledgeBaseId);
    result.fold(
      (failure) => emit(DocumentFailure(message: failure.message)),
      (docs) {
        emit(DocumentLoaded(documents: docs));
        _maybeStartPolling(docs, event.knowledgeBaseId);
      },
    );
  }

  Future<void> _onUpload(
      DocumentUploadRequested event, Emitter<DocumentState> emit) async {
    final currentDocs = _currentDocs();
    emit(DocumentUploading(documents: currentDocs, fileName: event.fileName));

    final result = await uploadDocumentUsecase(UploadParams(
      knowledgeBaseId: event.knowledgeBaseId,
      filePath: event.filePath,
      fileName: event.fileName,
    ));

    result.fold(
      (failure) =>
          emit(DocumentFailure(message: failure.message, documents: currentDocs)),
      (doc) {
        final updated = [...currentDocs, doc];
        emit(DocumentLoaded(documents: updated));
        _startPolling(event.knowledgeBaseId);
      },
    );
  }

  Future<void> _onPollTick(
      DocumentPollingTick event, Emitter<DocumentState> emit) async {
    _pollAttempts++;
    if (_pollAttempts > AppConstants.documentPollingMaxAttempts) {
      _stopPolling();
      return;
    }

    final result = await getDocumentsUsecase(event.knowledgeBaseId);
    result.fold(
      (_) => null,
      (docs) {
        emit(DocumentLoaded(documents: docs));
        if (!docs.any((d) => d.isProcessing)) _stopPolling();
      },
    );
  }

  Future<void> _onReprocess(
      DocumentReprocessRequested event, Emitter<DocumentState> emit) async {
    await documentRepository.reprocessDocument(event.documentId);
    add(DocumentsLoadRequested(knowledgeBaseId: event.knowledgeBaseId));
  }

  void _maybeStartPolling(List<Document> docs, String kbId) {
    if (docs.any((d) => d.isProcessing)) _startPolling(kbId);
  }

  void _startPolling(String kbId) {
    _stopPolling();
    _pollAttempts = 0;
    _pollingTimer = Timer.periodic(
      AppConstants.documentPollingInterval,
      (_) => add(DocumentPollingTick(knowledgeBaseId: kbId)),
    );
  }

  void _stopPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = null;
  }

  List<Document> _currentDocs() {
    final s = state;
    if (s is DocumentLoaded) return s.documents;
    if (s is DocumentUploading) return s.documents;
    if (s is DocumentFailure) return s.documents;
    return [];
  }

  @override
  Future<void> close() {
    _stopPolling();
    return super.close();
  }
}