import 'package:flutter/material.dart';
import 'dart:io';
import 'package:open_file/open_file.dart';
import 'package:quizmanage/Datahelp/tables.dart';

class Down extends StatefulWidget {
  const Down({super.key});

  @override
  State<Down> createState() => _DownState();
}
class _DownState extends State<Down> {
  late Future<List<Map<String, dynamic>>> _questionBanksFuture;

  @override
  void initState() {
    super.initState();
    _questionBanksFuture = _fetchQuestionBanks();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    setState(() {
      _questionBanksFuture = _fetchQuestionBanks();
    });
  }
  Future<List<Map<String, dynamic>>> _fetchQuestionBanks() async {
    await Future.delayed(Duration(milliseconds: 500));
    return await DatabaseHelper.instance.getAllQuestionBanks();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.lightBlueAccent,
      appBar: AppBar(
        title: Text("Question Banks"),
        centerTitle: true,
        backgroundColor: Colors.blueAccent,
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: () {
              setState(() {});
            },
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
        child: FutureBuilder(
            future: _fetchQuestionBanks(),
            builder: (context,snapshot){
              if (!snapshot.hasData) return Center(child: CircularProgressIndicator());
              if (snapshot.data!.isEmpty) return Center(child: Text("No Question Banks Available"));
              return ListView.builder(
                itemCount: snapshot.data!.length,
                itemBuilder: (context, index) {
                  var qb = snapshot.data![index];
                  return _buildQuestionBankCard(context,qb['title'], qb['author'], qb['file_path']);
                },
              );
            },
        ),
      ),
    );
  }
  Widget _buildQuestionBankCard(BuildContext context,String title, String author,String filepath) {
    return Card(
      margin: EdgeInsets.symmetric(vertical: 10),
      child: ListTile(
        title: Text(title,style: TextStyle(fontWeight: FontWeight.bold),),
        subtitle: Text(author),
        trailing: SizedBox(
          height: 40,
          child: ElevatedButton(
            onPressed: () {
              if (File(filepath).existsSync()) {
                OpenFile.open(filepath);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("File not found!")));
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blueAccent
            ),
            child: Text("Download",style: TextStyle(color: Colors.white,fontWeight: FontWeight.bold),),
          ),
        ),
      ),
    );
  }
}