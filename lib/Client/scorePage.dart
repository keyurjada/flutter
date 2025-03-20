import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:quizmanage/Datahelp/tables.dart';

class Score extends StatefulWidget {
  final int quizId;
  final int correctAnswers;
  final int totalQuestions;
  const Score({
    Key? key,
    required this.quizId,
    required this.correctAnswers,
    required this.totalQuestions,
  }) : super(key: key);

  @override
  State<Score> createState() => _ScoreState();
}
class _ScoreState extends State<Score> {
  String username = "Loading...";

  @override
  void initState() {
    super.initState();
    _fetchUsername();
  }
  Future<void> _fetchUsername() async {
    int userId = await DatabaseHelper.instance.getLoggedInUserId();
    if (userId != 0) {
      List<Map<String, dynamic>> userData = await DatabaseHelper.instance.getUserById(userId);
      if (userData.isNotEmpty) {
        setState(() {
          username = userData.first['name'];
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blueAccent,
      appBar: AppBar(
        title: Center(child: Text("Your Score",style: TextStyle(fontWeight: FontWeight.bold),)),
        backgroundColor: Colors.lightBlueAccent,
        centerTitle: true,
      ),
      body: Center(
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.white38, Colors.lightBlueAccent],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text("Your Score : ${widget.correctAnswers}/${widget.totalQuestions}", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),),
              const SizedBox(height: 20),
              Text(username, style: TextStyle(fontSize: 16)),
              const SizedBox(height: 20),
              Text("Congratulations! You have completed this quiz.", textAlign: TextAlign.center, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),),
              const SizedBox(height: 10),
              Text("Let's keep testing more knowledge by playing more quizzes.", textAlign: TextAlign.center, style: TextStyle(fontSize: 14),),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context,ModalRoute.withName('/'));
                },style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.yellowAccent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)
                  ),
                ),child: Text("Explore more",style: TextStyle(fontSize: 20,fontWeight: FontWeight.bold),),
              ),
              const SizedBox(height: 30),
              const Text("Rate this Quiz:", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),),
              const SizedBox(height: 10),
              RatingBar.builder(
                initialRating: 0,
                minRating: 1,
                direction: Axis.horizontal,
                allowHalfRating: true,
                itemCount: 5,
                itemPadding: const EdgeInsets.symmetric(horizontal: 4.0),
                itemBuilder: (context, _) => const Icon(
                  Icons.star,
                  color: Colors.amber,
                ),
                onRatingUpdate: (rating) async{
                  int userId = await DatabaseHelper.instance.getLoggedInUserId();
                  await DatabaseHelper.instance.insertReview(widget.quizId, rating);
                  ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text("Review submitted successfully!"))
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}