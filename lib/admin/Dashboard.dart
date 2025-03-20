import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:quizmanage/admin/EditQuiz.dart';
import 'package:quizmanage/admin/Histort.dart';
import 'package:quizmanage/admin/addQuiz.dart';
import 'package:quizmanage/admin/profile.dart';
import 'package:page_transition/page_transition.dart';
import 'package:quizmanage/Datahelp/tables.dart';
import 'package:quizmanage/admin/viewQuiz.dart';
import 'dart:io';

class AdminDashboard extends StatefulWidget {
  final String username;
  AdminDashboard({required this.username});

  @override
  _AdminDashboardState createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  List<Map<String, dynamic>> _adminQuizHistory = [];
  Future<void> _loadAdminQuizHistory() async {
    List<Map<String, dynamic>> history = await DatabaseHelper.instance.fetchAdminQuizHistory(widget.username);
    setState(() {
      _adminQuizHistory = history;
    });
  }
  int _selectedIndex = 0;
  String? _profileImagePath;
  late List<Widget> _pages;
  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }
  @override
  void initState(){
    super.initState();
    checkDatabaseSchema();
    _loadProfileImage();
    _loadAdminQuizHistory();
    _pages = <Widget>[
      Dashb(username:widget.username,profileImagePath: _profileImagePath,),
      ProPage(username:widget.username,onProfileImageUpdated: _updateProfileImage,),
      HisPage(username: widget.username,),
    ];
  }
  Future<void> checkDatabaseSchema() async {
    await DatabaseHelper.instance.checkQuizHistoryTable();
  }
  Future<void> _loadProfileImage() async {
    String? imagePath = await DatabaseHelper.instance.getAdminProfileImage(widget.username);
    setState(() => _profileImagePath = imagePath);
  }
  void _updateProfileImage(String? newPath) {
    setState(() {
      _profileImagePath = newPath;
      _pages[0] = Dashb(username: widget.username, profileImagePath: _profileImagePath);
    });
  }
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blueAccent,
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
          BottomNavigationBarItem(icon: Icon(Icons.history), label: 'History'),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.blue,
        onTap: _onItemTapped,
      ),
    );
  }
}
class Dashb extends StatefulWidget {
  final String username;
  final String? profileImagePath;
  Dashb({required this.username,this.profileImagePath});

