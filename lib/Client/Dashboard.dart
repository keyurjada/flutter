import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:quizmanage/Client/QustionPage.dart';
import 'profilePage.dart';
import 'historyPage.dart';
import 'package:quizmanage/Datahelp/tables.dart';
import 'dart:io';

class MainPage extends StatefulWidget {
  final String username;
  MainPage({required this.username});

  @override
  _MainScreenState createState() => _MainScreenState();
}
class _MainScreenState extends State<MainPage> {
  int _selectedIndex = 0;
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  List<Widget>? _pages;
  int? _userId;
  String? _profileImagePath;
  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }
  @override
  void initState(){
    super.initState();
    _loadUserId();
    _loadProfileImage();
  }
  Future<void> _loadProfileImage() async {
    String? imagePath = await DatabaseHelper.instance.getAdminProfileImage(widget.username);
    setState(() => _profileImagePath = imagePath);
  }
  Future<void> _loadUserId() async{
    int userId = await _dbHelper.getLoggedInUserId();
    setState(() {
      _userId = userId;
      _pages = <Widget>[
      Dashboard(username: widget.username,profileImagePath: _profileImagePath,),
      Profile(username: widget.username,userId: _userId!,onProfileImageUpdated: _updateProfileImage,),
      History(userId: _userId!),
      ];
    });
  }
  void _updateProfileImage(String? newPath) {
    setState(() {
      _profileImagePath = newPath;
      _pages![0] = Dashboard(username: widget.username, profileImagePath: _profileImagePath);
    });
  }
  @override
  Widget build(BuildContext context) {
    if(_pages == null){
      return Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    return Scaffold(
      backgroundColor: Colors.blueAccent,
      body: _pages![_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.blue,
        onTap: _onItemTapped,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home,color: Colors.black,), label: "Home"),
          BottomNavigationBarItem(icon: Icon(Icons.person,color: Colors.black,), label: "Profile"),
          BottomNavigationBarItem(icon: Icon(Icons.history,color: Colors.black,), label: "History"),
        ],
      ),
    );
  }
}
class Dashboard extends StatefulWidget {
  final String username;
  final String? profileImagePath;
  Dashboard({required this.username,this.profileImagePath});

