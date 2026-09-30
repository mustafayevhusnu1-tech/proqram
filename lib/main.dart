import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

void main() {
  runApp(const MaterialApp(
    home: TikTokDownloaderApp(),
    debugShowCheckedModeBanner: false,
  ));
}

class TikTokDownloaderApp extends StatefulWidget {
  const TikTokDownloaderApp({super.key});

  @override
  State<TikTokDownloaderApp> createState() => _TikTokDownloaderAppState();
}

class _TikTokDownloaderAppState extends State<TikTokDownloaderApp> {
  final TextEditingController _urlController = TextEditingController();
  bool _isLoading = false;
  String? _videoUrl;
  String? _title;
  String? _error;

  Future<void> fetchVideo() async {
    final inputUrl = _urlController.text.trim();
    if (inputUrl.isEmpty) return;

    setState(() {
      _isLoading = true;
      _error = null;
      _videoUrl = null;
    });

    try {
      final response = await http.get(
        Uri.parse('https://www.tikwm.com/api/?url=$inputUrl'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['code'] == 0) {
          setState(() {
            _videoUrl = data['data']['play'];
            _title = data['data']['title'];
          });
        } else {
          setState(() {
            _error = "Video tapılmadı və ya link səhvdir.";
          });
        }
      } else {
        setState(() {
          _error = "Server xətası baş verdi.";
        });
      }
    } catch (e) {
      setState(() {
        _error = "Xəta: İnternet bağlantısını yoxlayın.";
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        title: const Text('TikTok No-Watermark', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.black,
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _urlController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'TikTok video linkini yapışdırın...',
                hintStyle: const TextStyle(color: Colors.grey),
                filled: true,
                fillColor: const Color(0xFF1E1E1E),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFE2C55),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: _isLoading ? null : fetchVideo,
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Videonu Tap', style: TextStyle(fontSize: 16, color: Colors.white)),
              ),
            ),
            const SizedBox(height: 24),
            if (_error != null)
              Text(_error!, style: const TextStyle(color: Colors.redAccent)),
            if (_videoUrl != null) ...[
              Text(
                _title ?? '',
                style: const TextStyle(color: Colors.white70),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 16),
              SelectableText(
                'Təmiz video linki:\n$_videoUrl',
                style: const TextStyle(color: Colors.greenAccent),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
