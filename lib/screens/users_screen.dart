import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:sadaqahlink/widgets/background_wrapper.dart';
import 'package:sadaqahlink/widgets/blurred_app_bar.dart';
import 'package:provider/provider.dart';
import 'package:sadaqahlink/models/user_model.dart';
import 'package:sadaqahlink/services/auth_service.dart';
import 'package:sadaqahlink/widgets/custom_loading.dart';

import 'package:sadaqahlink/utils/app_localizations.dart';

class UsersScreen extends StatefulWidget {
  const UsersScreen({super.key});

  @override
  State<UsersScreen> createState() => _UsersScreenState();
}

class _UsersScreenState extends State<UsersScreen> {
  final DatabaseReference _db = FirebaseDatabase.instance.ref().child('users');

  void _showAddUserDialog() {
    showDialog(context: context, builder: (context) => const UserDialog());
  }

  void _showEditUserDialog(UserModel user) {
    showDialog(
      context: context,
      builder: (context) => UserDialog(user: user),
    );
  }

  void _deleteUser(UserModel user) {
    final localizations = AppLocalizations.of(context);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(localizations.get('delete_user')),
        content: Text(
          '${localizations.get('delete_user_confirmation')} ${user.fullname}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(localizations.get('cancel')),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                // Delete from Database
                await _db.child(user.uid).remove();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(localizations.get('user_removed')),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        '${localizations.get('error_deleting_user')}: $e',
                      ),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            child: Text(
              localizations.get('delete'),
              style: const TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    return BackgroundWrapper(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: BlurredAppBar(
          title: _isSearching
              ? TextField(
                  controller: _searchController,
                  autofocus: true,
                  decoration: InputDecoration(
                    hintText: localizations.get('search_users'),
                    border: InputBorder.none,
                    hintStyle: const TextStyle(color: Colors.white70),
                  ),
                  style: const TextStyle(color: Colors.white),
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value.toLowerCase();
                    });
                  },
                )
              : Consumer<AuthService>(
                  builder: (context, auth, _) {
                    final user = auth.userModel;
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'SadaqahLink',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        if (user != null)
                          Text(
                            '${user.role} | ${user.name}',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                      ],
                    );
                  },
                ),
          centerTitle: false,
          actions: [
            IconButton(
              icon: Icon(_isSearching ? Icons.close : Icons.search),
              onPressed: () {
                setState(() {
                  if (_isSearching) {
                    _isSearching = false;
                    _searchQuery = '';
                    _searchController.clear();
                  } else {
                    _isSearching = true;
                  }
                });
              },
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: _showAddUserDialog,
          icon: const Icon(Icons.add),
          label: Text(localizations.get('add_user')),
          backgroundColor: Theme.of(context).primaryColor,
          foregroundColor: Colors.white,
        ),
        body: StreamBuilder<DatabaseEvent>(
          stream: _db.onValue,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CustomLoadingWidget());
            }

            if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            }

            if (!snapshot.hasData || snapshot.data!.snapshot.value == null) {
              return Center(child: Text(localizations.get('no_users_found')));
            }

            final data = snapshot.data!.snapshot.value as Map<dynamic, dynamic>;
            final users = data.entries
                .map((e) {
                  final map = Map<String, dynamic>.from(e.value as Map);
                  return UserModel.fromMap(map, e.key);
                })
                .where((user) {
                  if (_searchQuery.isEmpty) return true;
                  return user.fullname.toLowerCase().contains(_searchQuery) ||
                      user.name.toLowerCase().contains(_searchQuery) ||
                      user.email.toLowerCase().contains(_searchQuery) ||
                      user.role.toLowerCase().contains(_searchQuery);
                })
                .toList();

            if (users.isEmpty) {
              return Center(child: Text(localizations.get('no_users_found')));
            }

            return ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: users.length,
              separatorBuilder: (context, index) => const SizedBox(height: 16),
              itemBuilder: (context, index) {
                final user = users[index];
                return _buildUserCard(user, index);
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildUserCard(UserModel user, int index) {
    final localizations = AppLocalizations.of(context);
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color ?? Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    user.fullname,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      height: 1.2,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert, color: Colors.grey),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onSelected: (value) {
                    if (value == 'edit') {
                      _showEditUserDialog(user);
                    } else if (value == 'delete') {
                      _deleteUser(user);
                    }
                  },
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          const Icon(Icons.edit, size: 18),
                          const SizedBox(width: 8),
                          Text(localizations.get('edit')),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          const Icon(Icons.delete, size: 18, color: Colors.red),
                          const SizedBox(width: 8),
                          Text(
                            localizations.get('delete'),
                            style: const TextStyle(color: Colors.red),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              user.name, // Username
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).textTheme.bodySmall?.color,
              ),
            ),
            Text(
              user.email,
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).textTheme.bodySmall?.color,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: user.role == 'admin'
                    ? Colors.orange.withOpacity(0.1)
                    : Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                user.role.toUpperCase(),
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: user.role == 'admin' ? Colors.orange : Colors.blue,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class UserDialog extends StatefulWidget {
  final UserModel? user;

  const UserDialog({super.key, this.user});

  @override
  State<UserDialog> createState() => _UserDialogState();
}

