import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../repositories/auth_repository.dart';

part 'login_event.dart';
part 'login_state.dart';

class LoginBloc extends Bloc<LoginEvent, LoginState> {
  final AuthRepository authRepository;

  LoginBloc({required this.authRepository}) : super(LoginInitial()) {
    on<LoginWithGooglePressed>((event, emit) async {
      emit(LoginLoading());
      try {
        final user = await authRepository.signInWithGoogle();

        if (user == null || !user.email!.endsWith('@addu.edu.ph')) {
          await FirebaseAuth.instance.signOut();
          emit(LoginFailure(message: 'Please sign in with your ADDU email.'));
          return;
        }

        emit(LoginSuccess(user: user));
      } catch (e) {
        emit(LoginFailure(message: e.toString()));
      }
    });
  }
}