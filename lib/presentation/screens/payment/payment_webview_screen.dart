import 'package:arunika_app/data/repositories/payment_repository.dart';
import 'package:arunika_app/di/locator.dart';
import 'package:arunika_app/presentation/screens/payment/payment_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:webview_flutter/webview_flutter.dart';

class PaymentScreen extends StatelessWidget {
  const PaymentScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) =>
          PaymentCubit(repository: locator<PaymentRepository>())
            ..createTransaction(),
      child: const _PaymentView(),
    );
  }
}

class _PaymentView extends StatelessWidget {
  const _PaymentView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pembayaran Premium')),
      body: BlocBuilder<PaymentCubit, PaymentState>(
        builder: (context, state) {
          if (state is PaymentLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is PaymentError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(state.message),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () =>
                        context.read<PaymentCubit>().createTransaction(),
                    child: const Text('Coba Lagi'),
                  ),
                ],
              ),
            );
          }
          if (state is PaymentSnapReady) {
            return _SnapWebView(url: state.redirectUrl);
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }
}

class _SnapWebView extends StatefulWidget {
  final String url;
  const _SnapWebView({required this.url});

  @override
  State<_SnapWebView> createState() => _SnapWebViewState();
}

class _SnapWebViewState extends State<_SnapWebView> {
  late final WebViewController _controller;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..loadRequest(Uri.parse(widget.url))
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (url) {
            // When Midtrans redirects to a finish/error URL, pop back.
            if (url.contains('finish') || url.contains('error')) {
              Navigator.pop(context);
            }
          },
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    return WebViewWidget(controller: _controller);
  }
}
