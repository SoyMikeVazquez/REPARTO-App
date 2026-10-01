import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/reparto_button.dart';
import '../../models/order_model.dart';

class ProofOfDeliverySheet extends StatefulWidget {
  final OrderModel order;
  final Function(String signature, String receivedBy, String? photoUrl) onConfirm;

  const ProofOfDeliverySheet({
    super.key,
    required this.order,
    required this.onConfirm,
  });

  @override
  State<ProofOfDeliverySheet> createState() => _ProofOfDeliverySheetState();
}

class _ProofOfDeliverySheetState extends State<ProofOfDeliverySheet> {
  final _recipientController = TextEditingController();
  final _pinController = TextEditingController();
  final List<Offset?> _points = [];
  bool _photoTaken = false;
  bool _isPinValid = true;

  @override
  void initState() {
    super.initState();
    _recipientController.text = widget.order.customerName;
  }

  @override
  void dispose() {
    _recipientController.dispose();
    _pinController.dispose();
    super.dispose();
  }

  void _confirmDelivery() {
    if (_pinController.text.isNotEmpty &&
        _pinController.text != widget.order.deliveryPin) {
      setState(() => _isPinValid = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: RepartoColors.statusCanceled,
          content: Text('El código PIN no coincide con el del cliente.'),
        ),
      );
      return;
    }

    widget.onConfirm(
      _points.isNotEmpty ? 'signature_captured_data' : 'Firma en pantalla',
      _recipientController.text.trim(),
      _photoTaken ? 'https://reparto.mx/storage/proof_photo_demo.jpg' : null,
    );

    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? RepartoColors.darkBgSecondary : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark
                      ? RepartoColors.darkBorder
                      : RepartoColors.lightBorder,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),

            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: RepartoColors.statusDeliveredBg,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.verified_outlined,
                    color: RepartoColors.statusDelivered,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Prueba de Entrega Digital',
                        style: GoogleFonts.outfit(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: isDark
                              ? RepartoColors.darkTextPrimary
                              : RepartoColors.lightTextPrimary,
                        ),
                      ),
                      Text(
                        'Pedido #${widget.order.id} • ${widget.order.customerName}',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: isDark
                              ? RepartoColors.darkTextSecondary
                              : RepartoColors.lightTextSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Recipient Name
            Text(
              'Nombre de quien recibe:',
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isDark
                    ? RepartoColors.darkTextSecondary
                    : RepartoColors.lightTextSecondary,
              ),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: _recipientController,
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.person_outline, size: 20),
                hintText: 'Ej. Juan Pérez (Titular o Conserje)',
              ),
            ),
            const SizedBox(height: 16),

            // PIN Verification Code
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'PIN de confirmación (4 dígitos):',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: isDark
                        ? RepartoColors.darkTextSecondary
                        : RepartoColors.lightTextSecondary,
                  ),
                ),
                Text(
                  '(PIN Cliente: ${widget.order.deliveryPin})',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: RepartoColors.statusInRoute,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            TextField(
              controller: _pinController,
              keyboardType: TextInputType.number,
              maxLength: 4,
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.pin_outlined, size: 20),
                counterText: '',
                hintText: widget.order.deliveryPin,
                errorText: _isPinValid ? null : 'PIN inválido',
              ),
            ),
            const SizedBox(height: 16),

            // Digital Signature Pad
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Firma digital en pantalla:',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: isDark
                        ? RepartoColors.darkTextSecondary
                        : RepartoColors.lightTextSecondary,
                  ),
                ),
                TextButton(
                  onPressed: () => setState(() => _points.clear()),
                  child: Text(
                    'Limpiar',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: RepartoColors.primaryRed,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Container(
              height: 120,
              decoration: BoxDecoration(
                color: isDark ? RepartoColors.darkCard : RepartoColors.lightCard,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isDark
                      ? RepartoColors.darkBorder
                      : RepartoColors.lightBorder,
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: GestureDetector(
                  onPanUpdate: (DragUpdateDetails details) {
                    RenderBox? renderBox =
                        context.findRenderObject() as RenderBox?;
                    if (renderBox != null) {
                      setState(() {
                        _points.add(details.localPosition);
                      });
                    }
                  },
                  onPanEnd: (DragEndDetails details) => _points.add(null),
                  child: CustomPaint(
                    painter: SignaturePainter(
                      points: _points,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                    size: Size.infinite,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Photo Proof Capture Simulation
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      setState(() => _photoTaken = !_photoTaken);
                    },
                    icon: Icon(
                      _photoTaken
                          ? Icons.check_circle_rounded
                          : Icons.camera_alt_outlined,
                      color: _photoTaken
                          ? RepartoColors.statusDelivered
                          : RepartoColors.primaryRed,
                    ),
                    label: Text(
                      _photoTaken
                          ? 'Foto de entrega lista'
                          : 'Tomar foto de entrega',
                      style: GoogleFonts.outfit(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Confirm Delivery Button
            RepartoButton(
              label: 'Completar y Validar Entrega',
              icon: Icons.check_circle_outline,
              onPressed: _confirmDelivery,
              width: double.infinity,
            ),
          ],
        ),
      ),
    );
  }
}

class SignaturePainter extends CustomPainter {
  final List<Offset?> points;
  final Color color;

  SignaturePainter({required this.points, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 3.0;

    for (int i = 0; i < points.length - 1; i++) {
      if (points[i] != null && points[i + 1] != null) {
        canvas.drawLine(points[i]!, points[i + 1]!, paint);
      }
    }
  }

  @override
  bool shouldRepaint(SignaturePainter oldDelegate) => true;
}
