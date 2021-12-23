import 'package:flutter/material.dart';
import 'package:logk8s/services/auth.dart';
import 'package:email_validator/email_validator.dart';
import 'package:logk8s/shared/constants.dart';
import 'package:logk8s/shared/loading.dart';

class SignIn extends StatefulWidget {
  final Function toggleView;
  const SignIn({Key? key, required this.toggleView}) : super(key: key);

  @override
  _SignInState createState() => _SignInState();
}

class _SignInState extends State<SignIn> {
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
            //backgroundColor: Colors.brown[100],
            appBar: AppBar(
              //backgroundColor: Colors.brown[400],
              elevation: 0.0,
              title: const Text('Sign in'),
              actions: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  child: TextButton.icon(
                    onPressed: () {
                      widget.toggleView();
                    },
                    icon: const Icon(Icons.person),
                    label: const Text('Register'),
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
                  ElevatedButton(
                    child: const Text('Sign in Anonimously'),
                    onPressed: () async {
                      debugPrint('Sign in anonimously pressed');
                      dynamic res = await _authService.signInAnon();
                      if (res == null) {
                        debugPrint('error signing in');
                      } else {
                        debugPrint('siged in');
                        debugPrint(res.uid);
                      }
                    },
                  ),
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
                              ? 'password shouh be at least 6 charectures'
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
                                  await _authService.signIn(email, password);
                              if (result == null) {
                                setState(() {
                                  error = 'Failed to sign in';
                                  loading = false;
                                });
                              }
                            }
                          },
                          child: const Text('Sign in'),
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
