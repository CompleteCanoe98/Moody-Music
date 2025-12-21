import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:spotify_sdk/spotify_sdk.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:spotify_sdk/models/image_uri.dart';
import 'dart:typed_data';
import 'package:marquee/marquee.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart'; 
import 'dart:async';
import 'package:url_launcher/url_launcher.dart';

class Music_Player extends StatefulWidget {
  final String mood;
  final String genre;

  const Music_Player({super.key, required this.mood, required this.genre});

  @override
  State<Music_Player> createState() => _Music_PlayerState();
}

class _Music_PlayerState extends State<Music_Player> with SingleTickerProviderStateMixin {
  final String clientId = dotenv.env['SPOTIFY_CLIENT_ID'] ?? '';
  final String redirectUrl = dotenv.env['SPOTIFY_REDIRECT_URL'] ?? '';

  // STATE VARIABLES
  late final AnimationController _rotationController;
  bool _isConnected = false;
  bool _isPaused = false;
  String _currentSongTitle = "Not Playing";
  String _currentArtistName = "Unknown Artist";
  Uint8List? _albumArt;
  String? songURI;
  
  // LOGIC VARIABLES
  String? _lastImageId;
  StreamSubscription? _playerSubscription;

  // --- PLAYLIST DATA ---
  final Map<String, String> mixMoodPlaylists = {
    'Happy' : 'spotify:playlist:37i9dQZF1EIgNoWOvbnUCk',
    'Sad' : 'spotify:playlist:37i9dQZF1EIhmSBwUDxg84',
    'Hype' : 'spotify:playlist:37i9dQZF1EIeU3RFfPV9ui',
    'Calm' : 'spotify:playlist:37i9dQZF1EIe7gYhF3NROX'
  };

  final Map<String, String> popmoodPlaylists = {
    'Happy': 'spotify:playlist:37i9dQZF1EIdYDF5bwm196', 
    'Sad': 'spotify:playlist:37i9dQZF1EIdZrPvCvCkh4',   
    'Hype': 'spotify:playlist:37i9dQZF1EIePmEgz7p91b', 
    'Calm': 'spotify:playlist:37i9dQZF1EIe0Dagt2506d',  
  };

  final Map<String, String> rockmoodPlaylists = {
    'Happy': 'spotify:playlist:37i9dQZF1EIhGU9wlBUJK9', 
    'Sad': 'spotify:playlist:37i9dQZF1EIcxHInSBQ4YQ',   
    'Hype': 'spotify:playlist:37i9dQZF1EIh4ObqDPnHKI', 
    'Calm': 'spotify:playlist:37i9dQZF1EIdpDytsjmeSg',  
  };
  
  final Map<String, String> instrumentalmoodPlaylists = {
    'Happy': 'spotify:playlist:37i9dQZF1EIe3Ecth03qvW', 
    'Sad': 'spotify:playlist:37i9dQZF1EIh1T1PukZNVG',   
    'Hype': 'spotify:playlist:37i9dQZF1EIcU1hUUSwSXK', 
    'Calm': 'spotify:playlist:5gaVqhrTrbBigae3ZAZfbq',  
  };

  final Map<String, String> hipHopmoodPlaylists = {
    'Happy': 'spotify:playlist:37i9dQZF1EIcHCl8kCVSai', 
    'Sad': 'spotify:playlist:37i9dQZF1EIcZUgkA3BSiL',   
    'Hype': 'spotify:playlist:37i9dQZF1EIfYOWZLm9iq6', 
    'Calm': 'spotify:playlist:37i9dQZF1EIf4OaZ1XTJYw',  
  };

  final Map<String, String> jazzmoodPlaylists = {
    'Happy': 'spotify:playlist:37i9dQZF1DWZCkamcYMQkz', 
    'Sad': 'spotify:playlist:37i9dQZF1DWWR73B3Bnjfh',   
    'Hype': 'spotify:playlist:37i9dQZF1EIfmQhasKW8vp', 
    'Calm': 'spotify:playlist:37i9dQZF1DX949uWWpmTjT',  
  };

