import 'package:url_launcher/url_launcher.dart';

enum FocusMood {
  study,
  chill,
  work,
  gaming,
}

class SpotifyService {
  // Hardcoded high-quality playlists
  // Study: Lo-Fi Beats
  static const _studyPlaylist = 'https://open.spotify.com/playlist/37i9dQZF1DX8Uebhn9wzrS'; 
  // Chill: Chill Hits
  static const _chillPlaylist = 'https://open.spotify.com/playlist/37i9dQZF1DX4WYpdgoIcn6'; 
  // Work: Deep Focus
  static const _workPlaylist = 'https://open.spotify.com/playlist/37i9dQZF1DX5g856aiKiDS'; 
  // Gaming: Top Gaming Tracks
  static const _gamingPlaylist = 'https://open.spotify.com/playlist/37i9dQZF1DWTyiBJ6yEqeu';

  String getPlaylistUrl(FocusMood mood) {
    switch (mood) {
      case FocusMood.study: return _studyPlaylist;
      case FocusMood.chill: return _chillPlaylist;
      case FocusMood.work: return _workPlaylist;
      case FocusMood.gaming: return _gamingPlaylist;
    }
  }

  String getMoodName(FocusMood mood) {
    switch (mood) {
      case FocusMood.study: return "Study Mode";
      case FocusMood.chill: return "Chill Vibes";
      case FocusMood.work: return "Deep Work";
      case FocusMood.gaming: return "Gaming Zone";
    }
  }

  String getMoodDescription(FocusMood mood) {
    switch (mood) {
      case FocusMood.study: return "Lo-Fi beats to help you concentrate.";
      case FocusMood.chill: return "Relaxing tracks to unwind.";
      case FocusMood.work: return "Instrumental focus music for productivity.";
      case FocusMood.gaming: return "High energy tracks for your gaming sessions.";
    }
  }

  String getMoodImageUrl(FocusMood mood) {
    switch (mood) {
      case FocusMood.study: 
        return "https://images.unsplash.com/photo-1516321318423-f06f85e504b3?w=500&q=80";
      case FocusMood.chill: 
        return "https://images.unsplash.com/photo-1518609878373-06d740f60d8b?w=500&q=80";
      case FocusMood.work: 
        return "https://images.unsplash.com/photo-1497366216548-37526070297c?w=500&q=80";
      case FocusMood.gaming:
        return "https://images.unsplash.com/photo-1538481199705-c710c4e965fc?w=500&q=80";
    }
  }

  Future<void> launchSpotify(FocusMood mood) async {
    final webUrl = getPlaylistUrl(mood);
    
    // 1. Try to create a Deep Link (spotify:playlist:ID)
    // Extract ID from https://open.spotify.com/playlist/ID
    final uri = Uri.parse(webUrl);
    final pathSegments = uri.pathSegments;
    
    if (pathSegments.length >= 2 && pathSegments[0] == 'playlist') {
      final playlistId = pathSegments[1];
      final deepLink = Uri.parse('spotify:playlist:$playlistId');

      // Try to launch the App
      if (await canLaunchUrl(deepLink)) {
        await launchUrl(deepLink);
        return;
      }
    }

    // 2. Fallback to Web URL if App not installed or deep link fails
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      throw 'Could not launch $webUrl';
    }
  }
}

