import 'package:flutter/material.dart';
import 'package:page_transition/page_transition.dart';
import 'package:quizmanage/Client/downLoadQB.dart';
import 'package:quizmanage/Client/historyPage.dart';
import 'package:quizmanage/landingpage.dart';
import 'package:quizmanage/loginPage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart';
import 'package:quizmanage/Datahelp/tables.dart';

class Profile extends StatefulWidget {
  final String username;
  final int userId;
  final Function(String?) onProfileImageUpdated;
  Profile({required this.username,required this.userId,required this.onProfileImageUpdated});
  @override
  State<Profile> createState() => _ProfileState();
}
class _ProfileState extends State<Profile> {
  File? _image;
  void initState() {
    super.initState();
    _loadProfileImage();
  }
  Future<void> _pickImage() async {
    final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      File imageFile = File(pickedFile.path);
      File savedImage = await _saveImage(imageFile);
      setState(() {
        _image = savedImage;
      });
      await DatabaseHelper.instance.updateUserProfileImage(widget.username, savedImage.path);
      widget.onProfileImageUpdated(savedImage.path);
    }
  }
  Future<File> _saveImage(File image) async {
    final directory = await getApplicationDocumentsDirectory();
    final path = directory.path;
    final fileName = basename(image.path);
    final savedImage = await image.copy('$path/$fileName');
    return savedImage;
  }
  Future<void> _loadProfileImage() async {
    String? imagePath = await DatabaseHelper.instance.getUserProfileImage(widget.username);
    if (imagePath != null && File(imagePath).existsSync()) {
      setState(() => _image = File(imagePath));
      widget.onProfileImageUpdated(imagePath);
    }
  }
  Future<void> _deleteImage() async {
    setState(() => _image = null);
    await DatabaseHelper.instance.deleteUserProfileImage(widget.username);
    if (widget.onProfileImageUpdated != null) {
      widget.onProfileImageUpdated!(null);
    }
  }
  Future<void> logout(BuildContext context) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const Loginpage()),
          (route) => false,
    );
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: Colors.blueAccent,
        appBar: AppBar(
          title: Text("Profile"),
          backgroundColor: Colors.lightBlueAccent,
          centerTitle: true,
        ),
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.white38, Colors.lightBlueAccent],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Column(
                  children: [
                    Stack(
                      children: [
                        CircleAvatar(
                          radius: 50,
                          backgroundColor: Colors.grey[400],
                          backgroundImage: _image != null && _image!.existsSync() ? FileImage(_image!) : AssetImage("assets/default_profile.png") as ImageProvider,
                          child: Icon(Icons.person, size: 50, color: Colors.white),
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: GestureDetector(
                            onTap: _pickImage,
                            child: CircleAvatar(
                              radius: 15,
                              backgroundColor: Colors.black,
                              child: Icon(Icons.file_upload_outlined, size: 15, color: Colors.white),
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (_image != null && _image!.existsSync()) ElevatedButton(onPressed: _deleteImage, child: Text("Remove Image")),
                  ],
                ),
                SizedBox(height: 15),
                Text(widget.username, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),),
                Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.grey,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text("User", style: TextStyle(color: Colors.white, fontSize: 12,fontWeight: FontWeight.bold),)
                ),
                SizedBox(height: 20),
                _buildMenuItem(Icons.home, "Home",()=>Navigator.pop(context)),
                _buildMenuItem(Icons.history, "History",()=>Navigator.push(context, PageTransition(child: History(userId: widget.userId,), type: PageTransitionType.fade))),
                _buildMenuItem(Icons.book, "Question Bank",()=>Navigator.push(context, PageTransition(child: const Down(), type: PageTransitionType.fade))),
                Spacer(),
                _buildButton(Icons.logout,"Logout", Colors.grey[300]!, ()=>logout(context)),
                SizedBox(height: 10),
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(context, PageTransition(child: LandingPage(), type: PageTransitionType.fade));
                  },
                  icon: Icon(Icons.delete),
                  label: Text("Delete account",style: TextStyle(fontWeight: FontWeight.bold,color: Colors.white),),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    minimumSize: Size(double.infinity, 50),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
  }
  Widget _buildMenuItem(IconData icon, String title,VoidCallback onTap) {
    return Card(
      margin: EdgeInsets.symmetric(vertical: 8),
      child: ListTile(
        leading: Icon(icon, color: Colors.grey[700]),
        title: Text(title),
        trailing: Icon(Icons.arrow_forward_ios, size: 16),
        onTap: onTap,
      ),
    );
  }
  Widget _buildButton(IconData icon, String text, Color color,VoidCallback onPressed) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        minimumSize: Size(double.infinity, 50),
        elevation: 0,
      ),
      onPressed: onPressed,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: Colors.black),
          SizedBox(width: 10),
          Text(text, style: TextStyle(color: Colors.black, fontSize: 16),),
        ],
      ),
    );
  }
}