class _UserDialogState extends State<UserDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _fullnameController;
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  String _role = 'ajk';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _fullnameController = TextEditingController(
      text: widget.user?.fullname ?? '',
    );
    _nameController = TextEditingController(text: widget.user?.name ?? '');
    _emailController = TextEditingController(text: widget.user?.email ?? '');
    _role = (widget.user?.role ?? 'ajk').toLowerCase();
  }

  @override
  void dispose() {
    _fullnameController.dispose();
    _nameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _saveUser() async {
    final localizations = AppLocalizations.of(context);
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      try {
        if (widget.user == null) {
          // Add New User
          FirebaseApp secondaryApp = await Firebase.initializeApp(
            name: 'SecondaryApp',
            options: Firebase.app().options,
          );

          try {
            UserCredential userCredential =
                await FirebaseAuth.instanceFor(
                  app: secondaryApp,
                ).createUserWithEmailAndPassword(
                  email: _emailController.text.trim(),
                  password: 'tempPassword123!', // Temporary password
                );

            final newUser = UserModel(
              uid: userCredential.user!.uid,
              email: _emailController.text.trim(),
              name: _nameController.text.trim(),
              fullname: _fullnameController.text.trim(),
              role: _role.toLowerCase(),
            );

            await FirebaseDatabase.instance
                .ref()
                .child('users')
                .child(newUser.uid)
                .set(newUser.toMap());

            await FirebaseAuth.instanceFor(
              app: secondaryApp,
            ).sendPasswordResetEmail(email: newUser.email);

            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(localizations.get('user_created')),
                  backgroundColor: Colors.green,
                ),
              );
              Navigator.pop(context);
            }
          } finally {
            await secondaryApp.delete();
          }
        } else {
          // Edit Existing User
          final updatedUser = UserModel(
            uid: widget.user!.uid,
            email: widget.user!.email, // Keep original email
            name: _nameController.text.trim(),
            fullname: _fullnameController.text.trim(),
            role: _role.toLowerCase(),
          );

          await FirebaseDatabase.instance
              .ref()
              .child('users')
              .child(updatedUser.uid)
              .update(updatedUser.toMap());

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(localizations.get('user_updated')),
                backgroundColor: Colors.green,
              ),
            );
            Navigator.pop(context);
          }
        }
      } catch (e) {
        if (e is FirebaseAuthException && e.code == 'email-already-in-use') {
          // Handle restoration case
          try {
            final sanitizedEmail = _emailController.text
                .trim()
                .replaceAll('.', ',') // Sanitize for DB key
                .toLowerCase();

            // Queue for restoration
            await FirebaseDatabase.instance
                .ref()
                .child('pending_restores')
                .child(sanitizedEmail)
                .set({
                  'email': _emailController.text.trim(),
                  'name': _nameController.text.trim(),
                  'fullname': _fullnameController.text.trim(),
                  'role': _role.toLowerCase(),
                  'timestamp': ServerValue.timestamp,
                });

            // Send password reset email
            await FirebaseAuth.instance.sendPasswordResetEmail(
              email: _emailController.text.trim(),
            );

            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(localizations.get('user_restore_queued')),
                  backgroundColor: Colors.orange,
                  duration: const Duration(seconds: 4),
                ),
              );
              Navigator.pop(context);
            }
          } catch (restoreError) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Error queuing restore: $restoreError'),
                  backgroundColor: Colors.red,
                ),
              );
            }
          }
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
            );
          }
        }
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    return AlertDialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 16.0),
      title: Text(
        widget.user == null
            ? localizations.get('add_new_user')
            : localizations.get('edit_user'),
      ),
      content: SingleChildScrollView(
        child: SizedBox(
          width: double.maxFinite,
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _fullnameController,
                  decoration: InputDecoration(
                    labelText: localizations.get('full_name'),
                  ),
                  validator: (v) => v!.isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    labelText: localizations.get('username'),
                  ),
                  validator: (v) => v!.isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _emailController,
                  decoration: InputDecoration(
                    labelText: localizations.get('email'),
                  ),
                  enabled: widget.user == null, // Disable email edit for now
                  validator: (v) => v!.isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: _role,
                  decoration: InputDecoration(
                    labelText: localizations.get('role'),
                  ),
                  items: [
                    DropdownMenuItem(
                      value: 'admin',
                      child: Text(localizations.get('admin')),
                    ),
                    DropdownMenuItem(
                      value: 'ajk',
                      child: Text(localizations.get('ajk')),
                    ),
                  ],
                  onChanged: (v) => setState(() => _role = v!),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ElevatedButton(
              onPressed: _isLoading ? null : _saveUser,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: Theme.of(context).brightness == Brightness.dark
                    ? Colors.transparent
                    : Theme.of(context).primaryColor,
                foregroundColor: Theme.of(context).brightness == Brightness.dark
                    ? Colors.blueAccent
                    : Colors.white,
                elevation: Theme.of(context).brightness == Brightness.dark
                    ? 0
                    : 4,
                shadowColor: Theme.of(context).primaryColor.withOpacity(0.4),
                side: Theme.of(context).brightness == Brightness.dark
                    ? const BorderSide(color: Colors.blueAccent, width: 2)
                    : BorderSide.none,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(
                      widget.user == null
                          ? localizations.get('register')
                          : localizations.get('done'),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                localizations.get('cancel'),
                style: TextStyle(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.white70
                      : Colors.grey[700],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
