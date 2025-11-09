import 'dart:developer' show log;
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart'; // for formatting dates

class AddEditUserPage extends StatefulWidget {
  final Map<String, dynamic>? userData;
  const AddEditUserPage({super.key, this.userData});

  @override
  State<AddEditUserPage> createState() => _AddEditUserPageState();
}

class _AddEditUserPageState extends State<AddEditUserPage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _dobController;
  late TextEditingController _ageController;
  bool _isSaving = false;

  bool get isEditMode => widget.userData != null;

  @override
  void initState() {
    super.initState();
    _nameController =
        TextEditingController(text: widget.userData?["name"] ?? "");
    _ageController =
        TextEditingController(text: widget.userData?["age"] ?? "");
    _dobController =
        TextEditingController(text: widget.userData?["dob"] ?? "");
    _emailController =
        TextEditingController(text: widget.userData?["email"] ?? "");
  }

Future<void> _saveUser() async {
  if (!_formKey.currentState!.validate()) return;
  setState(() => _isSaving = true);

  try {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getInt('user_id') ?? 0;

    if (userId == 0) {
      log("User not logged in");
      return;
    }

    final url = Uri.parse(isEditMode
        ? "http://192.168.43.2/api/updateuser.php"
        : "http://192.168.43.2/api/adduser.php");

    final body = isEditMode
        ? {
            "user_id": userId.toString(),
            "id": widget.userData!["id"].toString(),
            "name": _nameController.text,
            "email": _emailController.text,
            "dob": _dobController.text,
            "age": _ageController.text
          }
        : {
            "user_id": userId.toString(),
            "name": _nameController.text,
            "email": _emailController.text,
            "dob": _dobController.text,
            "age": _ageController.text
          };

    final res = await http.post(url, body: body);
    var data = res.body;
    if (data == "true") {
      if (mounted) Navigator.pop(context, true);
    } else {
      log("Error inserting/updating data: $data");
    }
  } catch (e) {
    log("Error saving user: $e");
  } finally {
    setState(() => _isSaving = false);
  }
}

  // Reusable TextFormField builder
  Widget textInputField(
      String label, TextEditingController controller, IconData icon,
      {TextInputType keyboardType = TextInputType.text,
      String? Function(String?)? validator,
      VoidCallback? onTap,
      bool readOnly = false}) {
    return TextFormField(
      controller: controller,
      cursorColor: Colors.pink,
      readOnly: readOnly,
      onTap: onTap,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.pink)),
        disabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.black)) ,
        prefixIcon: Icon(icon,color: Colors.pink,),
        border: OutlineInputBorder(borderSide: BorderSide(color: Colors.pink)),
      ),
      validator: validator ??
          (value) => value!.isEmpty ? "Please enter a $label" : null,
    );
  }

Future<void> _selectDate() async {
  DateTime initialDate = DateTime.tryParse(_dobController.text) ??
      DateTime.now().subtract(const Duration(days: 365 * 18));

  final DateTime? picked = await showDatePicker(
    context: context,
    initialDate: initialDate,
    firstDate: DateTime(1950),
    lastDate: DateTime.now(),
    helpText: 'Select Date of Birth',
    builder: (context, child) {
      return Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(
            primary: Colors.pink,        // header background color
            onPrimary: Colors.white,     // header text color
          ), // calendar background
          textButtonTheme: TextButtonThemeData(
            style: TextButton.styleFrom(
              foregroundColor: Colors.pink, // "OK"/"CANCEL" buttons
            ),
          ), dialogTheme: DialogThemeData(backgroundColor: Colors.white),
        ),
        child: child!,
      );
    },
  );

  if (picked != null) {
    setState(() {
      _dobController.text = DateFormat('dd/MM/yyy').format(picked);
    });
  }
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6),
      appBar: AppBar(
        title: Text(isEditMode ? "Edit User" : "Add User"),
        leading: IconButton(onPressed: ()=>Navigator.of(context).pop(), icon: Icon(Icons.arrow_back)),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Center(
          child: Card(
            elevation: 6,
            shadowColor:Colors.grey,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    textInputField("Name", _nameController, Icons.person),
                    const SizedBox(height: 16),

                    // Email with format validation
                    textInputField("Email", _emailController,
                        Icons.email_outlined, keyboardType: TextInputType.emailAddress,
                        validator: (value) {
                      if (value == null || value.isEmpty) {
                        return "Please enter an email";
                      }
                      final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+');
                      if (!emailRegex.hasMatch(value)) {
                        return "Enter a valid email address";
                      }
                      return null;
                    }),
                    const SizedBox(height: 16),

                    // Age only numbers
                    textInputField("Age", _ageController, Icons.numbers,
                        keyboardType: TextInputType.number,
                        validator: (value) {
                      if (value == null || value.isEmpty) {
                        return "Please enter age";
                      }
                      if (int.tryParse(value) == null) {
                        return "Age must be a number";
                      }
                      return null;
                    }),
                    const SizedBox(height: 16),

                    // DOB picker
                    textInputField("Date of Birth", _dobController,
                        Icons.calendar_month,
                        readOnly: true, onTap: _selectDate),
                    const SizedBox(height: 25),

                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton.icon(
                        onPressed: _isSaving ? null : _saveUser,
                        icon: Icon(
                          isEditMode ? Icons.done : Icons.add,
                          color: Colors.white,
                        ),
                        label: Text(
                          _isSaving
                              ? "Saving..."
                              : isEditMode
                                  ? "Update User"
                                  : "Add User",
                          style: const TextStyle(
                              fontSize: 16, color: Colors.white),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.pink,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
