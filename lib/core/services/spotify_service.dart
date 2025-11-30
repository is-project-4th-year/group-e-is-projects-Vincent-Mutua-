import 'dart:async';
import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:spotify/spotify.dart';
import 'package:flutter_web_auth_2/flutter_web_auth_2.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:http/http.dart' as http;

final spotifyServiceProvider = Provider<SpotifyService>((ref) {
  return SpotifyService();
});

class SpotifyService {
  // TODO: Replace with your actual Client ID and Redirect URI from Spotify Dashboard
  static const String _clientId = '27ffa25d44be4c168bf799bdf9cf843d'; 
  static const String _redirectUri = 'adhd-app://call-back';
  
  SpotifyApi? _spotifyApi;
  final FlutterSecureStorage _storage = const FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
    ),
  );
  
  // State for UI
  final StreamController<PlaybackState?> _playbackStateController = StreamController<PlaybackState?>.broadcast();
  final StreamController<bool> _authStateController = StreamController<bool>.broadcast(); // New auth stream

  Stream<PlaybackState?> get playbackStateStream => _playbackStateController.stream;
  Stream<bool> get authStateStream => _authStateController.stream; // Expose auth stream
  Timer? _pollingTimer;

  bool get isAuthenticated => _spotifyApi != null;

  SpotifyService() {
    _restoreSession();
  }

  Future<void> _restoreSession() async {
    try {
      final accessToken = await _storage.read(key: 'spotify_access_token');
      final refreshToken = await _storage.read(key: 'spotify_refresh_token');
      final expirationStr = await _storage.read(key: 'spotify_expiration');

      if (accessToken != null && refreshToken != null && expirationStr != null) {
        final expiration = DateTime.parse(expirationStr);
        final now = DateTime.now();

        // Create credentials initially
        var credentials = SpotifyApiCredentials(
          _clientId,
          null,
          accessToken: accessToken,
          refreshToken: refreshToken,
          expiration: expiration,
        );

        // Check if expired or expiring soon (within 5 mins)
        if (now.isAfter(expiration.subtract(const Duration(minutes: 5)))) {
          print("Token expired or expiring soon. Refreshing...");
          final refreshed = await _refreshAccessToken(refreshToken);
          if (refreshed != null) {
            credentials = refreshed;
          } else {
            print("Failed to refresh token during restore. Clearing session.");
            await logout();
            return;
          }
        }

        _spotifyApi = SpotifyApi(credentials);
        _authStateController.add(true);
        _startPolling();
      } else {
        _authStateController.add(false);
      }
    } catch (e) {
      print('Error restoring Spotify session: $e');
      await logout();
    }
  }

  Future<SpotifyApiCredentials?> _refreshAccessToken(String refreshToken) async {
    try {
      print("Attempting to refresh Spotify token...");
      final response = await http.post(
        Uri.parse('https://accounts.spotify.com/api/token'),
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: {
          'grant_type': 'refresh_token',
          'refresh_token': refreshToken,
          'client_id': _clientId,
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final newAccessToken = data['access_token'];
        final expiresIn = data['expires_in'];
        final newExpiration = DateTime.now().add(Duration(seconds: expiresIn));
        
        // Refresh token might be rotated, or stay the same
        final newRefreshToken = data['refresh_token'] ?? refreshToken;

        print("Token refreshed successfully.");

        final credentials = SpotifyApiCredentials(
          _clientId,
          null,
          accessToken: newAccessToken,
          refreshToken: newRefreshToken,
          expiration: newExpiration,
        );

        await _saveCredentials(credentials);
        return credentials;
      } else {
        print('Failed to refresh token: ${response.body}');
        return null;
      }
    } catch (e) {
      print('Error refreshing token: $e');
      return null;
    }
  }

  Future<void> logout() async {
    await _storage.delete(key: 'spotify_access_token');
    await _storage.delete(key: 'spotify_refresh_token');
    await _storage.delete(key: 'spotify_expiration');
    _spotifyApi = null;
    _authStateController.add(false);
    _pollingTimer?.cancel();
  }

  Future<void> _saveCredentials(SpotifyApiCredentials credentials) async {
    if (credentials.accessToken != null) {
      await _storage.write(key: 'spotify_access_token', value: credentials.accessToken);
    }
    if (credentials.refreshToken != null) {
      await _storage.write(key: 'spotify_refresh_token', value: credentials.refreshToken);
    }
    if (credentials.expiration != null) {
      await _storage.write(key: 'spotify_expiration', value: credentials.expiration!.toIso8601String());
    }
  }

  Future<bool> authenticate() async {
    try {
      final grant = SpotifyApi.authorizationCodeGrant(
        SpotifyApiCredentials(_clientId, null),
      );

      final authUrl = grant.getAuthorizationUrl(
        Uri.parse(_redirectUri),
        scopes: [
          'user-read-private',
          'user-read-email',
          'playlist-read-private',
          'user-modify-playback-state',
          'user-read-playback-state',
          'user-read-currently-playing'
        ],
      );

      final result = await FlutterWebAuth2.authenticate(
        url: authUrl.toString(),
        callbackUrlScheme: 'adhd-app',
      );

      final responseUri = Uri.parse(result);
      final client = await grant.handleAuthorizationResponse(responseUri.queryParameters);
      
      // Save credentials from the client
      final credentials = SpotifyApiCredentials(
        _clientId,
        null,
        accessToken: client.credentials.accessToken,
        refreshToken: client.credentials.refreshToken,
        expiration: client.credentials.expiration,
      );
      await _saveCredentials(credentials);

      _spotifyApi = SpotifyApi.fromClient(client);
      _authStateController.add(true); // Notify auth success
      _startPolling();
      
      return true;
    } on PlatformException catch (e) {
      print('Spotify Auth Platform Exception: ${e.message} (Code: ${e.code})');
      // User canceled or browser error
      return false;
    } catch (e, stack) {
      print('Spotify Auth Error: $e');
      print('Stack trace: $stack');
      return false;
    }
  }

  void _startPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = Timer.periodic(const Duration(seconds: 1), (_) async {
      if (_spotifyApi != null) {
        try {
          final state = await _spotifyApi!.player.playbackState();
          _playbackStateController.add(state);
        } catch (e) {
          // print('Error polling playback state: $e');
        }
      }
    });
  }

  // Helper to update UI immediately before API responds to make it feel responsive (Tiimo-like)
  void _updateOptimisticState(bool isPlaying) {
    try {
      // Construct a minimal valid state
      final state = PlaybackState.fromJson({
        'is_playing': isPlaying,
        'device': {'is_active': true, 'name': 'Spotify Connect'},
        'item': {'name': 'Loading...', 'artists': [{'name': 'Spotify'}]}
      });
      _playbackStateController.add(state);
    } catch (e) {
      print("Optimistic update error: $e");
    }
  }

  void dispose() {
    _pollingTimer?.cancel();
    _playbackStateController.close();
  }

  Future<List<PlaylistSimple>> getUserPlaylists() async {
    if (_spotifyApi == null) return [];
    try {
      final playlists = await _spotifyApi!.playlists.me.all();
      return playlists.toList();
    } catch (e) {
      print('Error fetching playlists: $e');
      return [];
    }
  }

  Future<void> openPlaylist(String playlistId) async {
    // Try to open in Spotify App using Deep Link
    final deepLink = Uri.parse('spotify:playlist:$playlistId');
    if (await canLaunchUrl(deepLink)) {
      await launchUrl(deepLink);
    } else {
      // Fallback to Web
      final webUrl = Uri.parse('https://open.spotify.com/playlist/$playlistId');
      await launchUrl(webUrl, mode: LaunchMode.externalApplication);
    }
  }

  Future<Playlist> getPlaylist(String playlistId) async {
    if (_spotifyApi == null) throw Exception("Not authenticated");
    return await _spotifyApi!.playlists.get(playlistId);
  }

  Future<void> playPlaylistOnActiveDevice(String playlistUri, {Function(String)? onError}) async {
    if (_spotifyApi == null) {
      onError?.call("Not authenticated");
      return;
    }
    try {
      // 1. Check for devices
      final devices = await _spotifyApi!.player.devices();
      
      if (devices.isEmpty) {
        onError?.call("No active Spotify device found. Opening Spotify...");
        final playlistId = playlistUri.split(':').last;
        await openPlaylist(playlistId);
        return;
      }

      // 2. Check if any device is active
      bool hasActiveDevice = devices.any((d) => d.isActive == true);

      if (!hasActiveDevice) {
        // Try to activate the first available device
        final deviceId = devices.first.id;
        if (deviceId != null) {
          await _spotifyApi!.player.transfer(deviceId);
          await Future.delayed(const Duration(milliseconds: 500));
        }
      }

      // 3. Start Playback
      _updateOptimisticState(true); // Show "Playing" immediately
      await _spotifyApi!.player.startWithContext(playlistUri);
      
      // 4. Force update state
      Future.delayed(const Duration(milliseconds: 500), () async {
        try {
          final state = await _spotifyApi!.player.playbackState();
          _playbackStateController.add(state);
        } catch (_) {}
      });

    } catch (e) {
      print('Error starting playback: $e');
      if (e.toString().contains("403") || e.toString().contains("Premium")) {
        onError?.call("Spotify Premium required for in-app control.");
      } else {
        onError?.call("Could not start playback. Opening Spotify...");
        final playlistId = playlistUri.split(':').last;
        await openPlaylist(playlistId);
      }
    }
  }

  // Curated Focus Playlists
  static const Map<String, String> focusPlaylists = {
    "Deep Focus": "37i9dQZF1DWZeKCadgRdKQ",
    "Lo-Fi Beats": "37i9dQZF1DWWQRwui0ExPn",
    "White Noise": "37i9dQZF1DWZZbwlv3HTJr",
    "Brain Food": "37i9dQZF1DWXLeA8Omikj7",
  };

  Future<void> openFocusPlaylist(String name, {Function(String)? onError}) async {
    final id = focusPlaylists[name];
    if (id != null) {
      // Try to play directly first
      await playPlaylistOnActiveDevice('spotify:playlist:$id', onError: onError);
    }
  }

  Future<void> pause() async {
    if (_spotifyApi == null) return;
    try {
      _updateOptimisticState(false);
      await _spotifyApi!.player.pause();
    } catch (e) {
      print('Error pausing: $e');
    }
  }

  Future<void> resume() async {
    if (_spotifyApi == null) return;
    try {
      _updateOptimisticState(true);
      await _spotifyApi!.player.resume();
    } catch (e) {
      print('Error resuming: $e');
    }
  }

  Future<void> skipNext() async {
    if (_spotifyApi == null) return;
    try {
      await _spotifyApi!.player.next();
    } catch (e) {
      print('Error skipping next: $e');
    }
  }

  Future<void> skipPrevious() async {
    if (_spotifyApi == null) return;
    try {
      await _spotifyApi!.player.previous();
    } catch (e) {
      print('Error skipping previous: $e');
    }
  }

  Future<List<Device>> getAvailableDevices() async {
    if (_spotifyApi == null) return [];
    try {
      final devices = await _spotifyApi!.player.devices();
      return devices.toList();
    } catch (e) {
      print('Error fetching devices: $e');
      return [];
    }
  }

  Future<bool> transferPlayback(String deviceId) async {
    if (_spotifyApi == null) return false;
    try {
      await _spotifyApi!.player.transfer(deviceId);
      return true;
    } catch (e) {
      print('Error transferring playback: $e');
      return false;
    }
  }
}
