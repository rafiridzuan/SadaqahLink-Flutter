import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';
import 'package:sadaqahlink/models/user_model.dart';

class AuthService with ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final DatabaseReference _db = FirebaseDatabase.instance.ref();

  User? get currentUser => _auth.currentUser;
  UserModel? _userModel;
  UserModel? get userModel => _userModel;

  AuthService() {
    _auth.authStateChanges().listen(_fetchUserModel);
  }

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  Future<void> signInWithEmailAndPassword(String email, String password) async {
    try {
      UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      await _fetchUserModel(result.user);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> _fetchUserModel(User? user) async {
    if (user != null) {
      try {
        final snapshot = await _db.child('users').child(user.uid).get();
        if (snapshot.exists) {
          final data = snapshot.value;
          if (data is Map) {
            // Convert Map<Object?, Object?> to Map<String, dynamic>
            final Map<String, dynamic> userData = Map<String, dynamic>.from(
              data.map((key, value) => MapEntry(key.toString(), value)),
            );
            _userModel = UserModel.fromMap(userData, user.uid);
            notifyListeners();
          }
        } else {
          // Check for pending restore
          try {
            final sanitizedEmail = user.email!
                .trim()
                .replaceAll('.', ',')
                .toLowerCase();
            final restoreSnapshot = await _db
                .child('pending_restores')
                .child(sanitizedEmail)
                .get();

            if (restoreSnapshot.exists) {
              final restoreData = restoreSnapshot.value;
              if (restoreData is Map) {
                // Restore user
                final Map<String, dynamic> userData = Map<String, dynamic>.from(
                  restoreData.map(
                    (key, value) => MapEntry(key.toString(), value),
                  ),
                );

                // Add fields that might be missing
                userData['uid'] = user.uid;

                // Write to users node
                await _db.child('users').child(user.uid).set(userData);

                // Delete from pending_restores
                await _db
                    .child('pending_restores')
                    .child(sanitizedEmail)
                    .remove();

                // Set local model
                _userModel = UserModel.fromMap(userData, user.uid);
                notifyListeners();
              }
            }
          } catch (e) {
            if (kDebugMode) {
              print("Error checking pending restore: $e");
            }
          }
        }
      } catch (e) {
        if (kDebugMode) {
          print("Error fetching user model: $e");
        }
      }
    } else {
      _userModel = null;
      notifyListeners();
    }
  }

  Future<void> updateUserName(String newName) async {
    final user = _auth.currentUser;
    if (user != null && _userModel != null) {
      try {
        await _db.child('users').child(user.uid).update({'name': newName});
        // Update local model
        _userModel = UserModel(
          uid: _userModel!.uid,
          email: _userModel!.email,
          name: newName,
          fullname: _userModel!.fullname,
          role: _userModel!.role,
        );
        notifyListeners();
      } catch (e) {
        if (kDebugMode) {
          print("Error updating user name: $e");
        }
        rethrow;
      }
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
    _userModel = null;
    notifyListeners();
  }
}
