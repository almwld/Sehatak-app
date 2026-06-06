import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../core/services/firestore_rest.dart';
import '../../../data/models/user_models/user_model.dart';

abstract class AuthEvent extends Equatable {
  const AuthEvent();
}
class AppStarted extends AuthEvent { @override List<Object?> get props => []; }
class LoginWithEmail extends AuthEvent {
  final String email, password;
  const LoginWithEmail({required this.email, required this.password});
  @override List<Object?> get props => [email, password];
}
class RegisterWithEmail extends AuthEvent {
  final String name, email, phone, password;
  const RegisterWithEmail({required this.name, required this.email, required this.phone, required this.password});
  @override List<Object?> get props => [name, email, phone, password];
}
class Logout extends AuthEvent { @override List<Object?> get props => []; }

abstract class AuthState extends Equatable {
  const AuthState();
}
class AuthInitial extends AuthState { @override List<Object?> get props => []; }
class AuthLoading extends AuthState { @override List<Object?> get props => []; }
class Authenticated extends AuthState {
  final UserModel user;
  const Authenticated(this.user);
  @override List<Object?> get props => [user];
}
class Unauthenticated extends AuthState { @override List<Object?> get props => []; }
class AuthError extends AuthState {
  final String message;
  const AuthError(this.message);
  @override List<Object?> get props => [message];
}

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  AuthBloc() : super(AuthInitial()) {
    on<AppStarted>(_onAppStarted);
    on<LoginWithEmail>(_onLogin);
    on<RegisterWithEmail>(_onRegister);
    on<Logout>(_onLogout);
  }

  void _onAppStarted(AppStarted e, Emitter<AuthState> emit) {
    if (_auth.currentUser != null) {
      emit(Authenticated(UserModel(id: _auth.currentUser!.uid, email: _auth.currentUser!.email)));
    } else {
      emit(Unauthenticated());
    }
  }

  Future<void> _onLogin(LoginWithEmail e, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    try {
      await _auth.signInWithEmailAndPassword(email: e.email.trim(), password: e.password);
      emit(Authenticated(UserModel(id: _auth.currentUser!.uid, email: e.email)));
    } on FirebaseAuthException catch (ex) {
      emit(AuthError(_msg(ex.code)));
    }
  }

  Future<void> _onRegister(RegisterWithEmail e, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    try {
      final cred = await _auth.createUserWithEmailAndPassword(email: e.email.trim(), password: e.password);
      // Use REST API instead of cloud_firestore
      await FirestoreRest.setDocument('users/${cred.user!.uid}', {
        'id': cred.user!.uid,
        'email': e.email,
        'phone': e.phone,
        'fullName': e.name,
        'role': 'patient',
        'createdAt': DateTime.now().toIso8601String(),
      });
      emit(Authenticated(UserModel(id: cred.user!.uid, email: e.email, fullName: e.name, phone: e.phone)));
    } on FirebaseAuthException catch (ex) {
      emit(AuthError(_msg(ex.code)));
    }
  }

  Future<void> _onLogout(Logout e, Emitter<AuthState> emit) async {
    await _auth.signOut();
    emit(Unauthenticated());
  }

  String _msg(String code) {
    switch (code) {
      case 'invalid-email': return 'بريد غير صالح';
      case 'user-not-found': return 'مستخدم غير موجود';
      case 'wrong-password': return 'كلمة مرور خاطئة';
      case 'email-already-in-use': return 'البريد مستخدم';
      case 'weak-password': return 'كلمة مرور ضعيفة';
      default: return code;
    }
  }
}
