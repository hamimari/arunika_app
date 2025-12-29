import 'package:flutter/material.dart';

class SuccessDialog extends StatelessWidget {
  final int lesson;
  final String userName;
  final int reward;

  const SuccessDialog({
    super.key,
    required this.lesson,
    required this.userName,
    required this.reward,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 32, vertical: 100),
      backgroundColor: Colors.transparent,
      child: Stack(
        alignment: Alignment.topCenter,
        children: [
          // main card
          Container(
            margin: const EdgeInsets.only(top: 80),
            padding: const EdgeInsets.fromLTRB(24, 100, 24, 24),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF6D5), // light cream
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.orange.shade200, width: 2),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Good job, $userName!',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Reward',
                  style: TextStyle(
                    color: Colors.orange,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Image.network(
                      'https://media-hosting.imagekit.io/79108ca295a14cf3/29Y_6di5usrkc5p2qc1k-removebg-preview.png?Expires=1840113759&Key-Pair-Id=K2ZIVPTIP2VGHC&Signature=dHiHlO6ajyTm3lnK6n0cOuYhYITSVeGLOY36bGVoDdMFctrCyd5wjeyqoe3vwd85-BcMyKEMOj9-MWnEmD2Kxt2zmOkN2QO28BLTUsK~h7y0uqJ0s3uHzeG-gALnrpH0u4JMvpVj0yW027RgjIrMwL-8scYjKr3A50FCfJDoY4PpBMK6EKHJIf2dY0QEMg8tBGqqfYXt6B5J2NR1BD5CFxn~g2DLySrAC-oX4jJUkQ2R3vJTq0TR3v6mI0nKmzoHVt2ZlVMlTeioUmS9qoCN5pE0kUkiF2K3hYuTlXa2jjx6TpCm00Qorr2Th-Y4u7gC-tBUUa~NUhfVpmsBPJ08pQ__', // candy placeholder
                      height: 40,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'x $reward',
                      style: const TextStyle(
                        fontSize: 24,
                        color: Colors.orange,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),
                // Yellow button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      backgroundColor: const Color(0xFFFFCC29),
                      shadowColor: Colors.transparent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                        side: const BorderSide(color: Color(0xFFFFE071), width: 3),
                      ),
                    ),
                    child: const Text(
                      'YAY, OK!',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // banner + stars on top
          Positioned(
            top: 20,
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    3,
                        (_) => const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 6),
                      child: Icon(Icons.star, color: Colors.amber, size: 40),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xffFF9E32), Color(0xffFF7F2B)],
                    ),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Column(
                    children: [
                      Text(
                        'Lesson $lesson',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'COMPLETE',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                          fontFamily: 'Comic', // optional fun font
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