  @override
  State<Dashboard> createState() => _DashboardState();
}
class _DashboardState extends State<Dashboard> {
  List<Map<String, dynamic>> _quizzes = [];
  List<Map<String, dynamic>> _filteredQuizzes = [];
  List<Map<String, dynamic>> _quizHistory = [];
  Map<String, dynamic>? _lastTakenQuiz;
  final TextEditingController _searchController = TextEditingController();
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  @override
  void initState(){
    super.initState();
    _dbHelper.manuallyLogInUser(1);
    _loadQuizzes();
    _loadUserQuizHistory();
    _searchController.addListener(_searchQuizzes);
  }
  Future<void> _loadUserQuizHistory() async {
    int userId = await _dbHelper.getLoggedInUserId();
    if (userId == 0) {
      return;
    }
    setState(() {
      _quizHistory = [];
      _lastTakenQuiz = null;
    });
    List<Map<String, dynamic>> history = await _dbHelper.fetchUserQuizHistory(userId);
    setState(() {
      _quizHistory = history;
      _lastTakenQuiz = history.isNotEmpty ? history.first : null;
    });
  }
  Future<void> _loadQuizzes() async {
    await Future.delayed(Duration(milliseconds: 500));
    List<Map<String, dynamic>> quizzes = await _dbHelper.fetchAllQuizzes();
    setState(() {
      _quizzes = quizzes;
      _filteredQuizzes = quizzes;
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadQuizzes();
    _loadUserQuizHistory();
  }
  void _searchQuizzes() {
    String query = _searchController.text.toLowerCase();
    setState(() {
      _filteredQuizzes = _quizzes.where((quiz) {
        return quiz['title'].toLowerCase().contains(query);
      }).toList();
    });
  }
  Widget _buildLastTakenQuiz() {
    if(_lastTakenQuiz == null){
      return Center(child: Text("No recent quizzes played", style: TextStyle(color: Colors.white70)));
    }
    String title = _lastTakenQuiz?['title'] ?? "Unknown Quiz";
    int progress = _lastTakenQuiz?['progress'] ?? 0;
    int total = _lastTakenQuiz?['total'] ?? 1;
    return GestureDetector(
      onTap: () async {
        int userId = await _dbHelper.getLoggedInUserId();
        Navigator.push(context, MaterialPageRoute(builder: (context) => History(userId: userId)),);
      },
      child: AnimatedBuilder(
        animation: Listenable.merge([ValueNotifier(progress)]),
        builder: (context, _) {
          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.3), blurRadius: 5)],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                Text("$total Questions"),
                const SizedBox(height: 8),
                LinearProgressIndicator(
                  value: (total > 0) ? (progress / total) : 0.0,
                  backgroundColor: Colors.grey[300],
                  color: Colors.blue,
                ),
                const SizedBox(height: 4),
                Text("Progress: $progress/$total"),
              ],
            ),
          );
        },
      ),
    );
  }
  void _startQuiz(int quizId, String title, int totalQuestions) async {
    int userId = await _dbHelper.getLoggedInUserId();
    int? result = await Navigator.push(context, MaterialPageRoute(builder: (context) => QuesScreen(quizId: quizId)),);
    int correctAnswers = (result is int) ? result : 0;
    int newProgress = (correctAnswers >= 0 && correctAnswers <= totalQuestions) ? correctAnswers : 0;
    await _dbHelper.insertUserQuizHistory(
      userId: userId,
      quizId: quizId,
      title: title,
      totalQuestions: totalQuestions,
      progress: newProgress,
      category: "General",
    );
    await _loadUserQuizHistory();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blueAccent,
      appBar: AppBar(
        title: Text("Home",style: TextStyle(fontWeight: FontWeight.bold),),
        centerTitle: true,
        backgroundColor: Colors.lightBlueAccent,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: Colors.white),
            onPressed: () {
              _loadQuizzes();
            },
          )
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
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 30,
                        backgroundImage: widget.profileImagePath != null && File(widget.profileImagePath!).existsSync()
                            ? FileImage(File(widget.profileImagePath!))
                            : AssetImage("assets/default_profile.png") as ImageProvider,
                      ),
                      const SizedBox(width: 10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(widget.username, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.grey,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Text("User", style: TextStyle(color: Colors.white, fontSize: 12,fontWeight: FontWeight.bold),),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: "Search quizzes",
                      prefixIcon: const Icon(Icons.search),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildLastTakenQuiz(),
                  const SizedBox(height: 16),
                  const Text("Quiz", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  CarouselSlider(
                    options: CarouselOptions(height: 150, autoPlay: true, enlargeCenterPage: true,enableInfiniteScroll: true),
                    items: [
                      "https://th.bing.com/th/id/OIP.PRjOe_WL5VGVgqyl04ai5QHaDu?w=344&h=175&c=7&r=0&o=5&dpr=1.1&pid=1.7",
                      "https://th.bing.com/th/id/OIP.GplH6RXkVVSMYmY4B4F_DgHaD_?w=271&h=180&c=7&r=0&o=5&dpr=1.1&pid=1.7",
                      "https://th.bing.com/th/id/OIP.IEU3IyE8irWtNkt5zEB44wHaEo?w=297&h=123&c=7&r=0&o=5&dpr=1.1&pid=1.7",
                      "https://th.bing.com/th/id/OIP.YxUj3hNdMjQ5e5tBhvhsBgHaD5?w=337&h=180&c=7&r=0&o=5&dpr=1.1&pid=1.7",
                      "https://th.bing.com/th/id/OIP.qpegqWN-X6gOGg1L_rVpmAHaEK?w=316&h=180&c=7&r=0&o=5&dpr=1.1&pid=1.7"
                    ].map((imageUrl) {
                      return Container(
                        margin: const EdgeInsets.symmetric(horizontal: 5.0),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          image: DecorationImage(
                            image: NetworkImage(imageUrl),
                            fit: BoxFit.cover,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),
                  const Text("More Quizzes", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  SizedBox(
                    height: MediaQuery.of(context).size.height * 0.65,
                    child: _filteredQuizzes.isEmpty
                    ? Center(child: Text("No quizzes found", style: TextStyle(color: Colors.white)))
                    : ListView.builder(
                      shrinkWrap: true,
                      physics: NeverScrollableScrollPhysics(),
                      itemCount: _filteredQuizzes.length,
                      itemBuilder: (context, index) {
                        final quiz = _filteredQuizzes[index];
                        return GestureDetector(
                          onTap: () {
                            if (quiz['id'] == null || quiz['title'] == null || quiz['total'] == null) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text("Quiz data is incomplete"))
                              );
                              return;
                            }
                            _startQuiz(quiz['id'], quiz['title'], quiz['total']);
                          },
                          child: Container(
                            margin: const EdgeInsets.symmetric(vertical: 8),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(color: Colors.grey.withOpacity(0.3), blurRadius: 5),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(quiz['title'], style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                                Text("Category: ${quiz['category']}"),
                                Text("Author: ${quiz['author']}"),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}