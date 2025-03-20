import 'package:flutter/material.dart';
import 'package:quizmanage/Datahelp/tables.dart';

class HisPage extends StatefulWidget {
  final String username;
  const HisPage({super.key, required this.username});

  @override
  State<HisPage> createState() => _HisPageState();
}
class _HisPageState extends State<HisPage> {
  List<Map<String, dynamic>> adminQuizHistory = [];
  List<Map<String, dynamic>> quizHistory = [];
  Future<void> loadQuizHistory() async {
    final data = await DatabaseHelper.instance.fetchAdminQuizHistory(widget.username);
    setState(() {
      quizHistory = data;
    });
  }
  void refreshAdminHistory() async {
    List<Map<String, dynamic>> updatedHistory = await DatabaseHelper.instance.fetchAdminQuizHistory(widget.username);
    if (mounted) {
      setState(() {
        adminQuizHistory = updatedHistory;
      });
    }
  }
  void clearAdminHistory() async {
    bool confirmDelete = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Clear History"),
        content: Text("Are you sure you want to clear all history?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text("Cancel")),
          TextButton(onPressed: () => Navigator.pop(context, true), child: Text("Clear")),
        ],
      ),
    );
    if (confirmDelete == true) {
      await DatabaseHelper.instance.clearAdminQuizHistory(widget.username);
      refreshAdminHistory();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("History cleared successfully!")));
    }
  }
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    refreshAdminHistory();
  }
  @override
  void initState() {
    super.initState();
    loadQuizHistory();
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
            icon: Icon(Icons.delete),
            onPressed: clearAdminHistory,
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.white38, Colors.lightBlueAccent],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
              child: adminQuizHistory.isEmpty
                  ? Center(child: Text("No quiz history available."))
                  :ListView.builder(
                  padding: EdgeInsets.all(16.0),
                  itemCount: adminQuizHistory.length,
                  itemBuilder: (context, index) {
                    final quiz = adminQuizHistory[index];
                    return Card(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
                                color: Colors.grey[300],
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(quiz["title"], style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),),
                                  SizedBox(height: 4),
                                  Text("${quiz['total'] ?? 0} Questions", style: TextStyle(fontSize: 14, color: Colors.grey[700]),),
                                  Text("Category: ${quiz['category']?.trim().isNotEmpty == true ? quiz['category'] : 'Unknown'}", style: TextStyle(fontSize: 14, color: Colors.grey[700]),),
                                  SizedBox(height: 4),
                                  Text("Created at: ${quiz["date"]}", style: TextStyle(fontSize: 12, color: Colors.grey[600]),),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
            ),
          ),
        ],
      ),
    );
  }
}