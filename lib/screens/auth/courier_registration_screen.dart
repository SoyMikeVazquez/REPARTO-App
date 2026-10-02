import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/widgets/reparto_button.dart';
import '../../core/widgets/reparto_logo.dart';
import '../../providers/auth_provider.dart';
import 'login_screen.dart';

class CourierRegistrationScreen extends StatefulWidget {
  const CourierRegistrationScreen({super.key});

  @override
  State<CourierRegistrationScreen> createState() => _CourierRegistrationScreenState();
}

class _CourierRegistrationScreenState extends State<CourierRegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController(text: '+52');
  final _otpController = TextEditingController();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();

  bool _otpSent = false;
  bool _otpVerified = false;
  bool _isLoading = false;
  String _errorMessage = '';

  @override
  void dispose() {
    _phoneController.dispose();
    _otpController.dispose();
    _nameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _sendOtp() async {
    if (_phoneController.text.length < 10) return;
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });
    try {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      await auth.signInWithPhone(_phoneController.text.trim());
      setState(() => _otpSent = true);
    } catch (e) {
      setState(() => _errorMessage = e.toString());
    } finally {
      setState(() => _isLoading = false);
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
      await auth.verifyOTP(_phoneController.text.trim(), _otpController.text.trim());
      setState(() => _otpVerified = true);
    } catch (e) {
      setState(() => _errorMessage = e.toString());
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _submitRegistration() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });
    try {
      final supabase = Supabase.instance.client;
      final userId = supabase.auth.currentUser?.id;
      
      if (userId == null) throw Exception("Error de autenticación");

      // Insertar en repartidores
      await supabase.from('repartidores').insert({
        'id_repartidor': userId,
        'name': _nameController.text.trim(),
        'email': _emailController.text.trim(),
        'phone': _phoneController.text.trim(),
        'status': 'Pendiente',
        // 'vehicle_photos': [], 'driver_photos': []
      });

      if (!mounted) return;
      // Refrescar auth para que tome el status Pendiente
      await Provider.of<AuthProvider>(context, listen: false).logout(); // Forzamos relogin o redirigimos
      
      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (_) => AlertDialog(
            title: const Text('Solicitud Enviada'),
            content: const Text('Tu solicitud ha sido enviada con éxito. Un administrador revisará tus datos.'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                    (route) => false,
                  );
                },
                child: const Text('Aceptar'),
              )
            ],
          )
        );
      }
    } catch (e) {
      setState(() => _errorMessage = e.toString());
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Registro de Repartidor'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
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
                      'Únete al equipo',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.outfit(
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 24),
                    
                    if (_errorMessage.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.all(12),
                        margin: const EdgeInsets.only(bottom: 20),
                        color: Colors.red.withValues(alpha: 0.1),
                        child: Text(_errorMessage, style: const TextStyle(color: Colors.red)),
                      ),

                    if (!_otpSent && !_otpVerified) ...[
                      TextFormField(
                        controller: _phoneController,
                        keyboardType: TextInputType.phone,
                        decoration: const InputDecoration(labelText: 'Número de Teléfono', prefixIcon: Icon(Icons.phone)),
                      ),
                      const SizedBox(height: 24),
                      RepartoButton(
                        label: 'Verificar Teléfono',
                        onPressed: _isLoading ? null : _sendOtp,
                        isLoading: _isLoading,
                        width: double.infinity,
                      ),
                    ] else if (_otpSent && !_otpVerified) ...[
                      TextFormField(
                        controller: _otpController,
                        keyboardType: TextInputType.number,
                        textAlign: TextAlign.center,
                        decoration: const InputDecoration(labelText: 'Código SMS'),
                      ),
                      const SizedBox(height: 24),
                      RepartoButton(
                        label: 'Confirmar Código',
                        onPressed: _isLoading ? null : _verifyOtp,
                        isLoading: _isLoading,
                        width: double.infinity,
                      ),
                    ] else if (_otpVerified) ...[
                      TextFormField(
                        controller: _nameController,
                        textCapitalization: TextCapitalization.words,
                        decoration: const InputDecoration(labelText: 'Nombre Completo', prefixIcon: Icon(Icons.person)),
                        validator: (v) => v!.isEmpty ? 'Requerido' : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: const InputDecoration(labelText: 'Correo Electrónico', prefixIcon: Icon(Icons.email)),
                        validator: (v) => v!.isEmpty ? 'Requerido' : null,
                      ),
                      const SizedBox(height: 24),
                      // Faltaría botón para subir fotos, etc.
                      RepartoButton(
                        label: 'Enviar Solicitud',
                        onPressed: _isLoading ? null : _submitRegistration,
                        isLoading: _isLoading,
                        width: double.infinity,
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
