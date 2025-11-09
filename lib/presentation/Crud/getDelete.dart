import 'dart:convert';
import 'dart:developer' show log;
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:iot_app/presentation/Crud/addEditUser.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ------------------------------------------------------
// USERS PAGE (List + Delete + Navigate to Add/Edit Page)
// ------------------------------------------------------
class UsersDetails extends StatefulWidget {
  const UsersDetails({super.key});

  @override
  State<UsersDetails> createState() => _UsersDetailsState();
}

class _UsersDetailsState extends State<UsersDetails> {
  late Future<List<Map<String, dynamic>>> _futureUsers;

  @override
  void initState() {
    super.initState();
    _futureUsers = getUserData();
  }

Future<List<Map<String, dynamic>>> getUserData() async {
  final prefs = await SharedPreferences.getInstance();
  final userId = prefs.getInt('user_id') ?? 0;

  if (userId == 0) return [];

  final url = Uri.parse("http://192.168.43.2/api/getdata.php");
  final res = await http.post(url, body: {
    "user_id": userId.toString(),
  });

  if (res.statusCode == 200) {
    List data = jsonDecode(res.body);
    return data.map((e) => Map<String, dynamic>.from(e)).toList();
  } else {
    throw Exception("Failed to load data");
  }
}


Future<void> deleteUser(int? id) async {
  if (id == null) return;

  final prefs = await SharedPreferences.getInstance();
  final userId = prefs.getInt('user_id') ?? 0;
  if (userId == 0) return; // user not logged in

  final url = Uri.parse("http://192.168.43.2/api/deleteuser.php");
  final res = await http.post(url, body: {
    "id": id.toString(),
    "user_id": userId.toString(),
  });

  final data = res.body;
  if (data == "true") {
    log("User deleted successfully");
    setState(() {
      _futureUsers = getUserData(); // refresh list
    });
  } else if (data == "not_logged_in") {
    log("User not logged in");
  } else {
    log("Error deleting user: $data");
  }
}



  void _navigateToAddUser() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AddEditUserPage()),
    );
    if (result == true) {
      setState(() {
        _futureUsers = getUserData();
      });
    }
  }

  void _navigateToEditUser(Map<String, dynamic> user) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
          builder: (context) => AddEditUserPage(userData: user)),
    );
    if (result == true) {
      setState(() {
        _futureUsers = getUserData();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6),
      appBar: AppBar(
  title: Text("CRUD management"),
  centerTitle: true,
  actions: [
    PopupMenuButton<String>(
      icon: const Icon(Icons.more_vert, color: Colors.white),
      onSelected: (value) async {
        if (value == 'add') {
          _navigateToAddUser();
        } else if (value == 'logout') {
          // Show confirmation dialog
          final shouldLogout = await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text("Logout", style: TextStyle(color: Colors.pink)),
              content: const Text("Are you sure you want to logout?"),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text("Cancel", style: TextStyle(color: Colors.pink)),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text("Logout", style: TextStyle(color: Colors.pink)),
                ),
              ],
            ),
          );

          if (shouldLogout == true && context.mounted) {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setBool('isLoggedIn', false);
  Navigator.pushReplacementNamed(context, '/login');
}

        }
      },
      itemBuilder: (context) => [
        const PopupMenuItem(
          value: 'add',
          child: Row(
            children: [
              Icon(Icons.add, color: Colors.pink),
              SizedBox(width: 10),
              Text("Add User"),
            ],
          ),
        ),
        const PopupMenuItem(
          value: 'logout',
          child: Row(
            children: [
              Icon(Icons.logout, color: Colors.pink),
              SizedBox(width: 10),
              Text("Logout"),
            ],
          ),
        ),
      ],
    ),
  ],
),

      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _futureUsers,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            log("Error: ${snapshot.error}");
            return const Center(child: Text("Failed to load data"));
          } else if (snapshot.hasData && snapshot.data!.isNotEmpty) {
            final users = snapshot.data!;
            return ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: users.length,
              itemBuilder: (context, index) {
                final user = users[index];
                return Card(
                  elevation: 4,
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15)),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.pink.shade100,
                      child: const Icon(Icons.person, color: Colors.pink),
                    ),
                    title: Text(
                      user["name"] ?? "Unknown",
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    subtitle: Text(user["email"] ?? ""),
                    trailing: Wrap(
                      spacing: 10,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit, color: Colors.green),
                          onPressed: () => _navigateToEditUser(user),
                        ),
                        IconButton(
  icon: const Icon(Icons.delete, color: Colors.red),
  onPressed: () async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Colors.white,
        title: const Text("Delete User"),
        content: const Text("Are you sure you want to delete this user?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Cancel",style: TextStyle(color: Colors.black),),),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text("Delete",style: TextStyle(color: Colors.pink))),
        ],
      ),
    );
    if (confirm == true) {
      deleteUser(int.tryParse(user["id"].toString()));
    }
  },
),
                      ],
                    ),
                  ),
                );
              },
            );
          } else {
            return const Center(
              child: Text(
                "No users found.",
                style: TextStyle(fontSize: 16),
              ),
            );
          }
        },
      ),
    );
  }
}
