# Simple Chat App

A simple chat application with a Flutter frontend and Phoenix (Elixir) backend.

The Flutter app displays a chat conversation with an input field and "Send" button. The Phoenix backend responds with random positive responses (OK, GOOD, NICE, GREAT, etc.).

## Project Structure

```
simple_chat_app/
├── backend/          # Phoenix/Elixir backend
│   ├── lib/
│   │   └── chat_backend/
│   │       ├── application.ex
│   │       ├── endpoint.ex
│   │       ├── user_socket.ex
│   │       └── chat_channel.ex
│   ├── config/
│   │   └── config.exs
│   ├── mix.exs
│   └── Dockerfile
├── flutter_app/      # Flutter frontend
│   ├── lib/
│   │   └── main.dart
│   └── pubspec.yaml
└── README.md
```

## Running the Backend

### Option 1: Using Docker (Recommended)

Build and run the backend with a single Docker command:

```bash
cd backend

# Build the Docker image
docker build -t chat-backend .

# Run the container
docker run -p 4000:4000 chat-backend
```

Or run both commands together:

```bash
docker build -t chat-backend . && docker run -p 4000:4000 chat-backend
```

The backend will be available at `ws://localhost:4000/socket/websocket`

### Option 2: Running Locally (requires Elixir installed)

```bash
cd backend
mix deps.get
mix phx.server
```

## Running the Flutter App

1. Navigate to the Flutter app directory:

```bash
cd flutter_app
```

2. Get dependencies:

```bash
flutter pub get
```

3. Run the app:

```bash
# For web
flutter run -d chrome

# For macOS
flutter run -d macos

# For iOS simulator
flutter run -d ios

# For Android emulator (update the WebSocket URL to use 10.0.2.2 instead of localhost)
flutter run -d android
```

### Android Emulator Note

If running on Android emulator, you need to change the WebSocket URL in `lib/main.dart`:

```dart
// Change this:
'ws://localhost:4000/socket/websocket'

// To this:
'ws://10.0.2.2:4000/socket/websocket'
```

This is because `localhost` on Android emulator refers to the emulator itself, not the host machine. `10.0.2.2` is a special alias that routes to the host's loopback interface.

## How It Works

### Backend (Phoenix)

The Phoenix backend:
1. Accepts WebSocket connections at `/socket/websocket`
2. Handles the `chat:lobby` channel
3. Listens for `new_message` events
4. Broadcasts the user's message to all connected clients
5. Responds with a random positive message (OK, GOOD, NICE, GREAT, PERFECT, AWESOME, EXCELLENT, WONDERFUL, FANTASTIC, AMAZING, SUPERB, BRILLIANT)

### Frontend (Flutter)

The Flutter app:
1. Connects to the Phoenix WebSocket server
2. Joins the `chat:lobby` channel
3. Displays messages in a scrollable list with chat bubbles
4. User messages appear on the right (green avatar)
5. Bot responses appear on the left (blue robot avatar)
6. Shows connection status in the app bar

## Features

- Real-time WebSocket communication using Phoenix Channels
- Clean Material Design 3 UI
- Connection status indicator
- Auto-scroll to latest messages
- Responsive input area with send button
- Message bubbles with avatars
- Error handling for connection issues

## Dependencies

### Backend
- Phoenix ~> 1.7.0
- Jason ~> 1.4 (JSON handling)
- Plug Cowboy ~> 2.6 (HTTP server)
- CORS Plug ~> 3.0 (CORS support)

### Frontend
- phoenix_socket ^0.8.0 (Phoenix WebSocket client)
- Flutter SDK >=3.0.0

## License

MIT
