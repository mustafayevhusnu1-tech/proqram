import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:gal/gal.dart';

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
  bool _isDownloading = false;
  String? _videoUrl;
  String? _title;
  String? _statusMessage;
  Color _statusColor = Colors.white70;

  Future<void> fetchVideo() async {
    final inputUrl = _urlController.text.trim();
    if (inputUrl.isEmpty) return;

    setState(() {
      _isLoading = true;
      _statusMessage = null;
      _videoUrl = null;
      _title = null;
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
            _statusMessage = "Video bulunamadı veya bağlantı geçersiz.";
            _statusColor = Colors.redAccent;
          });
        }
      } else {
        setState(() {
          _statusMessage = "Sunucu hatası oluştu.";
          _statusColor = Colors.redAccent;
        });
      }
    } catch (e) {
      setState(() {
        _statusMessage = "Bağlantı hatası: İnternetinizi kontrol edin.";
        _statusColor = Colors.redAccent;
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> downloadToGallery() async {
    if (_videoUrl == null) return;

    setState(() {
      _isDownloading = true;
      _statusMessage = "Video indiriliyor, lütfen bekleyin...";
      _statusColor = Colors.amber;
    });

    try {
      final response = await http.get(Uri.parse(_videoUrl!));
      if (response.statusCode == 200) {
        final tempDir = Directory.systemTemp;
        final filePath = '${tempDir.path}/tiktok_${DateTime.now().millisecondsSinceEpoch}.mp4';
        final file = File(filePath);
        await file.writeAsBytes(response.bodyBytes);

        // Galeriye kaydet
        await Gal.putVideo(filePath);

        setState(() {
          _statusMessage = "Video başarıyla Galeriye kaydedildi!";
          _statusColor = Colors.greenAccent;
        });
      } else {
        setState(() {
          _statusMessage = "Video dosyası indirilemedi.";
          _statusColor = Colors.redAccent;
        });
      }
    } catch (e) {
      setState(() {
        _statusMessage = "Kayıt hatası: Galeri erişim iznini kontrol edin.";
        _statusColor = Colors.redAccent;
      });
    } finally {
      setState(() {
        _isDownloading = false;
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _urlController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'TikTok video linkini yapıştırın...',
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
                onPressed: _isLoading || _isDownloading ? null : fetchVideo,
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Videoyu Bul', style: TextStyle(fontSize: 16, color: Colors.white)),
              ),
            ),
            const SizedBox(height: 24),
            if (_statusMessage != null)
              Text(
                _statusMessage!,
                textAlign: TextAlign.center,
                style: TextStyle(color: _statusColor, fontSize: 15),
              ),
            if (_videoUrl != null) ...[
              const SizedBox(height: 16),
              Text(
                _title ?? '',
                style: const TextStyle(color: Colors.white70),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: _isDownloading ? null : downloadToGallery,
                  icon: _isDownloading
                      ? const SizedBox.shrink()
                      : const Icon(Icons.download, color: Colors.white),
                  label: _isDownloading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('Galeriye Kaydet', style: TextStyle(fontSize: 16, color: Colors.white)),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
