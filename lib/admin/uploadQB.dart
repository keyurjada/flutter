import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:quizmanage/Datahelp/tables.dart';

class Uploadqb extends StatefulWidget {
  final String username;
  const Uploadqb({super.key, required this.username});

  @override
  State<Uploadqb> createState() => _UploadqbState();
}
class _UploadqbState extends State<Uploadqb> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _dateController = TextEditingController();
  double? _uploadProgress;
  List<Map<String, dynamic>> _questionBanks = [];
  String? _fileName;

  @override
  void initState() {
    super.initState();
    _fetchQuestionBanks();
  }
  Future<void> _fetchQuestionBanks() async {
    List<Map<String, dynamic>> banks = await DatabaseHelper.instance.getQuestionBanks(widget.username);
    setState(() {
      _questionBanks = List.from(banks);
    });
  }
  Future<void> _pickDate(BuildContext context) async {
    DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (pickedDate != null) {
      setState(() {
        _dateController.text = "${pickedDate.day}/${pickedDate.month}/${pickedDate.year}";
      });
    }
  }
  Future<void> _pickFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );
    if (result != null) {
      String? filePath = result.files.single.path;
      if (filePath != null && filePath.endsWith('.pdf')) {
        setState(() {
          _fileName = filePath;
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Please select a valid PDF file!")),
        );
      }
    }
  }
  void _uploadToDatabase() async {
    if (_fileName != null && _titleController.text.isNotEmpty && _dateController.text.isNotEmpty) {
      await DatabaseHelper.instance.insertQuestionBank(
        _titleController.text,
        widget.username,
        _dateController.text,
        _fileName!,
      );
      _fetchQuestionBanks();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Question Bank Uploaded Successfully!")));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Please fill all fields!")));
    }
  }
  void _deleteQuestionBank(int id) async {
    int deletedRows = await DatabaseHelper.instance.deleteQuestionBank(id, widget.username);
    if (deletedRows > 0) {
      setState(() {
        _questionBanks = List.from(_questionBanks)..removeWhere((qb) => qb['id'] == id);
      });
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Question Bank Deleted Successfully!"))
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to delete Question Bank."))
      );
    }
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.lightBlueAccent,
      appBar: AppBar(
        title: Text("Upload Question Bank"),
        centerTitle: true,
        backgroundColor: Colors.blueAccent,
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.white38, Colors.lightBlueAccent],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("QB Title:", style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.black),),
                TextField(
                  controller: _titleController,
                  decoration: InputDecoration(
                    filled: true,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    hintText: "Enter Question Bank Title",
                  ),
                ),
                SizedBox(height: 10),
                Text("Date:", style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.black),),
                TextField(
                  controller: _dateController,
                  readOnly: true,
                  decoration: InputDecoration(
                    filled: true,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    hintText: "DD/MM/YYYY",
                    suffixIcon: IconButton(
                      icon: Icon(Icons.calendar_today),
                      onPressed: () => _pickDate(context),
                    ),
                  ),
                ),
                SizedBox(height: 10),
                Text("Select File:", style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.black),),
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          border: Border.all(color: Colors.grey),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(_fileName ?? "No file chosen"),
                      ),
                    ),
                    SizedBox(width: 10),
                    ElevatedButton(
                      onPressed: () {
                        setState(() {
                          _pickFile();
                        });
                      },
                      child: Text("Choose", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 18),),
                    ),
                  ],
                ),
                SizedBox(height: 20),
                if (_uploadProgress != null) ...[
                  SizedBox(
                    height: 5,
                    child: LinearProgressIndicator(value: _uploadProgress),
                  ),
                  SizedBox(height: 10),
                ],
                Center(
                  child: ElevatedButton(
                    onPressed: _uploadToDatabase,
                    style: ElevatedButton.styleFrom(
                      minimumSize: Size(double.infinity, 45),
                    ),
                    child: Text("Upload", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 18),),
                  ),
                ),
                SizedBox(height: 20,),
                SizedBox(
                  height: 300,
                    child: ListView.builder(
                      shrinkWrap: true,
                        physics: NeverScrollableScrollPhysics(),
                        itemCount: _questionBanks.length,
                        itemBuilder: (context,index){
                          var qb = _questionBanks[index];
                          return Card(
                            child: ListTile(
                              title: Text(qb['title']),
                              subtitle: Text("By: ${qb['author']}"),
                              trailing: IconButton(
                                icon: Icon(Icons.delete, color: Colors.red),
                                onPressed: () => _deleteQuestionBank(qb['id']),
                              ),
                            ),
                          );
                        }
                    )
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}