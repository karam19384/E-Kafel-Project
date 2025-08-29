// lib/src/blocs/auth/auth_bloc.dart

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:e_kafel/src/services/auth_service.dart';

part 'auth_event.dart';
part 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthService _authService;

  AuthBloc(this._authService) : super(AuthInitial()) {
    on<CheckAuthStatus>((event, emit) {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        emit(AuthAuthenticated());
      } else {
        emit(AuthUnauthenticated());
      }
    });

    on<LoginButtonPressed>((event, emit) async {
      emit(AuthLoading());
      final error = await _authService.signIn(
        email: event.email,
        password: event.password,
      );
      if (error == null) {
        emit(AuthAuthenticated());
      } else {
        emit(AuthErrorState(message: error));
      }
    });

    on<LogoutButtonPressed>((event, emit) async {
      await _authService.signOut();
      emit(AuthUnauthenticated());
    });

    on<SignUpButtonPressed>((event, emit) async {
      emit(AuthLoading());
      final error = await _authService.signUp(
        name: event.name,
        email: event.email,
        password: event.password,
        role: event.userRole,
        institutionId: event.institutionId,
      );
      if (error == null) {
        emit(AuthAuthenticated());
      } else {
        emit(AuthErrorState(message: error));
      }
    });

    on<SignInWithGoogleButtonPressed>((event, emit) async {
      emit(AuthLoading());
      final error = await _authService.signInWithGoogle();
      if (error == null) {
        emit(AuthAuthenticated());
      } else {
        emit(AuthErrorState(message: error));
      }
    });
  }
}
