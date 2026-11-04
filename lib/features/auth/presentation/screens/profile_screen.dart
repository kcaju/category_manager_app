import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/models/user_profile.dart';
import '../cubit/auth_cubit.dart';

class ProfileScreen extends StatelessWidget {
  final UserProfile user;

  const ProfileScreen({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF08080B),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // 1. Top Header Banner with Action Buttons and Overlapping Double-Ring Avatar
          SliverToBoxAdapter(
            child: Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.topCenter,
              children: [
                // Scenic / Mountain Silhouette Header Banner Card
                Container(
                  height: 195,
                  margin: const EdgeInsets.fromLTRB(14, 44, 14, 0),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(28),
                    gradient: const LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Color(0xFF262A36),
                        Color(0xFF171922),
                        Color(0xFF0C0D12),
                      ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.6),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(28),
                    child: Stack(
                      children: [
                        // Subtle mountain horizon silhouette
                        Positioned.fill(
                          child: CustomPaint(
                            painter: _MountainSilhouettePainter(),
                          ),
                        ),

                        // Top bar action buttons inside the banner
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              _buildCircleAction(
                                icon: Icons.logout_rounded,
                                tooltip: 'Logout',
                                onTap: () => _confirmLogout(context),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Overlapping Double-Ring Avatar
                Positioned(top: 130, child: _buildDoubleRingAvatar(user.name)),
              ],
            ),
          ),

          // Space for the overlapping avatar
          const SliverToBoxAdapter(child: SizedBox(height: 72)),

          // 2. User Name, Location Chip, and Catchphrase Bio
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  // Full Name
                  Text(
                    user.name,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      letterSpacing: 0.3,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),

                  // Location and Joined Badges
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Location pin badge
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.location_on,
                            color: Color(0xFF4F83F6),
                            size: 16,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            user.city.isNotEmpty
                                ? '${user.city},${user.street}'
                                : 'California, USA',
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 12.5,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(width: 16),

                      // Clock / Joined badge
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.man,
                            color: Color(0xFFFBBF24),
                            size: 15,
                          ),
                          const SizedBox(width: 2),
                          Text(
                            'User #${user.id}',
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 12.5,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // 3. Sleek Bento Grid for User Details
                  _buildBentoGrid(context, user),

                  // Bottom padding for bottom navigation bar
                  const SizedBox(height: 90),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- BENTO GRID LAYOUT ---

  Widget _buildBentoGrid(BuildContext context, UserProfile user) {
    return Column(
      children: [
        // 1. Featured Top Hero Tile: Name & Username (Full Width)
        _buildIdentityHeroTile(user),
        const SizedBox(height: 12),

        // 2. Email Tile (Full Width - no truncation, full email always visible)
        _buildFullWidthTile(
          context: context,
          icon: Icons.mail,
          iconColor: const Color(0xFF10B981),
          label: 'EMAIL',
          value: user.email,
          isCopyable: true,
        ),
        const SizedBox(height: 12),

        // 3. Middle Row: Phone (left) & Website (right)
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _buildBentoTile(
                context: context,
                icon: Icons.phone_rounded,
                iconColor: const Color(0xFFF59E0B),
                label: 'PHONE',
                value: user.phone,
                isCopyable: true,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildBentoTile(
                context: context,
                icon: Icons.language_rounded,
                iconColor: const Color(0xFF06B6D4),
                label: 'WEBSITE',
                value: user.website,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // 4. Company Tile (Full Width - full company name and business scope completely visible)
        _buildFullWidthTile(
          context: context,
          icon: Icons.business_rounded,
          iconColor: const Color(0xFFEC4899),
          label: 'COMPANY',
          value: user.companyName,
          subtitle: user.companyBs.isNotEmpty
              ? '${user.companyCatchPhrase}\n${user.companyBs} '
              : null,
        ),
      ],
    );
  }

  Widget _buildIdentityHeroTile(UserProfile user) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF14151D),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.08),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: const Color(0xFF3B82F6).withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: const Color(0xFF3B82F6).withValues(alpha: 0.28),
                width: 1,
              ),
            ),
            child: const Icon(
              Icons.badge_rounded,
              color: Color(0xFF60A5FA),
              size: 24,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'IDENTITY',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.8,
                        color: Colors.white.withValues(alpha: 0.45),
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2.5,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF10B981).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 5.5,
                            height: 5.5,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: Color(0xFF10B981),
                            ),
                          ),
                          const SizedBox(width: 5),
                          const Text(
                            'Active',
                            style: TextStyle(
                              color: Color(0xFF34D399),
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  user.name,
                  style: const TextStyle(
                    fontSize: 16.5,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                  softWrap: true,
                ),
                const SizedBox(height: 2),
                Text(
                  '@${user.username}',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF60A5FA),
                  ),
                  softWrap: true,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFullWidthTile({
    required BuildContext context,
    required IconData icon,
    required Color iconColor,
    required String label,
    required String value,
    String? subtitle,
    bool isCopyable = false,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFF14151D),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.08),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: iconColor, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8,
                    color: Colors.white.withValues(alpha: 0.45),
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  value.isNotEmpty ? value : '—',
                  style: const TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                  softWrap: true,
                ),
                if (subtitle != null && subtitle.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 11.5,
                      color: Colors.white.withValues(alpha: 0.5),
                    ),
                    softWrap: true,
                  ),
                ],
              ],
            ),
          ),
          if (isCopyable)
            IconButton(
              icon: const Icon(Icons.copy_rounded, size: 18),
              color: Colors.white.withValues(alpha: 0.35),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              tooltip: 'Copy',
              onPressed: () {
                Clipboard.setData(ClipboardData(text: value));
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('$label copied to clipboard'),
                    duration: const Duration(seconds: 1),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildBentoTile({
    required BuildContext context,
    required IconData icon,
    required Color iconColor,
    required String label,
    required String value,
    String? subtitle,
    bool isCopyable = false,
  }) {
    return Container(
      constraints: const BoxConstraints(minHeight: 115),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF14151D),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.08),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: iconColor, size: 20),
              ),
              if (isCopyable)
                IconButton(
                  icon: const Icon(Icons.copy_rounded, size: 16),
                  color: Colors.white.withValues(alpha: 0.35),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  tooltip: 'Copy',
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: value));
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('$label copied to clipboard'),
                        duration: const Duration(seconds: 1),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                ),
            ],
          ),
          const SizedBox(height: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.7,
                  color: Colors.white.withValues(alpha: 0.45),
                ),
              ),
              const SizedBox(height: 3),
              Text(
                value.isNotEmpty ? value : '—',
                style: const TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
                softWrap: true,
              ),
              if (subtitle != null && subtitle.isNotEmpty) ...[
                const SizedBox(height: 1),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 10.5,
                    color: Colors.white.withValues(alpha: 0.45),
                  ),
                  softWrap: true,
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  // --- HEADER & AVATAR BUILDERS ---

  Widget _buildDoubleRingAvatar(String name) {
    final initial = name.isNotEmpty ? name[0].toUpperCase() : 'U';

    return Container(
      width: 120,
      height: 120,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.85),
          width: 2.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.7),
            blurRadius: 16,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(4.0),
        child: Container(
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: Color(0xFF090A0E),
          ),
          child: Padding(
            padding: const EdgeInsets.all(2.5),
            child: CircleAvatar(
              radius: 50,
              backgroundColor: const Color(0xFF1E212D),
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      const Color(0xFF3B82F6).withValues(alpha: 0.35),
                      const Color(0xFF1E2230),
                    ],
                  ),
                ),
                child: Center(
                  child: Text(
                    initial,
                    style: const TextStyle(
                      fontSize: 42,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 1.0,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCircleAction({
    required IconData icon,
    required VoidCallback onTap,
    String? tooltip,
  }) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        shape: BoxShape.circle,
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.15),
          width: 0.8,
        ),
      ),
      child: IconButton(
        padding: EdgeInsets.zero,
        tooltip: tooltip,
        icon: Icon(icon, color: Colors.white, size: 20),
        onPressed: onTap,
      ),
    );
  }

  void _confirmLogout(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E28),
        title: const Text('Logout', style: TextStyle(color: Colors.white)),
        content: const Text(
          'Are you sure you want to log out?',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text(
              'Cancel',
              style: TextStyle(color: Colors.white54),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              Navigator.pop(dialogCtx);
              context.read<AuthCubit>().logout();
            },
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }
}

// Subtle mountain silhouette painter for the top banner
class _MountainSilhouettePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.04)
      ..style = PaintingStyle.fill;

    final path = Path()
      ..moveTo(0, size.height * 0.75)
      ..quadraticBezierTo(
        size.width * 0.25,
        size.height * 0.45,
        size.width * 0.5,
        size.height * 0.65,
      )
      ..quadraticBezierTo(
        size.width * 0.75,
        size.height * 0.85,
        size.width,
        size.height * 0.55,
      )
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
