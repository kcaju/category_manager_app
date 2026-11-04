import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/models/user_profile.dart';
import '../cubit/auth_cubit.dart';
import '../cubit/auth_state.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  int? _selectedUserId;
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isFetchingUsers = false;
  List<UserProfile> _cachedUsers = [];

  // Horizontal wheel scroll controller
  final FixedExtentScrollController _wheelController =
      FixedExtentScrollController(initialItem: 0);

  // Animation controller for lock open icon popping up from inside login button
  late AnimationController _unlockAnimationController;
  late Animation<double> _lockScaleAnimation;
  late Animation<Offset> _lockSlideAnimation;
  late Animation<double> _textFadeAnimation;
  bool _isUnlocking = false;

  @override
  void initState() {
    super.initState();
    _unlockAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
    );

    _lockScaleAnimation = Tween<double>(begin: 0.2, end: 1.0).animate(
      CurvedAnimation(
        parent: _unlockAnimationController,
        curve: Curves.elasticOut,
      ),
    );

    _lockSlideAnimation =
        Tween<Offset>(begin: const Offset(0.0, 1.4), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _unlockAnimationController,
            curve: Curves.easeOutBack,
          ),
        );

    _textFadeAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _unlockAnimationController,
        curve: const Interval(0.0, 0.35, curve: Curves.easeIn),
      ),
    );

    _loadUsersFromApi();
  }

  Future<void> _loadUsersFromApi() async {
    setState(() => _isFetchingUsers = true);
    try {
      final users = await context
          .read<AuthCubit>()
          .authRepository
          .fetchAvailableUsers();
      if (mounted) {
        setState(() {
          _cachedUsers = users;
          _isFetchingUsers = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isFetchingUsers = false);
      }
    }
  }

  void _onWheelIdSelected(int index) {
    if (index == 0) {
      // Index 0 represents "--" (unselected)
      setState(() {
        _selectedUserId = null;
        _nameController.clear();
        _emailController.clear();
      });
      return;
    }

    final id = index; // 1 through 10
    setState(() {
      _selectedUserId = id;
    });

    final matched = _cachedUsers.where((u) => u.id == id).firstOrNull;
    if (matched != null) {
      _nameController.text = matched.name;
      _emailController.text = matched.email;
    } else {
      _nameController.text = 'User #$id';
      _emailController.text = 'user$id@jsonplaceholder.api';
    }
  }

  void _decreaseId() {
    final current = _wheelController.selectedItem;
    if (current > 0) {
      _wheelController.animateToItem(
        current - 1,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
      );
    }
  }

  void _increaseId() {
    final current = _wheelController.selectedItem;
    if (current < 10) {
      _wheelController.animateToItem(
        current + 1,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  void dispose() {
    _wheelController.dispose();
    _unlockAnimationController.dispose();
    _nameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _onLoginPressed() async {
    if (_selectedUserId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Please select a User ID (1 - 10) using the locker',
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
          ),
          backgroundColor: Colors.grey,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    if (_isUnlocking) return;

    setState(() {
      _isUnlocking = true;
    });

    // 1. Play lock opening animation inside the button
    await _unlockAnimationController.forward();

    // 2. Short pause with open lock glowing
    await Future.delayed(const Duration(milliseconds: 350));

    if (mounted) {
      // 3. Authenticate and enter profile screen
      context.read<AuthCubit>().loginWithUserId(_selectedUserId!);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        body: BlocConsumer<AuthCubit, AuthState>(
          listener: (context, state) {
            if (state is AuthError) {
              setState(() {
                _isUnlocking = false;
              });
              _unlockAnimationController.reset();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.message),
                  backgroundColor: Colors.redAccent,
                  behavior: SnackBarBehavior.floating,
                ),
              );
            }
          },
          builder: (context, state) {
            return Stack(
              children: [
                // 1. Asset Background Image
                Positioned.fill(
                  child: Image.asset(
                    'assets/bgImage.png',
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Color(0xFF141414), Color(0xFF000000)],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                          ),
                        ),
                      );
                    },
                  ),
                ),

                // 2. Ambient Dark Gradient Overlay
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withValues(alpha: 0.35),
                          Colors.black.withValues(alpha: 0.65),
                          Colors.black.withValues(alpha: 0.92),
                        ],
                        stops: const [0.0, 0.5, 1.0],
                      ),
                    ),
                  ),
                ),

                // 3. Foreground Form Content
                SafeArea(
                  child: Center(
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24.0,
                        vertical: 16.0,
                      ),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const SizedBox(height: 10),

                            // Heading
                            const Text(
                              'Log In, Manage Your\nCategories',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                                height: 1.25,
                                letterSpacing: -0.3,
                              ),
                            ),

                            const SizedBox(height: 24),

                            // Horizontal Combination Locker Section
                            Center(
                              child: Column(
                                children: [
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        'SELECT USER ID',
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w700,
                                          color: Colors.white.withValues(
                                            alpha: 0.7,
                                          ),
                                          letterSpacing: 1.2,
                                        ),
                                      ),
                                      if (_isFetchingUsers) ...[
                                        const SizedBox(width: 8),
                                        const SizedBox(
                                          width: 12,
                                          height: 12,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: Colors.white70,
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                  const SizedBox(height: 12),

                                  // Horizontal Locker with Navigation Arrows
                                  _buildHorizontalLockerSelector(),
                                ],
                              ),
                            ),

                            const SizedBox(height: 24),

                            // Name Field (Only populated when ID is selected)
                            const Text(
                              'Name',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 6),
                            _buildGlassField(
                              controller: _nameController,
                              hintText: 'Select an ID above to populate name',
                              prefixIcon: Icons.person_outline,
                            ),

                            const SizedBox(height: 16),

                            // Email Field (Only populated when ID is selected)
                            const Text(
                              'Email',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 6),
                            _buildGlassField(
                              controller: _emailController,
                              hintText: 'Select an ID above to populate email',
                              prefixIcon: Icons.mail_outline,
                            ),

                            const SizedBox(height: 32),

                            // Animated Login Button with Lock Open Icon Effect
                            _buildAnimatedLoginButton(),

                            const SizedBox(height: 24),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  /// Horizontal Locker with Left and Right arrow buttons to increase/decrease ID
  Widget _buildHorizontalLockerSelector() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Left Arrow Mark (Decrease ID)
        _buildArrowButton(
          icon: Icons.arrow_back_ios_new_rounded,
          tooltip: 'Previous ID',
          onTap: _decreaseId,
        ),

        const SizedBox(width: 12),

        // Horizontal Combination Locker Drum
        _buildHorizontalLockerDrum(),

        const SizedBox(width: 12),

        // Right Arrow Mark (Increase ID)
        _buildArrowButton(
          icon: Icons.arrow_forward_ios_rounded,
          tooltip: 'Next ID',
          onTap: _increaseId,
        ),
      ],
    );
  }

  /// Glassmorphic Arrow Button
  Widget _buildArrowButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback onTap,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(22),
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withValues(alpha: 0.1),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.28),
                width: 1.2,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.4),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Icon(icon, color: Colors.white, size: 18),
          ),
        ),
      ),
    );
  }

  /// 3D Horizontal Combination Locker Drum
  Widget _buildHorizontalLockerDrum() {
    const drumWidth = 170.0;
    const drumHeight = 62.0;
    const itemExtent = 50.0;

    return Container(
      width: drumWidth,
      height: drumHeight,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFF121216),
            Color(0xFF282832),
            Color(0xFF40404C),
            Color(0xFF282832),
            Color(0xFF121216),
          ],
          stops: [0.0, 0.25, 0.5, 0.75, 1.0],
        ),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.35),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.65),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Center vertical selection groove highlight
          Container(
            width: itemExtent,
            height: drumHeight,
            decoration: BoxDecoration(
              border: Border.symmetric(
                vertical: BorderSide(
                  color: Colors.white.withValues(alpha: 0.45),
                  width: 1.4,
                ),
              ),
              color: Colors.white.withValues(alpha: 0.06),
            ),
          ),

          // Horizontal Wheel created via RotatedBox
          RotatedBox(
            quarterTurns: 3,
            child: SizedBox(
              width: drumHeight,
              height: drumWidth,
              child: ListWheelScrollView.useDelegate(
                controller: _wheelController,
                itemExtent: itemExtent,
                diameterRatio: 1.2,
                perspective: 0.003,
                physics: const FixedExtentScrollPhysics(),
                onSelectedItemChanged: _onWheelIdSelected,
                childDelegate: ListWheelChildBuilderDelegate(
                  builder: (context, index) {
                    final isSelected = (_selectedUserId ?? 0) == index;
                    final text = index == 0 ? '—' : '$index';

                    return RotatedBox(
                      quarterTurns: 1,
                      child: Center(
                        child: Text(
                          text,
                          style: TextStyle(
                            fontFamily: 'monospace',
                            fontSize: isSelected ? 24 : 18,
                            fontWeight: isSelected
                                ? FontWeight.w900
                                : FontWeight.w600,
                            color: isSelected
                                ? Colors.white
                                : Colors.white.withValues(alpha: 0.45),
                            letterSpacing: 1.0,
                          ),
                        ),
                      ),
                    );
                  },
                  childCount: 11, // 0 is '—', 1 to 10 are user IDs
                ),
              ),
            ),
          ),

          // Left cylindrical shadow vignette
          Positioned(
            left: 0,
            top: 0,
            bottom: 0,
            width: 36,
            child: IgnorePointer(
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.horizontal(
                    left: Radius.circular(12),
                  ),
                  gradient: LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    colors: [
                      Colors.black.withValues(alpha: 0.85),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Right cylindrical shadow vignette
          Positioned(
            right: 0,
            top: 0,
            bottom: 0,
            width: 36,
            child: IgnorePointer(
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.horizontal(
                    right: Radius.circular(12),
                  ),
                  gradient: LinearGradient(
                    begin: Alignment.centerRight,
                    end: Alignment.centerLeft,
                    colors: [
                      Colors.black.withValues(alpha: 0.85),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Glassmorphic Read-Only Field for Name and Email
  Widget _buildGlassField({
    required TextEditingController controller,
    required String hintText,
    required IconData prefixIcon,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(30),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: TextFormField(
          controller: controller,
          readOnly: true,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.white.withValues(alpha: 0.08),
            hintText: hintText,
            hintStyle: TextStyle(
              color: Colors.white.withValues(alpha: 0.4),
              fontSize: 13,
            ),
            prefixIcon: Icon(
              prefixIcon,
              color: Colors.white.withValues(alpha: 0.7),
              size: 20,
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 20,
              vertical: 15,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(30),
              borderSide: BorderSide(
                color: Colors.white.withValues(alpha: 0.25),
                width: 1.2,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(30),
              borderSide: BorderSide(
                color: Colors.white.withValues(alpha: 0.25),
                width: 1.2,
              ),
            ),
            focusedBorder: const OutlineInputBorder(
              borderRadius: BorderRadius.all(Radius.circular(30)),
              borderSide: BorderSide(color: Colors.white, width: 1.5),
            ),
          ),
        ),
      ),
    );
  }

  /// Button that animates an open lock icon surfacing from inside when tapped
  Widget _buildAnimatedLoginButton() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(30),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: InkWell(
          onTap: _onLoginPressed,
          borderRadius: BorderRadius.circular(30),
          child: Container(
            height: 54,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(30),
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.white.withValues(alpha: 0.35),
                  Colors.white.withValues(alpha: 0.12),
                ],
              ),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.45),
                width: 1.2,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.25),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            alignment: Alignment.center,
            child: AnimatedBuilder(
              animation: _unlockAnimationController,
              builder: (context, child) {
                return Stack(
                  alignment: Alignment.center,
                  clipBehavior: Clip.hardEdge,
                  children: [
                    // 1. "Login" text that fades out
                    Opacity(
                      opacity: _textFadeAnimation.value,
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.lock_outline,
                            color: Colors.white70,
                            size: 18,
                          ),
                          SizedBox(width: 8),
                          Text(
                            'Login',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.4,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // 2. Lock Open Icon emerging and scaling up from bottom
                    SlideTransition(
                      position: _lockSlideAnimation,
                      child: ScaleTransition(
                        scale: _lockScaleAnimation,
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withValues(alpha: 0.2),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.greenAccent.withValues(
                                  alpha: 0.4,
                                ),
                                blurRadius: 16,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.lock_open_rounded,
                            color: Colors.white,
                            size: 26,
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