  late final Map<String, Map<String, String>> genrePlaylists = {
    'Mix' :mixMoodPlaylists,
    'Pop': popmoodPlaylists,
    'Rock': rockmoodPlaylists,
    'Jazz': jazzmoodPlaylists,
    'Hip-Hop': hipHopmoodPlaylists,
    'Instrumental': instrumentalmoodPlaylists,
  };

  @override
  void initState() {
    super.initState();
    
    // Setup the spinner (10 seconds for one full rotation)
    _rotationController = AnimationController(
      duration: const Duration(seconds: 10), 
      vsync: this,
    );

    initSpotify();
  }

  @override
  void dispose() {
    _rotationController.dispose();
    _playerSubscription?.cancel();
    super.dispose();
  }

  Future<void> initSpotify() async {
    try {
      var result = await SpotifySdk.connectToSpotifyRemote(
        clientId: clientId,
        redirectUrl: redirectUrl,
      );
      
      if (!mounted) return;

      if (result) {
        setState(() => _isConnected = true);

        _playerSubscription = SpotifySdk.subscribePlayerState().listen((playerState) {
          _updatePlayerUI(playerState);
        }, onError: (error) {
           print("Player State Error: $error");
        });

        await Future.delayed(const Duration(milliseconds: 500));
        if (!mounted) return;
        
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

  void _updatePlayerUI(var playerState) {
    if (!mounted) return;
    
    if (playerState.track != null) {
      setState(() {
        _currentSongTitle = playerState.track!.name;
        _currentArtistName = playerState.track!.artist.name ?? "Unknown";
        _isPaused = playerState.isPaused;
        songURI = playerState.track!.uri;
      });

      if (_isPaused) {
        _rotationController.stop(); 
      } else {
        if (!_rotationController.isAnimating) {
          _rotationController.repeat(); 
        }
      }

      var newImageId = playerState.track?.imageUri.raw;
      if (newImageId != null && newImageId != _lastImageId) {
        _lastImageId = newImageId;
        fetchImage(playerState.track!.imageUri!);
      }
    }
  }

  Future<void> playMoodPlaylist() async {
    try {
      Map<String, String>? selectedGenreMap = genrePlaylists[widget.genre];

      if (selectedGenreMap != null) {
        String? playlistUri = selectedGenreMap[widget.mood];

        if (playlistUri != null) {
          await SpotifySdk.play(spotifyUri: playlistUri);
          
          await Future.delayed(const Duration(milliseconds: 500));
          if (!mounted) return;

          await SpotifySdk.setShuffle(shuffle: false);
          await SpotifySdk.setShuffle(shuffle: true);
          await SpotifySdk.skipNext(); 
        } else {
           _showError("No playlist found for ${widget.mood} in ${widget.genre}");
        }
      } else {
         _showError("Genre ${widget.genre} not found");
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
      if (!mounted) return;
      
      setState(() {
        _albumArt = image;
      });
    } catch (e) {
      print("Image fetch error: $e");
    }
  }

  Future<void> openSpotify() async {
    if (songURI == null) return;

    try {
      final Uri uri = Uri.parse(songURI!);

      // 1. Try to open the Spotify App directly
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        // 2. Fallback: Open the Standard Spotify Web Player
        final parts = songURI!.split(':');
        // Valid URI format: spotify:track:12345
        if (parts.length == 3) {
           // final type = parts[1]; // track
           final id = parts[2];     // id
           
           // Construct valid web URL: https://open.spotify.com/track/ID
           final webUri = Uri.parse("https://open.spotify.com/${parts[1]}/$id");
           
           if (await canLaunchUrl(webUri)) {
             await launchUrl(webUri, mode: LaunchMode.externalApplication);
           } else {
              _showError("Could not launch web player");
           }
        } else {
          _showError("Invalid Spotify URI");
        }
      }
    } catch (e) {
      print("Error launching URL: $e");
      _showError("Could not open Spotify");
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
    setState(() => _currentSongTitle = "Error");
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
      body: Container( 
        height: size.height, 
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment(0, -1),
            end: Alignment(0, 1),
            colors: [
              Color.fromARGB(255, 200, 169, 254),
              Color.fromARGB(255, 94, 37, 250) // Deep Purple Accent
            ],
          ),
        ),
        child: Column(
             children: [
            SizedBox(height: size.height * 0.05),
            const Text(
              'Playing music for Feeling:', 
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
              ),
            SizedBox(height: size.height * 0.005),
            Text(
              "${widget.mood} (${widget.genre})", 
              style: const TextStyle(
                fontSize: 32, 
                fontStyle: FontStyle.italic, 
                fontWeight: FontWeight.bold,
                shadows: [Shadow(offset: Offset(0, 4), blurRadius: 8.0, color: Colors.purple)],
              ),
              textAlign: TextAlign.center,
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
                child: _isConnected ?
                   Marquee( 
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
                  : const Center( 
                      child: Text(
                        "Connecting...",
                        style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.black),
                      ),
                    ),
              ),
            ),
            
            SizedBox(height: size.height * 0.02),

            // ROTATING VINYL WIDGET
            RotationTransition(
              turns: _rotationController,
              child: Container(
                height: 300,
                width: 300,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.black,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.4), 
                      blurRadius: 20, 
                      offset: const Offset(0, 10)
                    )
                  ],
                ),
                child: _albumArt != null
                    ? ClipOval( 
                        child: Image.memory(_albumArt!, fit: BoxFit.cover),
                      )
                    : const Icon(Icons.music_note, size: 100, color: Colors.white54),
              ),
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
                    splashColor: Colors.white.withOpacity(0.5),
                    highlightColor: Colors.white.withOpacity(0.5),
                    splashRadius: 20,
                  ),
                  
                  IconButton(
                    iconSize: 50,
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
                    splashColor: Colors.white.withOpacity(0.5),
                    highlightColor: Colors.white.withOpacity(0.5),
                    splashRadius: 20,
                  ),
                  
                  IconButton(
                    iconSize: 50,
                    icon: SvgPicture.asset('assets/icons/next.svg', height: 50, width: 50, colorFilter: const ColorFilter.mode(Colors.black, BlendMode.srcIn)),
                    onPressed: () => SpotifySdk.skipNext(),
                    splashColor: Colors.white.withOpacity(0.5),
                    highlightColor: Colors.white.withOpacity(0.5),
                    splashRadius: 20,
                  ),
                ],
              ),

            SizedBox(height: size.height * 0.03),

            if (_isConnected)
              Row(
                children: [
                  SizedBox(width: size.width * 0.35),
                  IconButton(
                    icon: SvgPicture.asset('assets/icons/add.svg', height: 40, width: 40, colorFilter: const ColorFilter.mode(Colors.black, BlendMode.srcIn)),
                    onPressed: () async { 
                      if (songURI != null) {
                        try {
                          await SpotifySdk.addToLibrary(spotifyUri: songURI!);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text("Added to Your Library!"),
                                backgroundColor: Colors.green,
                              ),
                            );
                          }
                        } catch (e) {
                          print("Error adding to library: $e");
                        }
                      }
                    },
                    splashColor: Colors.white.withOpacity(0.5),
                    highlightColor: Colors.white.withOpacity(0.5),
                    splashRadius: 20,
                  ),

                  SizedBox(width: size.width * 0.04),

                  IconButton(
                    onPressed: openSpotify, 
                    icon: SvgPicture.asset(
                      'assets/icons/spotify.svg', 
                      height: 40, 
                      width: 40, 
                      colorFilter: const ColorFilter.mode(Colors.black, BlendMode.srcIn)
                    ),
                    splashColor: Colors.white.withOpacity(0.5),
                    highlightColor: Colors.white.withOpacity(0.5),
                    splashRadius: 20,
                  ),
                ],
              )
          ],
        )
      )
    );
  }
}