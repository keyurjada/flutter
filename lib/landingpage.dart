import 'package:flutter/material.dart';
import 'package:page_transition/page_transition.dart';
import 'package:quizmanage/SignUpPage.dart';
import 'package:quizmanage/loginPage.dart';

class LandingPage extends StatelessWidget {
  const LandingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blueAccent,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: [Colors.white38,Colors.lightBlueAccent],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Center(
                child: Image(
                  image: NetworkImage("https://th.bing.com/th/id/OIP.jlbfUEQz_eE66juMgR7kegHaFd?w=233&h=180&c=7&r=0&o=5&dpr=1.1&pid=1.7"),width: MediaQuery.of(context).size.width * 0.7,fit: BoxFit.contain,
                ),
              ),
              SizedBox(height: 20,),
              const Text(
                "Successful people ask better questions, as a result, they get better answers.",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 60),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildGradientButton(
                    context,
                    label: "Log In",
                    onPressed: () => Navigator.pushReplacement(context,PageTransition(child: const Loginpage(), type: PageTransitionType.fade))
                  ),
                  const SizedBox(width: 30),
                  _buildGradientButton(
                    context,
                    label: "Sign Up",
                    onPressed: () => Navigator.pushReplacement(context,PageTransition(child: const SignUp(), type: PageTransitionType.fade))
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
  Widget _buildGradientButton(BuildContext context, {required String label, required VoidCallback onPressed}) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Colors.blue, Colors.purple],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
        ),
        child: Text(
          label,
          style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}