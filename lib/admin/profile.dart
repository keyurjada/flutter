import 'package:flutter/material.dart';
import 'package:page_transition/page_transition.dart';
import 'package:quizmanage/admin/Histort.dart';
import 'package:quizmanage/loginPage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:quizmanage/admin/NotificationPage.dart';
import 'package:quizmanage/admin/uploadQB.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart';
import 'package:quizmanage/Datahelp/tables.dart';

class ProPage extends StatefulWidget {
  final String username;
  final Function(String?) onProfileImageUpdated;
  ProPage({required this.username,required this.onProfileImageUpdated});

  @override
  State<ProPage> createState() => _ProPageState();
}
class _ProPageState extends State<ProPage> {
  File? _image;
  @override
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
      await DatabaseHelper.instance.updateAdminProfileImage(widget.username, savedImage.path);
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
    String? imagePath = await DatabaseHelper.instance.getAdminProfileImage(widget.username);
    if (imagePath != null && File(imagePath).existsSync()) {
      setState(() => _image = File(imagePath));
      widget.onProfileImageUpdated(imagePath);
    }
  }
  Future<void> _deleteImage() async {
    setState(() => _image = null);
    await DatabaseHelper.instance.deleteAdminProfileImage(widget.username);
    widget.onProfileImageUpdated(null);
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
        title: Text("Your Profile"),
        centerTitle: true,
        backgroundColor: Colors.lightBlueAccent,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: [Colors.white38,Colors.lightBlueAccent],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Center(
                child: Column(
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
                    SizedBox(height: 10),
                    Text(widget.username, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),),
                    Container(
                      margin: EdgeInsets.only(top: 5),
                      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: Colors.black,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text("Admin", style: TextStyle(color: Colors.white, fontSize: 12),),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 30),
              Expanded(
                child: ListView(
                  children: [
                    _buildListItem(Icons.home, "Home",()=>Navigator.pop(context)),
                    SizedBox(height: 15),
                    _buildListItem(Icons.history, "History",()=>Navigator.push(context, PageTransition(child: HisPage(username: widget.username,), type: PageTransitionType.fade))),
                    SizedBox(height: 15),
                    _buildListItem(Icons.upload_file, "Upload Question Bank",()=>Navigator.push(context, PageTransition(child: Uploadqb(username: widget.username,), type: PageTransitionType.fade))),
                    SizedBox(height: 15),
                    _buildListItem(Icons.notification_add, "Notifications",()=>Navigator.push(context, PageTransition(child: const Notificationpage(), type: PageTransitionType.fade))),
                  ],
                ),
              ),
              SizedBox(height: 10),
              _buildButton(Icons.logout, "Log out", Colors.grey[300]!,()=>logout(context)),
              SizedBox(height: 10),
              _buildButton(Icons.delete, "Delete account", Colors.red,()=>logout(context)),
            ],
          ),
        ),
      ),
    );
  }
  Widget _buildListItem(IconData icon, String title,VoidCallback onTap) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: Colors.grey[300],
        child: Icon(icon, color: Colors.black),
      ),
      title: Text(title, style: TextStyle(fontSize: 20)),
      trailing: Icon(Icons.arrow_forward_ios, size: 20),
      onTap: onTap
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