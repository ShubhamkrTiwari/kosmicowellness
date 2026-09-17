import 'package:flutter/foundation.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import '../managers/user_manager.dart';
import '../managers/notification_manager.dart';
import '../managers/post_manager.dart';

class SocketService {
  static final SocketService _instance = SocketService._internal();
  factory SocketService() => _instance;
  SocketService._internal();

  IO.Socket? _socket;
  bool _isConnected = false;

  bool get isConnected => _isConnected;

  void init() {
    if (_socket != null && _isConnected) return;

    try {
      debugPrint('DEBUG: Initializing Socket.IO connection to https://api.kosmicowellness.com');
      
      _socket = IO.io('https://api.kosmicowellness.com', <String, dynamic>{
        'transports': ['websocket'],
        'autoConnect': true,
        'reconnection': true,
        'reconnectionAttempts': 10,
        'reconnectionDelay': 1000,
      });

      _socket!.onConnect((_) {
        _isConnected = true;
        debugPrint('✅ WebSocket Connected!');
        
        // Authenticate/register user if logged in
        final userId = UserManager().userId;
        final token = UserManager().token;
        if (userId != null && userId.isNotEmpty) {
          _socket!.emit('authenticate', {'userId': userId, 'token': token});
          _socket!.emit('join', userId);
        }
      });

      _socket!.onDisconnect((_) {
        _isConnected = false;
        debugPrint('❌ WebSocket Disconnected');
      });

      _socket!.onConnectError((err) {
        _isConnected = false;
        debugPrint('⚠️ WebSocket Connect Error: $err');
      });

      _socket!.onError((err) {
        debugPrint('⚠️ WebSocket Error: $err');
      });

      // Listen to real-time events for app & website sync
      _socket!.on('notification', (data) {
        debugPrint('🔔 Real-time Notification received: $data');
        if (data is Map) {
          NotificationManager().addNotification(
            title: data['title']?.toString() ?? 'New Notification',
            message: data['message']?.toString() ?? '',
            icon: data['icon']?.toString() ?? '🔔',
            type: data['type']?.toString() ?? 'general',
          );
        } else {
          NotificationManager().fetchFromApi(isInitial: false);
        }
      });

      _socket!.on('order_update', (data) {
        debugPrint('🛍️ Real-time Order Update received: $data');
        NotificationManager().addNotification(
          title: 'Order Status Updated',
          message: data is Map ? (data['message']?.toString() ?? 'Your order status has changed.') : 'Your order status has changed.',
          icon: '🛍️',
          type: 'order',
        );
      });

      _socket!.on('post_update', (data) {
        debugPrint('📝 Real-time Post Update received: $data');
        PostManager().fetchFeed();
      });

      _socket!.on('new_post', (data) {
        debugPrint('📝 Real-time New Post received: $data');
        PostManager().fetchFeed();
      });

      _socket!.on('like_update', (data) {
        debugPrint('❤️ Real-time Like Update received: $data');
        PostManager().fetchFeed();
      });

      _socket!.on('comment_update', (data) {
        debugPrint('💬 Real-time Comment Update received: $data');
        PostManager().fetchFeed();
      });

      _socket!.on('glucose_update', (data) {
        debugPrint('🩸 Real-time Glucose Update received: $data');
      });

    } catch (e) {
      debugPrint('Socket initialization error: $e');
    }
  }

  void disconnect() {
    if (_socket != null) {
      _socket!.disconnect();
      _socket = null;
      _isConnected = false;
      debugPrint('🔌 WebSocket manually disconnected.');
    }
  }

  void emit(String event, dynamic data) {
    if (_socket != null && _isConnected) {
      _socket!.emit(event, data);
    }
  }
}
