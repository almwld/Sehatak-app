import 'package:firebase_auth/firebase_auth.dart';

class FirebaseService {
  static final FirebaseService _instance = FirebaseService._internal();
  factory FirebaseService() => _instance;
  FirebaseService._internal();

  late final FirebaseAuth auth;

  Future<void> initialize() async {
    auth = FirebaseAuth.instance;
    auth.setLanguageCode('ar');
  }

  User? get currentUser => auth.currentUser;
  Stream<User?> get authState => auth.authStateChanges();
  bool get isLoggedIn => auth.currentUser != null;
}
