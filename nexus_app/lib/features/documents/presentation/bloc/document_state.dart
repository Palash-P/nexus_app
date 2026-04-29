import 'package:equatable/equatable.dart';
import '../../domain/entities/document.dart';

abstract class DocumentState extends Equatable {
  const DocumentState();
  @override
  List<Object?> get props => [];
}

class DocumentInitial extends DocumentState {
  const DocumentInitial();
}

class DocumentLoading extends DocumentState {
  const DocumentLoading();
}

class DocumentLoaded extends DocumentState {
  final List<Document> documents;

  const DocumentLoaded({required this.documents});

  bool get hasProcessing => documents.any((d) => d.isProcessing);

  @override
  List<Object?> get props => [documents];
}

class DocumentUploading extends DocumentState {
  final List<Document> documents;
  final String fileName;
  const DocumentUploading({required this.documents, required this.fileName});
  @override
  List<Object?> get props => [documents, fileName];
}

class DocumentFailure extends DocumentState {
  final String message;
  final List<Document> documents;
  const DocumentFailure({required this.message, this.documents = const []});
  @override
  List<Object?> get props => [message, documents];
}