import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'sound_service.dart';
import 'vibration_service.dart';

class SoundSettingsScreen extends StatefulWidget {
  const SoundSettingsScreen({super.key});

  @override
  State<SoundSettingsScreen> createState() => _SoundSettingsScreenState();
}

class _SoundSettingsScreenState extends State<SoundSettingsScreen> {
  String? _selectedSound;
  double _volume = 0.8;
  bool _vibrationEnabled = true;
  String _vibrationPattern = 'Standard';
  List<String> _customSounds = [];

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final sound = await SoundService().getSelectedSound();
    final volume = await SoundService().getVolume();
    final vibration = await SoundService().getVibrationEnabled();
    final vibrationPattern = await VibrationService().getVibrationPattern();
    final customSounds = await SoundService().getCustomSounds();

    setState(() {
      _selectedSound = sound;
      _volume = volume;
      _vibrationEnabled = vibration;
      _vibrationPattern = vibrationPattern;
      _customSounds = customSounds;
    });
  }

  Future<void> _addCustomSound() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.audio,
        allowMultiple: false,
      );

      if (result != null && result.files.single.path != null) {
        final filePath = result.files.single.path!;
        await SoundService().addCustomSound(filePath);
        await _loadSettings();
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Ses dosyasý eklendi!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Hata: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _removeCustomSound(String filePath) async {
    await SoundService().removeCustomSound(filePath);
    await _loadSettings();
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Ses dosyasý silindi!'),
        backgroundColor: Colors.orange,
      ),
    );
  }

  Future<void> _playSound(String soundName) async {
    await SoundService().setSelectedSound(soundName);
    await SoundService().playAlarmSound();
    
    setState(() {
      _selectedSound = soundName;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1A2E),
        title: const Text('Alarm Sesleri', style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Ses Seçimi
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Alarm Sesleri',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Default Sesler
                  ...SoundService.defaultSounds.map((sound) => _buildSoundTile(
                    sound: sound,
                    isCustom: false,
                    isSelected: _selectedSound == sound,
                  )),
                  
                  // Custom Sesler
                  if (_customSounds.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    const Text(
                      'Özel Sesler',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ..._customSounds.map((sound) => _buildSoundTile(
                      sound: sound.split('/').last,
                      isCustom: true,
                      isSelected: _selectedSound == sound,
                      filePath: sound,
                    )),
                  ],
                  
                  const SizedBox(height: 16),
                  
                  // Özel Ses Ekle
                  ElevatedButton.icon(
                    onPressed: _addCustomSound,
                    icon: const Icon(Icons.add),
                    label: const Text('Özel Ses Ekle'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 20),
            
            // Ses Seviyesi
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Ses Seviyesi',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      const Icon(Icons.volume_down, color: Colors.white54),
                      Expanded(
                        child: Slider(
                          value: _volume,
                          min: 0.0,
                          max: 1.0,
                          divisions: 10,
                          activeColor: Colors.orange,
                          inactiveColor: Colors.white24,
                          onChanged: (value) async {
                            setState(() {
                              _volume = value;
                            });
                            await SoundService().setVolume(value);
                          },
                        ),
                      ),
                      const Icon(Icons.volume_up, color: Colors.white54),
                    ],
                  ),
                  Text(
                    '%{(_volume * 100).toInt()}',
                    style: const TextStyle(color: Colors.white70),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 20),
            
            // Titreþim
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Titreþim',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  SwitchListTile(
                    title: const Text(
                      'Titreþim Aktif',
                      style: TextStyle(color: Colors.white),
                    ),
                    subtitle: const Text(
                      'Alarm çaldýðýnda titreþim',
                      style: TextStyle(color: Colors.white70),
                    ),
                    value: _vibrationEnabled,
                    onChanged: (value) async {
                      setState(() {
                        _vibrationEnabled = value;
                      });
                      await SoundService().setVibrationEnabled(value);
                    },
                    activeColor: Colors.orange,
                  ),
                  if (_vibrationEnabled) ...[
                    const SizedBox(height: 16),
                    const Text(
                      'Titreþim Pattern',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ...VibrationService().getAvailablePatterns().map((pattern) => 
                      Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        decoration: BoxDecoration(
                          color: _vibrationPattern == pattern 
                              ? Colors.blue.withOpacity(0.2) 
                              : Colors.white.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: _vibrationPattern == pattern ? Colors.blue : Colors.white24,
                          ),
                        ),
                        child: ListTile(
                          leading: Icon(
                            Icons.vibration,
                            color: _vibrationPattern == pattern ? Colors.blue : Colors.white70,
                          ),
                          title: Text(
                            pattern,
                            style: TextStyle(
                              color: _vibrationPattern == pattern ? Colors.blue : Colors.white,
                              fontWeight: _vibrationPattern == pattern ? FontWeight.bold : FontWeight.normal,
                            ),
                          ),
                          subtitle: Text(
                            VibrationService().getPatternDescription(pattern),
                            style: const TextStyle(color: Colors.white54, fontSize: 12),
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                onPressed: () => VibrationService().testVibration(pattern),
                                icon: const Icon(Icons.play_arrow, color: Colors.green),
                                tooltip: 'Test et',
                              ),
                              if (_vibrationPattern == pattern)
                                const Icon(Icons.check, color: Colors.blue),
                            ],
                          ),
                          onTap: () async {
                            setState(() {
                              _vibrationPattern = pattern;
                            });
                            await VibrationService().setVibrationPattern(pattern);
                          },
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSoundTile({
    required String sound,
    required bool isCustom,
    required bool isSelected,
    String? filePath,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: isSelected ? Colors.orange.withOpacity(0.2) : Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isSelected ? Colors.orange : Colors.white24,
        ),
      ),
      child: ListTile(
        leading: Icon(
          isCustom ? Icons.music_note : Icons.alarm,
          color: isSelected ? Colors.orange : Colors.white70,
        ),
        title: Text(
          sound,
          style: TextStyle(
            color: isSelected ? Colors.orange : Colors.white,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Play butonu
            IconButton(
              onPressed: () => _playSound(isCustom ? filePath! : sound),
              icon: const Icon(Icons.play_arrow, color: Colors.green),
              tooltip: 'Dinle',
            ),
            // Sil butonu (sadece custom sesler için)
            if (isCustom)
              IconButton(
                onPressed: () => _removeCustomSound(filePath!),
                icon: const Icon(Icons.delete, color: Colors.red),
                tooltip: 'Sil',
              ),
          ],
        ),
        onTap: () => _playSound(isCustom ? filePath! : sound),
      ),
    );
  }
}
