class ApiEndpoints {
  static const String baseUrl = 'https://nexus-production-6a7c.up.railway.app';

  // Auth
  static const String login = '/api/auth/token/';

  // Knowledge bases
  static const String knowledgeBases = '/api/knowledge-bases/';
  static String knowledgeBaseDetail(String id) => '/api/knowledge-bases/$id/';

  // Documents
  static const String documents = '/api/documents/';
  static String reprocessDocument(String id) => '/api/documents/$id/reprocess/';

  // Chat
  static const String chat = '/api/chat/';
  static const String ask = '/api/ask/';

  // Analytics
  static const String analytics = '/api/analytics/';
}