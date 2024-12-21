import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supermarket/pages/admin.dart';
import 'package:supermarket/pages/u_home.dart';
import 'package:supermarket/sql.dart';

class UserLoginPage extends StatefulWidget {
  final String name;

  const UserLoginPage({super.key, required this.name});

  @override
  State<UserLoginPage> createState() => _UserLoginPageState();
}

class _UserLoginPageState extends State<UserLoginPage> {
  final _formKey = GlobalKey<FormState>();
  late String _username;
  late String _password;
  bool loading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Text(
              widget.name,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 10,),
            TextButton(
              style: TextButton.styleFrom(
                  backgroundColor: Colors.white.withOpacity(0.05)
              ),
              onPressed: () {
                SQLService.deleteCredentials();
                Navigator.pop(context);
              },
              child: Text(
                "logout".tr(),
                style: const TextStyle(color: Colors.red),
              ),
            ),
          ],
        ),
        leading: const Icon(Icons.shopping_bag, color: Colors.white, size: 30,),
        backgroundColor: Colors.blueGrey[900],
        actions: [
          PopupMenuButton<Locale>(
            tooltip: "",
            icon: const Padding(
              padding: EdgeInsets.all(8.0),
              child: Icon(Icons.language, color: Colors.white),
            ),
            onSelected: (Locale newValue) {
              _formKey.currentState?.reset();
              context.setLocale(newValue); // Change app language
            },
            itemBuilder: (BuildContext context) {
              return [
                PopupMenuItem<Locale>(
                  value: const Locale('en'),
                  child: Text('English', style: TextStyle(color: Colors.blueGrey[700]),),
                ),
                PopupMenuItem<Locale>(
                  value: const Locale('tr'),
                  child: Text('Türkçe', style: TextStyle(color: Colors.blueGrey[700])),
                ),
                PopupMenuItem<Locale>(
                  value: const Locale('ar'),
                  child: Text('العربية', style: TextStyle(color: Colors.blueGrey[700])),
                ),
              ];
            },
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.blueGrey.shade900, // Starting color
              Colors.white, // Ending color
            ],
            begin: Alignment.topCenter, // Start position
            end: Alignment.bottomCenter, // End position
          ),
        ),
        child: Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 550),
            padding: const EdgeInsets.all(16.0),
            child: Card(
              elevation: 5,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Form(
                  key: _formKey,
                  child: SizedBox(
                    height: 330,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.person, color: Colors.blueGrey[600], size: 60,),
                            Text(
                              "utitle2".tr(),
                              style: const TextStyle(
                                fontSize: 40,
                                fontWeight: FontWeight.bold,
                                color: Colors.blueGrey,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 50),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 48.0),
                                child: TextFormField(
                                  inputFormatters: [
                                    FilteringTextInputFormatter.deny(RegExp(r'\s')), // Deny spaces
                                  ],
                                  cursorColor: Colors.blueGrey[600],
                                  decoration: InputDecoration(
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10),
                                      borderSide: const BorderSide(
                                        color: Colors.blueGrey,
                                        width: 3,
                                      ),
                                    ),
                                    hintText: 'uhintText1'.tr(),
                                  ),
                                  validator: (value) =>
                                  value!.isEmpty ? 'uerror1'.tr() : null,
                                  onSaved: (value) => _username = value!,
                                ),
                              ),
                            ),

                          ],
                        ),
                        const SizedBox(height: 10),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 48.0),
                                child: TextFormField(
                                  obscureText: true,
                                  cursorColor: Colors.blueGrey[600],
                                  decoration: InputDecoration(
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10),
                                      borderSide: const BorderSide(
                                        color: Colors.blueGrey,
                                        width: 3,
                                      ),
                                    ),
                                    hintText: 'uhintText2'.tr(),
                                  ),
                                  validator: (value) =>
                                  value!.isEmpty ? 'uerror2'.tr() : null,
                                  onSaved: (value) => _password = value!,
                                ),
                              ),
                            ),

                          ],
                        ),
                        const SizedBox(height: 20),
                        Center(
                          child: ElevatedButton(
                            onPressed: _login,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blueGrey[700],
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 20, vertical: 10),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: loading ? const CircularProgressIndicator(color: Colors.white,) : Text(
                                'login'.tr(),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
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
        ),
      ),
    );
  }

  Future<void> _login() async {
    if (!loading) {
      if (_formKey.currentState!.validate()) {
        _formKey.currentState!.save();
        setState(() {
          loading = true;
        });
        String res = "";
        try{
          res = await SQLService.userLogin(username: _username.toLowerCase().replaceAll(" ", ""), pass: _password);
        } catch (e) {
          showDialog(
            context: context,
            
            builder: (BuildContext context) {
              return AlertDialog(
                title: Text(
                  'conn'.tr(),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.red,
                  ),
                ),
                content: Text(
                  'poor'.tr(),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                actions: <Widget>[
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueGrey[700],
                    ),
                    child: Text('cdialogyes'.tr(), style: const TextStyle(color: Colors.white)), // Customize button style
                    onPressed: () {
                      Navigator.of(context).pop(); // Close the dialog
                    },
                  ),
                ],
              );
            },
          );
          setState(() {
            loading = false;
          });
          return;
        }
        setState(() {
          loading = false;
        });

        if (res.isNotEmpty) {
          _formKey.currentState?.reset();
          if (int.parse(res) >= 4) {
            SQLService.botSendMessage("🔷 Admin _`${_username.toUpperCase()}`_ logged In.");
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) =>
                    AdminHome(
                      name: _username.toUpperCase().replaceAll(" ", ""),
                      level: int.parse(res),
                    ),
              ),
            );
          } else {
            SQLService.botSendMessage("🟢 User _`${_username.toUpperCase()}`_ logged In.");
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) =>
                    UserHome(
                      name: _username.toUpperCase().replaceAll(" ", ""),
                      level: res,
                    ),
              ),
            );
          }
        } else {
          showDialog(
            context: context,
             // User must tap button to dismiss
            builder: (BuildContext context) {
              return AlertDialog(
                title: Text(
                  'lfailed'.tr(),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.red, // Customize the color
                  ),
                ),
                content: Text(
                  'lfailed2'.tr(),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                actions: <Widget>[
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueGrey[700],
                    ),
                    child: Text('cdialogyes'.tr(), style: const TextStyle(color: Colors.white)), // Customize button style
                    onPressed: () {
                      Navigator.of(context).pop(); // Close the dialog
                    },
                  ),
                ],
              );
            },
          );
        }
      }
    }
  }
}
