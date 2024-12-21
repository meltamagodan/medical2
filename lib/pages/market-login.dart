import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supermarket/pages/user-login.dart';
import 'package:supermarket/sql.dart';

class MarketLoginPage extends StatefulWidget {
  const MarketLoginPage({super.key});

  @override
  State<MarketLoginPage> createState() => _MarketLoginPageState();
}

class _MarketLoginPageState extends State<MarketLoginPage> {
  final _formKey = GlobalKey<FormState>();
  late String _marketName;
  late String _password;
  bool check = true;
  bool loading = false;

  @override
  void initState() {
    checkMarket();
    super.initState();
  }

  Future<void> checkMarket() async {
    final data = await SQLService.retrieveCredentials();

    if (data.isNotEmpty) {
      String res = "";
      try {
        res = await SQLService.marketLogin(name: data[1]??"".toLowerCase().replaceAll(" ", ""), pass: data[2]??"");
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
          check = false;
        });
        return;
      }
      if (res.isNotEmpty) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => UserLoginPage(
              name: res,
            ),
          ),
        );
      } else {
        showDialog(
          context: context,
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
        setState(() {
          check = false;
        });
        return;
      }
      await Future.delayed(const Duration(seconds: 1));
      setState(() {
        check = false;
      });
    } else {
      setState(() {
        check = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[600],
      appBar: AppBar(
        title: Text(
          'mtitle'.tr(),
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        leading: const Icon(
          Icons.shopping_bag,
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
          child: check
              ? const CircularProgressIndicator(
                  color: Colors.white,
                )
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
                          height: 330,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Center(
                                child: Text(
                                  "mtitle2".tr(),
                                  style: const TextStyle(
                                    fontSize: 40,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blueGrey,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 50),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 58.0),
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
                                          hintText: 'mhintText1'.tr(),
                                        ),
                                        validator: (value) => value!.isEmpty ? 'merror1'.tr() : null,
                                        onSaved: (value) => _marketName = value!,
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
                                      padding: const EdgeInsets.symmetric(horizontal: 58.0),
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
                                          hintText: 'mhintText2'.tr(),
                                        ),
                                        validator: (value) => value!.isEmpty ? 'merror2'.tr() : null,
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
                                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: loading
                                        ? const CircularProgressIndicator(
                                            color: Colors.white,
                                          )
                                        : Text(
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
        try {
          res = await SQLService.marketLogin(name: _marketName.toLowerCase().replaceAll(" ", ""), pass: _password);
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
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => UserLoginPage(
                name: res,
              ),
            ),
          );
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
