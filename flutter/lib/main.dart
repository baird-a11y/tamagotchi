import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'dart:convert';
import 'package:universal_html/html.dart' as web;
import 'dart:async';
import 'package:flutter/animation.dart';

// Nur für mobile/Desktop-Plattformen verwenden wir dart:io
import 'dart:io' if (dart.library.io) 'dart:io';

void main() {
  runApp(ToDoTamagotchiApp());
}

class ToDoTamagotchiApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        fontFamily: 'NotoSans',
      ),
      home: ToDoTamagotchiScreen(),
    );
  }
}

class ToDoTamagotchiScreen extends StatefulWidget {
  @override
  _ToDoTamagotchiScreenState createState() => _ToDoTamagotchiScreenState();
}

class _ToDoTamagotchiScreenState extends State<ToDoTamagotchiScreen> with SingleTickerProviderStateMixin {
  List<Map<String, dynamic>> tasks = [];
  int completedTasks = 0;
  String tamagotchiName = "";
  String selectedTamagotchi = "";
  List<String> tamagotchiFrames = [
    'assets/tamagotchis/Slime_Idle1.png',
    'assets/tamagotchis/Slime_Idle2.png',
    'assets/tamagotchis/Slime_Idle3.png',
    'assets/tamagotchis/Slime_Idle4.png',
  ];
  int currentFrame = 0;
  Timer? animationTimer;
  late AnimationController _jumpController;
  late Animation<double> _jumpAnimation;

  @override
  void initState() {
    super.initState();
    _loadProfile();
    _startAnimation();
    _jumpController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 300),
    );
    _jumpAnimation = Tween<double>(begin: 0, end: -20).animate(
      CurvedAnimation(parent: _jumpController, curve: Curves.easeOut),
    );
  }

  void _startAnimation() {
    animationTimer = Timer.periodic(Duration(milliseconds: 300), (timer) {
      setState(() {
        currentFrame = (currentFrame + 1) % tamagotchiFrames.length;
      });
    });
  }

  void _jumpTamagotchi() {
    _jumpController.forward().then((_) => _jumpController.reverse());
  }

  @override
  void dispose() {
    animationTimer?.cancel();
    _jumpController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(tamagotchiName.isNotEmpty ? tamagotchiName : "Slime", style: TextStyle(fontFamily: 'NotoSans'))),
      body: Column(
        children: [
          SizedBox(height: 20),
          AnimatedBuilder(
            animation: _jumpAnimation,
            builder: (context, child) {
              return Transform.translate(
                offset: Offset(0, _jumpAnimation.value),
                child: child,
              );
            },
            child: Image.asset(tamagotchiFrames[currentFrame], height: 150),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: tasks.length,
              itemBuilder: (context, index) {
                return ListTile(
                  leading: Checkbox(
                    value: tasks[index]['done'],
                    onChanged: (value) {
                      setState(() {
                        tasks[index]['done'] = value;
                        _saveProfile();
                      });
                      _jumpTamagotchi();
                    },
                  ),
                  title: Text(tasks[index]['title'], style: TextStyle(fontFamily: 'NotoSans')),
                  trailing: IconButton(
                    icon: Icon(Icons.delete),
                    onPressed: () {
                      setState(() {
                        tasks.removeAt(index);
                        _saveProfile();
                      });
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        child: Icon(Icons.add),
        onPressed: () {
          showDialog(
            context: context,
            builder: (context) {
              String newTask = "";
              return AlertDialog(
                title: Text('Neue Aufgabe hinzufügen', style: TextStyle(fontFamily: 'NotoSans')),
                content: TextField(
                  onChanged: (value) => newTask = value,
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text('Abbrechen', style: TextStyle(fontFamily: 'NotoSans')),
                  ),
                  TextButton(
                    onPressed: () {
                      if (newTask.isNotEmpty) {
                        setState(() {
                          tasks.add({'title': newTask, 'done': false});
                        });
                        _saveProfile();
                      }
                      Navigator.pop(context);
                    },
                    child: Text('Hinzufügen', style: TextStyle(fontFamily: 'NotoSans')),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _loadProfile() async {
    if (kIsWeb) {
      String? storedProfile = web.window.localStorage['profile'];
      print("[DEBUG] Loading profile from Web: $storedProfile");
      if (storedProfile != null) {
        Map<String, dynamic> profileData = json.decode(storedProfile);
        setState(() {
          tamagotchiName = profileData['tamagotchiName'] ?? "";
          selectedTamagotchi = profileData['selectedTamagotchi'] ?? "";
          tasks = List<Map<String, dynamic>>.from(profileData['tasks'] ?? []);
          completedTasks = tasks.where((task) => task['done']).length;
        });
      }
    }
  }

  Future<void> _saveProfile() async {
    Map<String, dynamic> profileData = {
      'tamagotchiName': tamagotchiName,
      'selectedTamagotchi': selectedTamagotchi,
      'tasks': tasks,
    };
    String encodedProfile = json.encode(profileData);
    print("[DEBUG] Saving profile: $encodedProfile");
    if (kIsWeb) {
      web.window.localStorage['profile'] = encodedProfile;
    }
  }
}
