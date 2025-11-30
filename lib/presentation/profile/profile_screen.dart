import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:is_application/core/theme/app_colors.dart';
import 'package:is_application/core/theme/app_theme.dart';
import 'package:is_application/presentation/auth/providers/auth_providers.dart';
import 'package:is_application/presentation/profile/providers/profile_provider.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final brightness = Theme.of(context).brightness;
    final colors = ref.watch(appColorsProvider(brightness));
    final authState = ref.watch(authStateProvider);
    
    // Watch providers for new features
    final themeMode = ref.watch(appThemeModeProvider);
    final notificationsEnabled = ref.watch(notificationEnabledProvider);
    final profileState = ref.watch(profileControllerProvider);

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        title: Text(
          'Profile & Settings',
          style: TextStyle(color: colors.onBackground, fontWeight: FontWeight.bold),
        ),
        backgroundColor: colors.background,
        elevation: 0,
        centerTitle: false,
      ),
      body: authState.when(
        data: (user) {
          if (user == null) {
            return Center(child: Text('Not signed in', style: TextStyle(color: colors.onBackground)));
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // --- USER HEADER ---
                Center(
                  child: Column(
                    children: [
                      // GestureDetector(
                      //   onTap: () {
                      //     ref.read(profileControllerProvider.notifier).updateProfileImage();
                      //   },
                      //   child: Stack(
                      //     children: [
                            CircleAvatar(
                              radius: 50,
                              backgroundColor: colors.primaryLight,
                              backgroundImage: user.photoURL != null ? NetworkImage(user.photoURL!) : null,
                              child: profileState.isLoading
                                  ? const CircularProgressIndicator()
                                  : (user.photoURL == null
                                      ? Text(
                                          (user.displayName ?? user.email ?? 'U').substring(0, 1).toUpperCase(),
                                          style: TextStyle(
                                            fontSize: 40,
                                            fontWeight: FontWeight.bold,
                                            color: colors.primaryDark,
                                          ),
                                        )
                                      : null),
                            ),
                            // Positioned(
                            //   bottom: 0,
                            //   right: 0,
                            //   child: Container(
                            //     padding: const EdgeInsets.all(6),
                            //     decoration: BoxDecoration(
                            //       color: colors.primary,
                            //       shape: BoxShape.circle,
                            //       border: Border.all(color: colors.background, width: 2),
                            //     ),
                            //     child: const Icon(
                            //       Icons.camera_alt,
                            //       size: 16,
                            //       color: Colors.white,
                            //     ),
                            //   ),
                            // ),
                      //     ],
                      //   ),
                      // ),
                      const SizedBox(height: 16),
                      Text(
                        user.displayName ?? 'User',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: colors.onBackground,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        user.email ?? '',
                        style: TextStyle(
                          fontSize: 16,
                          color: colors.onSurface.withValues(alpha: 0.7),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 40),

                // --- SETTINGS SECTION ---
                Text(
                  'PREFERENCES',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: colors.onSurface.withValues(alpha: 0.5),
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 10),
                _SettingsTile(
                  icon: Icons.palette_outlined,
                  title: 'Theme',
                  subtitle: _getThemeName(themeMode),
                  colors: colors,
                  onTap: () {
                    _showThemePicker(context, ref, colors);
                  },
                ),
                _SettingsTile(
                  icon: notificationsEnabled ? Icons.notifications_active_outlined : Icons.notifications_off_outlined,
                  title: 'Notifications',
                  subtitle: notificationsEnabled ? 'On' : 'Off',
                  colors: colors,
                  trailing: Switch(
                    value: notificationsEnabled,
                    activeThumbColor: colors.primary,
                    onChanged: (value) {
                      ref.read(notificationEnabledProvider.notifier).state = value;
                    },
                  ),
                  onTap: () {
                    // Toggle via tap as well
                    ref.read(notificationEnabledProvider.notifier).state = !notificationsEnabled;
                  },
                ),

                const SizedBox(height: 30),

                // --- ACCOUNT SECTION ---
                Text(
                  'ACCOUNT',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: colors.onSurface.withValues(alpha: 0.5),
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 10),
                _SettingsTile(
                  icon: Icons.logout,
                  title: 'Sign Out',
                  colors: colors,
                  isDestructive: true,
                  onTap: () async {
                    await ref.read(authControllerProvider.notifier).signOut();
                  },
                ),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, s) => Center(child: Text('Error: $e')),
      ),
    );
  }

  String _getThemeName(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.system:
        return 'System Default';
      case ThemeMode.light:
        return 'Light Mode';
      case ThemeMode.dark:
        return 'Dark Mode';
    }
  }

  void _showThemePicker(BuildContext context, WidgetRef ref, AppColors colors) {
    showModalBottomSheet(
      context: context,
      backgroundColor: colors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 16),
              Text(
                'Choose Theme',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: colors.onSurface,
                ),
              ),
              const SizedBox(height: 16),
              _ThemeOption(
                title: 'System Default',
                mode: ThemeMode.system,
                colors: colors,
                ref: ref,
              ),
              _ThemeOption(
                title: 'Light Mode',
                mode: ThemeMode.light,
                colors: colors,
                ref: ref,
              ),
              _ThemeOption(
                title: 'Dark Mode',
                mode: ThemeMode.dark,
                colors: colors,
                ref: ref,
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }
}

class _ThemeOption extends StatelessWidget {
  final String title;
  final ThemeMode mode;
  final AppColors colors;
  final WidgetRef ref;

  const _ThemeOption({
    required this.title,
    required this.mode,
    required this.colors,
    required this.ref,
  });

  @override
  Widget build(BuildContext context) {
    final currentMode = ref.watch(appThemeModeProvider);
    final isSelected = currentMode == mode;

    return ListTile(
      title: Text(
        title,
        style: TextStyle(
          color: isSelected ? colors.primary : colors.onSurface,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      trailing: isSelected ? Icon(Icons.check, color: colors.primary) : null,
      onTap: () {
        ref.read(appThemeModeProvider.notifier).state = mode;
        Navigator.pop(context);
      },
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final AppColors colors;
  final VoidCallback onTap;
  final bool isDestructive;
  final Widget? trailing;

  const _SettingsTile({
    required this.icon,
    required this.title,
    this.subtitle,
    required this.colors,
    required this.onTap,
    this.isDestructive = false,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.border.withValues(alpha: 0.5)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: isDestructive ? colors.error.withValues(alpha: 0.1) : colors.primaryLight.withValues(alpha: 0.2),
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            color: isDestructive ? colors.error : colors.primaryDark,
            size: 22,
          ),
        ),
        title: Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 16,
            color: isDestructive ? colors.error : colors.onSurface,
          ),
        ),
        subtitle: subtitle != null
            ? Text(
                subtitle!,
                style: TextStyle(
                  color: colors.onSurface.withValues(alpha: 0.6),
                  fontSize: 13,
                ),
              )
            : null,
        trailing: trailing ?? Icon(
          Icons.chevron_right,
          color: colors.onSurface.withValues(alpha: 0.3),
        ),
      ),
    );
  }
}
