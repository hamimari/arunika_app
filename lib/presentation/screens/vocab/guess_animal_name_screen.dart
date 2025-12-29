import 'package:arunika_app/presentation/screens/dialog/success_dialog_screen.dart';
import 'package:flutter/material.dart';

class GuessAnimalNameScreen extends StatefulWidget {
  const GuessAnimalNameScreen({super.key});

  @override
  State<GuessAnimalNameScreen> createState() => _GuessAnimalNameScreenState();
}

class _GuessAnimalNameScreenState extends State<GuessAnimalNameScreen> {
  // correct answer for this question
  final String correct = 'Crocodile';

  String? selected; // keeps which answer was tapped

  void _onAnswerTap(String value) {
    setState(() => selected = value);

    // simulate feedback (replace with real logic)
    final isCorrect = value == correct;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(isCorrect ? 'Correct! 🎉' : 'Oops… try again'),
        backgroundColor: isCorrect ? Colors.green : Colors.red,
        duration: const Duration(seconds: 1),
      ),
    );

    // if correct -> navigate / show success popup
    // if (isCorrect) Navigator.push(context, ...);
  }

  @override
  Widget build(BuildContext context) {
    final answers = ['Crocodile', 'Rabbit', 'Dolphin', 'Bee'];

    return Scaffold(
      appBar: AppBar(
        leading: const BackButton(color: Colors.black),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              // Picture
              Expanded(
                flex: 3,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    'https://media-hosting.imagekit.io/907fd719ad6f416d/7e2c2e69-e2b1-456d-9f80-437942633b50.jpg?Expires=1840111511&Key-Pair-Id=K2ZIVPTIP2VGHC&Signature=CWnMpU5Vpr3H1A7lid6z2b3L0RqehhffTfOegSaf8V3m~fvcItDbSfwiEm3~Vq5BvBJ2xtcswmlZWOoyk5euvbRqQiZaxgrtc-xfTtz74dz2S8L8qcPs4ihaaPosf3469B3KWnTpLc2TRT8u5N~cVCLVZlxHQtVZau1tQFZOweQGW00FwoPKX1dv6ytTr9x7W5Pb6XuYSjN40-i-Oki7akFH6dWorO9yhyCyW5RNALljK0SORDskPKSAnl5DzRgKxZZAmJovo5HAwkCjUSuiy1LhpCT2Oh49yT5fpVUPFVkcnTDn7FwdT~UdPaAW68ueOmdyVJH-3yA7p~WJZMSuLQ__',
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Answer buttons
              ...answers.map(
                (txt) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: selected == null
                          ? Colors.orange
                          : // lock color after selection
                          (txt == correct
                              ? Colors.green
                              : (txt == selected ? Colors.red : Colors.orange)),
                      foregroundColor: Colors.white,
                      minimumSize: const Size.fromHeight(44),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onPressed: selected == null
                        ? () => showDialog(
                              context: context,
                              barrierDismissible: false,
                              builder: (_) => const SuccessDialog(
                                lesson: 12,
                                userName: 'Oliver',
                                reward: 10,
                              ),
                            )
                        : null, // disable after choose
                    child: Text(txt),
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
