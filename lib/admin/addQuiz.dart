import 'package:flutter/material.dart';
import 'package:quizmanage/admin/Dashboard.dart';
import 'package:page_transition/page_transition.dart';
import 'package:quizmanage/Datahelp/tables.dart';

class Addquiz extends StatefulWidget {
  final String username;
  const Addquiz({super.key, required this.username});

  @override
  State<Addquiz> createState() => _AddquizState();
}

class _AddquizState extends State<Addquiz> {
  final TextEditingController titleController = TextEditingController();
  final TextEditingController categoryController = TextEditingController();
  final TextEditingController questionController = TextEditingController();
  final TextEditingController op1Controller = TextEditingController();
  final TextEditingController op2Controller = TextEditingController();
  final TextEditingController op3Controller = TextEditingController();
  final TextEditingController op4Controller = TextEditingController();
  final TextEditingController correctAnsController = TextEditingController();
  Future<void> addQuizToDB() async {
    print("addQuizToDB() FUNCTION CALLED!");
    final dbHelper = DatabaseHelper.instance;
    int insertedId = await dbHelper.addquiz(
      title: titleController.text.trim(),
      category: categoryController.text.trim(),
      author: widget.username,
      question: questionController.text.trim(),
      op1: op1Controller.text.trim(),
      op2: op2Controller.text.trim(),
      op3: op3Controller.text.trim(),
      op4: op4Controller.text.trim(),
      correctAns: correctAnsController.text.trim(),
    );
    if(insertedId > 0){
      await dbHelper.insertAdminQuizHistory(
        quizId: insertedId,
        title: titleController.text.trim(),
        category: categoryController.text.trim(),
        adminName: widget.username,
      );
      Navigator.pushReplacement(context, PageTransition(
          child: AdminDashboard(username: widget.username),
          type: PageTransitionType.fade
        ),
      );
    } else {
      print("Failed to add quiz.");
    }
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blueAccent,
      appBar: AppBar(
        title: Text("Add Quiz"),
        backgroundColor: Colors.blueAccent,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.white38, Colors.lightBlueAccent],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                buildTextField("Quiz Title",controller: titleController),
                SizedBox(height: 10),
                buildTextField("Quiz Category",controller: categoryController),
                SizedBox(height: 10),
                Center(
                  child: SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: () {
                        addQuizToDB();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                      ),
                      child: Text("Make It", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black, fontSize: 20),),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
  Widget buildTextField(String hint,{TextEditingController? controller}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5.0),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.8),
              spreadRadius: 2,
              blurRadius: 5,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: TextField(
          controller: controller,
          decoration: InputDecoration(
            hintText: hint,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            filled: true,
            fillColor: Colors.white,
            prefixIcon: Icon(Icons.edit, color: Colors.blueAccent),
            contentPadding: EdgeInsets.symmetric(vertical: 15, horizontal: 20),
          ),
        ),
      ),
    );
  }
}