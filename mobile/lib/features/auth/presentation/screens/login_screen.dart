import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/localization/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../../../../shared/widgets/error_banner.dart';
import '../../../../shared/widgets/language_selector.dart';
import '../auth_provider.dart';

import '../../../../shared/widgets/theme_toggle_button.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
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

    final horizontalPadding = screenWidth < 360 ? 16.0 : (screenWidth > 600 ? 40.0 : 24.0);

    return Scaffold(
      appBar: AppBar(
        title: Text(context.tr('login_title')),
        elevation: 0,
        backgroundColor: Colors.transparent,
        actions: const [
          ThemeToggleButton(),
          Padding(
            padding: EdgeInsets.only(right: 12.0),
            child: LanguageSelector(),
          ),
        ],
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: 16.0),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight - 32.0,
                ),
                child: IntrinsicHeight(
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        SizedBox(height: screenHeight * 0.01),

                        Center(
                          child: Image.asset(
                            'assets/images/logo.png',
                            width: 64,
                            height: 64,
                            fit: BoxFit.contain,
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Title & Subtitle using AppLocalizations
                        Text(
                          context.tr('login_welcome'),
                          textAlign: TextAlign.center,
                          style: AppTypography.display,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          context.tr('login_subtitle'),
                          textAlign: TextAlign.center,
                          style: AppTypography.bodyMedium,
                        ),
                        SizedBox(height: screenHeight * 0.03),

                        // Error Banner
                        if (authState.errorMessage != null) ...[
                          ErrorBanner(message: authState.errorMessage!),
                          const SizedBox(height: 16),
                        ],

                        // Input Fields
                        AppTextField(
                          label: context.tr('email_label'),
                          hint: context.tr('email_hint'),
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          prefixIcon: Icons.email_outlined,
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return context.tr('email_label');
                            }
                            final emailRegex = RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
                            if (!emailRegex.hasMatch(value.trim())) {
                              return context.tr('email_hint');
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),

                        AppTextField(
                          label: context.tr('password_label'),
                          hint: context.tr('password_hint'),
                          controller: _passwordController,
                          isPassword: true,
                          prefixIcon: Icons.lock_outline,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return context.tr('password_label');
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 24),

                        // Submit Button
                        AppButton(
                          text: context.tr('login_button'),
                          isLoading: authState.isLoading,
                          onPressed: _submit,
                        ),

                        const Spacer(),
                        const SizedBox(height: 24),

                        // Footer Link
                        Center(
                          child: Text.rich(
                            TextSpan(
                              text: context.tr('dont_have_account'),
                              style: AppTypography.bodyMedium,
                              children: [
                                TextSpan(
                                  text: context.tr('register_link'),
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
