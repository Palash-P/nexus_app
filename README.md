<div align="center">

<img width="100" height="100" alt="icon" src="https://github.com/user-attachments/assets/c60890dd-ff4c-4b7f-9b7e-d347724f893b" />

# Nexus — AI Knowledge Base

**Chat with your documents. Get cited answers. Built for teams.**

[![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?style=flat-square&logo=flutter)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.x-0175C2?style=flat-square&logo=dart)](https://dart.dev)
[![Django](https://img.shields.io/badge/Django-6.0-092E20?style=flat-square&logo=django)](https://djangoproject.com)
[![Railway](https://img.shields.io/badge/Deployed-Railway-0B0D0E?style=flat-square&logo=railway)](https://railway.app)
[![License](https://img.shields.io/badge/License-MIT-6C63FF?style=flat-square)](LICENSE)

[Live Backend](https://nexus-production-6a7c.up.railway.app) · [Backend Repo](https://github.com/palash-p/nexus) · [Portfolio](https://palash-p.github.io)

</div>

---

## What is Nexus?

Nexus is a production-grade AI knowledge base mobile app. Upload your company documents — PDFs, markdown, text files — and chat with them using natural language. Every answer comes with **source citations and page numbers** so you always know where the information came from.

Built as a full-stack solo project to demonstrate production Flutter development, Clean Architecture, and AI/RAG integration.

---

## Screenshots

| Login | Home | Documents | Chat |
|-------|------|-----------|------|
| <img width="200" alt="Login" src="https://github.com/user-attachments/assets/158ee4bf-b375-4b12-b653-22399800e4bf"/> | <img width="200" alt="Home" src="https://github.com/user-attachments/assets/21735347-60cc-4f4b-9faf-9abce523cede"/> | <img width="200" alt="Documents" src="https://github.com/user-attachments/assets/1e708494-bac5-4c17-ae65-31e7b5ad60e2"/> | <img width="200" alt="Chat" src="https://github.com/user-attachments/assets/19a965ee-f1e3-45e6-9bb0-2f399a27491e"/> |

## Features

**Core**
- JWT token authentication with secure storage
- Create and manage multiple knowledge bases
- Upload PDF, TXT, and Markdown documents
- Real-time document processing status with auto-polling every 5 seconds
- Multi-turn AI chat with source citations and confidence scores
- Markdown rendering in AI responses — bold, headers, code blocks, lists

**UX**
- Dark "intelligence" theme with indigo + teal accent system
- Staggered entry animations on every screen
- Spring physics FAB, elastic scale transitions between routes
- Haptic feedback on all interactive elements
- Shimmer loading states — no blank screens ever
- Pull to refresh on all list screens
- Long press AI messages to copy to clipboard
- Keyboard dismisses on scroll in chat

**Technical**
- Offline-aware — graceful failure on no network
- Token auto-injected into every request via Dio interceptor
- Document processing polling stops automatically when all docs are ready
- Conversation ID management — first message creates the conversation, subsequent messages continue it

---

## Architecture

This app follows **Clean Architecture** with strict layer separation. The domain layer has zero Flutter or external dependencies — it can be unit tested in isolation with no mocks required.

```
lib/
├── core/                          # Shared infrastructure
│   ├── api/                       # Dio client + interceptors
│   ├── errors/                    # Failures + exceptions
│   ├── network/                   # Connectivity check
│   ├── storage/                   # flutter_secure_storage wrapper
│   ├── theme/                     # AppColors, AppTextStyles, AppTheme
│   ├── router/                    # go_router with auth guard
│   └── widgets/                   # GlassCard, GradientButton, StatusBadge...
│
├── features/
│   ├── auth/
│   │   ├── data/                  # AuthRemoteDatasource, UserModel
│   │   ├── domain/                # User entity, AuthRepository, LoginUsecase
│   │   └── presentation/          # AuthBloc, LoginPage
│   │
│   ├── knowledge_base/
│   │   ├── data/                  # KBRemoteDatasource, KBModel
│   │   ├── domain/                # KnowledgeBase entity, KBRepository
│   │   └── presentation/          # KBBloc, HomePage
│   │
│   ├── documents/
│   │   ├── data/                  # DocumentRemoteDatasource, DocumentModel
│   │   ├── domain/                # Document entity, DocumentRepository
│   │   └── presentation/          # DocumentBloc, DocumentsPage
│   │
│   └── chat/
│       ├── data/                  # ChatRemoteDatasource, MessageModel
│       ├── domain/                # Message entity, ChatRepository
│       └── presentation/          # ChatBloc, ChatPage
│
├── injection_container.dart        # GetIt service locator
└── main.dart
```

### Data flow

```
UI (Page)
  → dispatches Event
    → Bloc calls Usecase
      → Usecase calls Repository (abstract)
        → RepositoryImpl calls RemoteDatasource
          → Datasource calls ApiClient (Dio)
            → Django REST API on Railway
```

Every repository returns `Either<Failure, T>` — errors are values, not exceptions. The Bloc folds the Either and emits the appropriate state. The UI never sees exceptions.

---

## Tech Stack

### Mobile (Flutter)

| Package | Purpose |
|---------|---------|
| `flutter_bloc` | State management — Bloc pattern |
| `dio` | HTTP client with interceptors |
| `get_it` | Service locator / dependency injection |
| `go_router` | Declarative routing with auth guard |
| `dartz` | Functional `Either` type for error handling |
| `flutter_secure_storage` | Encrypted token storage |
| `file_picker` | Document upload (PDF, TXT, MD) |
| `flutter_markdown` | Renders AI responses with full markdown |
| `equatable` | Value equality for Bloc states |
| `connectivity_plus` | Network status check |

### Backend (Django)

| Technology | Purpose |
|-----------|---------|
| Django 6.0 + DRF | REST API |
| PostgreSQL + pgvector | Vector similarity search |
| Google Gemini | LLM + embeddings (gemini-2.5-flash) |
| Celery + Redis | Async document processing |
| Cloudinary | File storage (shared between web + worker) |
| Railway | Deployment (web service + worker service) |

---

## Key Engineering Decisions

**Why Clean Architecture over MVC/MVVM?**

Three distinct layers — data, domain, presentation — with dependency inversion at each boundary. The domain layer has no Flutter imports. Swapping Dio for http, or changing the state management library, touches only one layer. More importantly, it demonstrates the kind of thinking expected at mid-to-senior level.

**Why `Either<Failure, T>` over try/catch?**

Every possible failure is encoded in the type system. A repository that returns `Either<Failure, User>` cannot silently swallow an error — the caller is forced to handle both cases. This eliminates an entire class of runtime bugs that try/catch approaches miss.

**Why GetIt over Provider/Riverpod for DI?**

GetIt is a service locator — dependencies are registered once at app start and resolved anywhere without BuildContext. This means usecases, repositories, and datasources can be instantiated and tested independently of the widget tree.

**Why Cloudinary for file storage?**

Railway runs web and worker as separate containers with separate filesystems. Uploaded files saved to local disk on the web container are invisible to the Celery worker container. Cloudinary gives both containers access to the same file via URL — the web container uploads, the worker downloads and processes.

**Why polling over WebSockets for document status?**

Document processing takes 30–120 seconds. WebSockets add significant complexity (connection management, reconnection logic, server-side channels). Polling every 5 seconds is simple, reliable, and stops automatically when all documents reach a terminal state. The UX difference is imperceptible.

---

## Local Setup

**Prerequisites:** Flutter 3.x, Dart 3.x, a running Nexus backend

```bash
# Clone
git clone https://github.com/palash-p/nexus-app.git
cd nexus-app

# Install dependencies
flutter pub get

# Run
flutter run
```

The app points to the live Railway backend by default. To run against a local backend, update `ApiEndpoints.baseUrl` in `lib/core/api/api_endpoints.dart`:

```dart
static const String baseUrl = 'http://10.0.2.2:8000'; // Android emulator
static const String baseUrl = 'http://localhost:8000'; // iOS simulator
```

---

## Backend

The Django backend is a separate repository:

- **Repo:** [github.com/palash-p/nexus](https://github.com/palash-p/nexus)
- **Live API:** [nexus-production-6a7c.up.railway.app](https://nexus-production-6a7c.up.railway.app)
- **Stack:** Django 6.0, DRF, PostgreSQL, pgvector, Celery, Redis, Cloudinary, Railway

---

## What I'd add with more time

- **Unit tests** — Bloc tests with `bloc_test`, repository tests with `mockito`
- **Offline cache** — store last-fetched KBs and messages in `drift` (SQLite)
- **Push notifications** — notify when document processing completes
- **Conversation history** — list and resume past conversations
- **Analytics screen** — query volume, cost per query, response time charts
- **Search** — semantic search across all knowledge bases

---

## About

Built by **Palash** — Flutter & Django developer based in Pune, India.

2 years of production experience shipping real apps — payment integrations (Razorpay across 3 apps), Google Maps SDK, B2B marketplace, fintech. Currently building at the intersection of mobile and AI.

- **Portfolio:** [palash-p.github.io](https://palash-p.github.io)
- **LinkedIn:** [linkedin.com/in/palash-p](https://www.linkedin.com/in/palash-pingale-72418329b/)
- **Email:** palashpingale135@email.com

---

<div align="center">

**If this project helped you or impressed you — star it ⭐**

</div>
