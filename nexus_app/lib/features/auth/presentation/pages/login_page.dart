import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/gradient_button.dart';
import '../../../../injection_container.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';
import '../bloc/auth_state.dart';

class LoginPage extends StatefulWidget {
  final VoidCallback onLoginSuccess;
  const LoginPage({super.key, required this.onLoginSuccess});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _usernameCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _obscurePassword = true;
  bool _hasAttempted = false;

  late AnimationController _entryController;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _logoSlideAnim;
  late Animation<Offset> _formSlideAnim;

  @override
  void initState() {
    super.initState();
    _entryController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    );

    _fadeAnim = CurvedAnimation(
      parent: _entryController,
      curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
    );

    _logoSlideAnim = Tween<Offset>(
      begin: const Offset(0, -0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _entryController,
      curve: const Interval(0.0, 0.55, curve: Curves.easeOutCubic),
    ));

    _formSlideAnim = Tween<Offset>(
      begin: const Offset(0, 0.15),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _entryController,
      curve: const Interval(0.25, 0.85, curve: Curves.easeOutCubic),
    ));

    _entryController.forward();
  }

  @override
  void dispose() {
    _entryController.dispose();
    _usernameCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  void _submit(BuildContext context) {
    setState(() => _hasAttempted = true);
    if (!_formKey.currentState!.validate()) return;
    HapticFeedback.mediumImpact();
    context.read<AuthBloc>().add(AuthLoginRequested(
          username: _usernameCtrl.text.trim(),
          password: _passwordCtrl.text,
        ));
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<AuthBloc>(),
      child: BlocConsumer<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is AuthAuthenticated) {
            HapticFeedback.heavyImpact();
            widget.onLoginSuccess();
          }
          if (state is AuthFailure) {
            HapticFeedback.vibrate();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Row(
                  children: [
                    const Icon(Icons.error_outline_rounded,
                        color: AppColors.error, size: 18),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(state.message,
                          style: AppTextStyles.body
                              .copyWith(color: AppColors.textPrimary)),
                    ),
                  ],
                ),
                backgroundColor: AppColors.surfaceElevated,
                behavior: SnackBarBehavior.floating,
                margin: const EdgeInsets.all(16),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            );
          }
        },
        builder: (context, state) {
          final isLoading = state is AuthLoading;

          return Scaffold(
            backgroundColor: AppColors.background,
            body: Stack(
              children: [
                // Background geometric decoration
                const _BackgroundDecoration(),

                // Main content
                SafeArea(
                  child: SingleChildScrollView(
                    physics: const ClampingScrollPhysics(),
                    child: SizedBox(
                      height: MediaQuery.of(context).size.height -
                          MediaQuery.of(context).padding.top,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 28),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 60),

                              // Logo + branding
                              FadeTransition(
                                opacity: _fadeAnim,
                                child: SlideTransition(
                                  position: _logoSlideAnim,
                                  child: const _LogoSection(),
                                ),
                              ),

                              const Spacer(),

                              // Form section
                              FadeTransition(
                                opacity: _fadeAnim,
                                child: SlideTransition(
                                  position: _formSlideAnim,
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text('Sign in',
                                          style: AppTextStyles.h1),
                                      const SizedBox(height: 6),
                                      Text(
                                        'Access your knowledge bases',
                                        style: AppTextStyles.bodyLarge
                                            .copyWith(
                                                color: AppColors.textMuted),
                                      ),
                                      const SizedBox(height: 36),

                                      // Username field
                                      _AnimatedField(
                                        delay: const Duration(
                                            milliseconds: 200),
                                        child: _NexusTextField(
                                          controller: _usernameCtrl,
                                          label: 'USERNAME',
                                          hint: 'Enter your username',
                                          prefixIcon: Icons.person_outline_rounded,
                                          textInputAction:
                                              TextInputAction.next,
                                          keyboardType: TextInputType.text,
                                          enabled: !isLoading,
                                          validator: _hasAttempted
                                              ? (v) => (v == null ||
                                                      v.trim().isEmpty)
                                                  ? 'Username is required'
                                                  : null
                                              : null,
                                        ),
                                      ),
                                      const SizedBox(height: 14),

                                      // Password field
                                      _AnimatedField(
                                        delay: const Duration(
                                            milliseconds: 320),
                                        child: _NexusTextField(
                                          controller: _passwordCtrl,
                                          label: 'PASSWORD',
                                          hint: 'Enter your password',
                                          prefixIcon: Icons.lock_outline_rounded,
                                          obscureText: _obscurePassword,
                                          enabled: !isLoading,
                                          textInputAction:
                                              TextInputAction.done,
                                          onSubmitted: (_) => _submit(context),
                                          validator: _hasAttempted
                                              ? (v) => (v == null ||
                                                      v.isEmpty)
                                                  ? 'Password is required'
                                                  : null
                                              : null,
                                          suffixIcon: GestureDetector(
                                            onTap: () => setState(() =>
                                                _obscurePassword =
                                                    !_obscurePassword),
                                            child: AnimatedSwitcher(
                                              duration: const Duration(
                                                  milliseconds: 200),
                                              child: Icon(
                                                _obscurePassword
                                                    ? Icons
                                                        .visibility_off_outlined
                                                    : Icons
                                                        .visibility_outlined,
                                                key: ValueKey(
                                                    _obscurePassword),
                                                color: AppColors.textMuted,
                                                size: 20,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 32),

                                      // Sign in button
                                      _AnimatedField(
                                        delay: const Duration(
                                            milliseconds: 440),
                                        child: GradientButton(
                                          label: 'Sign in',
                                          isLoading: isLoading,
                                          onPressed: isLoading
                                              ? null
                                              : () => _submit(context),
                                        ),
                                      ),

                                      const SizedBox(height: 60),
                                    ],
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
              ],
            ),
          );
        },
      ),
    );
  }
}

// ─── Background decoration ─────────────────────────────────────────────────

class _BackgroundDecoration extends StatelessWidget {
  const _BackgroundDecoration();

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Stack(
      children: [
        // Top-right glow orb
        Positioned(
          top: -100,
          right: -80,
          child: Container(
            width: 300,
            height: 300,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  AppColors.primary.withValues(alpha: 0.18),
                  AppColors.primary.withValues(alpha: 0.0),
                ],
              ),
            ),
          ),
        ),
        // Bottom-left glow orb
        Positioned(
          bottom: 80,
          left: -60,
          child: Container(
            width: 220,
            height: 220,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  AppColors.secondary.withValues(alpha: 0.12),
                  AppColors.secondary.withValues(alpha: 0.0),
                ],
              ),
            ),
          ),
        ),
        // Subtle grid pattern
        CustomPaint(
          size: Size(size.width, size.height),
          painter: _GridPainter(),
        ),
      ],
    );
  }
}

