import 'package:flutter/material.dart';
import 'package:page_transition/page_transition.dart';
import 'package:quizmanage/Client/Dashboard.dart';
import 'package:quizmanage/admin/Dashboard.dart';
import 'package:quizmanage/SignUpPage.dart';
import 'package:quizmanage/Datahelp/tables.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Loginpage extends StatefulWidget {
  const Loginpage({super.key});

  @override
  State<Loginpage> createState() => _LoginpageState();
}
class _LoginpageState extends State<Loginpage> {
  final _formkey = GlobalKey<FormState>();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final _db = DatabaseHelper.instance;
  bool isPasswordVisible = false;
  String? selectedRole;
  Future<void> _handleLogin() async {
    if(_formkey.currentState!.validate()){
      String email = emailController.text;
      String password = passwordController.text;
      if(selectedRole == null){
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Please select a role")),
        );
        return;
      }
      Map<String, dynamic>? user = await _db.login(email: email, password: password);
      if(user != null && user['role'] == selectedRole){
        SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setString('email', user['email']);
        await prefs.setString('role', user['role']);
        await prefs.setInt('logged_in_user_id', user['id']);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Login successful!")),
        );
        if(user['role'] == 'admin'){
          Navigator.pushReplacement(context, PageTransition(
              child: AdminDashboard(username: user['name'],),
              type: PageTransitionType.rightToLeftWithFade,
            ),
          );
        }else{
          Navigator.pushReplacement(context, PageTransition(
              type: PageTransitionType.rightToLeftWithFade,
              child: MainPage(username: user['name'])
            ),
          );
        }
      }else{
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Invalid credentials or role mismatch")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blueAccent,
      appBar: AppBar(
        title: Text("Log In", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.lightBlueAccent,
        centerTitle: true,
      ),
      body: Form(
        key: _formkey,
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.white38, Colors.lightBlueAccent],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: Center(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(15),
                      child: SizedBox(
                        width: 100,
                        child: Image.network(
                          "https://th.bing.com/th/id/OIP.NzBgTTvAWU1WaIup3Sve6QHaH6?w=160&h=180&c=7&r=0&o=5&dpr=1.1&pid=1.7",
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    const SizedBox(height: 30),
                    DropdownButtonFormField<String>(
                      value: selectedRole,
                      decoration: InputDecoration(
                        labelText: "Select Role",
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: EdgeInsets.symmetric(horizontal: 16),
                      ),
                      items: ['admin', 'user'].map((role) => DropdownMenuItem(value: role, child: Text(role))).toList(),
                      onChanged: (String? newValue) {
                        setState(() {
                          selectedRole = newValue;
                        });
                      },
                      validator: (value) => value == null ? "Please select a role" : null,
                    ),
                    const SizedBox(height: 20),
                    TextFormField(
                      controller: emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: InputDecoration(
                        labelText: 'Email',
                        prefixIcon: Icon(Icons.email),
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      validator: (val) {
                        if (val == null || val.isEmpty) {
                          return "Please enter your email";
                        }
                        final emailValid = RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
                        if (!emailValid.hasMatch(val)) {
                          return "Enter a valid email address";
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),
                    TextFormField(
                      controller: passwordController,
                      obscureText: !isPasswordVisible,
                      decoration: InputDecoration(
                        labelText: 'Password',
                        prefixIcon: Icon(Icons.lock),
                        suffixIcon: IconButton(
                          icon: Icon(
                            isPasswordVisible ? Icons.visibility : Icons.visibility_off,
                          ),
                          onPressed: () {
                            setState(() {
                              isPasswordVisible = !isPasswordVisible;
                            });
                          },
                        ),
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      validator: (val) {
                        if (val == null || val.isEmpty) {
                          return "Please enter your password";
                        }
                        return null;
                      },
                    ),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () {
                          print("forgot");
                        },
                        child: Text('Forgot Password?',style: TextStyle(fontWeight: FontWeight.bold,color: Colors.white),),
                      ),
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _handleLogin,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blueAccent,
                          padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                        child: Text("Login", style: TextStyle(fontSize: 23, color: Colors.white),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Align(
                      alignment: Alignment.center,
                      child: TextButton(
                        onPressed: () {
                          Navigator.push(context, PageTransition(type: PageTransitionType.leftToRightWithFade,child: const SignUp()));
                        },
                        child: Text("Don't Have An Account? Sign Up", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w500, decoration: TextDecoration.underline,),),
                      ),
                    ),
                    const SizedBox(height: 10),
                    const SizedBox(height: 5),
                    Text("Or",style: TextStyle(fontSize: 20),),
                    const SizedBox(height: 5),
                    Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(5.0),
                            child: Container(
                              height: 50,
                              child: ElevatedButton.icon(onPressed: (){
                                print("Sign in from google");
                              },icon: Image.network('https://th.bing.com/th/id/OIP.DoYuESoRecI9l-vyqdrEnQHaE-?w=241&h=180&c=7&r=0&o=5&dpr=1.1&pid=1.7',height: 30.0,), label: Text('Google',style: TextStyle(fontSize: 18),),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.white,
                                ),
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(5.0),
                            child: Container(
                              height: 50,
                              child: ElevatedButton.icon(onPressed: (){
                                print("Sign in from facebook");
                              },icon: Image.network('https://th.bing.com/th/id/OIP.i0iz1VjijKJLVqdiibW7LAHaHa?w=178&h=180&c=7&r=0&o=5&dpr=1.1&pid=1.7',height: 30.0), label: Text('Facebook',style: TextStyle(fontSize: 18),),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}