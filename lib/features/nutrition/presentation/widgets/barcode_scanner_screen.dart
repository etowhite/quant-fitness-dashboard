import '../../../../core/localization/app_strings.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../data/open_food_facts_service.dart';

class BarcodeScannerScreen extends StatefulWidget {
  const BarcodeScannerScreen({super.key});
  @override
  State<BarcodeScannerScreen> createState() => _BarcodeScannerScreenState();
}

class _BarcodeScannerScreenState extends State<BarcodeScannerScreen>
    with WidgetsBindingObserver {
  final _controller = MobileScannerController(autoStart: false, formats: [
    BarcodeFormat.ean8,
    BarcodeFormat.ean13,
    BarcodeFormat.upcA,
    BarcodeFormat.upcE,
    BarcodeFormat.itf
  ]);
  bool _found = false;
  String? _error;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _start());
  }

  Future<void> _start() async {
    if (!mounted || _found) return;
    try {
      await _controller.start();
    } catch (_) {
      if (mounted) {
        setState(() =>
            _error = 'Камера недоступна. Вернитесь и введите код вручную.');
      }
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(_start());
    } else {
      unawaited(_controller.stop());
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    unawaited(_controller.dispose());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
      appBar: AppBar(title: const QText('Штрихкод продукта')),
      body: Stack(children: [
        MobileScanner(
            controller: _controller,
            onDetect: (capture) {
              if (_found) return;
              for (final barcode in capture.barcodes) {
                final code = barcode.rawValue;
                if (code != null && OpenFoodFactsService.validBarcode(code)) {
                  _found = true;
                  unawaited(_controller.stop());
                  Navigator.pop(context, code);
                  break;
                }
              }
            }),
        Align(
            alignment: Alignment.bottomCenter,
            child: Container(
                padding: const EdgeInsets.all(24),
                color: Colors.black87,
                child: QText(_error ??
                    'Наведите камеру на штрихкод упаковки. Снимки не сохраняются и не отправляются.'))),
      ]));
}
