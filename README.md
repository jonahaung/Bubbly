# Bubbly

A native iOS messaging app built with SwiftUI, SwiftData, Firebase Authentication, and a Vapor backend.

## Overview

Bubbly is organized as a modular iOS application with focused Swift packages for conversations, contacts, authentication, media, persistence, and shared UI. The companion backend stores contact profiles and profile images in PostgreSQL while Firebase remains the identity provider.

## Features

- Phone and email authentication with Firebase
- Real-time conversations with rich message attachments
- Contact discovery and profile management
- Photo, video, document, and location sharing
- Local persistence powered by SwiftData
- Push notifications through Firebase Cloud Messaging
- Background refresh and message synchronization

## Technology

| Area | Stack |
| --- | --- |
| App | Swift, SwiftUI, SwiftData |
| Concurrency | Swift structured concurrency |
| Authentication | Firebase Authentication |
| Messaging services | Firebase |
| Backend | Swift, Vapor, Fluent |
| Database | PostgreSQL |
| Infrastructure | Docker Compose |

## Project Structure

```text
Bubbly/
├── Bubbly/                  # iOS application entry point and resources
├── NotificationService/    # Push notification service extension
├── Packages/               # Local Swift packages
│   ├── Conversation/       # Messaging UI and composition
│   ├── Database/           # SwiftData models and repositories
│   ├── FirePhoneOTP/       # Firebase authentication flows
│   ├── Inbox/              # Conversation list
│   ├── MediaPicker/        # Photo and video selection
│   ├── Services/           # Networking and service integrations
│   └── XUI/                # Shared UI components
├── Backend/                # Vapor API and PostgreSQL integration
├── BubblyTests/            # App tests
└── BubblyUITests/          # UI tests
```

## Requirements

- macOS with Xcode capable of building the configured iOS deployment target
- Docker Desktop or another Docker Compose-compatible runtime
- A Firebase project with Authentication and Cloud Messaging configured

## Getting Started

### 1. Configure Firebase

Add the iOS Firebase configuration file at:

```text
Bubbly/Resources/GoogleService-Info.plist
```

Create a Firebase service account for the backend and encode its JSON file:

```sh
base64 < service-account.json | tr -d '\n'
```

Keep service-account credentials and signing keys out of source control.

### 2. Start the backend

```sh
cd Backend
cp .env.example .env
```

Set secure values for `DATABASE_PASSWORD` and `FIREBASE_SERVICE_ACCOUNT_JSON_BASE64` in `Backend/.env`, then start the API and PostgreSQL:

```sh
docker compose --env-file .env up --build
```

Confirm the service is available:

```sh
curl http://127.0.0.1:8080/health
```

For additional deployment and API details, see the [backend documentation](Backend/README.md).

### 3. Run the iOS app

1. Open `Bubbly.xcodeproj` in Xcode.
2. Select the `Bubbly` scheme.
3. Choose an iOS simulator or a configured physical device.
4. Build and run.

Debug builds use `http://127.0.0.1:8080` by default. When running on a physical device, set `BUBBLY_API_BASE_URL` in the scheme environment to an address the device can reach.

## Development

Build the app from the command line:

```sh
xcodebuild \
  -project Bubbly.xcodeproj \
  -scheme Bubbly \
  -configuration Debug \
  -destination 'generic/platform=iOS' \
  CODE_SIGNING_ALLOWED=NO \
  CODE_SIGNING_REQUIRED=NO \
  build
```

Run backend tests:

```sh
cd Backend
swift test
```

## Security

- Never commit `.env`, Firebase service-account JSON, APNs signing keys, or production credentials.
- Use HTTPS for the production API and TLS for PostgreSQL connections.
- Store deployment secrets in the platform secret manager and rotate them regularly.
- Keep automatic migrations disabled in multi-instance production deployments.
