import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/reparto_button.dart';
import '../../core/widgets/reparto_logo.dart';
import '../../providers/auth_provider.dart';
import '../main_navigation_screen.dart';
import 'courier_registration_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController(text: '+52');
  final _otpController = TextEditingController();
  
  bool _otpSent = false;
  bool _isLoading = false;
  String _errorMessage = '';

  @override
  void dispose() {
    _phoneController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  Future<void> _sendOtp() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      await auth.signInWithPhone(_phoneController.text.trim());
      setState(() {
        _otpSent = true;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _verifyOtp() async {
    if (_otpController.text.isEmpty) return;

    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      await auth.verifyOTP(
        _phoneController.text.trim(),
        _otpController.text.trim(),
      );
      
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const MainNavigationScreen()),
        );
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Center(child: RepartoLogo(size: 40)),
                    const SizedBox(height: 12),
                    Text(
                      'Portal de Acceso',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.outfit(
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        color: isDark
                            ? RepartoColors.darkTextPrimary
                            : RepartoColors.lightTextPrimary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Ingresa tu número de teléfono para continuar',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: isDark
                            ? RepartoColors.darkTextSecondary
                            : RepartoColors.lightTextSecondary,
                      ),
                    ),
                    const SizedBox(height: 32),
                    
                    if (_errorMessage.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.all(12),
                        margin: const EdgeInsets.only(bottom: 20),
                        decoration: BoxDecoration(
                          color: Colors.red.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
                        ),
                        child: Text(
                          _errorMessage,
                          style: const TextStyle(color: Colors.red, fontSize: 13),
                          textAlign: TextAlign.center,
                        ),
                      ),

                    if (!_otpSent) ...[
                      TextFormField(
                        controller: _phoneController,
                        keyboardType: TextInputType.phone,
                        decoration: const InputDecoration(
                          labelText: 'Número de Teléfono',
                          hintText: '+52 555 555 5555',
                          prefixIcon: Icon(Icons.phone),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty || value.length < 10) {
                            return 'Ingresa un número válido';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 24),
                      RepartoButton(
                        label: 'Enviar Código por SMS',
                        onPressed: _isLoading ? null : _sendOtp,
                        isLoading: _isLoading,
                        width: double.infinity,
                      ),
                      const SizedBox(height: 24),
                      Row(
                        children: [
                          Expanded(child: Divider(color: isDark ? RepartoColors.darkBorder : Colors.grey.shade300)),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            child: Text(
                              '¿Quieres unirte como repartidor?',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                color: isDark ? RepartoColors.darkTextMuted : RepartoColors.lightTextMuted,
                              ),
                            ),
                          ),
                          Expanded(child: Divider(color: isDark ? RepartoColors.darkBorder : Colors.grey.shade300)),
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
                          side: const BorderSide(color: RepartoColors.primaryRed),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: Text(
                          'Solicitar Registro como Repartidor',
                          style: GoogleFonts.inter(
                            fontWeight: FontWeight.w600,
                            color: RepartoColors.primaryRed,
                          ),
                        ),
                      ),
                    ] else ...[
                      TextFormField(
                        controller: _otpController,
                        keyboardType: TextInputType.number,
                        textAlign: TextAlign.center,
                        style: const TextStyle(letterSpacing: 8, fontSize: 24, fontWeight: FontWeight.bold),
                        decoration: const InputDecoration(
                          labelText: 'Código de 6 dígitos',
                          hintText: '000000',
                        ),
                        maxLength: 6,
                      ),
                      const SizedBox(height: 24),
                      RepartoButton(
                        label: 'Verificar Código',
                        onPressed: _isLoading ? null : _verifyOtp,
                        isLoading: _isLoading,
                        width: double.infinity,
                      ),
                      const SizedBox(height: 12),
                      TextButton(
                        onPressed: _isLoading ? null : () {
                          setState(() {
                            _otpSent = false;
                            _otpController.clear();
                          });
                        },
                        child: const Text('Cambiar número de teléfono'),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
