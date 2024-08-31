import 'package:anynote/GlobalConfig.dart';
import 'package:anynote/main.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart';
import '../MainController.dart';

class LoginPage extends StatefulWidget {
  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  MainController controller = Get.find<MainController>();
  final _formKey = GlobalKey<FormState>();
  String _serverUrl = '';
  String _secret = '';

  void _handleServerUrlChange(String value) {
    setState(() {
      _serverUrl = value;
    });
  }

  void _handleSecretChange(String value) {
    setState(() {
      _secret = value;
    });
  }

  void _handleSignIn() async {
    if (_formKey.currentState!.validate()) {
      controller.updateBaseUrl(_serverUrl, _secret);
      if (await controller.login()) {
        GlobalConfig.baseUrl = _serverUrl;
        GlobalConfig.secretStr = _secret;
        GlobalConfig.isLoggedIn = true;
        Get.snackbar("success", "登录成功");
        Get.off(() => const HomePage());
      } else {
        print("login failed");
        Get.snackbar('错误', '登录失败，请检查网络连接');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    Image.asset(
                      'assets/Logo.png',
                      width: 160,
                      height: 160,
                    ),
                    const SizedBox(height: 48),
                    const Text(
                      'AnyNote',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Capture ideas anytime, anywhere 💡',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 48),
                    TextFormField(
                      decoration: InputDecoration(
                        labelText: 'Server URL',
                        prefixIcon: const Icon(Icons.cloud_outlined),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey[300]!),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Colors.blue),
                        ),
                      ),
                      onChanged: _handleServerUrlChange,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter a server URL';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      obscureText: true,
                      decoration: InputDecoration(
                        labelText: 'Secret',
                        prefixIcon: const Icon(Icons.lock_outline),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey[300]!),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Colors.blue),
                        ),
                      ),
                      onChanged: _handleSecretChange,
                    ),
                    const SizedBox(height: 24),
                    // Row(
                    //   children: [
                    //     Checkbox(
                    //       value: _rememberMe,
                    //       onChanged: _handleRememberMeChange,
                    //       activeColor: Colors.blue,
                    //     ),
                    //     const Text('Remember me'),
                    //   ],
                    // ),
                    // const SizedBox(height: 24),
                    MaterialButton(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      onPressed: _handleSignIn,
                      child: const Text(
                        'Sign In',
                        style: TextStyle(fontSize: 18),
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
