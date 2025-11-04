import 'dart:io';
import 'package:chat_app_cld/cld%20chat/chat_app_01/Screens/MainScreen.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../AuthServices/authSyncService.dart'; // ✅ new import

class AuthScreen extends StatefulWidget {
  @override
  _AuthScreenState createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _displayNameController = TextEditingController();

  bool _isLogin = true;
  bool _isLoading = false;
  File? _selectedImage;

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() => _selectedImage = File(pickedFile.path));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_isLogin ? 'Login' : 'Sign Up')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (!_isLogin) ...[
                  GestureDetector(
                    onTap: _pickImage,
                    child: CircleAvatar(
                      radius: 45,
                      backgroundColor: Colors.grey[300],
                      backgroundImage:
                      _selectedImage != null ? FileImage(_selectedImage!) : null,
                      child: _selectedImage == null
                          ? const Icon(Icons.camera_alt, size: 35, color: Colors.grey)
                          : null,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _displayNameController,
                    decoration: const InputDecoration(labelText: 'Display Name'),
                    validator: (value) {
                      if (!_isLogin && (value == null || value.isEmpty)) {
                        return 'Please enter a display name';
                      }
                      return null;
                    },
                  ),
                ],
                const SizedBox(height: 16),
                TextFormField(
                  controller: _emailController,
                  decoration: const InputDecoration(labelText: 'Email'),
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) =>
                  value == null || value.isEmpty ? 'Please enter an email' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _passwordController,
                  decoration: const InputDecoration(labelText: 'Password'),
                  obscureText: true,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a password';
                    }
                    if (value.length < 6) {
                      return 'Password must be at least 6 characters';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),
                _isLoading
                    ? const CircularProgressIndicator()
                    : ElevatedButton(
                  onPressed: _handleAuth,
                  child: Text(_isLogin ? 'Login' : 'Sign Up'),
                ),
                TextButton(
                  onPressed: () => setState(() => _isLogin = !_isLogin),
                  child: Text(_isLogin
                      ? 'Don\'t have an account? Sign up'
                      : 'Already have an account? Login'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _handleAuth() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final authService = Provider.of<AuthSyncService>(context, listen: false); // ✅ use new service
    String? error;

    if (_isLogin) {
      error = await authService.syncSignIn(
        _emailController.text.trim(),
        _passwordController.text.trim(),
      );
      if(error==null){
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (context)=>MainScreen()));
      }
    } else {
      error = await authService.syncSignUp(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
        displayName: _displayNameController.text.trim(),
        profileImage: _selectedImage,
      );
      if(error==null){
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (context)=>MainScreen()));
      }
    }

    setState(() => _isLoading = false);

    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error)),
      );
    } else {
      Navigator.pushReplacementNamed(context, '/mainScreen');
    }
  }
}
