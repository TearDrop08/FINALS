part of 'login_bloc.dart';

abstract class LoginState extends Equatable {
  @override
  List<Object?> get props => [];
}

class LoginInitial extends LoginState {}
class LoginLoading extends LoginState {}
class LoginSuccess extends LoginState {
  final User user;
  LoginSuccess({required this.user});
  @override List<Object?> get props => [user];
}
class LoginFailure extends LoginState {
  final String message;
  LoginFailure({required this.message});
  @override List<Object?> get props => [message];
}