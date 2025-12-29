import 'package:arunika_app/presentation/screens/dialog/success_dialog_screen.dart';
import 'package:flutter/material.dart';

class GuessAnimalVoiceScreen extends StatelessWidget {
  const GuessAnimalVoiceScreen({super.key});

  void _playSound() {
    debugPrint('🔊 Play animal sound');
    // TODO: integrate audioplayer here
  }

  void _onImageTap(BuildContext context, String url) {
    debugPrint('User picked image: $url');

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const SuccessDialog(
        lesson: 12,
        userName: 'Oliver',
        reward: 10,
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: const BackButton(color: Colors.black),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: const Text('Guess the Animal'),
      ),
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              // top‑right speaker
              Align(
                alignment: Alignment.centerRight,
                child: IconButton(
                  icon: const Icon(Icons.volume_up,
                      color: Colors.orange, size: 32),
                  onPressed: _playSound,
                ),
              ),

              // 2‑picture grid
              Expanded(
                child: GridView.count(
                  crossAxisCount: 2,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  children: pictures
                      .map(
                        (url) => ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: InkWell(
                        onTap: () => _onImageTap(context, url),
                        child: Image.network(url, fit: BoxFit.cover),
                      ),
                    ),
                  )
                      .toList(),
                ),
              ),

              // bottom rectangle play‑sound button
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _playSound,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text(
                    'PLAY SOUND',
                    style:
                    TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Only two placeholder images now
const pictures = [
  'https://media-hosting.imagekit.io/907fd719ad6f416d/7e2c2e69-e2b1-456d-9f80-437942633b50.jpg?Expires=1840111511&Key-Pair-Id=K2ZIVPTIP2VGHC&Signature=CWnMpU5Vpr3H1A7lid6z2b3L0RqehhffTfOegSaf8V3m~fvcItDbSfwiEm3~Vq5BvBJ2xtcswmlZWOoyk5euvbRqQiZaxgrtc-xfTtz74dz2S8L8qcPs4ihaaPosf3469B3KWnTpLc2TRT8u5N~cVCLVZlxHQtVZau1tQFZOweQGW00FwoPKX1dv6ytTr9x7W5Pb6XuYSjN40-i-Oki7akFH6dWorO9yhyCyW5RNALljK0SORDskPKSAnl5DzRgKxZZAmJovo5HAwkCjUSuiy1LhpCT2Oh49yT5fpVUPFVkcnTDn7FwdT~UdPaAW68ueOmdyVJH-3yA7p~WJZMSuLQ__',
  'https://media-hosting.imagekit.io/907fd719ad6f416d/7e2c2e69-e2b1-456d-9f80-437942633b50.jpg?Expires=1840111511&Key-Pair-Id=K2ZIVPTIP2VGHC&Signature=CWnMpU5Vpr3H1A7lid6z2b3L0RqehhffTfOegSaf8V3m~fvcItDbSfwiEm3~Vq5BvBJ2xtcswmlZWOoyk5euvbRqQiZaxgrtc-xfTtz74dz2S8L8qcPs4ihaaPosf3469B3KWnTpLc2TRT8u5N~cVCLVZlxHQtVZau1tQFZOweQGW00FwoPKX1dv6ytTr9x7W5Pb6XuYSjN40-i-Oki7akFH6dWorO9yhyCyW5RNALljK0SORDskPKSAnl5DzRgKxZZAmJovo5HAwkCjUSuiy1LhpCT2Oh49yT5fpVUPFVkcnTDn7FwdT~UdPaAW68ueOmdyVJH-3yA7p~WJZMSuLQ__',
  'https://media-hosting.imagekit.io/907fd719ad6f416d/7e2c2e69-e2b1-456d-9f80-437942633b50.jpg?Expires=1840111511&Key-Pair-Id=K2ZIVPTIP2VGHC&Signature=CWnMpU5Vpr3H1A7lid6z2b3L0RqehhffTfOegSaf8V3m~fvcItDbSfwiEm3~Vq5BvBJ2xtcswmlZWOoyk5euvbRqQiZaxgrtc-xfTtz74dz2S8L8qcPs4ihaaPosf3469B3KWnTpLc2TRT8u5N~cVCLVZlxHQtVZau1tQFZOweQGW00FwoPKX1dv6ytTr9x7W5Pb6XuYSjN40-i-Oki7akFH6dWorO9yhyCyW5RNALljK0SORDskPKSAnl5DzRgKxZZAmJovo5HAwkCjUSuiy1LhpCT2Oh49yT5fpVUPFVkcnTDn7FwdT~UdPaAW68ueOmdyVJH-3yA7p~WJZMSuLQ__',
  'https://media-hosting.imagekit.io/907fd719ad6f416d/7e2c2e69-e2b1-456d-9f80-437942633b50.jpg?Expires=1840111511&Key-Pair-Id=K2ZIVPTIP2VGHC&Signature=CWnMpU5Vpr3H1A7lid6z2b3L0RqehhffTfOegSaf8V3m~fvcItDbSfwiEm3~Vq5BvBJ2xtcswmlZWOoyk5euvbRqQiZaxgrtc-xfTtz74dz2S8L8qcPs4ihaaPosf3469B3KWnTpLc2TRT8u5N~cVCLVZlxHQtVZau1tQFZOweQGW00FwoPKX1dv6ytTr9x7W5Pb6XuYSjN40-i-Oki7akFH6dWorO9yhyCyW5RNALljK0SORDskPKSAnl5DzRgKxZZAmJovo5HAwkCjUSuiy1LhpCT2Oh49yT5fpVUPFVkcnTDn7FwdT~UdPaAW68ueOmdyVJH-3yA7p~WJZMSuLQ__',
];
