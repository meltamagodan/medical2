import 'dart:io';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:supermarket/pages/code.dart';
import 'package:supermarket/pages/market-login.dart';
import 'package:path_provider/path_provider.dart';
import 'package:window_manager/window_manager.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await EasyLocalization.ensureInitialized();
  await windowManager.ensureInitialized();
  runApp(
    EasyLocalization(
      supportedLocales: const [Locale('en'), Locale('ar'), Locale('tr')],
      path: 'assets/translations',
      fallbackLocale: const Locale('en'),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  Future<bool>? _activationFileExists;

  @override
  void initState() {
    super.initState();
    _activationFileExists = _getActivationFile();
  }

  Future<bool> _getActivationFile() async {
    try {
      final directory = await getApplicationSupportDirectory();
      final path = "${directory.path}/.a"; // Hidden file
      return await File(path).exists();
    } catch (e) {
      print("Error accessing the activation file: $e");
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      localizationsDelegates: context.localizationDelegates,
      supportedLocales: context.supportedLocales,
      locale: context.locale,
      home: FutureBuilder<bool>(
        future: _activationFileExists, // Use the Future stored in initState
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Colors.white)); // Loading indicator
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}')); // Handle errors
          } else if (snapshot.hasData) {
            bool isActivated = snapshot.data ?? false;
            return isActivated ? const MarketLoginPage() : const CodePage();
          } else {
            return const CodePage(); // Fallback to CodePage if there's no data
          }
        },
      ),
    );
  }
}

