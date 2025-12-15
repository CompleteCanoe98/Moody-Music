import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:spotify_sdk/spotify_sdk.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:spotify_sdk/models/image_uri.dart';
import 'dart:typed_data';
import 'package:marquee/marquee.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart'; // Don't forget to import!
import 'dart:async';

class Music_Player extends StatefulWidget {
  final String mood;

  const Music_Player({super.key, required this.mood});

  @override
  State<Music_Player> createState() => _Music_PlayerState();
}

class _Music_PlayerState extends State<Music_Player> {
  final String clientId = dotenv.env['SPOTIFY_CLIENT_ID'] ?? '';
  final String redirectUrl = dotenv.env['SPOTIFY_REDIRECT_URL'] ?? '';

  // STATE VARIABLES
  bool _isConnected = false;
  bool _isPaused = false;
  String _currentSongTitle = "Not Playing";
  String _currentArtistName = "Unknown Artist";
  Uint8List? _albumArt;
  
  // LOGIC VARIABLES
  String? _lastImageId;
  StreamSubscription? _playerSubscription; // <--- 1. NEW: To track the listener

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

  // <--- 2. NEW: DISPOSE METHOD (Cleans up when you leave the page)
  @override
  void dispose() {
    _playerSubscription?.cancel(); // Stop listening to Spotify updates
    super.dispose();
  }

  Future<void> initSpotify() async {
    try {
      var result = await SpotifySdk.connectToSpotifyRemote(
        clientId: clientId,
        redirectUrl: redirectUrl,
      );
      
      // <--- 3. NEW: MOUNTED CHECK (Prevents crashes if user left)
      if (!mounted) return;

      if (result) {
        setState(() => _isConnected = true);

        // Start listening (and save the subscription so we can cancel it later)
        _playerSubscription = SpotifySdk.subscribePlayerState().listen((playerState) {
          // Pass the data to a dedicated method to keep this clean
          _updatePlayerUI(playerState);
        }, onError: (error) {
           print("Player State Error: $error");
        });

        // Wait before playing
        await Future.delayed(const Duration(milliseconds: 500));
        if (!mounted) return; // Check again after delay
        
        playMoodPlaylist();
      }
    } on PlatformException catch (e) {
      _showError("Connection Failed: ${e.message}");
    } on MissingPluginException {
      _showError("Spotify app not installed");
    } catch (e) {
      _showError("Unknown Error: $e");
    }
  }

  // <--- 4. NEW: DEDICATED UI UPDATE METHOD
  void _updatePlayerUI(var playerState) {
    if (!mounted) return; // Safety check
    
    if (playerState.track != null) {
      setState(() {
        _currentSongTitle = playerState.track!.name;
        _currentArtistName = playerState.track!.artist.name ?? "Unknown";
        _isPaused = playerState.isPaused;
      });

      // Image Logic
      var newImageId = playerState.track?.imageUri.raw;
      if (newImageId != null && newImageId != _lastImageId) {
        _lastImageId = newImageId;
        fetchImage(playerState.track!.imageUri!);
      }
    }
  }

  Future<void> playMoodPlaylist() async {
    try {
      String? playlistUri = moodPlaylists[widget.mood];
      if (playlistUri != null) {
        await SpotifySdk.play(spotifyUri: playlistUri);
        
        await Future.delayed(const Duration(milliseconds: 500));
        if (!mounted) return;

        // Force Shuffle Logic
        await SpotifySdk.setShuffle(shuffle: false);
        await SpotifySdk.setShuffle(shuffle: true);
        await SpotifySdk.skipNext(); 
      }
    } catch (e) {
      print("Playback error: $e");
    }
  }

  Future<void> fetchImage(ImageUri imageUri) async {
    try {
      var image = await SpotifySdk.getImage(
        imageUri: imageUri,
        dimension: ImageDimension.large,
      );
      if (!mounted) return; // Safety check before setState
      
      setState(() {
        _albumArt = image;
      });
    } catch (e) {
      print("Image fetch error: $e");
    }
  }

  // <--- 5. NEW: HELPER TO SHOW ERRORS ON SCREEN
  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
    setState(() => _currentSongTitle = "Error Connecting");
  }

  @override
  Widget build(BuildContext context) {
    // ... (Your existing build method goes here unchanged) ...
    // Just make sure your Container still has the gradient code!
    final size = MediaQuery.of(context).size;
    return Scaffold(
        backgroundColor: const Color.fromARGB(255, 219, 186, 233),
        appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 20,
        title: const Text("Moody Music", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Container( 
        // Force full screen height for gradient
        height: size.height, 
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFB388FF),
              Color.fromARGB(255, 115, 64, 253)
            ],
          ),
        ),
        child: Column(
             // ... Paste your existing children here ...
             children: [
            SizedBox(height: size.height * 0.05),
            const Text(
              'Playing music for Feeling:', 
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold

              ),

              ),
            SizedBox(height: size.height * 0.005),
            Text(
              widget.mood,
              style: const TextStyle(
                fontSize: 40, 
                fontStyle: FontStyle.italic, 
                fontWeight: FontWeight.bold,
                shadows: [Shadow(offset: Offset(0, 4), blurRadius: 8.0, color: Colors.purple)],
              ),
            ),
            SizedBox(height: size.height * 0.02),
            
            // TITLE
            Row(mainAxisAlignment: MainAxisAlignment.center ,
            
              children: [
                _isConnected ? const Icon(Icons.music_note, size: 30, color: Colors.black) : const SizedBox.shrink(),
                _isConnected ? const Text(
                  'Now Playing: ',
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.black),
                ): const SizedBox.shrink(),
              ],
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: SizedBox(
                height: 40,
                // FIX: Switch widgets based on connection
                child: _isConnected ?
                   Marquee( // If connected, use the scrolling widget
                      text: "$_currentSongTitle - $_currentArtistName    ",
                      style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color.fromARGB(255, 103, 0, 121),
                      shadows: [
                        Shadow(offset: Offset(0, 2), blurRadius: 4.0, color: Colors.black),
                      ]
                      ),
                      scrollAxis: Axis.horizontal,
                      blankSpace: 20.0,
                      velocity: 50.0,
                    )
                  : const Center( // If NOT connected, just use normal centered text
                      child: Text(
                        "Connecting...",
                        style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.black),
                      ),
                    ),
              ),
            ),
            
            SizedBox(height: size.height * 0.02),

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

            SizedBox(height: size.height * 0.01),

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
        )
      )
    );
  }
}