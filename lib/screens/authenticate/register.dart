import 'package:flutter/material.dart';
import 'package:logk8s/services/auth.dart';
import 'package:email_validator/email_validator.dart';
import 'package:logk8s/shared/constants.dart';
import 'package:logk8s/shared/loading.dart';

class Register extends StatefulWidget {
  final Function? toggleView;

  const Register({Key? key, this.toggleView}) : super(key: key);

  @override
  _RegisterState createState() => _RegisterState();
}

class _RegisterState extends State<Register> {
  final AuthService _authService = AuthService();
  final _formKey = GlobalKey<FormState>();
  String email = '';
  String password = '';
  String error = '';
  bool loading = false;

  @override
  Widget build(BuildContext context) {
    return loading
        ? const Loading()
        : Scaffold(
            backgroundColor: Colors.brown[100],
            appBar: AppBar(
              backgroundColor: Colors.brown[400],
              elevation: 0.0,
              title: const Text('Sing up to logk8s'),
              actions: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  child: TextButton.icon(
                    onPressed: () {
                      widget.toggleView!();
                    },
                    icon: const Icon(Icons.person),
                    label: const Text('Sign in'),
                    style: ButtonStyle(
                      foregroundColor:
                          MaterialStateProperty.all<Color>(Colors.white),
                    ),
                  ),
                )
              ],
            ),
            body: Container(
              padding: const EdgeInsets.symmetric(vertical: 20.0, horizontal: 50.0),
              child: Column(
                children: [
                  Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        const SizedBox(height: 20.0),
                        TextFormField(
                          decoration: textInputDecoration(context, 'Email'),
                          validator: (value) => EmailValidator.validate(value!)
                              ? null
                              : 'invalid email',
                          onChanged: (value) => {
                            setState(() {
                              email = value;
                            })
                          },
                        ),
                        const SizedBox(height: 20.0),
                        TextFormField(
                          decoration: textInputDecoration(context, 'Password'),
                          validator: (value) => value!.length < 6
                              ? 'password shoud be at least 6 charecters long'
                              : null,
                          obscureText: true,
                          onChanged: (value) => {
                            setState(() {
                              password = value;
                            })
                          },
                        ),
                        const SizedBox(height: 20.0),
                        ElevatedButton(
                          onPressed: () async {
                            if (_formKey.currentState!.validate()) {
                              setState(() {
                                loading = true;
                              });
                              var result =
                                  await _authService.register(email, password);
                              if (result == null) {
                                setState(() {
                                  error = 'Failed to register';
                                  loading = false;
                                });
                              }
                            }
                          },
                          child: const Text('Sign up'),
                          style: ElevatedButton.styleFrom(
                            primary: Colors.brown[900], // background
                            onPrimary: Colors.white, // foreground
                          ),
                        ),
                        const SizedBox(
                          height: 10.0,
                        ),
                        Text(
                          error,
                          style:
                              TextStyle(color: Colors.red[900], fontSize: 14.0),
                        )
                      ],
                    ),
                  )
                ],
              ),
            ));
  }
}
