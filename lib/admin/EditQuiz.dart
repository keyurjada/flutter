import 'package:flutter/material.dart';
import 'package:page_transition/page_transition.dart';
import 'package:quizmanage/admin/extraQues.dart';
class Editquiz extends StatelessWidget {
  final int quizId;
  Editquiz({required this.quizId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blueAccent,
      appBar: AppBar(
        title: Text("Edit Quiz"),
        centerTitle: true,
        backgroundColor: Colors.lightBlueAccent,
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
            colors: [Colors.white38,Colors.lightBlueAccent],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                      colors: [Colors.blue,Colors.purpleAccent]
                  ),
                  borderRadius: BorderRadius.circular(8)
                ),
                child: SizedBox(
                  width: 300,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.push(context, PageTransition(
                        type: PageTransitionType.leftToRightWithFade,
                        child: Extraques(quizId: quizId),
                        duration: Duration(milliseconds: 500),
                      ),);
                    },style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      ),
                      child: Text("Add Question",style: TextStyle(fontSize: 16,color: Colors.white,fontWeight: FontWeight.bold),),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}