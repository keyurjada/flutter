import 'package:flutter/material.dart';
import 'package:quizmanage/Datahelp/tables.dart';
import 'package:quizmanage/loginPage.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class SignUp extends StatefulWidget {
  const SignUp({super.key});

  @override
  State<SignUp> createState() => _SignUpState();
}
class _SignUpState extends State<SignUp> {
  final _formkey = GlobalKey<FormState>();
  bool isDropdownOpened = false;
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final _db = DatabaseHelper.instance;
  bool isPasswordVisible = false;
  String? _role;

  @override
  void initState() {
    super.initState();
    // _checkUserSession();
  }
  String hashPassword(String password) {
    return sha256.convert(utf8.encode(password)).toString();
  }
  Future<void> _checkUserSession() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? role = prefs.getString('role');
    Future.delayed(Duration.zero, () {
      if(role != null){
        if(role == 'admin'){
          Navigator.push(context, MaterialPageRoute(builder: (context) => Loginpage()),);
        }else{
          Navigator.push(context, MaterialPageRoute(builder: (context) => Loginpage()),);
        }
      }
    });
  }
  Future<void> _registerUser() async {
    if(_formkey.currentState!.validate()){
      try{
        int id = await _db.signup(
          role: _role!,
          name: _nameController.text,
          email: _emailController.text,
          password: _passwordController.text,
          phone: phoneController.text,
        );
        if(id > 0){
          final db = await DatabaseHelper.instance.database;
          final users = await db.query('users');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Signup successful!")),
          );
          if(_role == 'admin'){
            Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => Loginpage()),);
          }else{
            Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => Loginpage()),);
          }
        }else{
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Failed to insert data")),
          );
        }
      }catch (e){
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: ${e.toString()}")),
        );
      }
    }else{
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Enter valid credentials.")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blueAccent,
      appBar: AppBar(
        title: Text("Sign Up", style: TextStyle(fontWeight: FontWeight.bold)),
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
                padding: const EdgeInsets.all(15),
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
                      value: _role,
                      decoration: InputDecoration(
                        labelText: 'Select Role',
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: EdgeInsets.symmetric(horizontal: 16),
                      ),
                      items: ['admin', 'user'].map<DropdownMenuItem<String>>((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value),
                        );
                      }).toList(),
                      onChanged: (String? newValue) {
                        setState(() {
                          _role = newValue;
                        });
                      },
                      validator: (value) => value == null ? 'Select a role' : null,
                    ),
                    const SizedBox(height: 20),
                    TextFormField(
                      controller: _nameController,
                      decoration: InputDecoration(
                        labelText: 'Name',
                        prefixIcon: Icon(Icons.drive_file_rename_outline),
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      validator: (val) => val!.isEmpty ? "Please enter your Name" : null,
                    ),
                    const SizedBox(height: 20),
                    TextFormField(
                      controller: phoneController,
                      keyboardType: TextInputType.phone,
                      decoration: InputDecoration(
                        labelText: 'Phone Number',
                        prefixIcon: Icon(Icons.phone),
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      validator: (val) {
                        if (val == null || val.isEmpty) {
                          return "Please enter your phone number";
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),
                    TextFormField(
                      controller: _emailController,
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
                        if (val!.isEmpty) return "Please enter your Email";
                        if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(val)) {
                          return "Please enter a valid email";
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),
                    TextFormField(
                      controller: _passwordController,
                      obscureText: !isPasswordVisible,
                      decoration: InputDecoration(
                        labelText: 'Set Password',
                        prefixIcon: Icon(Icons.lock),
                        suffixIcon: IconButton(
                          icon: Icon(isPasswordVisible ? Icons.visibility : Icons.visibility_off),
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
                        if (val!.isEmpty) return "Please enter your Password";
                        if (val.length < 8) return "Password must be at least 8 characters";
                        if (!RegExp(r'(?=.*[0-9])').hasMatch(val)) return "Must contain at least one digit";
                        if (!RegExp(r'(?=.*[A-Z])').hasMatch(val)) return "Must contain at least one capital letter";
                        return null;
                      },
                    ),
                    const SizedBox(height: 40),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: (){
                          _registerUser();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blueAccent,
                          padding: EdgeInsets.symmetric(horizontal: 40, vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        child: Text("Register", style: TextStyle(fontSize: 23, color: Colors.white)),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Align(
                      alignment: Alignment.center,
                      child: TextButton(
                        onPressed: () {
                          Navigator.pop(context);
                        },
                        child: Text(
                          "Already Have An Account? Log In",
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w500,
                              decoration: TextDecoration.underline
                          ),
                        ),
                      ),
                    ),
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
class UserListPage extends StatefulWidget {
  @override
  _UserListPageState createState() => _UserListPageState();
}
class _UserListPageState extends State<UserListPage> {
  List<Map<String, dynamic>> users = [];

  @override
  void initState() {
    super.initState();
    _fetchUsers();
  }
  Future<void> _fetchUsers() async {
    final db = await DatabaseHelper.instance.database;
    final List<Map<String, dynamic>> userList = await db.query('users');
    setState(() {
      users = userList;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Registered Users")),
      body: ListView.builder(
        itemCount: users.length,
        itemBuilder: (context, index) {
          return ListTile(
            title: Text(users[index]['name']),
            subtitle: Text(users[index]['email']),
          );
        },
      ),
    );
  }
}