import 'package:flutter/material.dart';
import '../home_theme.dart';

class HomeTopbar extends StatelessWidget {
  final String userName;
  final int readinessPercent;
  final VoidCallback onNotification;
  final VoidCallback onBack;

  const HomeTopbar({
    super.key,
    required this.userName,
    required this.readinessPercent,
    required this.onNotification,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: const BoxDecoration(
        color: Color(0xD907080F),
        border: Border(bottom: BorderSide(color: HT.border)),
      ),
      child: Row(
        children: [
          // Left: title
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('Dashboard Home', style: TextStyle(
                  fontSize: 14, fontWeight: FontWeight.w700, color: HT.textColor,
                )),
                Text('Welcome back, $userName 👋', style: const TextStyle(
                  fontSize: 11, color: HT.muted,
                )),
              ],
            ),
          ),
          // Job Ready pill
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0x1400E5A0),
              border: Border.all(color: const Color(0x3300E5A0)),
              borderRadius: BorderRadius.circular(50),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 7, height: 7,
                  decoration: const BoxDecoration(
                    color: HT.accent,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Text('$readinessPercent% Job Ready', style: const TextStyle(
                  fontSize: 11, fontWeight: FontWeight.w600, color: HT.accent,
                )),
              ],
            ),
          ),
          const SizedBox(width: 8),
          // Notification btn
          _TbBtn(
            icon: Icons.notifications_outlined,
            hasIndicator: true,
            onTap: onNotification,
          ),
          const SizedBox(width: 6),
          // Back btn
          _TbBtn(icon: Icons.logout_rounded, onTap: onBack),
        ],
      ),
    );
  }
}

class _TbBtn extends StatelessWidget {
  final IconData icon;
  final bool hasIndicator;
  final VoidCallback onTap;

  const _TbBtn({
    required this.icon,
    required this.onTap,
    this.hasIndicator = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36, height: 36,
        decoration: BoxDecoration(
          color: const Color(0x0DFFFFFF),
          border: Border.all(color: HT.border),
          borderRadius: BorderRadius.circular(9),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Icon(icon, size: 16, color: HT.muted),
            if (hasIndicator)
              Positioned(
                right: 8, top: 8,
                child: Container(
                  width: 6, height: 6,
                  decoration: BoxDecoration(
                    color: HT.accent,
                    shape: BoxShape.circle,
                    border: Border.all(color: HT.bg, width: 1.5),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
