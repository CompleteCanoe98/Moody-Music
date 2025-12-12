import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:spotify_sdk/spotify_sdk.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:spotify_sdk/models/image_uri.dart';
import 'dart:typed_data';
import 'package:marquee/marquee.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart'; // Don't forget to import!

class Music_Player extends StatefulWidget {
  final String mood;

  const Music_Player({super.key, required this.mood});

  @override
  State<Music_Player> createState() => _Music_PlayerState();
}

class _Music_PlayerState extends State<Music_Player> {
  final String clientId = dotenv.env['SPOTIFY_CLIENT_ID'] ?? '';
  final String redirectUrl = dotenv.env['SPOTIFY_REDIRECT_URL'] ?? '';

  bool _isConnected = false;
  String _currentSongTitle = "Not Playing";
  Uint8List? _albumArt;
  bool _isPaused = false; // Added this back to help with button toggling
  String? _lastImageId;

  final Map<String, String> moodPlaylists = {
    'Happy': 'spotify:playlist:37i9dQZF1DXdPec7aLTmlC', 
    'Sad': 'spotify:playlist:37i9dQZF1DWSqBruwoIXkA',   
    'Hype': 'spotify:playlist:37i9dQZF1EIeU3RFfPV9ui', 
    'Calm': 'spotify:playlist:37i9dQZF1DWZeKCadgRdKQ',  
  };

  @override
  void initState() {
    super.initState();
    initSpotify();
  }

  // 1. Connect AND Start Listening immediately
  Future<void> initSpotify() async {
    try {
      var result = await SpotifySdk.connectToSpotifyRemote(
        clientId: clientId,
        redirectUrl: redirectUrl,
      );

      if (result) {
        setState(() {
          _isConnected = true;
        });

        // CRITICAL FIX: Start listening BEFORE playing music
        SpotifySdk.subscribePlayerState().listen((playerState) {
          if (playerState.track != null) {
            setState(() {
              _currentSongTitle = playerState.track!.name;
              _isPaused = playerState.isPaused;
            });


            // --- THE FIX IS HERE ---
            // Only fetch the image if the ID is different from the last one we saw
            var newImageId = playerState.track?.imageUri.raw;
            // Fetch image if it exists
            if (newImageId != null && newImageId != _lastImageId) {
              fetchImage(playerState.track!.imageUri!);
              _lastImageId = newImageId;
            }
          }
        });

        // Now that we are listening, start the music
        await Future.delayed(const Duration(milliseconds: 500));
        playMoodPlaylist();
      }
    } on PlatformException catch (e) {
      print("Error: ${e.message}");
      setState(() => _currentSongTitle = "Connection Failed");
    } on MissingPluginException {
      print("Spotify not installed");
    }
  }

  // 2. Just handle the playback logic
  Future<void> playMoodPlaylist() async {
    try {
      String? playlistUri = moodPlaylists[widget.mood];
      if (playlistUri != null) {
        // Play
        await SpotifySdk.play(spotifyUri: playlistUri);
        
        // Wait, Shuffle, Skip (Randomize)
        await Future.delayed(const Duration(milliseconds: 500));
        await SpotifySdk.setShuffle(shuffle: false);
        await SpotifySdk.setShuffle(shuffle: true);
        await SpotifySdk.skipNext(); 
      }
    } catch (e) {
      print("Error playing: $e");
    }
  }

  Future<void> fetchImage(ImageUri imageUri) async {
    try {
      var image = await SpotifySdk.getImage(
        imageUri: imageUri,
        dimension: ImageDimension.large,
      );
      setState(() {
        _albumArt = image;
      });
    } catch (e) {
      print("Error fetching image: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 219, 186, 233),
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 20,
        title: const Text("Moody Music", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Center(
        child: Column(
          children: [
            SizedBox(height: size.height * 0.05),
            const Text('Playing music for Feeling:', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
            SizedBox(height: size.height * 0.02),
            Text(
              widget.mood,
              style: const TextStyle(
                fontSize: 40, 
                fontStyle: FontStyle.italic, 
                fontWeight: FontWeight.bold,
                shadows: [Shadow(offset: Offset(0, 6), blurRadius: 4.0, color: Colors.black26)],
              ),
            ),
            SizedBox(height: size.height * 0.02),
            
            // TITLE
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: SizedBox(
                    height: 40, // Constraint height is required for Marquee
                    child: Marquee(
                      text: _isConnected ? "Playing: $_currentSongTitle   " : "Connecting...   ",
                      style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.black),
                      scrollAxis: Axis.horizontal,
                      blankSpace: 20.0,
                      velocity: 50.0,
                    ),
                  )
            ),
            
            SizedBox(height: size.height * 0.05),

            // ALBUM ART
            Container(
              height: 300,
              width: 300,
              decoration: BoxDecoration(
                color: Colors.black12,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 15, offset: const Offset(0, 10))],
              ),
              child: _albumArt != null
                  ? ClipRRect(borderRadius: BorderRadius.circular(20), child: Image.memory(_albumArt!, fit: BoxFit.cover))
                  : const Icon(Icons.music_note, size: 100, color: Colors.white54),
            ),

            SizedBox(height: size.height * 0.05),

            // CONTROLS
            if (_isConnected)
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    iconSize: 50,
                    icon: SvgPicture.asset('assets/icons/backPlay.svg', height: 50, width: 50, colorFilter: const ColorFilter.mode(Colors.black, BlendMode.srcIn)),
                    onPressed: () => SpotifySdk.skipPrevious(),
                  ),
                  
                  // SMART TOGGLE BUTTON (Play/Pause)
                  IconButton(
                    iconSize: 50,
                    // If Paused -> Show Play Icon. If Playing -> Show Pause Icon.
                    icon: _isPaused 
                      ? SvgPicture.asset('assets/icons/play.svg', height: 50, width: 50, colorFilter: const ColorFilter.mode(Colors.black, BlendMode.srcIn))
                      : SvgPicture.asset('assets/icons/pause.svg', height: 50, width: 50, colorFilter: const ColorFilter.mode(Colors.black, BlendMode.srcIn)),
                    onPressed: () {
                      if (_isPaused) {
                        SpotifySdk.resume();
                      } else {
                        SpotifySdk.pause();
                      }
                    },
                  ),
                  
                  IconButton(
                    iconSize: 50,
                    icon: SvgPicture.asset('assets/icons/next.svg', height: 50, width: 50, colorFilter: const ColorFilter.mode(Colors.black, BlendMode.srcIn)),
                    onPressed: () => SpotifySdk.skipNext(),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}