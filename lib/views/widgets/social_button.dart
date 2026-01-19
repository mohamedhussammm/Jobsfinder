import 'package:flutter/material.dart';
import '../../core/theme/colors.dart';

class SocialButton extends StatelessWidget {
  final String label;
  final String iconPath; // Path to asset or network url
  final VoidCallback onTap;
  final bool isOutlined;

  const SocialButton({
    Key? key,
    required this.label,
    required this.iconPath,
    required this.onTap,
    this.isOutlined = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 56,
        decoration: BoxDecoration(
          color: isOutlined ? Colors.transparent : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: isOutlined
              ? Border.all(color: Colors.white.withOpacity(0.3))
              : null,
          boxShadow: isOutlined
              ? null
              : [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Using network image for now to avoid asset setup complexity
            // In production, these should be SvgPicture.asset
            Image.network(
              iconPath,
              height: 24,
              width: 24,
              errorBuilder: (context, error, stackTrace) =>
                  const Icon(Icons.login),
            ),
            const SizedBox(width: 12),
            Text(
              label,
              style: TextStyle(
                color: isOutlined ? Colors.white : AppColors.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.bold,
                fontFamily: 'Manrope',
              ),
            ),
          ],
        ),
      ),
    );
  }
}
