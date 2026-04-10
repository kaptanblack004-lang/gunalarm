import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SpotifyTrack {
  final String id;
  final String name;
  final String artist;
  final String album;
  final String imageUrl;
  final String previewUrl;
  final int durationMs;

  SpotifyTrack({
    required this.id,
    required this.name,
    required this.artist,
    required this.album,
    required this.imageUrl,
    required this.previewUrl,
    required this.durationMs,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'artist': artist,
      'album': album,
      'imageUrl': imageUrl,
      'previewUrl': previewUrl,
      'durationMs': durationMs,
    };
  }

  factory SpotifyTrack.fromJson(Map<String, dynamic> json) {
    return SpotifyTrack(
      id: json['id'],
      name: json['name'],
      artist: json['artist'],
      album: json['album'],
      imageUrl: json['imageUrl'],
      previewUrl: json['previewUrl'],
      durationMs: json['durationMs'],
    );
  }
}

class SpotifyPlaylist {
  final String id;
  final String name;
  final String description;
  final String imageUrl;
  final int trackCount;

  SpotifyPlaylist({
    required this.id,
    required this.name,
    required this.description,
    required this.imageUrl,
    required this.trackCount,
  });
}

class SpotifyService {
  static final SpotifyService _instance = SpotifyService._internal();
  factory SpotifyService() => _instance;
  SpotifyService._internal();

  bool _isConnected = false;
  String? _accessToken;
  String? _refreshToken;
  List<SpotifyTrack> _recentTracks = [];
  List<SpotifyPlaylist> _playlists = [];
  SpotifyTrack? _selectedWakeUpTrack;
  String? _selectedPlaylistId;

  bool get isConnected => _isConnected;
  String? get accessToken => _accessToken;
  SpotifyTrack? get selectedWakeUpTrack => _selectedWakeUpTrack;
  String? get selectedPlaylistId => _selectedPlaylistId;

  static const List<SpotifyTrack> _mockTracks = [
    SpotifyTrack(
      id: '1',
      name: 'Morning Breeze',
      artist: 'Nature Sounds',
      album: 'Peaceful Mornings',
      imageUrl: 'https://picsum.photos/seed/morning1/300/300.jpg',
      previewUrl: 'https://example.com/preview1.mp3',
      durationMs: 180000,
    ),
    SpotifyTrack(
      id: '2',
      name: 'Sunrise Melody',
      artist: 'Acoustic Dreams',
      album: 'Gentle Awakening',
      imageUrl: 'https://picsum.photos/seed/sunrise2/300/300.jpg',
      previewUrl: 'https://example.com/preview2.mp3',
      durationMs: 240000,
    ),
    SpotifyTrack(
      id: '3',
      name: 'Ocean Waves',
      artist: 'Sea Sounds',
      album: 'Coastal Dreams',
      imageUrl: 'https://picsum.photos/seed/ocean3/300/300.jpg',
      previewUrl: 'https://example.com/preview3.mp3',
      durationMs: 300000,
    ),
    SpotifyTrack(
      id: '4',
      name: 'Forest Birds',
      artist: 'Nature Harmony',
      album: 'Wilderness',
      imageUrl: 'https://picsum.photos/seed/forest4/300/300.jpg',
      previewUrl: 'https://example.com/preview4.mp3',
      durationMs: 210000,
    ),
    SpotifyTrack(
      id: '5',
      name: 'Gentle Piano',
      artist: 'Classical Moods',
      album: 'Soft Awakening',
      imageUrl: 'https://picsum.photos/seed/piano5/300/300.jpg',
      previewUrl: 'https://example.com/preview5.mp3',
      durationMs: 195000,
    ),
  ];

  static const List<SpotifyPlaylist> _mockPlaylists = [
    SpotifyPlaylist(
      id: 'playlist1',
      name: 'Morning Vibes',
      description: 'Enerjik güne baþlangýç müzikleri',
      imageUrl: 'https://picsum.photos/seed/playlist1/300/300.jpg',
      trackCount: 25,
    ),
    SpotifyPlaylist(
      id: 'playlist2',
      name: 'Peaceful Awakening',
      description: 'Sakin ve huzurlu uyanma müzikleri',
      imageUrl: 'https://picsum.photos/seed/playlist2/300/300.jpg',
      trackCount: 18,
    ),
    SpotifyPlaylist(
      id: 'playlist3',
      name: 'Nature Sounds',
      description: 'Doða sesleri ve rahatlama müzikleri',
      imageUrl: 'https://picsum.photos/seed/playlist3/300/300.jpg',
      trackCount: 32,
    ),
    SpotifyPlaylist(
      id: 'playlist4',
      name: 'Epic Wakeup',
      description: 'Enerjik ve motivasyonel müzikler',
      imageUrl: 'https://picsum.photos/seed/playlist4/300/300.jpg',
      trackCount: 20,
    ),
  ];

