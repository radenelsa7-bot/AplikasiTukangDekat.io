import 'package:flutter/material.dart';
import '../../app/theme/app_theme.dart';

class TukangDekatFooter extends StatelessWidget {
  final String tagLine;

  const TukangDekatFooter({
    super.key,
    this.tagLine = 'Mendekatkan teknisi terpercaya untuk setiap kebutuhanmu.',
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppTheme.navy,
      padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'TukangDekat',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppTheme.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Row(
                children: const [
                  _FooterLink(label: 'Beranda'),
                  _FooterLink(label: 'Pesanan'),
                  _FooterLink(label: 'Akun'),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              color: AppTheme.cream,
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.all(12),
            child: Text(
              tagLine,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: AppTheme.navy),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            '© 2026 TukangDekat. Fast, friendly, and locally trusted.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppTheme.white.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }
}

class _FooterLink extends StatelessWidget {
  final String label;

  const _FooterLink({required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 16),
      child: Text(
        label,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: AppTheme.orange,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
