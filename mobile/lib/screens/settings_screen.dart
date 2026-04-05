import 'package:flutter/material.dart';

import '../models.dart';
import '../theme.dart';
import '../widgets/common.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({
    super.key,
    required this.profile,
    required this.onBack,
    required this.onLogout,
  });

  final UserProfile profile;
  final VoidCallback onBack;
  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconButton(
                onPressed: onBack,
                icon: const Icon(Icons.arrow_back_ios_new_rounded),
              ),
              Expanded(
                child: Text(
                  'SETTINGS',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.labelLarge?.copyWith(
                    letterSpacing: 1.2,
                  ),
                ),
              ),
              const SizedBox(width: 48),
            ],
          ),
          const SizedBox(height: 10),
          PanelCard(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 54,
                  height: 54,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.mutedGold,
                  ),
                  child: Center(
                    child: Text(
                      profile.initials,
                      style: const TextStyle(
                        color: AppColors.creamText,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Operator Account',
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: AppColors.softText,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        profile.username,
                        style: theme.textTheme.titleLarge,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${profile.roleLabel} access active',
                        style: theme.textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'PROFILE SNAPSHOT',
            style: theme.textTheme.labelMedium?.copyWith(
              color: AppColors.softText,
            ),
          ),
          const SizedBox(height: 8),
          PanelCard(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Column(
              children: [
                DetailLine(label: 'Username', value: profile.username),
                DetailLine(label: 'Role', value: profile.roleLabel),
                DetailLine(label: 'Location', value: profile.locationLabel),
                DetailLine(
                  label: 'Location ID',
                  value: profile.locationId.toString(),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'ACCESS',
            style: theme.textTheme.labelMedium?.copyWith(
              color: AppColors.softText,
            ),
          ),
          const SizedBox(height: 8),
          PanelCard(
            padding: const EdgeInsets.all(14),
            child: Column(
              children: [
                const _SettingsAccessTile(
                  icon: Icons.inventory_2_outlined,
                  title: 'Inventory Access',
                  subtitle: 'Assigned warehouse stock overview available',
                ),
                SizedBox(height: 10),
                const _SettingsAccessTile(
                  icon: Icons.notifications_active_outlined,
                  title: 'Alert Monitoring',
                  subtitle: 'Critical shortage notifications enabled',
                ),
              ],
            ),
          ),
          const Spacer(),
          PrimaryActionButton(
            label: 'Log Out',
            icon: Icons.logout_rounded,
            onPressed: onLogout,
          ),
        ],
      ),
    );
  }
}

class _SettingsAccessTile extends StatelessWidget {
  const _SettingsAccessTile({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: AppColors.mutedGold,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 18, color: AppColors.creamText),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: theme.textTheme.titleMedium,
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: theme.textTheme.bodyMedium,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
