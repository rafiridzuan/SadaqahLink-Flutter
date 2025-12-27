import 'package:flutter/material.dart';
import 'package:sadaqahlink/widgets/background_wrapper.dart';
import 'package:sadaqahlink/widgets/blurred_app_bar.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:sadaqahlink/services/auth_service.dart';
import 'package:sadaqahlink/services/fcm_service.dart';
import 'package:sadaqahlink/providers/settings_provider.dart';
import 'package:sadaqahlink/utils/app_localizations.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  bool _isEditing = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final user = Provider.of<AuthService>(context, listen: false).userModel;
    _nameController = TextEditingController(text: user?.name ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _saveChanges() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        await Provider.of<AuthService>(
          context,
          listen: false,
        ).updateUserName(_nameController.text.trim());
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(AppLocalizations.of(context).get('success_update')),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                '${AppLocalizations.of(context).get('error_update')}: $e',
              ),
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final user = authService.userModel;
    final localizations = AppLocalizations.of(context);
    final settingsProvider = Provider.of<SettingsProvider>(context);

    return BackgroundWrapper(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: BlurredAppBar(title: Text(localizations.get('settings'))),
        body: user == null
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      const SizedBox(height: 32),

                      // Avatar
                      CircleAvatar(
                        radius: 60,
                        backgroundColor: Theme.of(
                          context,
                        ).colorScheme.primaryContainer,
                        child: Text(
                          user.name.isNotEmpty
                              ? user.name[0].toUpperCase()
                              : 'U',
                          style: TextStyle(
                            fontSize: 48,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      ),

                      const SizedBox(height: 32),

                      // Editable Name Field
                      TextFormField(
                        controller: _nameController,
                        decoration: InputDecoration(
                          labelText: localizations.get('display_name'),
                          prefixIcon: const Icon(Icons.person_outline),
                          border: const OutlineInputBorder(),
                          helperText: localizations.get('display_name_helper'),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return localizations.get('please_enter_name');
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: 24),

                      // Read-Only Fields Card
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                localizations.get('account_info'),
                                style: Theme.of(context).textTheme.titleMedium
                                    ?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: Theme.of(
                                        context,
                                      ).textTheme.bodyLarge?.color,
                                    ),
                              ),
                              const SizedBox(height: 16),
                              _buildReadOnlyField(
                                context,
                                localizations.get('full_name'),
                                user.fullname,
                                Icons.badge,
                              ),
                              const Divider(),
                              _buildReadOnlyField(
                                context,
                                localizations.get('email'),
                                user.email,
                                Icons.email,
                              ),
                              const Divider(),
                              _buildReadOnlyField(
                                context,
                                localizations.get('role'),
                                user.role.toUpperCase(),
                                Icons.admin_panel_settings,
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 32),

                      // App Settings
                      Text(
                        localizations.get('app_settings'),
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Theme.of(
                                context,
                              ).textTheme.bodyLarge?.color,
                            ),
                      ),
                      const SizedBox(height: 16),
                      Card(
                        child: Column(
                          children: [
                            ListTile(
                              leading: const Icon(Icons.language),
                              title: Text(localizations.get('language')),
                              trailing: DropdownButton<Locale>(
                                value: settingsProvider.locale,
                                underline: const SizedBox(),
                                dropdownColor: Theme.of(context).cardColor,
                                onChanged: (Locale? newLocale) {
                                  if (newLocale != null) {
                                    settingsProvider.setLocale(newLocale);
                                  }
                                },
                                items: [
                                  DropdownMenuItem(
                                    value: const Locale('en'),
                                    child: Text(localizations.get('english')),
                                  ),
                                  DropdownMenuItem(
                                    value: const Locale('ms'),
                                    child: Text(localizations.get('malay')),
                                  ),
                                ],
                              ),
                            ),
                            const Divider(height: 1),
                            SwitchListTile(
                              secondary: const Icon(Icons.dark_mode),
                              title: Text(localizations.get('dark_mode')),
                              value:
                                  settingsProvider.themeMode == ThemeMode.dark,
                              onChanged: (bool value) {
                                settingsProvider.toggleTheme(value);
                              },
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 32),

                      // Save Changes Button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _isLoading ? null : _saveChanges,
                          icon: _isLoading
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Icon(Icons.save),
                          label: Text(
                            _isLoading
                                ? localizations.get('saving')
                                : localizations.get('save_changes'),
                          ),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            backgroundColor: Theme.of(context).primaryColor,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Logout Button
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: () {
                            showDialog(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: Text(localizations.get('logout')),
                                content: Text(
                                  localizations.get('logout_confirmation'),
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(context),
                                    child: Text(localizations.get('cancel')),
                                  ),
                                  TextButton(
                                    onPressed: () async {
                                      Navigator.pop(context);
                                      Navigator.of(
                                        context,
                                      ).popUntil((route) => route.isFirst);

                                      // Clean up FCM token before signing out
                                      final user =
                                          FirebaseAuth.instance.currentUser;
                                      if (user != null) {
                                        await FCMService().cleanup(user.uid);
                                      }

                                      authService.signOut();
                                    },
                                    child: Text(
                                      localizations.get('logout'),
                                      style: TextStyle(color: Colors.red),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                          icon: const Icon(Icons.logout, color: Colors.red),
                          label: Text(
                            localizations.get('logout'),
                            style: const TextStyle(color: Colors.red),
                          ),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            side: const BorderSide(color: Colors.red),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildReadOnlyField(
    BuildContext context,
    String label,
    String value,
    IconData icon,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(
            icon,
            color: Theme.of(context).iconTheme.color?.withOpacity(0.7),
            size: 20,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).textTheme.bodySmall?.color,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          Icon(Icons.lock, color: Theme.of(context).disabledColor, size: 16),
        ],
      ),
    );
  }
}
