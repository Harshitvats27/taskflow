# TaskFlow

## Overview
TaskFlow is a project management mobile app developed in Flutter. This is a local mock assignment leveraging a layered architecture to cleanly separate UI, business logic, and data storage. 

## Architecture
The application uses Clean Architecture principles, ensuring the domain layer is completely agnostic to external data sources and UI concerns.
- **Domain Layer:** Pure Dart entities and abstract repository interfaces. Contains use cases that encapsulate business rules.
- **Data Layer:** Connects to the local JSON mock data, simulates API calls with delays/errors via `ApiSimulator`, and maps JSON to data models.
- **Presentation Layer:** Built with Flutter widgets, using `flutter_riverpod` for state management and dependency injection, and `go_router` for declarative navigation.
- **Core Layer:** Shared utilities, constants, exceptions, and dependency injection providers.

## Folder Structure
```
lib/
├── core/
│   ├── constants/
│   ├── di/
│   ├── errors/
│   └── utils/
├── data/
│   ├── datasources/
│   ├── models/
│   └── repositories/
├── domain/
│   ├── entities/
│   ├── repositories/
│   └── usecases/
├── presentation/
│   ├── providers/
│   ├── screens/
│   └── widgets/
└── main.dart
```

## State Management
Uses `flutter_riverpod` (without code generation). Providers are defined in `lib/core/di/providers.dart` and `lib/presentation/providers/`.

## Mock Data Layer
Data is sourced from `assets/mock_data/TaskFlow-MockData.json`. It is parsed using a `MockDataSource` and wrapped by `ApiSimulator` before reaching the repositories to mock real-world network latency and potential failures.

## Auth Flow
Uses a mocked local authentication flow checking against `auth_mock.test_credentials`. Sessions are stored using `flutter_secure_storage`.

## Setup Instructions
1. Clone the repository.
2. Run `flutter pub get`.
3. Run the app on an emulator or real device.

## Testing
Unit and widget testing implementation details (TBD).

## Known Limitations
- No actual backend connected.
- All modifications (tasks created, modified) are held in memory by the mock repositories and will be lost on app restart.

## Screen Recording
Watch the full walkthrough (login, project/task management, assignment, offline handling, logout):
https://drive.google.com/file/d/1bGns7GqSyAKrpSfPT5cK2VIYJ89l9SL_/view?usp=drive_link
