import 'package:flutter/material.dart';
import 'package:quizmanage/Datahelp/tables.dart';

class Extraques extends StatefulWidget {
  final int quizId;
  Extraques({required this.quizId});

  @override
  State<Extraques> createState() => _ExtraquesState();
}
class _ExtraquesState extends State<Extraques> {
  TextEditingController questionController = TextEditingController();
  TextEditingController op1Controller = TextEditingController();
  TextEditingController op2Controller = TextEditingController();
  TextEditingController op3Controller = TextEditingController();
  TextEditingController op4Controller = TextEditingController();
  TextEditingController correctAnsController = TextEditingController();
  Future<void> _addQues() async{
    if(questionController.text.isEmpty || op1Controller.text.isEmpty || op2Controller.text.isEmpty || op3Controller.text.isEmpty || op4Controller.text.isEmpty || correctAnsController.text.isEmpty){
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Please fill all fields")),
      );
      return;
    }
    int res = await DatabaseHelper.instance.addQuestion(
        quizId: widget.quizId,
        questionText: questionController.text,
        option1: op1Controller.text,
        option2: op2Controller.text,
        option3: op3Controller.text,
        option4: op4Controller.text,
        correctAnswer: correctAnsController.text
    );
    if (res == -1) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: Quiz does not exist!")),
      );
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Question added successfully!")),
    );
    Navigator.pop(context);
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.lightBlueAccent,
      appBar: AppBar(
        title: Text("Add Question"),
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
                Text("Your Question :", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
                buildTextField("Question ?",controller: questionController),
                SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(child: buildTextField("A)",controller: op1Controller)),
                    SizedBox(width: 10),
                    Expanded(child: buildTextField("B)",controller: op2Controller)),
                  ],
                ),
                Row(
                  children: [
                    Expanded(child: buildTextField("C)",controller: op3Controller)),
                    SizedBox(width: 10),
                    Expanded(child: buildTextField("D)",controller: op4Controller)),
                  ],
                ),
                SizedBox(height: 10),
                Text("Correct Answer :", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
                buildTextField("",controller: correctAnsController),
                SizedBox(height: 30),
                Center(
                  child: SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _addQues,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                      ),
                      child: Text("Add there", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black, fontSize: 20)),
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
              color: Colors.grey.withOpacity(0.3),
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