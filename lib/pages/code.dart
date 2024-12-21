import 'dart:io';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:supermarket/pages/market-login.dart';
import 'package:supermarket/sql.dart';

class CodePage extends StatefulWidget {
  const CodePage({super.key});

  @override
  State<CodePage> createState() => _CodePageState();
}

class _CodePageState extends State<CodePage> {
  final _formKey = GlobalKey<FormState>();
  late String _marketName;
  bool check = false;
  bool loading = false;


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[600],
      appBar: AppBar(
        title: Text(
          'atitle'.tr(),
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        leading: const Icon(
          Icons.lock,
          color: Colors.white,
          size: 30,
        ),
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
                  child: Text(
                    'English',
                    style: TextStyle(color: Colors.blueGrey[700]),
                  ),
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
          child: check
              ? const CircularProgressIndicator(color: Colors.white,)
              : Container(
            constraints: const BoxConstraints(maxWidth: 600),
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
                    height: 250,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Center(
                          child: Text(
                            "atitle2".tr(),
                            style: const TextStyle(
                              fontSize: 40,
                              fontWeight: FontWeight.bold,
                              color: Colors.blueGrey,
                            ),
                          ),
                        ),
                        const SizedBox(height: 50),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 58.0),
                          child: TextFormField(
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
                              hintText: 'ahintText1'.tr(),
                            ),
                            validator: (value) => value!.isEmpty ? 'ahintText2'.tr() : null,
                            onSaved: (value) => _marketName = value!,
                          ),
                        ),
                        const SizedBox(height: 20),
                        Center(
                          child: ElevatedButton(
                            onPressed: _login,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blueGrey[700],
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: loading ? const CircularProgressIndicator(color: Colors.white,) :  Text(
                                'activate'.tr(),
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
    if(!loading) {
      if (_formKey.currentState!.validate()) {
        _formKey.currentState!.save();
        setState(() {
          loading = true;
        });
        bool res = false;
        try{
          res = await SQLService.checkCode(_marketName.toLowerCase().replaceAll(" ", ""));
        } catch (e) {
          showDialog(
            context: context,
            barrierDismissible: false,
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
        if (res) {
          createActivationFile();
          Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => const MarketLoginPage()),
          );
        } else {
          showDialog(
            context: context,
            barrierDismissible: false, // User must tap button to dismiss
            builder: (BuildContext context) {
              return AlertDialog(
                title: Text(
                  'afailed'.tr(),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.red, // Customize the color
                  ),
                ),
                content: Text(
                  'afailed2'.tr(),
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
  Future<void> createActivationFile() async {
    try {
      final directory = await getApplicationSupportDirectory();
      final path = "${directory.path}/.a";

      final File activationFile = File(path);
      await activationFile.create();

    } catch (e) {
      print("Error creating activation file: $e");
    }
  }
}
