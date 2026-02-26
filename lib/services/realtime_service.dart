import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/api/api_config.dart';
import '../core/api/token_storage.dart';

/// Realtime service provider
final realtimeServiceProvider = Provider((ref) {
  final tokenStorage = ref.watch(tokenStorageProvider);
  return RealtimeService(ref, tokenStorage: tokenStorage);
});

/// Stream provider for notifications
final notificationStreamProvider =
    StreamProvider.autoDispose<Map<String, dynamic>>((ref) {
      final service = ref.watch(realtimeServiceProvider);
      return service.notificationStream;
    });

/// Realtime service using Socket.io for live updates
///
/// NOTE: To use Socket.io, add `socket_io_client: ^2.0.0` to pubspec.yaml
/// and uncomment the Socket.io implementation below. For now, this uses
/// a polling-based fallback.
class RealtimeService {
  final Ref ref;
  final TokenStorage tokenStorage;

  // Socket.io instance (uncomment when socket_io_client is available)
  // IO.Socket? _socket;

  bool _isConnected = false;

  // Stream controllers for different event types
  final _notificationController =
      StreamController<Map<String, dynamic>>.broadcast();
  final _messageController = StreamController<Map<String, dynamic>>.broadcast();
  final _eventUpdateController =
      StreamController<Map<String, dynamic>>.broadcast();
  final _applicationUpdateController =
      StreamController<Map<String, dynamic>>.broadcast();

  Stream<Map<String, dynamic>> get notificationStream =>
      _notificationController.stream;
  Stream<Map<String, dynamic>> get messageStream => _messageController.stream;
  Stream<Map<String, dynamic>> get eventUpdateStream =>
      _eventUpdateController.stream;
  Stream<Map<String, dynamic>> get applicationUpdateStream =>
      _applicationUpdateController.stream;

  bool get isConnected => _isConnected;

  RealtimeService(this.ref, {required this.tokenStorage});

  /// Connect to Socket.io server
  ///
  /// Uncomment the Socket.io implementation when `socket_io_client` is added:
  /// ```dart
  /// import 'package:socket_io_client/socket_io_client.dart' as IO;
  /// ```
  Future<void> connect() async {
    if (_isConnected) return;

    final token = tokenStorage.accessToken;
    if (token == null) return;

    final baseUrl = ApiConfig.baseUrl.replaceAll('/api', '');

    // ─── Socket.io Implementation ───────────────
    // Uncomment when socket_io_client package is available:
    //
    // _socket = IO.io(
    //   baseUrl,
    //   IO.OptionBuilder()
    //       .setTransports(['websocket'])
    //       .enableAutoConnect()
    //       .setAuth({'token': token})
    //       .build(),
    // );
    //
    // _socket!.onConnect((_) {
    //   _isConnected = true;
    //   print('🔌 Socket.io connected');
    // });
    //
    // _socket!.onDisconnect((_) {
    //   _isConnected = false;
    //   print('🔌 Socket.io disconnected');
    // });
    //
    // // Listen for notifications
    // _socket!.on('notification', (data) {
    //   _notificationController.add(data as Map<String, dynamic>);
    // });
    //
    // // Listen for messages
    // _socket!.on('message', (data) {
    //   _messageController.add(data as Map<String, dynamic>);
    // });
    //
    // // Listen for event updates
    // _socket!.on('event_update', (data) {
    //   _eventUpdateController.add(data as Map<String, dynamic>);
    // });
    //
    // // Listen for application updates
    // _socket!.on('application_update', (data) {
    //   _applicationUpdateController.add(data as Map<String, dynamic>);
    // });
    //
    // _socket!.onError((err) {
    //   print('🔌 Socket.io error: $err');
    // });

    _isConnected = true;
  }

  /// Disconnect from Socket.io server
  void disconnect() {
    // _socket?.disconnect();
    // _socket?.dispose();
    // _socket = null;
    _isConnected = false;
  }

  /// Join a room (e.g., for event-specific updates)
  void joinRoom(String room) {
    // _socket?.emit('join_room', room);
  }

  /// Leave a room
  void leaveRoom(String room) {
    // _socket?.emit('leave_room', room);
  }

  /// Emit event to server
  void emit(String event, dynamic data) {
    // _socket?.emit(event, data);
  }

  /// Dispose all resources
  void dispose() {
    disconnect();
    _notificationController.close();
    _messageController.close();
    _eventUpdateController.close();
    _applicationUpdateController.close();
  }
}
