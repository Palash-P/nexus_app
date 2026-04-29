import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get_it/get_it.dart';

import 'core/api/api_client.dart';
import 'core/network/network_info.dart';
import 'core/storage/secure_storage.dart';
import 'features/auth/data/datasources/auth_remote_datasource.dart';
import 'features/auth/data/repositories/auth_repository_impl.dart';
import 'features/auth/domain/repositories/auth_repository.dart';
import 'features/auth/domain/usecases/login_usecase.dart';
import 'features/auth/domain/usecases/logout_usecase.dart';
import 'features/auth/presentation/bloc/auth_bloc.dart';

import 'features/knowledge_base/data/datasources/kb_remote_datasource.dart';
import 'features/knowledge_base/data/repositories/kb_repository_impl.dart';
import 'features/knowledge_base/domain/repositories/kb_repository.dart';
import 'features/knowledge_base/domain/usecases/get_knowledge_bases_usecase.dart';
import 'features/knowledge_base/domain/usecases/create_kb_usecase.dart';
import 'features/knowledge_base/presentation/bloc/kb_bloc.dart';

import 'features/documents/data/datasources/document_remote_datasource.dart';
import 'features/documents/data/repositories/document_repository_impl.dart';
import 'features/documents/domain/repositories/document_repository.dart';
import 'features/documents/domain/usecases/get_documents_usecase.dart';
import 'features/documents/domain/usecases/upload_document_usecase.dart';
import 'features/documents/presentation/bloc/document_bloc.dart';

import 'features/chat/data/datasources/chat_remote_datasource.dart';
import 'features/chat/data/repositories/chat_repository_impl.dart';
import 'features/chat/domain/repositories/chat_repository.dart';
import 'features/chat/domain/usecases/send_message_usecase.dart';
import 'features/chat/domain/usecases/start_conversation_usecase.dart';
import 'features/chat/presentation/bloc/chat_bloc.dart';


final sl = GetIt.instance;

Future<void> initDependencies() async {
  sl.registerLazySingleton(() => const FlutterSecureStorage());
  sl.registerLazySingleton(() => Connectivity());

  sl.registerLazySingleton(() => SecureStorage(sl()));
  sl.registerLazySingleton<NetworkInfo>(() => NetworkInfoImpl(sl()));
  sl.registerLazySingleton(() => ApiClient(secureStorage: sl()));

  _registerAuth();
  _registerKnowledgeBase();
  _registerDocuments();
  _registerChat();
}

void _registerAuth() {
  // Datasource
  sl.registerLazySingleton<AuthRemoteDatasource>(
    () => AuthRemoteDatasourceImpl(apiClient: sl(), secureStorage: sl()),
  );

  // Repository
  sl.registerLazySingleton<AuthRepository>(
    () => AuthRepositoryImpl(
      remoteDatasource: sl(),
      networkInfo: sl(),
      secureStorage: sl(),
    ),
  );

  // Usecases
  sl.registerLazySingleton(() => LoginUsecase(sl()));
  sl.registerLazySingleton(() => LogoutUsecase(sl()));

  // Bloc — factory so each page gets a fresh instance
  sl.registerFactory(
    () => AuthBloc(
      loginUsecase: sl(),
      logoutUsecase: sl(),
      authRepository: sl(),
    ),
  );
}

void _registerKnowledgeBase() {
  sl.registerLazySingleton<KBRemoteDatasource>(
    () => KBRemoteDatasourceImpl(apiClient: sl()),
  );
  sl.registerLazySingleton<KBRepository>(
    () => KBRepositoryImpl(remoteDatasource: sl(), networkInfo: sl()),
  );
  sl.registerLazySingleton(() => GetKnowledgeBasesUsecase(sl()));
  sl.registerLazySingleton(() => CreateKBUsecase(sl()));
  sl.registerFactory(
    () => KBBloc(
      getKnowledgeBasesUsecase: sl(),
      createKBUsecase: sl(),
    ),
  );
}
void _registerDocuments() {
  sl.registerLazySingleton<DocumentRemoteDatasource>(
    () => DocumentRemoteDatasourceImpl(apiClient: sl()),
  );
  sl.registerLazySingleton<DocumentRepository>(
    () => DocumentRepositoryImpl(
        remoteDatasource: sl(), networkInfo: sl()),
  );
  sl.registerLazySingleton(() => GetDocumentsUsecase(sl()));
  sl.registerLazySingleton(() => UploadDocumentUsecase(sl()));
  sl.registerFactory(() => DocumentBloc(
        getDocumentsUsecase: sl(),
        uploadDocumentUsecase: sl(),
        documentRepository: sl(),
      ));
}

void _registerChat() {
  sl.registerLazySingleton<ChatRemoteDatasource>(
    () => ChatRemoteDatasourceImpl(apiClient: sl()),
  );
  sl.registerLazySingleton<ChatRepository>(
    () => ChatRepositoryImpl(remoteDatasource: sl(), networkInfo: sl()),
  );
  sl.registerLazySingleton(() => SendMessageUsecase(sl()));
  sl.registerLazySingleton(() => StartConversationUsecase(sl()));
  sl.registerFactory(() => ChatBloc(
        sendMessageUsecase: sl(),
        startConversationUsecase: sl(),
      ));
}