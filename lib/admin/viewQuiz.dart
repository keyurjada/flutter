import 'package:flutter/material.dart';
import 'package:quizmanage/Datahelp/tables.dart';

class viewquiz extends StatefulWidget {
  final int quizId;
  final String title;
  viewquiz({required this.quizId,required this.title});

  @override
  State<viewquiz> createState() => _viewquizState();
}
class _viewquizState extends State<viewquiz> {
  List<Map<String, dynamic>> questions = [];
  Map<String, dynamic>? quiz;
  Map<int, bool> isEditing = {};

  @override
  void initState() {
    super.initState();
    _loadQuiz();
    _loadQuestions();
  }
  Future<void> _loadQuestions() async {
    final fetchedQuestions = await DatabaseHelper.instance.getQuestionsByQuizId(widget.quizId);
    setState(() {
      questions = fetchedQuestions;
      isEditing = {for (var q in questions) q['id']: false};
    });
  }
  Future<void> _updateQuestion(int questionId, String newQuestionText, String op1, String op2, String op3, String op4, String correctAns) async {
    await DatabaseHelper.instance.updateQuestion(
      questionId: questionId,
      questionText: newQuestionText,
      option1: op1,
      option2: op2,
      option3: op3,
      option4: op4,
      correctAnswer: correctAns,
    );
    _loadQuestions();
  }
  Future<void> _deleteQuestion(int questionId) async {
    bool confirmDelete = await _showDeleteDialog();
    if (confirmDelete) {
      await DatabaseHelper.instance.deleteQuestion(questionId);
      _loadQuestions();
    }
  }
  Future<bool> _showDeleteDialog() async {
    return await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Delete Question"),
        content: Text("Are you sure you want to delete this question?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text("Cancel")),
          TextButton(onPressed: () => Navigator.pop(context, true), child: Text("Delete", style: TextStyle(color: Colors.red))),
        ],
      ),
    ) ?? false;
  }
  Future<bool> _showEditConfirmationDialog() async {
    return await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Edit Question"),
        content: Text("Are you sure you want to edit this question?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text("Cancel"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text("Edit", style: TextStyle(color: Colors.blue)),
          ),
        ],
      ),
    ) ?? false;
  }
  Future<void> _refreshQuiz() async {
    await _loadQuiz();
    await _loadQuestions();
  }
  Future<void> _loadQuiz() async {
    final fetchedQuiz = await DatabaseHelper.instance.getQuizById(widget.quizId);
    setState(() {
      quiz = fetchedQuiz;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blueAccent,
      appBar: AppBar(
        title: Text(quiz?['title'] ?? 'Loading...'),
        centerTitle: true,
        backgroundColor: Colors.lightBlueAccent,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: [Colors.white38, Colors.lightBlueAccent],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: questions.isEmpty
            ? Center(child: Text("No questions available for this quiz"))
            : RefreshIndicator(
          onRefresh: _refreshQuiz,
          child: ListView.builder(
            padding: EdgeInsets.all(16),
            itemCount: questions.length,
            itemBuilder: (context, index) {
              return _buildQuestionCard(questions[index], index+1);
            },
          ),
        ),
      ),
    );
  }
  Widget _buildQuestionCard(Map<String, dynamic> question, int index) {
    int questionId = question['id'];
    bool editing  = isEditing[questionId] ?? false;
    TextEditingController questionController = TextEditingController(text: question['question_text']);
    TextEditingController option1Controller = TextEditingController(text: question['op1']);
    TextEditingController option2Controller = TextEditingController(text: question['op2']);
    TextEditingController option3Controller = TextEditingController(text: question['op3']);
    TextEditingController option4Controller = TextEditingController(text: question['op4']);
    TextEditingController correctAnswerController = TextEditingController(text: question['correct_ans']);
    return Container(
      margin: EdgeInsets.only(bottom: 16),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blueAccent, Colors.purpleAccent],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 8,
            offset: Offset(2, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          editing
              ? TextField(controller: questionController, decoration: InputDecoration(labelText: "Edit Question", filled: true, fillColor: Colors.white),)
              : Text("Q$index: ${question['question_text']}", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
          SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: editing ? _buildEditableOption(option1Controller, "Option 1") : _buildOption("A) ${question['op1']}")),
              SizedBox(width: 10),
              Expanded(child: editing ? _buildEditableOption(option2Controller, "Option 2") : _buildOption("B) ${question['op2']}")),
            ],
          ),
          SizedBox(height: 10),
          Row(
            children: [
              Expanded(child: editing ? _buildEditableOption(option3Controller, "Option 3") : _buildOption("C) ${question['op3']}")),
              SizedBox(width: 10),
              Expanded(child: editing ? _buildEditableOption(option4Controller, "Option 4") : _buildOption("D) ${question['op4']}")),
            ],
          ),
          SizedBox(height: 16),
          editing
              ? _buildEditableOption(correctAnswerController, "Correct Answer")
              : Text("✅ Correct Answer: ${question['correct_ans']}", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.yellowAccent)),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              editing
                  ? IconButton(
                icon: Icon(Icons.save, color: Colors.white),
                onPressed: () {
                  _updateQuestion(
                    questionId,
                    questionController.text,
                    option1Controller.text,
                    option2Controller.text,
                    option3Controller.text,
                    option4Controller.text,
                    correctAnswerController.text,
                  );
                  setState(() => isEditing[questionId] = false);
                },
              ) : IconButton(
                  icon: Icon(Icons.edit, color: Colors.white),
                  onPressed: () async {
                    bool confirmEdit = await _showEditConfirmationDialog();
                    if (confirmEdit) {
                      setState(() => isEditing[questionId] = true);
                    }
                  },
              ),
              IconButton(
                icon: Icon(Icons.delete, color: Colors.redAccent),
                onPressed: () => _deleteQuestion(questionId),
              ),
            ],
          ),
        ],
      ),
    );
  }
  Widget _buildOption(String text) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Container(
        padding: EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.8),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(text, style: TextStyle(fontSize: 16),textAlign: TextAlign.center,),
      ),
    );
  }
  Widget _buildEditableOption(TextEditingController controller, String hint) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(labelText: hint, filled: true, fillColor: Colors.white),
    );
  }
}