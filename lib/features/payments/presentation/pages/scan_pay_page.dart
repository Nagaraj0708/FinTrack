import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../app/theme/colors.dart';
import '../../../../core/providers/settings_provider.dart';
import '../providers/payment_provider.dart';

class ScanPayPage extends ConsumerStatefulWidget {
  const ScanPayPage({super.key});

  @override
  ConsumerState<ScanPayPage> createState() => _ScanPayPageState();
}

class _ScanPayPageState extends ConsumerState<ScanPayPage> {
  late MobileScannerController _scanner;
  bool _torchOn = false;
  bool _hasScanned = false;

  @override
  void initState() {
    super.initState();
    ref.read(qrScanProvider.notifier).reset();
    _scanner = MobileScannerController(
      detectionSpeed: DetectionSpeed.normal,
      facing: CameraFacing.back,
      torchEnabled: false,
    );
  }

  @override
  void dispose() {
    _scanner.dispose();
    super.dispose();
  }

  void _onDetected(BarcodeCapture capture) {
    if (_hasScanned) return;
    final raw = capture.barcodes.firstOrNull?.rawValue;
    if (raw == null || raw.isEmpty) return;

    setState(() => _hasScanned = true);
    _scanner.stop();
    ref.read(qrScanProvider.notifier).parseQr(raw);
  }

  @override
  Widget build(BuildContext context) {
    final scanState = ref.watch(qrScanProvider);

    // When QR is parsed, show the confirm bottom sheet
    ref.listen(qrScanProvider, (prev, next) {
      if (next.data != null && prev?.data == null) {
        _showPaymentConfirmSheet(context, next.data!);
      }
    });

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Camera
          MobileScanner(
            controller: _scanner,
            onDetect: _onDetected,
          ),

          // Overlay: dark vignette with clear center
          _ScannerOverlay(),

          // Top bar
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_rounded, color: Colors.white, size: 26),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const Text(
                    'Scan & Pay',
                    style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800),
                  ),
                  Row(
                    children: [
                      IconButton(
                        icon: Icon(
                          _torchOn ? Icons.flash_on_rounded : Icons.flash_off_rounded,
                          color: Colors.white,
                          size: 24,
                        ),
                        onPressed: () {
                          setState(() => _torchOn = !_torchOn);
                          _scanner.toggleTorch();
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.photo_library_rounded, color: Colors.white, size: 22),
                        onPressed: () async {
                          final picker = ImagePicker();
                          final file = await picker.pickImage(source: ImageSource.gallery);
                          if (file != null && context.mounted) {
                            final capture = await _scanner.analyzeImage(file.path);
                            if (capture == null && context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('No QR code found in the image')),
                              );
                            }
                          }
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Bottom instructions
          Positioned(
            bottom: 60,
            left: 0,
            right: 0,
            child: Column(
              children: [
                if (scanState.isScanning) ...[
                  const Text(
                    'Align QR code within the frame',
                    style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Supports UPI QR codes',
                    style: TextStyle(color: Colors.white54, fontSize: 13),
                    textAlign: TextAlign.center,
                  ),
                ],
                if (scanState.error != null)
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 40),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.error.withValues(alpha: 0.9),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      scanState.error!,
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                      textAlign: TextAlign.center,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showPaymentConfirmSheet(BuildContext context, ScannedQrData data) {
    final amountController = TextEditingController(text: data.amount ?? '');
    final noteController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      isDismissible: false,
      builder: (sheetCtx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(sheetCtx).viewInsets.bottom),
        child: _PaymentConfirmSheet(
          scannedData: data,
          amountController: amountController,
          noteController: noteController,
          onPay: (amount) async {
            Navigator.pop(sheetCtx);
            final userId = ref.read(settingsProvider).userEmail;
            await ref.read(paymentActionProvider.notifier).executePayment(
              userId: userId,
              payeeVpa: data.payeeVpa,
              amount: amount,
              description: noteController.text.isEmpty ? null : noteController.text,
              merchantName: data.merchantName,
            );
            if (context.mounted) {
              _showResultScreen(context);
            }
          },
          onCancel: () {
            Navigator.pop(sheetCtx);
            setState(() => _hasScanned = false);
            ref.read(qrScanProvider.notifier).reset();
            _scanner.start();
          },
        ),
      ),
    );
  }

  void _showResultScreen(BuildContext ctx) {
    final actionState = ref.read(paymentActionProvider);
    Navigator.pushReplacement(
      ctx,
      MaterialPageRoute(
        builder: (_) => PaymentResultPage(
          isSuccess: actionState.status == PaymentActionStatus.success,
          message: actionState.message ?? '',
          transactionId: actionState.transactionId,
        ),
      ),
    );
  }
}

// ── Scanner Overlay ──────────────────────────────────────────────────────

class _ScannerOverlay extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _OverlayPainter(),
      child: const SizedBox.expand(),
    );
  }
}