  Future<bool> connectToSpotify() async {
    try {
      // Simüle edilmiþ Spotify baðlantýsý
      await Future.delayed(const Duration(seconds: 2));
      
      _isConnected = true;
      _accessToken = 'mock_access_token_${DateTime.now().millisecondsSinceEpoch}';
      _refreshToken = 'mock_refresh_token';
      
      await _loadMockData();
      await _saveConnectionState();
      
      debugPrint('=== SPOTIFY CONNECTED ===');
      debugPrint('Access Token: ${_accessToken?.substring(0, 20)}...');
      debugPrint('========================');
      
      return true;
    } catch (e) {
      debugPrint('Spotify connection error: $e');
      return false;
    }
  }

  Future<void> disconnectFromSpotify() async {
    _isConnected = false;
    _accessToken = null;
    _refreshToken = null;
    _recentTracks.clear();
    _playlists.clear();
    _selectedWakeUpTrack = null;
    _selectedPlaylistId = null;
    
    await _saveConnectionState();
    
    debugPrint('=== SPOTIFY DISCONNECTED ===');
  }

  Future<void> _loadMockData() async {
    _recentTracks = List.from(_mockTracks);
    _playlists = List.from(_mockPlaylists);
    
    // Rastgele bir seçili parça belirle
    _selectedWakeUpTrack = _mockTracks.first;
    _selectedPlaylistId = _mockPlaylists.first.id;
  }

  Future<void> _saveConnectionState() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('spotify_connected', _isConnected);
    await prefs.setString('spotify_access_token', _accessToken ?? '');
    await prefs.setString('spotify_refresh_token', _refreshToken ?? '');
    
    if (_selectedWakeUpTrack != null) {
      await prefs.setString('selected_track', jsonEncode(_selectedWakeUpTrack!.toJson()));
    }
    
