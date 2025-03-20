import 'package:flutter/material.dart';
import 'package:quizmanage/Datahelp/tables.dart';

class Notificationpage extends StatefulWidget {
  const Notificationpage({super.key});

  @override
  State<Notificationpage> createState() => _NotificationpageState();
}
class _NotificationpageState extends State<Notificationpage> {
  List<Map<String, dynamic>> notifications = [];

  @override
  void initState() {
    super.initState();
    fetchNotifications();
    DatabaseHelper.instance.deleteInvalidReviews();
  }
  Future<void> fetchNotifications() async {
    int adminId = await DatabaseHelper.instance.getLoggedInAdminId();
    if (adminId == 0) {
      return;
    }
    List<Map<String, dynamic>> fetchedReviews = await DatabaseHelper.instance.getReviewsForAdmin(adminId);
    setState(() {
      notifications = fetchedReviews;
    });
  }
  void _refreshNotifications() async {
    List<Map<String, dynamic>> data = await DatabaseHelper.instance.getReviews();
    setState(() {
      notifications = data;
    });
  }
  void _confirmDeleteAllReviews() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Delete All Reviews"),
        content: Text("Are you sure you want to delete all quiz reviews?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Cancel"),
          ),
          TextButton(
            onPressed: () async {
              await DatabaseHelper.instance.deleteAllReviews();
              Navigator.pop(context);
              _refreshNotifications();
            },
            child: Text("Delete All", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.lightBlueAccent,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: const Text("Notifications"),
        centerTitle: true,
        backgroundColor: Colors.blueAccent,
        actions: [
          IconButton(
            icon: Icon(Icons.delete, color: Colors.white),
            onPressed: _confirmDeleteAllReviews,
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: [Colors.white38,Colors.lightBlueAccent],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(10.0),
          child: notifications.isEmpty ? const Center(child: Text("No Reviews Yet")) : ListView.builder(
            itemCount: notifications.length,
            itemBuilder: (context, index) {
              final notification = notifications[index];
              return Card(
                elevation: 3,
                margin: const EdgeInsets.symmetric(vertical: 5),
                child: Padding(
                  padding: const EdgeInsets.all(10.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(notification["user_name"] ?? "Unknown User", style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.blue,),),
                      Text("Title: ${notification["quiz_title"] ?? "Untitled Quiz"}"),
                      const SizedBox(height: 5),
                      Row(
                        children: [
                          const Text("Rating: ", style: TextStyle(fontWeight: FontWeight.bold,fontSize: 18),),
                          Row(
                            children: List.generate(5, (i) {
                              return Icon(
                                i < notification["rating"] ? Icons.star : Icons.star_border,
                                color: Colors.amber,
                              );
                            }),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}