class _OverlayPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final dark = Paint()..color = Colors.black.withValues(alpha: 0.6);
    const cutSize = 260.0;
    final cx = size.width / 2;
    final cy = size.height / 2 - 40;
    final rect = Rect.fromCenter(center: Offset(cx, cy), width: cutSize, height: cutSize);
    final full = Rect.fromLTWH(0, 0, size.width, size.height);

    final path = Path()
      ..addRect(full)
      ..addRRect(RRect.fromRectAndRadius(rect, const Radius.circular(16)))
      ..fillType = PathFillType.evenOdd;
    canvas.drawPath(path, dark);

    // Corner decorations
    final cornerPaint = Paint()
      ..color = const Color(0xFF9AE6B4)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    const cornerLen = 28.0;
    final r = rect;

    // Top-left
    canvas.drawLine(Offset(r.left + 12, r.top), Offset(r.left + 12 + cornerLen, r.top), cornerPaint);
    canvas.drawLine(Offset(r.left, r.top + 12), Offset(r.left, r.top + 12 + cornerLen), cornerPaint);
    // Top-right
    canvas.drawLine(Offset(r.right - 12, r.top), Offset(r.right - 12 - cornerLen, r.top), cornerPaint);
    canvas.drawLine(Offset(r.right, r.top + 12), Offset(r.right, r.top + 12 + cornerLen), cornerPaint);
    // Bottom-left
    canvas.drawLine(Offset(r.left + 12, r.bottom), Offset(r.left + 12 + cornerLen, r.bottom), cornerPaint);
    canvas.drawLine(Offset(r.left, r.bottom - 12), Offset(r.left, r.bottom - 12 - cornerLen), cornerPaint);
    // Bottom-right
    canvas.drawLine(Offset(r.right - 12, r.bottom), Offset(r.right - 12 - cornerLen, r.bottom), cornerPaint);
    canvas.drawLine(Offset(r.right, r.bottom - 12), Offset(r.right, r.bottom - 12 - cornerLen), cornerPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ── Payment Confirm Sheet ────────────────────────────────────────────────

class _PaymentConfirmSheet extends ConsumerWidget {
  final ScannedQrData scannedData;
  final TextEditingController amountController;
  final TextEditingController noteController;
  final void Function(int amount) onPay;
  final VoidCallback onCancel;

  const _PaymentConfirmSheet({
    required this.scannedData,
    required this.amountController,
    required this.noteController,
    required this.onPay,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final actionState = ref.watch(paymentActionProvider);
    final isLoading = actionState.status == PaymentActionStatus.loading;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)))),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Color(0xFF2196F3), Color(0xFF1565C0)]),
              shape: BoxShape.circle,
              boxShadow: [BoxShadow(color: const Color(0xFF2196F3).withValues(alpha: 0.3), blurRadius: 16, offset: const Offset(0, 8))],
            ),
            child: const Icon(Icons.storefront_rounded, color: Colors.white, size: 36),
          ),
          const SizedBox(height: 16),
          const Text('Paying To', style: TextStyle(color: AppColors.textSecondary, fontSize: 13, fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Text(
            scannedData.merchantName.isEmpty ? scannedData.payeeVpa : scannedData.merchantName,
            style: const TextStyle(color: AppColors.textPrimary, fontSize: 22, fontWeight: FontWeight.w800),
            textAlign: TextAlign.center,
          ),
          Text(scannedData.payeeVpa, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
          const SizedBox(height: 28),
          TextField(
            controller: amountController,
            keyboardType: const TextInputType.numberWithOptions(decimal: false),
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 44, fontWeight: FontWeight.w900, color: AppColors.textPrimary),
            decoration: const InputDecoration(
              prefixText: '₹  ',
              prefixStyle: TextStyle(fontSize: 44, fontWeight: FontWeight.w900, color: AppColors.textPrimary),
              hintText: '0',
              hintStyle: TextStyle(fontSize: 44, fontWeight: FontWeight.w900, color: Color(0xFFCBD5E1)),
              border: InputBorder.none,
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: noteController,
            decoration: InputDecoration(
              hintText: 'Add a note (optional)',
              prefixIcon: const Icon(Icons.edit_note_rounded, color: AppColors.textSecondary),
              filled: true,
              fillColor: const Color(0xFFF5F7F5),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: isLoading ? null : onCancel,
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppColors.primary),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text('Cancel', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700, fontSize: 16)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: FilledButton(
                  onPressed: isLoading
                      ? null
                      : () {
                          final raw = amountController.text.trim();
                          final amt = int.tryParse(raw);
                          if (amt == null || amt <= 0) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Please enter a valid amount')),
                            );
                            return;
                          }
                          onPay(amt);
                        },
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: isLoading
                      ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Text('Pay Now', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Payment Result Screen ────────────────────────────────────────────────

class PaymentResultPage extends StatelessWidget {
  final bool isSuccess;
  final String message;
  final String? transactionId;

  const PaymentResultPage({
    super.key,
    required this.isSuccess,
    required this.message,
    this.transactionId,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Icon with ring animation
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isSuccess
                      ? AppColors.success.withValues(alpha: 0.1)
                      : AppColors.error.withValues(alpha: 0.1),
                ),
                child: Icon(
                  isSuccess ? Icons.check_circle_rounded : Icons.cancel_rounded,
                  size: 80,
                  color: isSuccess ? AppColors.success : AppColors.error,
                ),
              ),
              const SizedBox(height: 32),
              Text(
                isSuccess ? 'Payment Successful!' : 'Payment Failed',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  color: isSuccess ? AppColors.success : AppColors.error,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.textSecondary, fontSize: 15),
              ),
              if (transactionId != null) ...[
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5F7F5),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.receipt_long_rounded, color: AppColors.textSecondary, size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Transaction ID', style: TextStyle(color: AppColors.textSecondary, fontSize: 11, fontWeight: FontWeight.w600)),
                            Text(transactionId!, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const Spacer(),
              SizedBox(
                width: double.infinity,
                height: 54,
                child: FilledButton(
                  onPressed: () {
                    // Pop back to Pay dashboard
                    Navigator.of(context).popUntil((route) => route.isFirst);
                  },
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: const Text('Done', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
                ),
              ),
              const SizedBox(height: 12),
              if (isSuccess)
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('View Receipt', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700)),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
