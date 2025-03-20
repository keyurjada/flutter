import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';
import 'package:intl/intl.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;
  DatabaseHelper._init();
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('data.db');
    return _database!;
  }
  Future<Database> _initDB(String filePath) async {
    final dir = await getApplicationDocumentsDirectory();
    final path = join(dir.path, filePath);
    return openDatabase(path, version: 21, onCreate: _createDB,onUpgrade: _upgradeDb);
  }
  Future _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE category (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL
      );
    ''');
    await db.execute('''
      CREATE TABLE users (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        email TEXT NOT NULL UNIQUE,
        phone TEXT NOT NULL,
        password TEXT NOT NULL,
        role TEXT CHECK(role IN ('admin', 'user')) DEFAULT 'user',
        profile_image TEXT DEFAULT NULL,
        is_logged_in INTEGER DEFAULT 0
      );
    ''');
    await db.execute('''
      CREATE TABLE quizzes (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
      title TEXT NOT NULL,
      category TEXT NOT NULL,
      author TEXT NOT NULL,
      question TEXT NOT NULL,
      op1 TEXT NOT NULL,
      op2 TEXT NOT NULL,
      op3 TEXT NOT NULL,
      op4 TEXT NOT NULL,
      correct_ans TEXT NOT NULL,
      admin_id INTEGER DEFAULT NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE questions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        quiz_id INTEGER NOT NULL,
        question_text TEXT NOT NULL,
        op1 TEXT NOT NULL,
        op2 TEXT NOT NULL,
        op3 TEXT NOT NULL,
        op4 TEXT NOT NULL,
        correct_ans TEXT NOT NULL,
        FOREIGN KEY (quiz_id) REFERENCES quiz (id) ON DELETE NO ACTION
      );
    ''');
    await db.execute('''
      CREATE TABLE answers (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        question_id INTEGER NOT NULL,
        answer_text TEXT NOT NULL,
        is_correct INTEGER NOT NULL CHECK(is_correct IN (0,1)),
        FOREIGN KEY (question_id) REFERENCES questions (id) ON DELETE CASCADE
      );
    ''');
    await db.execute('''
      CREATE TABLE scores (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL,
        quiz_id INTEGER NOT NULL,
        score INTEGER NOT NULL,
        FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE,
        FOREIGN KEY (quiz_id) REFERENCES quiz (id) ON DELETE CASCADE
      );
    ''');
    await db.execute(
      '''CREATE TABLE IF NOT EXISTS quiz_history (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          quiz_id INTEGER, 
          title TEXT, 
          total INTEGER, 
          progress INTEGER, 
          date TEXT,
          category TEXT,
          admin_name TEXT,
          user_id INTEGER DEFAULT NULL
       )''',
    );
    await db.execute('''
      CREATE TABLE reviews (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL,
        quiz_id INTEGER NOT NULL,
        rating REAL NOT NULL,
        FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
        FOREIGN KEY (quiz_id) REFERENCES quizzes(id) ON DELETE CASCADE
      );
    ''');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS question_banks (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        author TEXT NOT NULL,
        date TEXT NOT NULL,
        file_path TEXT NOT NULL
      );
    ''');
  }
  Future<Map<String, dynamic>?> getAdmin() async {
    final db = await instance.database;
    List<Map<String, dynamic>> result = await db.query(
        'users',
        where: "role = ?",
        whereArgs: ['admin'],
        limit: 1
    );
    return result.isNotEmpty ? result.first : null;
  }
  Future<int> signup({
    required String role,
    required String name,
    required String email,
    required String password,
    required String phone
  }) async {
    final db = await instance.database;
    String hashedPassword = sha256.convert(utf8.encode(password)).toString();
    final Map<String, dynamic> data = {
      'role': role,
      'name': name,
      'email': email,
      'password': hashedPassword,
      'phone' : phone
    };
    final tables = await db.rawQuery("SELECT name FROM sqlite_master WHERE type='table'");
    return await db.insert('users', data);
  }
  Future<Map<String, dynamic>?> login({
    required String email,
    required String password,
  }) async {
    final db = await instance.database;
    String hashedPassword = sha256.convert(utf8.encode(password)).toString();
    List<Map<String, dynamic>> result = await db.query(
      'users',
      where: 'email = ? AND password = ?',
      whereArgs: [email, hashedPassword],
    );
    if(result.isNotEmpty){
      int userId = result.first['id'];
      String role = result.first['role'];
      await db.rawUpdate("UPDATE users SET is_logged_in = 0 WHERE role = ?", [role]);
      await db.rawUpdate("UPDATE users SET is_logged_in = 1 WHERE id = ?", [userId]);
      return result.first;
    }else{
      return null;
    }
  }
  Future<int> addquiz({
    required String title,
    required String category,
    required String author,
    required String question,
    required String op1,
    required String op2,
    required String op3,
    required String op4,
    required String correctAns,
  }) async {
    final db = await database;
    int adminId = await getLoggedInAdminId();
    if (adminId == 0) {
      return -1;
    }
    int result = await db.insert(
      'quizzes',
      {
        'title': title,
        'category': category,
        'author': author,
        'question': question,
        'op1': op1,
        'op2': op2,
        'op3': op3,
        'op4': op4,
        'correct_ans': correctAns,
        'admin_id': adminId,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    return result;
  }
  Future<List<Map<String, dynamic>>> fetchQuizzes(String username) async {
    final db = await database;
    List<Map<String, dynamic>> quizzes = await db.rawQuery('''
    SELECT 
      quizzes.id, 
      quizzes.title, 
      quizzes.category, 
      quizzes.author,
      COUNT(questions.id) AS total 
      FROM quizzes 
      LEFT JOIN questions ON quizzes.id = questions.quiz_id 
      WHERE quizzes.author = ?
      GROUP BY quizzes.id
    ''',[username]);
    return quizzes;
  }
  Future<List<Map<String, dynamic>>> fetchUserQuizzes(int userId) async {
    final db = await database;
    return await db.rawQuery('''
    SELECT 
      quizzes.id, 
      quizzes.title, 
      quizzes.category, 
      quizzes.author,
      COUNT(questions.id) AS total 
      FROM quizzes 
      LEFT JOIN questions ON quizzes.id = questions.quiz_id 
      WHERE quizzes.id IN (
        SELECT DISTINCT quiz_id FROM quiz_history WHERE user_id = ?
    ) 
    GROUP BY quizzes.id
  ''', [userId]);
  }
  Future<void> _upgradeDb(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 17) {
      await db.execute('''
    CREATE TABLE IF NOT EXISTS reviews (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      user_id INTEGER NOT NULL,
      quiz_id INTEGER NOT NULL,
      rating REAL NOT NULL,
      FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
      FOREIGN KEY (quiz_id) REFERENCES quizzes(id) ON DELETE CASCADE
    );
  ''');
    }
    if (oldVersion < 18) {
      await db.execute("ALTER TABLE users ADD COLUMN profile_image TEXT DEFAULT NULL");
    }
    if (oldVersion < 19) {
      await db.execute('''
      CREATE TABLE IF NOT EXISTS question_banks (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        author TEXT NOT NULL,
        date TEXT NOT NULL,
        file_path TEXT NOT NULL
      );
    ''');
    }
    if (oldVersion < 20) {
      await db.execute("ALTER TABLE users ADD COLUMN is_logged_in INTEGER DEFAULT 0");
    }
    if (oldVersion < 21) {
      await db.execute("ALTER TABLE quizzes ADD COLUMN admin_id INTEGER DEFAULT NULL");
    }
  }
  Future<int> insertReview(int quizId, double rating) async {
    final db = await database;
    int userId = await getLoggedInUserId();
    if (userId == 0) {
      return -1;
    }
    return await db.insert(
      'reviews',
      {'user_id': userId, 'quiz_id': quizId, 'rating': rating},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }
  Future<List<Map<String, dynamic>>> getReviews() async {
    final db = await database;

    int adminId = await getLoggedInAdminId();
    if (adminId == 0) return [];

    return await db.rawQuery('''
    SELECT reviews.id, users.name AS user_name, quizzes.title AS quiz_title, reviews.rating, reviews.quiz_id
    FROM reviews
    JOIN users ON reviews.user_id = users.id
    JOIN quizzes ON reviews.quiz_id = quizzes.id
    WHERE quizzes.admin_id = ? 
  ''', [adminId]);
  }
  Future<List<Map<String, dynamic>>> getReviewsForAdmin(int adminId) async {
    final db = await database;

    List<Map<String, dynamic>> result = await db.rawQuery('''
    SELECT reviews.id, users.name AS user_name, quizzes.title AS quiz_title, reviews.rating, reviews.quiz_id
    FROM reviews
    JOIN users ON reviews.user_id = users.id
    JOIN quizzes ON reviews.quiz_id = quizzes.id
    WHERE quizzes.admin_id = ?
  ''', [adminId]);

    return result;
  }
  Future<void> checkQuizzesTable() async {
    final db = await database;
    List<Map<String, dynamic>> result = await db.rawQuery("SELECT * FROM quizzes");
    print("🔍 Quizzes Table Data: $result");
  }
  Future<void> deleteInvalidReviews() async {
    final db = await database;
    await db.rawDelete("DELETE FROM reviews WHERE quiz_id NOT IN (SELECT id FROM quizzes)");
    print("Deleted invalid reviews.");
  }
  Future<void> deleteAllReviews() async {
    final db = await database;
    await db.delete('reviews');
  }
  Future<void> updateAdminProfileImage(String username, String? imagePath) async {
    final db = await instance.database;
    await db.update(
      'users',
      {'profile_image': imagePath},
      where: 'name = ? AND role = ?',
      whereArgs: [username, 'admin'],
    );
  }
  Future<String?> getAdminProfileImage(String username) async {
    final db = await instance.database;
    List<Map<String, dynamic>> result = await db.query(
      'users',
      columns: ['profile_image'],
      where: 'name = ? AND role = ?',
      whereArgs: [username, 'admin'],
    );
    if(result.isNotEmpty){
      return result.first['profile_image'] as String?;
    }
    return null;
  }
  Future<void> deleteAdminProfileImage(String username) async {
    final db = await instance.database;
    await db.update(
      'users',
      {'profile_image': null},
      where: 'name = ? AND role = ?',
      whereArgs: [username, 'admin'],
    );
  }
  Future<Map<String, dynamic>?> getQuizById(int quizId) async {
    final db = await database;
    List<Map<String, dynamic>> result = await db.query(
      'quizzes',
      where: 'id = ?',
      whereArgs: [quizId],
      limit: 1,
    );
    return result.isNotEmpty ? result.first : null;
  }
  Future<int> addQuestion({
    required int quizId,
    required String questionText,
    required String option1,
    required String option2,
    required String option3,
    required String option4,
    required String correctAnswer,
  }) async {
    final db = await database;
    List<Map<String, dynamic>> quizExists = await db.query(
      'quizzes',
      where: 'id = ?',
      whereArgs: [quizId],
      limit: 1,
    );
    if(quizExists.isEmpty){
      return -1;
    }
    return await db.insert(
      'questions',
      {
        'quiz_id': quizId,
        'question_text': questionText,
        'op1': option1,
        'op2': option2,
        'op3': option3,
        'op4': option4,
        'correct_ans': correctAnswer,
      },
    );
  }
  Future<List<Map<String, dynamic>>> getQuestionsByQuizId(int quizId) async {
    final db = await database;
    return await db.query(
      'questions',
      where: 'quiz_id = ?',
      whereArgs: [quizId],
    );
  }
  Future<int> updateQuestion({
    required int questionId,
    required String questionText,
    required String option1,
    required String option2,
    required String option3,
    required String option4,
    required String correctAnswer,
  }) async {
    final db = await database;
    return await db.update(
      'questions',
      {
        'question_text': questionText,
        'op1': option1,
        'op2': option2,
        'op3': option3,
        'op4': option4,
        'correct_ans': correctAnswer,
      },
      where: 'id = ?',
      whereArgs: [questionId],
    );
  }
  Future<int> deleteQuestion(int questionId) async {
    final db = await database;
    return await db.delete(
      'questions',
      where: 'id = ?',
      whereArgs: [questionId],
    );
  }
  Future<void> insertAdminQuizHistory({
    required int quizId,
    required String title,
    required String category,
    required String adminName,
  }) async {
    final db = await database;
    String formattedDate = DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now());
    List<Map<String, dynamic>> existing = await db.query(
      'quiz_history',
      where: 'quiz_id = ? AND user_id IS NULL',
      whereArgs: [quizId],
    );
    if(existing.isEmpty){
      List<Map<String, dynamic>> countResult = await db.rawQuery(
          "SELECT COUNT(*) AS totalQuestions FROM questions WHERE quiz_id = ?",
          [quizId]
      );
      int totalQuestions = countResult.isNotEmpty ? countResult.first['totalQuestions'] as int : 0;
      await db.insert(
        'quiz_history',
        {
          'quiz_id': quizId,
          'title': title,
          'total': totalQuestions,
          'progress': 0,
          'date': formattedDate,
          'category': category.isNotEmpty ? category : 'Unknown',
          'user_id': null,
          'admin_name': adminName,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      print("Admin quiz recorded in history: $title with $totalQuestions questions.");
    } else {
      print("Admin quiz already exists in history, skipping insert.");
    }
  }
  Future<void> clearAdminQuizHistory(String adminName) async {
    final db = await database;
    await db.delete(
      'quiz_history',
      where: 'admin_name = ?',
      whereArgs: [adminName],
    );
  }
  Future<void> checkDatabaseColumns() async {
    final db = await database;
    List<Map<String, dynamic>> columns = await db.rawQuery("PRAGMA table_info(users)");
  }
  Future<void> manuallyLogInUser(int userId) async {
    final db = await database;
    await db.rawUpdate("UPDATE users SET is_logged_in = 1 WHERE id = ?", [userId]);
  }
  Future<void> insertUserQuizHistory({
    required int userId,
    required int quizId,
    required String title,
    required int totalQuestions,
    required int progress,
    required String category,
  }) async {
    final db = await database;
    String formattedDate = DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now());
    if(userId == 0 || userId == null){
      return;
    }
    List<Map<String, dynamic>> existing = await db.query(
      'quiz_history',
      where: 'quiz_id = ? AND user_id = ?',
      whereArgs: [quizId, userId],
    );
    if(existing.isNotEmpty){
      await db.update(
        'quiz_history',
        {
          'progress': progress,
          'date': formattedDate,
          'category': category.isNotEmpty ? category : existing.first['category'] ?? 'Unknown',
          'user_id': userId,
        },
        where: 'quiz_id = ? AND user_id = ?',
        whereArgs: [quizId, userId],
      );
      print("Updated quiz history for User ID: $userId, Quiz ID: $quizId, Progress: $progress");
    }else{
      await db.insert(
        'quiz_history',
        {
          'user_id': userId,
          'quiz_id': quizId,
          'title': title,
          'total': totalQuestions,
          'progress': progress,
          'date': formattedDate,
          'category': category.isNotEmpty ? category : 'Unknown',
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      print("Inserted new quiz history for User ID: $userId, Quiz ID: $quizId, Progress: $progress");
    }
  }
  Future<void> debugQuizHistory() async {
    final db = await database;
    List<Map<String, dynamic>> result = await db.rawQuery("SELECT * FROM quiz_history");
  }
  Future<void> deleteInvalidQuizHistory() async {
    final db = await database;
    await db.rawDelete("DELETE FROM quiz_history WHERE user_id IS NULL OR user_id = 0");
  }
  Future<void> checkQuizHistoryTable() async {
    final db = await database;
    List<Map<String, dynamic>> columns = await db.rawQuery("PRAGMA table_info(quiz_history)");
  }
  Future<void> deleteUserQuizHistory(int userId) async {
    final db = await database;
    await db.delete(
      'quiz_history',
      where: 'user_id = ?',
      whereArgs: [userId],
    );
  }
  Future<List<Map<String, dynamic>>> fetchAdminQuizHistory(String adminName) async {
    final db = await database;
    return await db.rawQuery('''
    SELECT 
      qh.quiz_id, 
      qh.title, 
      (SELECT COUNT(*) FROM questions WHERE questions.quiz_id = qh.quiz_id) AS total,
      qh.progress, 
      qh.date, 
      COALESCE(NULLIF(qh.category, ''), 'Unknown') AS category
      FROM quiz_history qh
      WHERE qh.admin_name = ?
      ORDER BY qh.date DESC
  ''',[adminName]);
  }
  Future<List<Map<String, dynamic>>> fetchUserQuizHistory(int userId) async {
    final db = await database;
    List<Map<String, dynamic>> result = await db.rawQuery(
        '''SELECT qh.quiz_id, qh.title, 
              (SELECT COUNT(*) FROM questions WHERE questions.quiz_id = qh.quiz_id) AS total,
              qh.progress, qh.date, 
              COALESCE(NULLIF(qh.category, ''), 'Unknown') AS category
              FROM quiz_history qh
              WHERE qh.user_id = ?
              ORDER BY qh.date DESC''',
        [userId]
    );
    return result;
  }
  Future<int> getLoggedInUserId() async {
    final db = await database;
    List<Map<String, dynamic>> result = await db.rawQuery(
        "SELECT id FROM users WHERE is_logged_in = 1 AND role = 'user' LIMIT 1"
    );
    if (result.isNotEmpty) {
      int userId = result.first['id'];
      return userId;
    } else {
      return 0;
    }
  }
  Future<int> getLoggedInAdminId() async {
    final db = await database;
    List<Map<String, dynamic>> result = await db.rawQuery(
        "SELECT id FROM users WHERE is_logged_in = 1 AND role = 'admin' LIMIT 1"
    );

    if (result.isNotEmpty) {
      int adminId = result.first['id'];
      return adminId;
    } else {
      return 0;
    }
  }
  Future<int> insertQuestionBank(String title, String adminName, String date, String filePath) async {
    final db = await database;
    return await db.insert(
      'question_banks',
      {
        'title': title,
        'author': adminName,
        'date': date,
        'file_path': filePath,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }
  Future<List<Map<String, dynamic>>> getQuestionBanks(String adminName) async {
    final db = await database;
    return await db.query(
      'question_banks',
      where: 'author = ?',
      whereArgs: [adminName],
    );
  }
  Future<List<Map<String, dynamic>>> getAllQuestionBanks() async {
    final db = await database;
    return await db.rawQuery('''
    SELECT * FROM question_banks
    ORDER BY id DESC
  ''');
  }
  Future<int> deleteQuestionBank(int id, String adminName) async {
    final db = await database;
    int result = await db.delete(
      'question_banks',
      where: 'id = ? AND author = ?',
      whereArgs: [id, adminName],
    );
    return result;
  }
  Future<void> updateUserProfileImage(String username, String? imagePath) async {
    final db = await instance.database;
    await db.update(
      'users',
      {'profile_image': imagePath},
      where: 'name = ? AND role = ?',
      whereArgs: [username, 'user'],
    );
  }
  Future<List<Map<String, dynamic>>> fetchAllQuizzes() async {
    final db = await database;
    return await db.rawQuery('''
    SELECT 
      quizzes.id, 
      quizzes.title, 
      quizzes.category, 
      quizzes.author, 
      COUNT(questions.id) AS total 
      FROM quizzes 
      LEFT JOIN questions ON quizzes.id = questions.quiz_id 
      GROUP BY quizzes.id
      ORDER BY quizzes.id DESC
    ''');
  }
  Future<void> updateQuizWithNewQuestions(int quizId, List<Map<String, dynamic>> newQuestions) async {
    final db = await database;
    await db.delete('questions', where: 'quiz_id = ?', whereArgs: [quizId]);
    for(var question in newQuestions){
      await db.insert('questions', {
        'quiz_id': quizId,
        'question_text': question['question_text'],
        'op1': question['op1'],
        'op2': question['op2'],
        'op3': question['op3'],
        'op4': question['op4'],
        'correct_ans': question['correct_ans'],
      });
    }
  }
  Future<String?> getUserProfileImage(String username) async {
    final db = await instance.database;
    List<Map<String, dynamic>> result = await db.query(
      'users',
      columns: ['profile_image'],
      where: 'name = ? AND role = ?',
      whereArgs: [username, 'user'],
    );
    if(result.isNotEmpty){
      return result.first['profile_image'] as String?;
    }
    return null;
  }
  Future<void> deleteUserProfileImage(String username) async {
    final db = await instance.database;
    await db.update(
      'users',
      {'profile_image': null},
      where: 'name = ? AND role = ?',
      whereArgs: [username, 'user'],
    );
  }
  Future<List<Map<String, dynamic>>> getUserById(int userId) async {
    final db = await database;
    return await db.query('users', where: 'id = ?', whereArgs: [userId], limit: 1);
  }
}