    if (_selectedPlaylistId != null) {
      await prefs.setString('selected_playlist_id', _selectedPlaylistId!);
    }
  }

  Future<void> _loadConnectionState() async {
    final prefs = await SharedPreferences.getInstance();
    _isConnected = prefs.getBool('spotify_connected') ?? false;
    _accessToken = prefs.getString('spotify_access_token');
    _refreshToken = prefs.getString('spotify_refresh_token');
    
    final selectedTrackJson = prefs.getString('selected_track');
    if (selectedTrackJson != null) {
      _selectedWakeUpTrack = SpotifyTrack.fromJson(jsonDecode(selectedTrackJson));
    }
    
    _selectedPlaylistId = prefs.getString('selected_playlist_id');
    
    if (_isConnected) {
      await _loadMockData();
    }
  }

  Future<List<SpotifyTrack>> searchTracks(String query) async {
    if (!_isConnected) return [];
    
    // Simüle edilmiþ arama
    await Future.delayed(const Duration(milliseconds: 800));
    
    return _mockTracks.where((track) =>
      track.name.toLowerCase().contains(query.toLowerCase()) ||
      track.artist.toLowerCase().contains(query.toLowerCase())
    ).toList();
  }

  Future<List<SpotifyTrack>> getWakeUpPlaylists() async {
    if (!_isConnected) return [];
    
    // Sabah müzikleri için öneriler
    return _mockTracks.where((track) =>
      track.name.toLowerCase().contains('morning') ||
      track.name.toLowerCase().contains('sunrise') ||
      track.name.toLowerCase().contains('gentle') ||
      track.artist.toLowerCase().contains('nature') ||
      track.artist.toLowerCase().contains('acoustic')
    ).toList();
  }

  Future<List<SpotifyPlaylist>> getUserPlaylists() async {
    if (!_isConnected) return [];
    
    await Future.delayed(const Duration(milliseconds: 500));
    return List.from(_playlists);
  }

  Future<void> selectWakeUpTrack(SpotifyTrack track) async {
    _selectedWakeUpTrack = track;
    await _saveConnectionState();
    
    debugPrint('Selected wake-up track: ${track.name} by ${track.artist}');
  }

  Future<void> selectPlaylist(String playlistId) async {
    _selectedPlaylistId = playlistId;
    await _saveConnectionState();
    
    debugPrint('Selected playlist: $playlistId');
  }

  Future<void> playWakeUpMusic() async {
    if (!_isConnected || _selectedWakeUpTrack == null) return;
    
    debugPrint('=== PLAYING SPOTIFY MUSIC ===');
    debugPrint('Track: ${_selectedWakeUpTrack!.name}');
    debugPrint('Artist: ${_selectedWakeUpTrack!.artist}');
    debugPrint('Duration: ${(_selectedWakeUpTrack!.durationMs / 1000 / 60).toStringAsFixed(1)} minutes');
    debugPrint('==========================');
    
    // Gerçek uygulamada burada Spotify SDK kullanýlýr
    // await SpotifySdk.play(trackId: _selectedWakeUpTrack!.id);
  }

  Future<void> playPlaylist() async {
    if (!_isConnected || _selectedPlaylistId == null) return;
    
    final playlist = _playlists.firstWhere((p) => p.id == _selectedPlaylistId);
    
    debugPrint('=== PLAYING SPOTIFY PLAYLIST ===');
    debugPrint('Playlist: ${playlist.name}');
    debugPrint('Description: ${playlist.description}');
    debugPrint('Track Count: ${playlist.trackCount}');
    debugPrint('===============================');
    
    // Gerçek uygulamada burada Spotify SDK kullanýlýr
    // await SpotifySdk.play(playlistId: _selectedPlaylistId!);
  }

  Future<void> pauseMusic() async {
    if (!_isConnected) return;
    
    debugPrint('=== PAUSED SPOTIFY MUSIC ===');
    
    // Gerçek uygulamada burada Spotify SDK kullanýlýr
    // await SpotifySdk.pause();
  }

  Future<void> stopMusic() async {
    if (!_isConnected) return;
    
    debugPrint('=== STOPPED SPOTIFY MUSIC ===');
    
    // Gerçek uygulamada burada Spotify SDK kullanýlýr
    // await SpotifySdk.stop();
  }

  Future<void> setVolume(double volume) async {
    if (!_isConnected) return;
    
    debugPrint('=== SPOTIFY VOLUME SET ===');
    debugPrint('Volume: ${(volume * 100).toInt()}%');
    debugPrint('==========================');
    
    // Gerçek uygulamada burada Spotify SDK kullanýlýr
    // await SpotifySdk.setVolume(volume);
  }

  Future<String> getCurrentPlayingTrack() async {
    if (!_isConnected || _selectedWakeUpTrack == null) return '';
    
    return '${_selectedWakeUpTrack!.name} - ${_selectedWakeUpTrack!.artist}';
  }

  Future<bool> isPlaying() async {
    if (!_isConnected) return false;
    
    // Simüle edilmiþ durum
    return false;
  }

  Future<void> refreshToken() async {
    if (_refreshToken == null) return;
    
    // Simüle edilmiþ token yenileme
    await Future.delayed(const Duration(seconds: 1));
    
    _accessToken = 'refreshed_access_token_${DateTime.now().millisecondsSinceEpoch}';
    await _saveConnectionState();
    
    debugPrint('=== SPOTIFY TOKEN REFRESHED ===');
  }

  Future<void> initialize() async {
    await _loadConnectionState();
    
    if (_isConnected) {
      debugPrint('Spotify already connected');
    } else {
      debugPrint('Spotify not connected');
    }
  }

  // Premium özellikler
  Future<List<SpotifyTrack>> getPersonalizedRecommendations() async {
    if (!_isConnected) return [];
    
    // Kullanýcý dinleme geçmiþine göre öneriler
    await Future.delayed(const Duration(seconds: 1));
    
    return _mockTracks.take(3).toList();
  }

  Future<void> createWakeUpPlaylist(String name, List<String> trackIds) async {
    if (!_isConnected) return;
    
    debugPrint('=== CREATING PLAYLIST ===');
    debugPrint('Name: $name');
    debugPrint('Tracks: ${trackIds.length}');
    debugPrint('========================');
    
    // Gerçek uygulamada burada Spotify API kullanýlýr
  }

  Future<void> addToWakeUpPlaylist(String trackId) async {
    if (!_isConnected || _selectedPlaylistId == null) return;
    
    debugPrint('=== ADDING TO PLAYLIST ===');
    debugPrint('Playlist: $_selectedPlaylistId');
    debugPrint('Track: $trackId');
    debugPrint('========================');
    
    // Gerçek uygulamada burada Spotify API kullanýlýr
  }
}
