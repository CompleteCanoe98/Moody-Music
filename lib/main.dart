import 'package:flutter/material.dart';
import 'package:mood_music/player.dart';
import 'splashPage.dart'; 
import 'package:flutter_dotenv/flutter_dotenv.dart'; // Import this

Future<void> main() async {
  // Ensure Flutter is ready
  WidgetsFlutterBinding.ensureInitialized();
  
  // Load the secret keys
  await dotenv.load(fileName: ".env");

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Moody Music',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: const SplashPage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});
  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final List<String> moods = ['Happy', 'Sad', 'Hype', 'Calm'];
  late String selectedMood;

  @override
  void initState() {
    super.initState();
    selectedMood = moods[0];
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 219, 186, 233),
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 0, 0, 0),
        title: Text(
          widget.title,
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        automaticallyImplyLeading: false,
        toolbarHeight: 60,
        shadowColor: const Color(0xFF7C4DFF),
        elevation: 20,
      ),
      body: Container(
        height: size.height,
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFB388FF),
              Color.fromARGB(255, 115, 64, 253) // Deep Purple Accet
            ],
          ),
        ),
        child: SingleChildScrollView(
          child: Column(
            children: [
              SizedBox(height: size.height * 0.05), // 10% of screen height
              
              const Text(
                'Welcome to Moody Music!',
                style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              
              SizedBox(height: size.height * 0.03), // 3% of screen height
              
              const Text(
                'Select your current mood:',
                style: TextStyle(fontSize: 18),
              ),
              
              SizedBox(height: size.height * 0.03), // 3% of screen height

              // Dropdown Menu
              Container(
                width: size.width * 0.7, 
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: const Color.fromARGB(255, 242, 165, 255),
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: Colors.deepPurple, width: 4),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.deepPurple.withOpacity(0.3),
                      offset: const Offset(0, 4),
                      blurRadius: 8,
                    ),
                  ],
                ),
                child: Theme(
                  data: Theme.of(context).copyWith(
                    splashColor: Colors.deepPurple.withAlpha(100),
                    highlightColor: Colors.deepPurple.withAlpha(50),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: selectedMood,
                      icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Colors.deepPurple),
                      iconSize: 32,
                      isExpanded: true,
                      elevation: 16,
                      dropdownColor: const Color.fromARGB(255, 250, 200, 255),
                      borderRadius: BorderRadius.circular(20),
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.deepPurple,
                      ),
                      onChanged: (String? newValue) {
                        if (newValue != null) {
                          setState(() {
                            selectedMood = newValue;
                          });
                        }
                      },
                      items: moods.map<DropdownMenuItem<String>>((String mood) {
                        return DropdownMenuItem<String>(
                          value: mood,
                          child: Container(
                            alignment: Alignment.centerLeft,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              border: Border(
                                bottom: BorderSide(
                                  color: Colors.deepPurple.withOpacity(0.5),
                                  width: 1,
                                ),
                              ),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: Text(mood),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ),

              SizedBox(height: size.height * 0.05), // 5% of height
              
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => Music_Player(mood: selectedMood),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurple,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Play',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ),

              SizedBox(height: size.height * 0.05),

              // --- CHANGED SECTION: USING LOCAL ASSET GIF ---
              Image.asset(
                'assets/gifs/spinningCd.gif', // <--- MAKE SURE FILENAME MATCHES YOURS
                height: size.height * 0.3, 
                fit: BoxFit.contain, 
                errorBuilder: (context, error, stackTrace) {
                  // This error usually means you forgot Step 2 (updating pubspec.yaml)
                  // or the filename is spelled wrong.
                  return const Column(
                    children: [
                       Icon(Icons.error, color: Colors.red, size: 50),
                       Text('GIF not found!', style: TextStyle(color: Colors.red)),
                       Text('Check assets/gifs/ folder and pubspec.yaml', textAlign: TextAlign.center),
                    ],
                  );
                },
              ),
              
              const SizedBox(height: 20), // Bottom padding
            ],
          ),
        ),
      ),
    );
  }
}
