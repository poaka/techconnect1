import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../../../../shared/widgets/error_banner.dart';
import '../auth_provider.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController(text: 'client@techconnect.cm');
  final _passwordController = TextEditingController(text: 'Password123!');
  late TapGestureRecognizer _registerTapRecognizer;

  @override
  void initState() {
    super.initState();
    _registerTapRecognizer = TapGestureRecognizer()
      ..onTap = () {
        context.push('/register');
      };
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _registerTapRecognizer.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      ref.read(authNotifierProvider.notifier).login(
            _emailController.text.trim(),
            _passwordController.text,
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authNotifierProvider);
    final mediaQuery = MediaQuery.of(context);
    final screenWidth = mediaQuery.size.width;
    final screenHeight = mediaQuery.size.height;

    // Responsive horizontal padding based on screen width
    final horizontalPadding = screenWidth < 360 ? 16.0 : (screenWidth > 600 ? 40.0 : 24.0);

    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: 16.0),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight - 32.0, // Account for vertical padding
                ),
                child: IntrinsicHeight(
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        SizedBox(height: screenHeight * 0.03),

                        // Logo Header
                        Center(
                          child: Container(
                            padding: const EdgeInsets.all(16.0),
                            decoration: const BoxDecoration(
                              color: AppColors.primarySubtle,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.handyman_rounded,
                              size: 44,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Title & Subtitle
                        const Text(
                          'Connexion',
                          textAlign: TextAlign.center,
                          style: AppTypography.display,
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Accédez à votre espace TechConnect Cameroun',
                          textAlign: TextAlign.center,
                          style: AppTypography.bodyMedium,
                        ),
                        SizedBox(height: screenHeight * 0.04),

                        // Error Banner
                        if (authState.errorMessage != null) ...[
                          ErrorBanner(message: authState.errorMessage!),
                          const SizedBox(height: 16),
                        ],

                        // Input Fields
                        AppTextField(
                          label: 'Adresse Email',
                          hint: 'ex: client@domain.cm',
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          prefixIcon: Icons.email_outlined,
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'L\'email est requis';
                            }
                            if (!value.contains('@')) {
                              return 'Adresse email invalide';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),

                        AppTextField(
                          label: 'Mot de passe',
                          hint: '••••••••',
                          controller: _passwordController,
                          isPassword: true,
                          prefixIcon: Icons.lock_outline,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Le mot de passe est requis';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 24),

                        // Submit Button
                        AppButton(
                          text: 'Se connecter',
                          isLoading: authState.isLoading,
                          onPressed: _submit,
                        ),

                        const Spacer(),
                        const SizedBox(height: 24),

                        // Responsive Footer Link (RichText replaces rigid unconstrained Row)
                        Center(
                          child: Text.rich(
                            TextSpan(
                              text: 'Vous n\'avez pas de compte ? ',
                              style: AppTypography.bodyMedium,
                              children: [
                                TextSpan(
                                  text: 'S\'inscrire',
                                  style: AppTypography.bodyMedium.copyWith(
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  recognizer: _registerTapRecognizer,
                                ),
                              ],
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        const SizedBox(height: 12),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
