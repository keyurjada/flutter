import 'package:flutter/material.dart';
import 'package:quizmanage/Client/Dashboard.dart';
import 'package:quizmanage/Client/QustionPage.dart';
import 'package:quizmanage/Client/downLoadQB.dart';
import 'package:quizmanage/Client/historyPage.dart';
import 'package:quizmanage/Client/profilePage.dart';
import 'package:quizmanage/Client/scorePage.dart';
import 'package:quizmanage/SignUpPage.dart';
import 'package:quizmanage/admin/Dashboard.dart';
import 'package:quizmanage/admin/EditQuiz.dart';
import 'package:quizmanage/admin/NotificationPage.dart';
import 'package:quizmanage/admin/addQuiz.dart';
import 'package:quizmanage/admin/extraQues.dart';
import 'package:quizmanage/admin/profile.dart';
import 'package:quizmanage/admin/uploadQB.dart';
import 'package:quizmanage/landingpage.dart';
import 'package:quizmanage/loginPage.dart';
import 'package:quizmanage/Datahelp/tables.dart';
void main() async{
  WidgetsFlutterBinding.ensureInitialized();

  await DatabaseHelper.instance.checkQuizzesTable();
  runApp(const MyApp());
}
class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: LandingPage(),
    );
  }
}
class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});
  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}
class _MyHomePageState extends State<MyHomePage> {
  int _counter = 0;
  void _incrementCounter() {
    setState(() {
      _counter++;
    });
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Text(
              'You have pushed the button this many times:',
            ),
            Text(
              '$_counter',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _incrementCounter,
        tooltip: 'Increment',
        child: const Icon(Icons.add),
      ),
    );
  }
}