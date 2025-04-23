import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../models/user_model.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({Key? key}) : super(key: key);

  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final _formKey = GlobalKey<FormState>();

  String? _name;
  String? _gender;
  DateTime? _dateOfBirth;
  String? _wonder;

  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    UserModel? user = await authService.getUserData();

    if (user != null) {
      setState(() {
        _name = user.name;
        _gender = user.gender;
        _dateOfBirth = user.dateOfBirth;
        _wonder = user.wonder;
        _isLoading = false;
      });
    } else {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _saveProfile() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      setState(() {
        _isSaving = true;
      });

      try {
        final authService = Provider.of<AuthService>(context, listen: false);
        await authService.updateUserProfile(
          name: _name,
          gender: _gender,
          dateOfBirth: _dateOfBirth,
          wonder: _wonder,
        );

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Profile updated successfully!')),
        );
      } catch (e) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error updating profile: $e')));
      } finally {
        if (mounted) {
          setState(() {
            _isSaving = false;
          });
        }
      }
    }
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _dateOfBirth ?? DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            primaryColor: Colors.blue,
            colorScheme: ColorScheme.light(primary: Colors.blue),
            buttonTheme: ButtonThemeData(textTheme: ButtonTextTheme.primary),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != _dateOfBirth) {
      setState(() {
        _dateOfBirth = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('My Profile'),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.blue, Colors.cyanAccent],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            colors: [
              Color.fromARGB(255, 255, 136, 25),
              Color.fromARGB(255, 206, 228, 12),
            ],
            radius: 3.0,
            center: Alignment(-2.0, -1.0),
          ),
        ),
        child:
            _isLoading
                ? Center(child: CircularProgressIndicator())
                : SingleChildScrollView(
                  padding: EdgeInsets.all(20),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Center(
                          child: CircleAvatar(
                            radius: 50,
                            backgroundColor: Colors.white,
                            child: Icon(
                              Icons.person,
                              size: 70,
                              color: Colors.blue,
                            ),
                          ),
                        ),
                        SizedBox(height: 20),
                        Center(
                          child: Text(
                            authService.currentUser?.email ?? '',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        SizedBox(height: 30),
                        Card(
                          elevation: 5,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                          child: Padding(
                            padding: EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Your Information',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Divider(),
                                SizedBox(height: 10),
                                TextFormField(
                                  initialValue: _name,
                                  decoration: InputDecoration(
                                    labelText: 'Full Name',
                                    border: OutlineInputBorder(),
                                    prefixIcon: Icon(Icons.person),
                                  ),
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Please enter your name';
                                    }
                                    return null;
                                  },
                                  onSaved: (value) => _name = value,
                                ),
                                SizedBox(height: 16),
                                DropdownButtonFormField<String>(
                                  value: _gender,
                                  decoration: InputDecoration(
                                    labelText: 'Gender',
                                    border: OutlineInputBorder(),
                                    prefixIcon: Icon(Icons.people),
                                  ),
                                  items:
                                      ['Male', 'Female', 'Other']
                                          .map(
                                            (gender) => DropdownMenuItem(
                                              value: gender,
                                              child: Text(gender),
                                            ),
                                          )
                                          .toList(),
                                  onChanged: (value) {
                                    setState(() {
                                      _gender = value;
                                    });
                                  },
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Please select your gender';
                                    }
                                    return null;
                                  },
                                ),
                                SizedBox(height: 16),
                                GestureDetector(
                                  onTap: _selectDate,
                                  child: AbsorbPointer(
                                    child: TextFormField(
                                      decoration: InputDecoration(
                                        labelText: 'Date of Birth',
                                        border: OutlineInputBorder(),
                                        prefixIcon: Icon(Icons.calendar_today),
                                      ),
                                      controller: TextEditingController(
                                        text:
                                            _dateOfBirth == null
                                                ? ''
                                                : DateFormat(
                                                  'yyyy-MM-dd',
                                                ).format(_dateOfBirth!),
                                      ),
                                      validator: (value) {
                                        if (_dateOfBirth == null) {
                                          return 'Please select your date of birth';
                                        }
                                        return null;
                                      },
                                    ),
                                  ),
                                ),
                                SizedBox(height: 30),
                                Text(
                                  'Your Life Wonder',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Divider(),
                                SizedBox(height: 10),
                                TextFormField(
                                  initialValue: _wonder,
                                  decoration: InputDecoration(
                                    labelText:
                                        'Something you want to do in life',
                                    border: OutlineInputBorder(),
                                    prefixIcon: Icon(Icons.celebration),
                                    hintText:
                                        'e.g., Visit the Grand Canyon, Learn to fly a plane',
                                  ),
                                  maxLines: 3,
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Please share your wonder';
                                    }
                                    return null;
                                  },
                                  onSaved: (value) => _wonder = value,
                                ),
                              ],
                            ),
                          ),
                        ),
                        SizedBox(height: 30),
                        Center(
                          child: ElevatedButton(
                            onPressed: _isSaving ? null : _saveProfile,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue,
                              padding: EdgeInsets.symmetric(
                                horizontal: 40,
                                vertical: 15,
                              ),
                              textStyle: TextStyle(fontSize: 18),
                            ),
                            child:
                                _isSaving
                                    ? CircularProgressIndicator(
                                      color: Colors.white,
                                    )
                                    : Text('Save Profile'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
      ),
    );
  }
}
