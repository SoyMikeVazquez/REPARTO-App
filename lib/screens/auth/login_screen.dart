import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/reparto_button.dart';
import '../../core/widgets/reparto_logo.dart';
import '../../core/widgets/auth_error_dialog.dart';
import '../../providers/auth_provider.dart';
import '../../providers/orders_provider.dart';
import '../main_navigation_screen.dart';
import 'courier_registration_screen.dart';
import 'pending_approval_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  final _clientEmailController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  // Tab index: 0 = Cliente, 1 = Repartidor
  int _currentTabIndex = 1; // Default to Repartidor as requested

  // Modo de búsqueda en tab Cliente: 0 = Teléfono (primero y por defecto con +52), 1 = Correo
  int _clientInputMode = 0;

  bool _isLoading = false;
  bool _obscurePassword = true;
  String _errorMessage = '';

  @override
  void dispose() {
    _phoneController.dispose();
    _clientEmailController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _switchTab(int index) {
    if (_currentTabIndex == index) return;
    setState(() {
      _currentTabIndex = index;
      _errorMessage = '';
    });
  }

  Future<void> _handleCourierLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final auth = Provider.of<AuthProvider>(context, listen: false);

    try {
      // 1. Iniciar sesión con email y contraseña en Supabase Auth y validar tabla repartidores
      final courierData = await auth.signInCourierWithEmail(
        email: email,
        password: password,
      );

      final status = (courierData['status'] ?? 'Confirmado').toString();
      final name = (courierData['name'] ?? 'Repartidor').toString();

      if (!mounted) return;

      if (status == 'Confirmado') {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('¡Bienvenido de nuevo, $name!'),
            backgroundColor: const Color(0xFF10B981),
            duration: const Duration(seconds: 2),
          ),
        );
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const MainNavigationScreen()),
        );
      } else if (status == 'Pendiente') {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const PendingApprovalScreen()),
        );
      } else {
        final errText =
            'Tu cuenta de repartidor se encuentra en estado: $status. Comunícate con soporte.';
        setState(() {
          _errorMessage = errText;
        });
        AuthErrorHelper.showErrorPopup(context, errText);
      }
    } catch (e) {
      if (!mounted) return;
      final errorInfo = AuthErrorHelper.parse(e);
      setState(() {
        _errorMessage = errorInfo.message;
      });
      AuthErrorHelper.showErrorPopup(context, e);
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showForgotPasswordDialog() {
    final resetEmailController =
        TextEditingController(text: _emailController.text.trim());
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Recuperar Contraseña',
          style: GoogleFonts.outfit(fontWeight: FontWeight.w700),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Ingresa el correo electrónico con el que te diste de alta para recibir el enlace de restablecimiento.',
              style: GoogleFonts.inter(fontSize: 13, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: resetEmailController,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(
                labelText: 'Correo Electrónico',
                prefixIcon: const Icon(Icons.alternate_email_rounded,
                    color: RepartoColors.primaryRed),
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancelar',
                style: GoogleFonts.inter(color: Colors.grey.shade600)),
          ),
          ElevatedButton(
            onPressed: () async {
              final mail = resetEmailController.text.trim();
              if (mail.isEmpty) return;
              Navigator.pop(ctx);
              try {
                final auth =
                    Provider.of<AuthProvider>(context, listen: false);
                await auth.sendPasswordReset(mail);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                          'Enlace enviado. Revisa tu bandeja de entrada.'),
                      backgroundColor: Color(0xFF10B981),
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  AuthErrorHelper.showErrorPopup(context, e);
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: RepartoColors.primaryRed,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            child: Text('Enviar enlace',
                style: GoogleFonts.inter(
                    color: Colors.white, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  Future<void> _handleClientLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    final isPhoneMode = _clientInputMode == 0;
    final String input;
    if (isPhoneMode) {
      final raw = _phoneController.text.trim();
      input = raw.replaceAll(RegExp(r'[^0-9]'), '');
    } else {
      input = _clientEmailController.text.trim().toLowerCase();
    }

    final auth = Provider.of<AuthProvider>(context, listen: false);
    final ordersProv = Provider.of<OrdersProvider>(context, listen: false);

    try {
      // Consulta directa en la tabla de entregas (deliveries) y órdenes en Supabase
      final foundOrders = await ordersProv.checkOrdersByPhoneOrEmail(input);

      if (foundOrders.isNotEmpty) {
        // Encontró órdenes asociadas a ese teléfono o correo
        await auth.loginAsClient(input);
        if (mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const MainNavigationScreen()),
          );
        }
      } else {
        // No hay órdenes registradas con este teléfono o correo
        if (mounted) {
          final label = isPhoneMode ? 'el celular "+52 $input"' : 'el correo "$input"';
          setState(() {
            _errorMessage =
                'No se encontraron entregas asociadas a $label. '
                'Verifica el dato registrado al momento de realizar tu pedido.';
          });
        }
      }
    } catch (e) {
      if (!mounted) return;
      final errorInfo = AuthErrorHelper.parse(e);
      setState(() {
        _errorMessage = errorInfo.message;
      });
      AuthErrorHelper.showErrorPopup(context, e);
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isCourierTab = _currentTabIndex == 1;

    return Scaffold(
      backgroundColor: isDark ? RepartoColors.darkBg : Colors.white,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Logo de Reparto.mx
                    const Center(child: RepartoLogo(size: 46)),
                    const SizedBox(height: 16),

                    // Título principal
                    Text(
                      'Portal de Acceso',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.outfit(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.5,
                        color: isDark
                            ? RepartoColors.darkTextPrimary
                            : const Color(0xFF111827),
                      ),
                    ),
                    const SizedBox(height: 6),

                    // Subtítulo contextual
                    Text(
                      isCourierTab
                          ? 'Acceso con correo y contraseña para repartidores'
                          : 'Ingresa para gestionar y rastrear tus pedidos',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: isDark
                            ? RepartoColors.darkTextSecondary
                            : const Color(0xFF6B7280),
                      ),
                    ),
                    const SizedBox(height: 28),

                    // Segmented Tabs: Cliente / Repartidor (Estilo Estpay)
                    _buildSegmentedTabs(isDark),
                    const SizedBox(height: 28),

                    // Mensaje de Error (descartable)
                    if (_errorMessage.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 12),
                        margin: const EdgeInsets.only(bottom: 20),
                        decoration: BoxDecoration(
                          color: isDark
                              ? const Color(0xFF3B1818)
                              : const Color(0xFFFEF2F2),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isDark
                                ? const Color(0xFF7F1D1D)
                                : const Color(0xFFFCA5A5),
                          ),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Padding(
                              padding: EdgeInsets.only(top: 2),
                              child: Icon(
                                Icons.error_outline_rounded,
                                color: Color(0xFFDC2626),
                                size: 18,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                _errorMessage,
                                style: GoogleFonts.inter(
                                  color: isDark
                                      ? const Color(0xFFFCA5A5)
                                      : const Color(0xFFB91C1C),
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  height: 1.35,
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                            InkWell(
                              onTap: () {
                                setState(() {
                                  _errorMessage = '';
                                });
                              },
                              borderRadius: BorderRadius.circular(12),
                              child: Padding(
                                padding: const EdgeInsets.all(2.0),
                                child: Icon(
                                  Icons.close_rounded,
                                  size: 16,
                                  color: isDark
                                      ? const Color(0xFFFCA5A5)
                                      : const Color(0xFFDC2626),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                    if (isCourierTab) ...[
                      // ================= PESTAÑA: REPARTIDOR (CORREO Y CONTRASEÑA) =================
                      Text(
                        'Correo Electrónico',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: isDark
                              ? RepartoColors.darkTextPrimary
                              : const Color(0xFF374151),
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        autocorrect: false,
                        style: GoogleFonts.inter(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white : const Color(0xFF111827),
                        ),
                        decoration: InputDecoration(
                          hintText: 'tu-correo@reparto.mx',
                          hintStyle: GoogleFonts.inter(
                            color: isDark ? Colors.grey.shade600 : Colors.grey.shade400,
                            fontSize: 14,
                          ),
                          prefixIcon: const Icon(
                            Icons.alternate_email_rounded,
                            color: RepartoColors.primaryRed,
                            size: 20,
                          ),
                          filled: true,
                          fillColor: isDark
                              ? RepartoColors.darkCard
                              : const Color(0xFFF9FAFB),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 16,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: isDark
                                  ? RepartoColors.darkBorder
                                  : const Color(0xFFE5E7EB),
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: isDark
                                  ? RepartoColors.darkBorder
                                  : const Color(0xFFE5E7EB),
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: RepartoColors.primaryRed,
                              width: 1.8,
                            ),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Ingresa tu correo electrónico';
                          }
                          final emailRegex =
                              RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
                          if (!emailRegex.hasMatch(value.trim())) {
                            return 'Ingresa un formato de correo válido';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      Text(
                        'Contraseña',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: isDark
                              ? RepartoColors.darkTextPrimary
                              : const Color(0xFF374151),
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        style: GoogleFonts.inter(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white : const Color(0xFF111827),
                        ),
                        decoration: InputDecoration(
                          hintText: '••••••••',
                          hintStyle: GoogleFonts.inter(
                            color: isDark ? Colors.grey.shade600 : Colors.grey.shade400,
                            fontSize: 16,
                          ),
                          prefixIcon: const Icon(
                            Icons.lock_outline_rounded,
                            color: RepartoColors.primaryRed,
                            size: 20,
                          ),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword
                                  ? Icons.visibility_off_rounded
                                  : Icons.visibility_rounded,
                              color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                              size: 20,
                            ),
                            onPressed: () {
                              setState(() {
                                _obscurePassword = !_obscurePassword;
                              });
                            },
                          ),
                          filled: true,
                          fillColor: isDark
                              ? RepartoColors.darkCard
                              : const Color(0xFFF9FAFB),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 16,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: isDark
                                  ? RepartoColors.darkBorder
                                  : const Color(0xFFE5E7EB),
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: isDark
                                  ? RepartoColors.darkBorder
                                  : const Color(0xFFE5E7EB),
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: RepartoColors.primaryRed,
                              width: 1.8,
                            ),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Ingresa tu contraseña';
                          }
                          if (value.length < 6) {
                            return 'La contraseña debe tener al menos 6 caracteres';
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: 10),
                      Wrap(
                        alignment: WrapAlignment.spaceBetween,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: 8,
                        runSpacing: 4,
                        children: [
                          InkWell(
                            onTap: () {
                              setState(() {
                                _emailController.text = 'mike.vaz1@hotmail.es';
                                _errorMessage = '';
                              });
                            },
                            borderRadius: BorderRadius.circular(8),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.check_circle_outline_rounded,
                                    size: 14,
                                    color: Color(0xFF10B981),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    'mike.vaz1@hotmail.es',
                                    style: GoogleFonts.inter(
                                      fontSize: 12,
                                      color: const Color(0xFF059669),
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          InkWell(
                            onTap: _showForgotPasswordDialog,
                            borderRadius: BorderRadius.circular(6),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
                              child: Text(
                                '¿Olvidaste tu contraseña?',
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  color: RepartoColors.primaryRed,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 24),

                      RepartoButton(
                        label: 'Iniciar Sesión como Repartidor',
                        icon: Icons.delivery_dining_rounded,
                        onPressed: _isLoading ? null : _handleCourierLogin,
                        isLoading: _isLoading,
                        width: double.infinity,
                      ),
                    ] else ...[
                      // ================= PESTAÑA: CLIENTE (SWITCH TELÉFONO / CORREO) =================
                      _buildClientInputModeSwitch(isDark),

                      if (_clientInputMode == 0) ...[
                        // Campo 1 (Primero): Teléfono Celular con LADA fija +52
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Número Celular (México)',
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: isDark
                                    ? RepartoColors.darkTextPrimary
                                    : const Color(0xFF374151),
                              ),
                            ),
                            Text(
                              '10 dígitos',
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: isDark
                                    ? RepartoColors.darkTextMuted
                                    : const Color(0xFF9CA3AF),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _phoneController,
                          keyboardType: TextInputType.phone,
                          maxLength: 10,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                          style: GoogleFonts.outfit(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.2,
                            color: isDark ? Colors.white : const Color(0xFF111827),
                          ),
                          decoration: InputDecoration(
                            counterText: '',
                            hintText: '55 1234 5678',
                            hintStyle: GoogleFonts.outfit(
                              color: isDark ? Colors.grey.shade600 : Colors.grey.shade400,
                              fontSize: 16,
                              letterSpacing: 1.2,
                            ),
                            prefixIcon: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14),
                              margin: const EdgeInsets.only(right: 12),
                              decoration: BoxDecoration(
                                border: Border(
                                  right: BorderSide(
                                    color: isDark
                                        ? RepartoColors.darkBorder
                                        : const Color(0xFFE5E7EB),
                                    width: 1.4,
                                  ),
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Text('🇲🇽', style: TextStyle(fontSize: 18)),
                                  const SizedBox(width: 8),
                                  Text(
                                    '+52',
                                    style: GoogleFonts.outfit(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w800,
                                      color: isDark ? Colors.white : const Color(0xFF111827),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            filled: true,
                            fillColor: isDark
                                ? RepartoColors.darkCard
                                : const Color(0xFFF9FAFB),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 16,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: isDark
                                    ? RepartoColors.darkBorder
                                    : const Color(0xFFE5E7EB),
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: isDark
                                    ? RepartoColors.darkBorder
                                    : const Color(0xFFE5E7EB),
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                color: RepartoColors.primaryRed,
                                width: 1.8,
                              ),
                            ),
                          ),
                          validator: (value) {
                            final clean = (value ?? '').replaceAll(RegExp(r'[^0-9]'), '');
                            if (clean.length < 10) {
                              return 'Ingresa los 10 dígitos de tu número celular';
                            }
                            return null;
                          },
                        ),
                      ] else ...[
                        // Campo 2: Correo Electrónico
                        Text(
                          'Correo Electrónico',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: isDark
                                ? RepartoColors.darkTextPrimary
                                : const Color(0xFF374151),
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _clientEmailController,
                          keyboardType: TextInputType.emailAddress,
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: isDark ? Colors.white : const Color(0xFF111827),
                          ),
                          decoration: InputDecoration(
                            hintText: 'cliente@correo.com',
                            hintStyle: GoogleFonts.inter(
                              color: isDark ? Colors.grey.shade600 : Colors.grey.shade400,
                              fontSize: 15,
                            ),
                            prefixIcon: const Icon(
                              Icons.alternate_email_rounded,
                              color: RepartoColors.primaryRed,
                              size: 20,
                            ),
                            filled: true,
                            fillColor: isDark
                                ? RepartoColors.darkCard
                                : const Color(0xFFF9FAFB),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 16,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: isDark
                                    ? RepartoColors.darkBorder
                                    : const Color(0xFFE5E7EB),
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: isDark
                                    ? RepartoColors.darkBorder
                                    : const Color(0xFFE5E7EB),
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                color: RepartoColors.primaryRed,
                                width: 1.8,
                              ),
                            ),
                          ),
                          validator: (value) {
                            if (value == null || !value.contains('@') || !value.contains('.')) {
                              return 'Ingresa un correo electrónico válido';
                            }
                            return null;
                          },
                        ),
                      ],
                      const SizedBox(height: 24),
                      RepartoButton(
                        label: 'Consultar Mis Pedidos',
                        icon: Icons.receipt_long_rounded,
                        onPressed: _isLoading ? null : _handleClientLogin,
                        isLoading: _isLoading,
                        width: double.infinity,
                      ),
                    ],

                    // Pie inferior: Registro como Repartidor
                    const SizedBox(height: 28),
                      Row(
                        children: [
                          Expanded(
                            child: Divider(
                              color: isDark
                                  ? RepartoColors.darkBorder
                                  : const Color(0xFFE5E7EB),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 14),
                            child: Text(
                              isCourierTab
                                  ? '¿Aún no estás dado de alta?'
                                  : '¿Quieres repartir con nosotros?',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: isDark
                                    ? RepartoColors.darkTextMuted
                                    : const Color(0xFF9CA3AF),
                              ),
                            ),
                          ),
                          Expanded(
                            child: Divider(
                              color: isDark
                                  ? RepartoColors.darkBorder
                                  : const Color(0xFFE5E7EB),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      OutlinedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const CourierRegistrationScreen(),
                            ),
                          );
                        },
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(
                            color: RepartoColors.primaryRed,
                            width: 1.2,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          backgroundColor: Colors.transparent,
                        ),
                        child: Text(
                          'Solicitar Registro como Repartidor',
                          style: GoogleFonts.inter(
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                            color: RepartoColors.primaryRed,
                          ),
                        ),
                      ),
                    ],
                  ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Selector entre Celular (+52) y Correo Electrónico para clientes
  Widget _buildClientInputModeSwitch(bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: isDark ? RepartoColors.darkCard : const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? RepartoColors.darkBorder : const Color(0xFFE5E7EB),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          // Opción 1 (Primero): Celular con Lada +52
          Expanded(
            child: _buildTabPill(
              title: 'Celular (+52)',
              icon: Icons.phone_android_rounded,
              isSelected: _clientInputMode == 0,
              onTap: () {
                if (_clientInputMode != 0) {
                  setState(() {
                    _clientInputMode = 0;
                    _errorMessage = '';
                  });
                }
              },
              isDark: isDark,
            ),
          ),
          // Opción 2: Correo Electrónico
          Expanded(
            child: _buildTabPill(
              title: 'Correo',
              icon: Icons.alternate_email_rounded,
              isSelected: _clientInputMode == 1,
              onTap: () {
                if (_clientInputMode != 1) {
                  setState(() {
                    _clientInputMode = 1;
                    _errorMessage = '';
                  });
                }
              },
              isDark: isDark,
            ),
          ),
        ],
      ),
    );
  }

  /// Segmented Control blanco estilo Estpay con dos pestañas: Cliente y Repartidor
  Widget _buildSegmentedTabs(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: isDark ? RepartoColors.darkCard : const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? RepartoColors.darkBorder : const Color(0xFFE5E7EB),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          // Pestaña: Cliente
          Expanded(
            child: _buildTabPill(
              title: 'Cliente',
              icon: Icons.person_outline_rounded,
              isSelected: _currentTabIndex == 0,
              onTap: () => _switchTab(0),
              isDark: isDark,
            ),
          ),
          // Pestaña: Repartidor
          Expanded(
            child: _buildTabPill(
              title: 'Repartidor',
              icon: Icons.two_wheeler_rounded,
              isSelected: _currentTabIndex == 1,
              onTap: () => _switchTab(1),
              isDark: isDark,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabPill({
    required String title,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(vertical: 11, horizontal: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? (isDark ? const Color(0xFF1E293B) : Colors.white)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.06),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 18,
                color: isSelected
                    ? RepartoColors.primaryRed
                    : (isDark
                        ? RepartoColors.darkTextMuted
                        : const Color(0xFF6B7280)),
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected
                      ? (isDark ? Colors.white : const Color(0xFF111827))
                      : (isDark
                          ? RepartoColors.darkTextMuted
                          : const Color(0xFF6B7280)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