class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.025)
      ..strokeWidth = 0.5;

    const step = 40.0;
    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(_GridPainter oldDelegate) => false;
}

// ─── Logo section ───────────────────────────────────────────────────────────

class _LogoSection extends StatefulWidget {
  const _LogoSection();

  @override
  State<_LogoSection> createState() => _LogoSectionState();
}

class _LogoSectionState extends State<_LogoSection>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat(reverse: true);

    _pulseAnim = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AnimatedBuilder(
          animation: _pulseAnim,
          builder: (_, _) => Opacity(
            opacity: _pulseAnim.value,
            child: Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                gradient: AppColors.accentGradient,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.4),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: const Center(
                child: Text(
                  '⬡',
                  style: TextStyle(fontSize: 26, color: Colors.white),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        RichText(
          text: TextSpan(
            children: [
              TextSpan(
                text: 'nexus',
                style: AppTextStyles.h3.copyWith(
                  color: AppColors.textPrimary,
                  fontFamily: 'SpaceGrotesk',
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 2,
                ),
              ),
              TextSpan(
                text: ' · ai knowledge base',
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.textMuted,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ─── Animated field wrapper ─────────────────────────────────────────────────

class _AnimatedField extends StatefulWidget {
  final Widget child;
  final Duration delay;
  const _AnimatedField({required this.child, required this.delay});

  @override
  State<_AnimatedField> createState() => _AnimatedFieldState();
}

class _AnimatedFieldState extends State<_AnimatedField>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _fade;
  late Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _slide = Tween<Offset>(
      begin: const Offset(0, 0.12),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));

    Future.delayed(widget.delay, () {
      if (mounted) _ctrl.forward();
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fade,
      child: SlideTransition(position: _slide, child: widget.child),
    );
  }
}

// ─── Custom text field ──────────────────────────────────────────────────────

class _NexusTextField extends StatefulWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final IconData prefixIcon;
  final bool obscureText;
  final Widget? suffixIcon;
  final TextInputAction? textInputAction;
  final TextInputType? keyboardType;
  final bool enabled;
  final String? Function(String?)? validator;
  final void Function(String)? onSubmitted;

  const _NexusTextField({
    required this.controller,
    required this.label,
    required this.hint,
    required this.prefixIcon,
    this.obscureText = false,
    this.suffixIcon,
    this.textInputAction,
    this.keyboardType,
    this.enabled = true,
    this.validator,
    this.onSubmitted,
  });

  @override
  State<_NexusTextField> createState() => _NexusTextFieldState();
}

class _NexusTextFieldState extends State<_NexusTextField>
    with SingleTickerProviderStateMixin {
  bool _isFocused = false;
  late AnimationController _borderCtrl;
  late Animation<Color?> _borderColorAnim;

  @override
  void initState() {
    super.initState();
    _borderCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _borderColorAnim = ColorTween(
      begin: AppColors.border,
      end: AppColors.primary,
    ).animate(CurvedAnimation(parent: _borderCtrl, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _borderCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AnimatedBuilder(
          animation: _borderColorAnim,
          builder: (_, child) => Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _borderColorAnim.value ?? AppColors.border,
                width: _isFocused ? 1.5 : 1.0,
              ),
              color: _isFocused
                  ? AppColors.primary.withValues(alpha: 0.06)
                  : const Color(0x0DFFFFFF),
            ),
            child: child,
          ),
          child: Focus(
            onFocusChange: (focused) {
              setState(() => _isFocused = focused);
              focused ? _borderCtrl.forward() : _borderCtrl.reverse();
            },
            child: TextFormField(
              controller: widget.controller,
              obscureText: widget.obscureText,
              textInputAction: widget.textInputAction,
              keyboardType: widget.keyboardType,
              enabled: widget.enabled,
              validator: widget.validator,
              onFieldSubmitted: widget.onSubmitted,
              style: AppTextStyles.body.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w500,
              ),
              decoration: InputDecoration(
                labelText: widget.label,
                hintText: widget.hint,
                prefixIcon: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  child: Icon(
                    widget.prefixIcon,
                    size: 18,
                    color: _isFocused
                        ? AppColors.primary
                        : AppColors.textMuted,
                  ),
                ),
                suffixIcon: widget.suffixIcon,
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                errorBorder: InputBorder.none,
                focusedErrorBorder: InputBorder.none,
                filled: false,
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 16),
              ),
            ),
          ),
        ),
      ],
    );
  }
}