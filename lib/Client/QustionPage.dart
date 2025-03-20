import 'package:flutter/material.dart';
import 'package:quizmanage/Datahelp/tables.dart';
import 'dart:async';

class QuesScreen extends StatefulWidget {
  final int quizId;
  QuesScreen({required this.quizId});
  @override
  _QuizScreenState createState() => _QuizScreenState();
}
class _QuizScreenState extends State<QuesScreen> {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  List<Map<String, dynamic>> _questions = [];
  int _currentQuestionIndex = 0;
  int _score = 0;
  int _timeLeft = 10;
  int selectedOption = -1;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _loadQuestions();
  }
  Future<void> _loadQuestions() async {
    List<Map<String, dynamic>> questions = await _dbHelper.getQuestionsByQuizId(widget.quizId);
    setState(() {
      _questions = questions;
    });
    _startTimer();
  }
  void _startTimer() {
    _timer?.cancel();
    setState(() {
      _timeLeft = 10;
    });
    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      if (_timeLeft > 0) {
        setState(() {
          _timeLeft--;
        });
      } else {
        _moveToNextQuestion();
      }
    });
  }
  void _answerQuestion(int selectedIndex) {
    _timer?.cancel();
    setState(() {
      selectedOption = selectedIndex;
    });
    List<String> options = _getOptions();
    if (selectedIndex >= 0 && selectedIndex < options.length) {
      String selectedAnswer = options[selectedIndex];
      String correctAnswer = _questions[_currentQuestionIndex]['correct_ans'];
      if (selectedAnswer == correctAnswer) {
        _score++;
      }
    }
    Future.delayed(Duration(milliseconds: 500), () {
      _moveToNextQuestion();
    });
  }
  void _moveToNextQuestion() {
    if (_currentQuestionIndex < _questions.length - 1) {
      setState(() {
        _currentQuestionIndex++;
        selectedOption = -1;
      });
      _startTimer();
    } else {
      _timer?.cancel();
      Navigator.pop(context, _score);
    }
  }
  List<String> _getOptions() {
    return [
      _questions[_currentQuestionIndex]['op1'],
      _questions[_currentQuestionIndex]['op2'],
      _questions[_currentQuestionIndex]['op3'],
      _questions[_currentQuestionIndex]['op4'],
    ];
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
  Widget _buildOption(int index) {
    List<String> options = _getOptions();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: ElevatedButton(
        onPressed: ()=> _answerQuestion(index),
        style: ElevatedButton.styleFrom(
          backgroundColor: selectedOption == index ? Colors.blue : Colors.grey[600],
          foregroundColor: Colors.white,
          padding: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        child: Align(
          alignment: Alignment.centerLeft,
          child: Text(
            options[index],
            style: const TextStyle(fontSize: 16),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_questions.isEmpty) {
      return Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    Map<String, dynamic> currentQuestion = _questions[_currentQuestionIndex];
    return Scaffold(
      backgroundColor: Colors.blueAccent,
      appBar: AppBar(
        title: Text("Question ${_currentQuestionIndex + 1}/${_questions.length}"),
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
              Container(
                padding: const EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(currentQuestion['question_text'], textAlign: TextAlign.center, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),),
              ),
              const SizedBox(height: 20),
              LinearProgressIndicator(
                value: _timeLeft / 10,
                minHeight: 8,
                backgroundColor: Colors.grey[300],
                valueColor: AlwaysStoppedAnimation<Color>(_timeLeft > 3 ? Colors.green : Colors.red,),
              ),
              const SizedBox(height: 20),
              Text("Time left: $_timeLeft sec", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: _timeLeft > 3 ? Colors.black : Colors.red,),),
              const SizedBox(height: 20),
              for (int i = 0; i < 4; i++) _buildOption(i),
            ],
          ),
        ),
      ),
    );
  }
}