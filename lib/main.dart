import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'face_api_service.dart';
import 'theme_provider.dart';
import 'calendar.dart';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (_) => ThemeProvider(),
      child: const SkinForRealApp(),
    ),
  );
}

class SkinForRealApp extends StatelessWidget {
  const SkinForRealApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    return MaterialApp(
      title: 'SkinForReal',
      debugShowCheckedModeBanner: false,
      themeMode: themeProvider.themeMode,
      theme: ThemeData(
        brightness: Brightness.light,
        fontFamily: 'San Francisco',
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        fontFamily: 'San Francisco',
      ),
      home: const SkinAnalyzer(),
    );
  }
}

class SkinAnalyzer extends StatefulWidget {
  const SkinAnalyzer({super.key});

  @override
  State<SkinAnalyzer> createState() => _SkinAnalyzerState();
}

class _SkinAnalyzerState extends State<SkinAnalyzer> with SingleTickerProviderStateMixin {
  File? _imageFile;
  String _skinColor = '';
  String _skinType = '';
  String _tips = '';
  String _culpritMessage = '';
  String _manualOverrideTone = '';
  String _lastSkinType = '';
  bool _loading = false;

  final List<String> _skinToneOptions = ['Light', 'Medium', 'Tan/Olive', 'Brown', 'Deep/Dark'];
  late AnimationController _fadeController;
  late Animation<double> _fadeIn;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
    _fadeIn = CurvedAnimation(parent: _fadeController, curve: Curves.easeIn);
    _loadTonePreference();
  }

  Future<void> _loadTonePreference() async {
    final prefs = await SharedPreferences.getInstance();
    final tone = prefs.getString('manual_override_tone');
    if (tone != null && _skinToneOptions.contains(tone)) {
      setState(() => _manualOverrideTone = tone);
    }
  }

  Future<void> _saveTonePreference(String tone) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('manual_override_tone', tone);
  }

  Future<void> _pickImage() async {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("⚠️ Flash Disclaimer"),
        content: const Text("If you're using flash or your environment is bright, your skin tone might appear lighter than usual. If the detected tone looks off, select your correct tone from the dropdown after capture."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Got it!"),
          )
        ],
      ),
    ).then((_) async {
      final pickedFile = await ImagePicker().pickImage(source: ImageSource.camera);
      if (pickedFile != null) {
        final file = File(pickedFile.path);
        setState(() {
          _imageFile = file;
          _skinColor = '';
          _skinType = '';
          _tips = '';
          _culpritMessage = '';
          _loading = true;
        });
        await _analyzeImage(file);
      }
    });
  }

  Future<void> _analyzeImage(File image) async {
    try {
      final attributes = await FaceApiService.analyzeFaceFromImage(image);
      final tone = FaceApiService.estimateSkinColorLabel(attributes);
      final type = FaceApiService.detectSkinType(attributes);
      final selectedTone = _manualOverrideTone.isNotEmpty ? _manualOverrideTone : tone;
      final tips = FaceApiService.skincareTips(type, selectedTone);
      final routine = FaceApiService.customizedRoutine(type, selectedTone);

      final prefs = await SharedPreferences.getInstance();
      final dateStr = DateTime.now().toIso8601String().split('T')[0];

      await prefs.setString('progress_$dateStr', type);
      await prefs.setString('log_$dateStr', jsonEncode({
        'type': type,
        'color': selectedTone,
        'tips': '$tips\n\n$routine',
      }));

      setState(() {
        _skinColor = tone;
        _skinType = type;
        _tips = '$tips\n\n$routine';
        _culpritMessage = FaceApiService.suggestCulprit(_lastSkinType, type);
        _lastSkinType = type;
        _loading = false;
      });

      _fadeController.forward(from: 0);
    } catch (e) {
      setState(() {
        _skinColor = 'Error: ${e.toString()}';
        _loading = false;
      });
    }
  }

  void _updateManualTone(String? tone) {
    if (tone == null) return;
    _saveTonePreference(tone);
    final tips = FaceApiService.skincareTips(_skinType, tone);
    final routine = FaceApiService.customizedRoutine(_skinType, tone);

    setState(() {
      _manualOverrideTone = tone;
      _tips = '$tips\n\n$routine';
    });
  }

  Widget _buildInfoCard(String title, String content, Color textColor) {
    return FadeTransition(
      opacity: _fadeIn,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 10),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.95),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 6)],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: textColor)),
            const SizedBox(height: 8),
            Text(content, style: TextStyle(fontSize: 14, height: 1.5, color: textColor)),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black87;
    final themeProvider = Provider.of<ThemeProvider>(context);

    return Scaffold(
      body: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: isDark
              ? null
              : const LinearGradient(
                  colors: [Color(0xFFFDEBFF), Color(0xFFE1D8FF), Color(0xFFD5ECF5)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
          color: isDark ? Colors.black : null,
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Text('SkinForReal Prototype', style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('🌙', style: TextStyle(fontSize: 20)),
                      Switch(
                        value: themeProvider.themeMode == ThemeMode.dark,
                        onChanged: (_) => themeProvider.toggleTheme(),
                      ),
                      const Text('☀️', style: TextStyle(fontSize: 20)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    onPressed: _pickImage,
                    icon: const Icon(Icons.camera_alt_outlined),
                    label: const Text('Take a Picture'),
                    style: ElevatedButton.styleFrom(
                      foregroundColor: Colors.purple.shade900,
                      backgroundColor: Colors.white,
                      elevation: 4,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(context, PageRouteBuilder(
                        pageBuilder: (_, __, ___) => const SkinProgressCalendar(),
                        transitionsBuilder: (_, animation, __, child) {
                          return FadeTransition(opacity: animation, child: child);
                        },
                      ));
                    },
                    icon: const Icon(Icons.calendar_today),
                    label: const Text('Track Skin Progress'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepPurple,
                      foregroundColor: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (_imageFile != null)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.file(_imageFile!, height: 200),
                    ),
                  if (_skinColor.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: DropdownButton<String>(
                        value: _manualOverrideTone.isNotEmpty ? _manualOverrideTone : _skinColor,
                        items: _skinToneOptions.map((tone) {
                          return DropdownMenuItem<String>(
                            value: tone,
                            child: Text(tone),
                          );
                        }).toList(),
                        onChanged: _updateManualTone,
                      ),
                    ),
                  const SizedBox(height: 10),
                  if (_loading)
                    const CircularProgressIndicator()
                  else if (_skinColor.isNotEmpty)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildInfoCard('Skin Tone', _manualOverrideTone.isNotEmpty ? _manualOverrideTone : _skinColor, textColor),
                        _buildInfoCard('Skin Type', _skinType, textColor),
                        _buildInfoCard('Tips & Routine', _tips, textColor),
                        _buildInfoCard('Flare-up & Trend Check', _culpritMessage, textColor),
                      ],
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
