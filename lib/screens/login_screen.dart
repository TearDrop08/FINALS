import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../blocs/login_bloc.dart';
import '../repositories/auth_repository.dart';
import 'dashboard_screen.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocProvider<LoginBloc>(
      create: (_) => LoginBloc(authRepository: AuthRepository()),
      child: BlocListener<LoginBloc, LoginState>(
        listener: (context, state) {
          if (state is LoginSuccess) {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (_) => const DashboardScreen()),
            );
          }
          if (state is LoginFailure) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message)),
            );
          }
        },
        child: const _LoginView(),
      ),
    );
  }
}

class _LoginView extends StatefulWidget {
  const _LoginView({Key? key}) : super(key: key);

  @override
  State<_LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<_LoginView> {
  bool rememberMe = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Container(color: const Color(0xFF0B0C69)),

          Opacity(
            opacity: 0.4,
            child: Container(
              decoration: const BoxDecoration(
                image: DecorationImage(
                  image: AssetImage("assets/images/bagobo_pattern.png"),
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),

          Center(
            child: SingleChildScrollView(
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: 660,
                  minHeight: 750,  // ↑ added minHeight
                ),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 32,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.95),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Image.asset(
                        "assets/images/addu_seal.png",
                        height: 200,
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        "UNIVENTS",
                        style: TextStyle(
                          fontSize: 30,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 3,
                          color: Color(0xFF0B0C69),
                        ),
                      ),
                      const SizedBox(height: 60),

                      BlocBuilder<LoginBloc, LoginState>(
                        builder: (context, state) {
                          if (state is LoginLoading) {
                            return const CircularProgressIndicator();
                          }
                          return ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              minimumSize: const Size.fromHeight(50),
                              side: const BorderSide(color: Colors.grey),
                              padding:
                                  const EdgeInsets.symmetric(vertical: 12),
                            ),
                            onPressed: () {
                              context
                                  .read<LoginBloc>()
                                  .add(LoginWithGooglePressed());
                            },
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Image.network(
                                  'https://www.gstatic.com/marketing-cms/assets/images/d5/dc/cfe9ce8b4425b410b49b7f2dd3f3/g.webp=s48-fcrop64=1,00000000ffffffff-rw',
                                  height: 40,
                                ),
                                const SizedBox(width: 20),
                                const Text(
                                  "Login with Google",
                                  style: TextStyle(color: Colors.black87),
                                ),
                              ],
                            ),
                          );
                        },
                      ),

                      const SizedBox(height: 35),

                      // Remember Me
                      Row(
                        children: [
                          Switch(
                            value: rememberMe,
                            onChanged: (val) {
                              setState(() => rememberMe = val);
                            },
                          ),
                          const Text("Remember Me"),
                        ],
                      ),

                      const SizedBox(height: 30),
                      const Text.rich(
                        TextSpan(
                          text: "",
                          children: [
                            TextSpan(
                              text: "ADMIN ONLY",
                              style: TextStyle(color: Colors.blue),
                            ),
                          ],
                        ),
                      ),

                      // extra space at bottom
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}