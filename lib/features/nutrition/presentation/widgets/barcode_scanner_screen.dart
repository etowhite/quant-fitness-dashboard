import 'package:smart_fitness_dashboard/shared/widgets/quant_layout.dart';
import 'package:smart_fitness_dashboard/core/theme/app_spacing.dart';
import 'package:smart_fitness_dashboard/shared/widgets/quant_dialog.dart';
import '../../../../core/localization/app_strings.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  bool _found = false, _manual = false;
  String? _error;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _start());
  }

  Future<void> _start() async {
    if (!mounted || _found || _manual) return;
    try {
      await _controller.start();
    } catch (_) {
      if (mounted) {
        setState(() => _error = 'Камера недоступна. Введите штрихкод вручную.');
      }
    }
  }

  Future<void> _stop() async {
    try {
      await _controller.stop();
    } catch (_) {/* Already stopped. */}
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(_start());
    } else if (state == AppLifecycleState.paused) {
      unawaited(_stop());
    }
  }

  Future<void> _enterCode() async {
    if (_manual || _found) return;
    _manual = true;
    await _stop();
    if (!mounted) return;
    final field = TextEditingController();
    final form = GlobalKey<FormState>();
    final code = await showDialog<String>(
        context: context,
        builder: (context) => QuantDialog(
              title: const QText('Ввести штрихкод вручную'),
              content: Form(
                  key: form,
                  child: TextFormField(
                      controller: field,
                      autofocus: true,
                      keyboardType: TextInputType.number,
                      maxLength: 14,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      decoration: InputDecoration(
                          hintText: context.tr('8 или 12–14 цифр')),
                      validator: (v) =>
                          OpenFoodFactsService.validBarcode(v ?? '')
                              ? null
                              : context
                                  .tr('Введите 8 или 12–14 цифр штрихкода.'))),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const QText('Отмена')),
                FilledButton(
                    onPressed: () {
                      if (form.currentState!.validate()) {
                        Navigator.pop(context, field.text);
                      }
                    },
                    child: const QText('Найти'))
              ],
            ));
    await Future<void>.delayed(const Duration(milliseconds: 250));
    field.dispose();
    _manual = false;
    if (!mounted) return;
    if (code != null) {
      _found = true;
      Navigator.pop(context, code);
    } else {
      await _start();
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
        appBar: QuantAppBar(
            context: context,
            title: const QText('Штрихкод продукта'),
            actions: [
              IconButton(
                  tooltip: context.tr('Фонарик'),
                  icon: const Icon(Icons.flashlight_on_outlined),
                  onPressed: () async {
                    try {
                      await _controller.toggleTorch();
                    } catch (_) {/* Device may not have a torch. */}
                  }),
            ]),
        body: LayoutBuilder(builder: (context, constraints) {
          final window = Rect.fromCenter(
              center:
                  Offset(constraints.maxWidth / 2, constraints.maxHeight * .4),
              width: constraints.maxWidth * .82,
              height: 180);
          return Stack(fit: StackFit.expand, children: [
            MobileScanner(
                controller: _controller,
                scanWindow: window,
                errorBuilder: (_, __, ___) => const ColoredBox(
                    color: Colors.black,
                    child: Center(
                        child: Icon(Icons.no_photography_outlined,
                            size: 72, color: Colors.white54))),
                onDetect: (capture) {
                  if (_found || _manual) return;
                  for (final barcode in capture.barcodes) {
                    final code = barcode.rawValue;
                    if (code != null &&
                        OpenFoodFactsService.validBarcode(code)) {
                      _found = true;
                      unawaited(_stop());
                      Navigator.pop(context, code);
                      break;
                    }
                  }
                }),
            IgnorePointer(
                child: CustomPaint(
                    painter: _ScanFrame(
                        window, Theme.of(context).colorScheme.secondary))),
            Align(
                alignment: Alignment.bottomCenter,
                child: SafeArea(
                    top: false,
                    child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(24),
                        color: Colors.black87,
                        child:
                            Column(mainAxisSize: MainAxisSize.min, children: [
                          QText(
                              _error ??
                                  'Наведите камеру на штрихкод упаковки. Снимки не сохраняются и не отправляются.',
                              style: const TextStyle(color: Colors.white),
                              textAlign: TextAlign.center),
                          const SizedBox(height: AppSpacing.section),
                          FilledButton.icon(
                              style: FilledButton.styleFrom(
                                  minimumSize: const Size.fromHeight(56),
                                  shape: const StadiumBorder()),
                              onPressed: _enterCode,
                              icon: const Icon(Icons.keyboard),
                              label: const QText('Ввести штрихкод вручную')),
                        ])))),
          ]);
        }),
      );
}

class _ScanFrame extends CustomPainter {
  const _ScanFrame(this.rect, this.color);
  final Rect rect;
  final Color color;
  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..addRect(Offset.zero & size)
      ..addRRect(RRect.fromRectAndRadius(rect, const Radius.circular(24)))
      ..fillType = PathFillType.evenOdd;
    canvas.drawPath(path, Paint()..color = Colors.black45);
    canvas.drawRRect(
        RRect.fromRectAndRadius(rect, const Radius.circular(24)),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3
          ..color = color);
  }

  @override
  bool shouldRepaint(_ScanFrame old) => rect != old.rect || color != old.color;
}