  @override
  State<Dashb> createState() => _DashbState();
}
class _DashbState extends State<Dashb> {
  TextEditingController searchController = TextEditingController();
  List<Map<String, dynamic>> quizzes = [];
  List<Map<String, dynamic>> filteredQuizzes = [];
  Future<void> loadQuizzes() async {
    final data = await DatabaseHelper.instance.fetchQuizzes(widget.username);
    setState(() {
      quizzes = data;
      filteredQuizzes = data;
    });
    for (var quiz in data) {
      await DatabaseHelper.instance.insertAdminQuizHistory(
        quizId: quiz['id'],
        title: quiz['title'],
        category: quiz['category'],
        adminName: widget.username,
      );
    }
  }
  void filterQuizzes(String query) {
    setState(() {
      filteredQuizzes = quizzes
          .where((quiz) => quiz['title'].toLowerCase().contains(query.toLowerCase()))
          .toList();
    });
  }
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      loadQuizzes();
    });
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: Colors.blueAccent,
      appBar: AppBar(
        title: Text("dashboard"),
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
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 30,
                      backgroundImage: widget.profileImagePath != null && File(widget.profileImagePath!).existsSync()
                          ? FileImage(File(widget.profileImagePath!))
                          : AssetImage("assets/default_profile.png") as ImageProvider,
                    ),
                    SizedBox(width: 10),
                    SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(widget.username, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.grey[300],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text("Admin", style: TextStyle(fontSize: 12)),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0,vertical: 10),
                child: TextField(
                  controller: searchController,
                  decoration: InputDecoration(
                    hintText: "Search quizzes",
                    prefixIcon: Icon(Icons.search),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onChanged: filterQuizzes,
                ),
              ),
              SizedBox(height: 10),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () async{
                      Navigator.push(context, PageTransition(child: Addquiz(username: widget.username,), type: PageTransitionType.fade));
                    },
                    icon: Icon(Icons.add, size: 30),
                    label: Text("Add Quiz", style: TextStyle(fontSize: 20)),
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: 15),
                    ),
                  ),
                ),
              ),
              SizedBox(height: 10),
              SizedBox(
                height: 150,
                child: CarouselSlider(
                  options: CarouselOptions(
                    height: 150.0,
                    enlargeCenterPage: true,
                    autoPlay: true,
                    aspectRatio: 16 / 9,
                    enableInfiniteScroll: true,
                  ),
                  items: [
                    "https://th.bing.com/th/id/OIP.4WitePQCm2OK5DdxLAxjlQHaEK?w=317&h=180&c=7&r=0&o=5&dpr=1.1&pid=1.7",
                    "https://th.bing.com/th/id/OIP.iNPLnTNk-Z9xp-7M1Eu0NgHaEC?w=309&h=180&c=7&r=0&o=5&dpr=1.1&pid=1.7",
                    "https://th.bing.com/th/id/OIP.4vaULQOAo3AMYMFth8tyLQHaDq?w=313&h=173&c=7&r=0&o=5&dpr=1.1&pid=1.7",
                  ].map((i) {
                    return ClipRRect(
                      borderRadius: BorderRadius.circular(15),
                      child: Image.network(i, fit: BoxFit.cover),
                    );
                  }).toList(),
                ),
              ),
              SizedBox(height: 10),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text("Your Quizzes", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  child: Padding(
                    padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
                    child: filteredQuizzes.isEmpty
                        ? Center(child: Text("No Quizzes available."))
                        : Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: GridView.builder(
                          shrinkWrap: true,
                          physics: NeverScrollableScrollPhysics(),
                          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 20,
                            mainAxisSpacing: 20,
                            childAspectRatio: 0.7,
                          ),
                          itemCount: filteredQuizzes.length,
                          itemBuilder: (context, index) {
                            if (index >= filteredQuizzes.length) {
                              return SizedBox();
                            }
                            final quiz = filteredQuizzes[index];
                            return GestureDetector(
                              onTap: () {
                                Navigator.push(context, MaterialPageRoute(builder: (context) => viewquiz(quizId: quiz['id'], title: quiz['title'],),),);
                                loadQuizzes();
                              },
                              child: Container(
                                padding: EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(child: Container(color: Colors.grey[300])),
                                    SizedBox(height: 10),
                                    Text(quiz["title"], style: TextStyle(fontWeight: FontWeight.bold)),
                                    Text("Category: ${quiz["category"]}"),
                                    Text("Created by: ${quiz["author"]}"),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        IconButton(onPressed: () async{
                                          await Navigator.push(context, PageTransition(child: Editquiz(quizId: quiz['id']), type: PageTransitionType.fade,duration: Duration(microseconds: 500)));
                                          loadQuizzes();
                                        }, icon: Icon(Icons.edit, size: 18)),
                                        IconButton(onPressed: () async {
                                          bool confirmDelete = await showDialog(
                                            context: context,
                                            builder: (context) => AlertDialog(
                                              title: Text("Delete Quiz"),
                                              content: Text("Are you sure you want to delete this quiz?"),
                                              actions: [
                                                TextButton(
                                                  onPressed: () => Navigator.pop(context, false),
                                                  child: Text("Cancel"),
                                                ),
                                                TextButton(
                                                  onPressed: () => Navigator.pop(context, true),
                                                  child: Text("Delete", style: TextStyle(color: Colors.red)),
                                                ),
                                              ],
                                            ),
                                          );
                                          if (!confirmDelete) return;
                                          int quizId = int.tryParse(quizzes[index]["id"].toString()) ?? -1;
                                          if(quizId == -1){
                                            return;
                                          }
                                          final db = await DatabaseHelper.instance.database;
                                          List<Map<String, dynamic>> result = await db.query("quizzes", where: "id = ?", whereArgs: [quizId]);
                                          if(result.isEmpty){
                                            setState(() {
                                              loadQuizzes();
                                            });
                                            return;
                                          }
                                          int deletedRows = await db.delete("quizzes", where: "id = ?", whereArgs: [quizId]);
                                          if(deletedRows > 0){
                                            setState(() {
                                              loadQuizzes();
                                            });
                                          }else{
                                            print("Failed to delete quiz. No matching ID found.");
                                          }
                                        }, icon: Icon(Icons.delete, size: 18, color: Colors.red)),
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
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}