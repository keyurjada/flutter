import 'package:flutter/material.dart';
import 'package:page_transition/page_transition.dart';
import 'package:quizmanage/Client/scorePage.dart';
import 'package:quizmanage/Datahelp/tables.dart';

class History extends StatefulWidget {
  final int userId;
  const History({super.key,required this.userId});
  @override
  State<History> createState() => _HistoryState();
}
class _HistoryState extends State<History> {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  List<Map<String, dynamic>> _quizHistory = [];

  @override
  void initState() {
    super.initState();
    _loadQuizHistory();
  }
  void _confirmDeleteHistory() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Delete History"),
        content: Text("Are you sure you want to delete your quiz history?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Cancel"),
          ),
          TextButton(
            onPressed: () {
              _deleteUserHistory();
              Navigator.pop(context);
            },
            child: Text("Delete", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
  void _deleteUserHistory() async {
    await _dbHelper.deleteUserQuizHistory(widget.userId);
    setState(() {
      _quizHistory=[];
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Quiz history deleted successfully!")),
    );
  }
  Future<void> _loadQuizHistory() async {
    int retries = 3;
    int userId = 0;
    while (retries > 0 && userId == 0) {
      await Future.delayed(Duration(milliseconds: 500));
      userId = await _dbHelper.getLoggedInUserId();
      retries--;
    }
    if (userId == 0) {
      return;
    }
    List<Map<String, dynamic>> history = await _dbHelper.fetchUserQuizHistory(userId);
    setState(() {
      _quizHistory = history;
    });
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: Colors.blueAccent,
        appBar: AppBar(
          title: Text("History"),
          centerTitle: true,
          backgroundColor: Colors.lightBlueAccent,
          actions: [
            IconButton(
              icon: Icon(Icons.delete, color: Colors.white),
              onPressed: _confirmDeleteHistory,
            ),
          ],
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
            child: _quizHistory.isEmpty ? Center(child: Text("No quiz history available", style: TextStyle(color: Colors.white)))
            : ListView.builder(
              itemCount: _quizHistory.length,
              itemBuilder: (context, index) {
                final quiz = _quizHistory[index];
                return _buildQuizCard(quiz,()=>Navigator.push(context,PageTransition(child: Score(quizId: quiz["quiz_id"],correctAnswers: quiz["progress"], totalQuestions: quiz["total"]), type: PageTransitionType.fade)));
              },
            ),
          ),
        ),
      );
  }
  Widget _buildQuizCard(Map<String, dynamic> quiz,VoidCallback onPressed) {
    int totalQuestions = quiz["total"] ?? 1;
    int completed = quiz["progress"] ?? 0;
    double progress = (totalQuestions > 0) ? (completed / totalQuestions) : 0.0;
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      margin: EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: Colors.yellowAccent,
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(quiz["title"] ?? "Unknown quiz", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),),
                  Text("$totalQuestions Questions", style: TextStyle(color: Colors.grey[700])),
                  SizedBox(height: 8),
                  LinearProgressIndicator(
                    value: progress.clamp(0.0, 1.0),
                    backgroundColor: Colors.grey[300],
                    color: Colors.red,
                    minHeight: 6,
                  ),
                  SizedBox(height: 4),
                  Text("Progress: $completed/$totalQuestions", style: TextStyle(fontSize: 14),),
                  SizedBox(height: 4),
                  Text("Date: ${quiz["date"] ?? "Unknown"}", style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                ],
              ),
            ),
            SizedBox(width: 8),
            IconButton(
              icon: Icon(Icons.visibility, color: Colors.blue),
              onPressed: onPressed
            ),
          ],
        ),
      ),
    );
  }
}