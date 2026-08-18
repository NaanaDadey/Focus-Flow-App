import 'package:flutter/material.dart';

/// Shown at the top of the dashboard while browsing without an account.
/// Tapping it routes to sign-up so guests can preserve the tasks they've
/// already entered instead of losing them.
class GuestBanner extends StatelessWidget {
  final VoidCallback onCreateAccount;
  const GuestBanner({super.key, required this.onCreateAccount});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: scheme.primaryContainer,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onCreateAccount,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Icon(Icons.cloud_off_rounded, color: scheme.onPrimaryContainer),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Browsing as guest',
                        style: TextStyle(
                            fontWeight: FontWeight.w700,
                            color: scheme.onPrimaryContainer)),
                    Text(
                      "Your data stays on this device. Create a free account to back it up and sync across devices.",
                      style: TextStyle(
                          fontSize: 12, color: scheme.onPrimaryContainer),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: scheme.onPrimaryContainer),
            ],
          ),
        ),
      ),
    );
  }
}
