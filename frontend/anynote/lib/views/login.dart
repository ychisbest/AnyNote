import 'package:anynote/GlobalConfig.dart';
import 'package:anynote/main.dart';
import 'package:anynote/views/WideView/wideHome.dart';
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
  String _serverUrl = 'demo.anynote.online'; // 修改：添加默认值
  String _secret = '';
  String _protocol = 'https'; // 新增：默认协议

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

  void _handleProtocolChange(String? value) {
    setState(() {
      _protocol = value ?? 'https';
    });
  }

  void _handleSignIn() async {
    if (_formKey.currentState!.validate()) {
      String fullUrl = '$_protocol://$_serverUrl'; // 修改：组合完整URL
      controller.updateBaseUrl(fullUrl, _secret);
      var loginResult = await controller.login();
      if (loginResult['isLoginSuccess'] == true) {
        GlobalConfig.baseUrl = fullUrl;
        GlobalConfig.secretStr = _secret;
        GlobalConfig.isLoggedIn = true;
        Get.snackbar("success", "Login Success");
        Get.off(() => HomePage());
      } else {
        Get.snackbar('error', loginResult['errorContent']);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: Container(
            constraints: const BoxConstraints(
              maxWidth: 600,
            ),
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
                        height: 300,
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
                      Row(
                        children: [
                          Expanded(
                            flex: 1,
                            child: DropdownButtonFormField<String>(
                              value: _protocol,
                              decoration: InputDecoration(
                                contentPadding:
                                    const EdgeInsets.symmetric(horizontal: 12),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide:
                                      BorderSide(color: Colors.grey[300]!),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide:
                                      const BorderSide(color: Colors.blue),
                                ),
                              ),
                              items: ['http', 'https'].map((String value) {
                                return DropdownMenuItem<String>(
                                  value: value,
                                  child: Text(value),
                                );
                              }).toList(),
                              onChanged: _handleProtocolChange,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            flex: 5,
                            child: TextFormField(
                              //initialValue: _serverUrl, // 新增：设置初始值
                              decoration: InputDecoration(
                                labelText: 'Server URL',
                                prefixIcon: const Icon(Icons.cloud_outlined),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide:
                                      BorderSide(color: Colors.grey[300]!),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide:
                                      const BorderSide(color: Colors.blue),
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
                          ),
                        ],
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
      ),
    );
  }
}
