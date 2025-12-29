import 'package:arunika_app/presentation/screens/signup/signup_bloc.dart';
import 'package:arunika_app/presentation/screens/signup/signup_event.dart';
import 'package:arunika_app/presentation/screens/signup/signup_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

class TrialScreen extends StatefulWidget {
  const TrialScreen({super.key});

  @override
  State<TrialScreen> createState() => _TrialScreenState();
}

class _TrialScreenState extends State<TrialScreen> {
  final _pageController = PageController();
  int _currentPage = 0;

  final List<String> imageAssets = [
    'https://media-hosting.imagekit.io/84d696c7d57244b8/4735474.jpg?Expires=1839336090&Key-Pair-Id=K2ZIVPTIP2VGHC&Signature=ZGhG5FNwwibanNAswfEWbG79qo-NPLrJ~Vq6RSIf0XvlwKlvgh6tBH~MT-QWdUMwVBr~URyoxZygeB58oziPYb501SDiaFl6LiHet9MDl~Wqfdjj8iZlJbXUl7-pwxQBRFj~G5xsURsguL5EDFJIRS5QguajXxHti4DjKFYJECnzVg-R2g6zxTbF5wrmFMiaGNeiFSP~cOq6XSNuQD3RKMwRS7J7DQY~vczvV-w6q7A6teZn8uTQtfY7skkcwPmWnRP0igjpUXdYaYB9MGJdi2oNBEcV9SAcSDCL-UFvWHU68iB82f7LtiXMBm8WcgJx4Lo8k8IybDNWjMmRP8J6EA__',
    'https://media-hosting.imagekit.io/8cdccfc67e0646dc/3537793.jpg?Expires=1839336216&Key-Pair-Id=K2ZIVPTIP2VGHC&Signature=26WS0loU2UEwh-UMAuc5iYCD9XehxJFnC1zTFvGvS5frPJrktseS9tCXGxVm8w5dObPjzLpSYBGQhG8sGogG6e0Gzb4m3DRBLqvsZqP2MLwEOlCEC4XmHVKi3-~6yJKJs32qnNaL~MM78CiOm9PJj6Y3676TbHQUotGhK10NZ~dP3RY7Zb9M5-FHxCoYw2zhhUoget5SEADPmVT2GhUsJQjUjxJGQgdhIyoGPkKhArHUGuLUPm4jkrdb-pnDNRJ39n~QLstPWVR6j1Cmhu8kwqVIK-uIxVFtcQ0UTEWLNWSRP18vAy-Fka2lZx6aYlBBLo7bNgkUyRjSftUi2cbHSg__',
    'https://media-hosting.imagekit.io/16d856363ea448b3/8553320.jpg?Expires=1839420599&Key-Pair-Id=K2ZIVPTIP2VGHC&Signature=HeKIlyl67ghndSixSyzZnz~G9S9Sf5Zm3tUmRWyH-bthtzmIxIoTLNxGQ3jvY~KxavwMEZ8z28RGfhn~i971U7noTdX1~3xRuGEiVdnHmKih98dldum~20zIOsPcN~TP4Dle6Wey58EpJ5oS7jzhKy204dYVY35BBn8VZvbcCgOOQJtRv9Rov0h0fb1rIwcWcPpYun7JUTQhZTXtepjtjxsqK5~5kPT6wBAmRCkoIKv0IEwL19C7uYESgiyofIIhfXumHy-5WanZzIjeCBpcW6e3uwqArPfePvkrj5FXyswjvLue3jA2x2O4YTGU0FlZGpDy~Dbc5N-uG3PC0tEnYg__',
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<SignupBloc, SignupState>(
      listener: (context, state) {
        if (state is NavigateToHomePage) {
          context.push('/home');
        }
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: Stack(
            children: [
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                child: Column(
                  children: [
                    /*Align(
                    alignment: Alignment.topRight,
                    child: IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),*/
                    const SizedBox(height: 8),

                    // Carousel with Dots
                    SizedBox(
                      height: 160,
                      child: Column(
                        children: [
                          Expanded(
                            child: PageView.builder(
                              controller: _pageController,
                              itemCount: imageAssets.length,
                              onPageChanged: (index) {
                                setState(() => _currentPage = index);
                              },
                              itemBuilder: (context, index) {
                                return Container(
                                  margin:
                                      const EdgeInsets.symmetric(horizontal: 8),
                                  decoration: BoxDecoration(
                                    color: Colors.orange.shade100,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child: Image.network(
                                      imageAssets[index],
                                      fit: BoxFit.cover,
                                      width: double.infinity,
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                          const SizedBox(height: 8),
                          SmoothPageIndicator(
                            controller: _pageController,
                            count: imageAssets.length,
                            effect: const WormEffect(
                              dotColor: Colors.grey,
                              activeDotColor: Colors.orange,
                              dotHeight: 8,
                              dotWidth: 8,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Header and Description
                    const Text(
                      'Coba Fitur Premium Gratis',
                      textAlign: TextAlign.center,
                      style:
                          TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Get access to hundred of exclusive\nfeatures and parenting tips for your beloved kids.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 14, color: Colors.black54),
                    ),
                    const SizedBox(height: 24),

                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF4E5),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.orange.shade300),
                      ),
                      child: const Text.rich(
                        TextSpan(
                          text: 'Coba 7 hari gratis\n',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                          children: [
                            TextSpan(
                              text: 'Lalu ',
                              style: TextStyle(fontSize: 12),
                            ),
                            TextSpan(
                              text: 'Rp29.900 PER BULAN',
                              style: TextStyle(color: Colors.orange),
                            ),
                          ],
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 24),

                    const FeatureItem(text: 'Dongeng interaktif'),
                    const FeatureItem(
                        text: 'Pembelajaran huruf, angka dan vocabulary'),
                    const FeatureItem(text: 'Info dan tips parenting'),
                    const SizedBox(height: 24),

                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          context.read<SignupBloc>().add(StartTrialSubmit());
                        },
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          backgroundColor: Colors.orange,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'MULAI UJI COBA GRATIS',
                          style: TextStyle(
                              color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),

                    const Text(
                      'Perpanjang otomatis. Batalkan kapan saja.',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class FeatureItem extends StatelessWidget {
  final String text;

  const FeatureItem({required this.text, super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          const Icon(Icons.check_circle, color: Colors.orange, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }
}
