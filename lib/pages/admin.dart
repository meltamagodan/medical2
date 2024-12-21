import 'dart:io';

import 'package:collection/collection.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supermarket/pages/products.dart';
import 'package:supermarket/pages/users.dart';
import 'package:supermarket/sql.dart';
import 'package:window_manager/window_manager.dart';

import 'history.dart';

class AdminHome extends StatefulWidget {
  final String name;
  final int level;

  const AdminHome({super.key, required this.name, required this.level});

  @override
  State<AdminHome> createState() => _AdminHomeState();
}

class _AdminHomeState extends State<AdminHome> with WindowListener {
  List<Map<String, dynamic>> soldProducts = [];
  bool isLoading = true;
  DateTime? startDate;
  DateTime? endDate;
  bool nopoints = false;

  @override
  void initState() {
    super.initState();
    loadC();
    WindowManager.instance.setPreventClose(true);
    WindowManager.instance.addListener(this);
    DateTime now = DateTime.now();
    startDate = DateTime(now.year, now.month, 1);
    endDate = now;

    loadSoldProductsInRange(startDate!, endDate!);
  }


  Future<void> loadC() async {
    final file = File('receipt_title.txt');
    String string = await file.readAsString();
    List<String> data = string.split("\n");

    setState(() {
      nopoints = bool.parse(data[3]);
    });
  }

  @override
  void dispose() {
    WindowManager.instance.removeListener(this);
    super.dispose();
  }

  @override
  Future<void> onWindowClose() async {
    await SQLService.botSendMessage("🔻 Admin _`${widget.name}`_ logged out.");
    exit(0);
  }

  void _showDateRangePicker(BuildContext context) {
    showDateRangePicker(
      context: context,
      firstDate: DateTime(2024),
      lastDate: DateTime.now(),
      builder: (BuildContext context, Widget? child) {
        return Theme(
          data: ThemeData(
            colorScheme: ColorScheme.light(
              primary: Colors.blueGrey[900]!, // Header background color
              onPrimary: Colors.white, // Header text color
              onSurface: Colors.blueGrey[900]!, // Body text color
            ),
            dialogBackgroundColor: Colors.white, // Background color of the picker
          ),
          child: child!,
        );
      },
    ).then((pickedRange) {
      if (pickedRange != null) {
        setState(() {
          startDate = pickedRange.start;
          endDate = pickedRange.end;
        });
        loadSoldProductsInRange(startDate!, endDate!);
      }
    });
  }

  Future<void> _showSettingsDialog() async {
    final file = File('receipt_title.txt');
    String string = await file.readAsString();
    List<String> data = string.split("\n");
    TextEditingController controller = TextEditingController(text: data[0]);
    TextEditingController controller2 = TextEditingController(text: data[1]);
    TextEditingController controller3 = TextEditingController(text: data[2]);

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) => AlertDialog(
            title: Text(
              'changer'.tr(),
              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blueGrey[700]),
            ),
            content: SizedBox(
              height: 280,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: TextField(
                      cursorColor: Colors.blueGrey,
                      controller: controller,
                      decoration: InputDecoration(
                        labelText: "rtitle".tr(),
                        labelStyle: const TextStyle(color: Colors.black),
                        border: const OutlineInputBorder(),
                        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Colors.blueGrey, width: 3)),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: TextField(
                      cursorColor: Colors.blueGrey,
                      controller: controller2,
                      decoration: InputDecoration(
                        labelText: "phoneno".tr(),
                        labelStyle: const TextStyle(color: Colors.black),
                        border: const OutlineInputBorder(),
                        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Colors.blueGrey, width: 3)),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: TextField(
                      cursorColor: Colors.blueGrey,
                      controller: controller3,
                      decoration: InputDecoration(
                        labelText: "email".tr(),
                        labelStyle: const TextStyle(color: Colors.black),
                        border: const OutlineInputBorder(),
                        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Colors.blueGrey, width: 3)),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(3.0),
                          child: Text("ctype".tr(),style: TextStyle(fontSize: 20),),
                        ),
                        Row(
                          children: [
                            SizedBox(
                              width: 120,
                              child: ElevatedButton(
                                onPressed: () {
                                  setState((){nopoints=false;});
                                },
                                style: ElevatedButton.styleFrom(
                                    backgroundColor: nopoints ? Colors.grey : Colors.blueGrey[700],
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(0),
                                    )
                                ),
                                child: Text("def".tr(),style: const TextStyle(color: Colors.white),),
                              ),
                            ),
                            SizedBox(
                              width: 120,
                              child: ElevatedButton(
                                onPressed: () {
                                  setState((){nopoints=true;});
                                },
                                style: ElevatedButton.styleFrom(
                                    backgroundColor: !nopoints ? Colors.grey : Colors.blueGrey[700],
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(0),
                                    )
                                ),
                                child: Text("nop".tr(),style: const TextStyle(color: Colors.white),),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: Text('cdialogno'.tr(), style: const TextStyle(color: Colors.red)),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueAccent,
                ),
                onPressed: () async {
                  await _saveTitleToFile("${controller.text}\n${controller2.text}\n${controller3.text}\n$nopoints");
                  Navigator.of(context).pop();
                },
                child: Text('save'.tr(), style: const TextStyle(color: Colors.white)),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _saveTitleToFile(String title) async {
    final file = File('receipt_title.txt');
    await file.writeAsString(title);
    setState(() {

    });
  }

  double getTotalBenefit() {
    double totalBenefits = 0.0;

    for (var product in soldProducts) {
      final price = double.parse(product['price']);
      final wholesalePrice = double.parse(product['wholesale_price']);
      final quantitySold = product['quantity_sold'];

      totalBenefits += (price - wholesalePrice) * quantitySold;
    }

    return totalBenefits;
  }

  Future<void> loadSoldProductsInRange(DateTime start, DateTime end) async {
    try {
      DateTime e = DateTime(end.year, end.month, end.day, 24);

      List<Map<String, dynamic>> benefitData = await SQLService.getSoldProductsInRange(start, e);
      print(soldProducts);
      setState(() {
        soldProducts = benefitData;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        soldProducts = [];
        isLoading = false;
      });
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
    }
  }

  @override
  Widget build(BuildContext context) {
    String startDateFormatted = "${startDate!.day}/${startDate!.month}/${startDate!.year}";
    String endDateFormatted = "${endDate!.day}/${endDate!.month}/${endDate!.year}";
    final groupedProducts = groupBy(soldProducts, (product) => product['barcode']);
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blueGrey[900],
        title: Row(
          children: [
            Text(
              "htitle".tr(args: [widget.name]),
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(
              width: 10,
            ),
            TextButton(
              style: TextButton.styleFrom(backgroundColor: Colors.white.withOpacity(0.05)),
              onPressed: () async {
                await SQLService.botSendMessage("🔻 Admin _`${widget.name}`_ logged out.");
                WindowManager.instance.setPreventClose(false);
                Navigator.pop(context);
              },
              child: Text(
                "logout".tr(),
                style: const TextStyle(color: Colors.red),
              ),
            ),
          ],
        ),
        leading: const Icon(
          Icons.shopping_bag,
          color: Colors.white,
          size: 30,
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => UsersPage(
                    level: widget.level,
                    name: widget.name,
                  ),
                ),
              );
            },
            child: Text(
              "users".tr(),
              style: TextStyle(color: Colors.blueGrey[700], fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: 20),
          ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const HistoryPage(),
                ),
              );
            },
            child: Text(
              "historybtn".tr(),
              style: TextStyle(color: Colors.blueGrey[700], fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: 20),
          ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ProductPage(),
                ),
              );
            },
            child: Text(
              "productsbtn".tr(),
              style: TextStyle(color: Colors.blueGrey[700], fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: 10),
          IconButton(
            icon: const Icon(
              Icons.settings,
              color: Colors.white,
            ),
            onPressed: () {
              _showSettingsDialog();
            },
          ),
          PopupMenuButton<Locale>(
            tooltip: "",
            icon: const Padding(
              padding: EdgeInsets.all(8.0),
              child: Icon(Icons.language, color: Colors.white),
            ),
            onSelected: (Locale newValue) {
              context.setLocale(newValue);
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
          IconButton(
            icon: const Icon(
              Icons.info_outline,
              color: Colors.white,
            ),
            onPressed: () {
              showDialog(
                barrierColor: Colors.transparent.withOpacity(0.1),
                context: context,
                builder: (context2) {
                  return AlertDialog(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    backgroundColor: Colors.white,
                    title: Column(
                      children: [
                        Text(
                          'about'.tr(),
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.blueGrey[700],
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const Divider(),
                      ],
                    ),
                    content: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ClipOval(
                          child: Image.asset(
                            'assets/logo.jpg',
                            width: 80.0,
                            height: 80.0,
                            fit: BoxFit.cover,
                          ),
                        ),
                        SizedBox(
                          width: 300,
                          child: Text(
                            "aboutinfo".tr(),
                            style: TextStyle(
                              color: Colors.blueGrey[800],
                              fontSize: 16,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              "aboutemail".tr(),
                              style: TextStyle(
                                fontFamily: 'roboto',
                                color: Colors.blueGrey[700],
                                fontSize: 12,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            GestureDetector(
                              onTap: () {
                                Clipboard.setData(const ClipboardData(text: "Sajjad.alhadethy@gmail.com"));
                                ScaffoldMessenger.of(context2).showSnackBar(
                                  SnackBar(
                                      backgroundColor: Colors.blueGrey[700],
                                      elevation: 5,
                                      content: Text(
                                        'esaved'.tr(),
                                        style: const TextStyle(color: Colors.white, fontSize: 20),
                                      )),
                                );
                              },
                              child: const Text(
                                "Sajjad.alhadethy@gmail.com",
                                style: TextStyle(
                                  fontFamily: 'roboto',
                                  color: Colors.blueAccent,
                                  fontSize: 12,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              "aboutphone".tr(),
                              style: TextStyle(
                                fontFamily: 'roboto',
                                color: Colors.blueGrey[700],
                                fontSize: 12,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            GestureDetector(
                              onTap: () {
                                Clipboard.setData(const ClipboardData(text: "07722700897"));
                                ScaffoldMessenger.of(context2).showSnackBar(
                                  SnackBar(
                                      backgroundColor: Colors.blueGrey[700],
                                      elevation: 5,
                                      content: Text(
                                        'psaved'.tr(),
                                        style: const TextStyle(color: Colors.white, fontSize: 20),
                                      )),
                                );
                              },
                              child: const Text(
                                "07722700897",
                                style: TextStyle(
                                  fontFamily: 'Roboto Slab',
                                  color: Colors.blueAccent,
                                  fontSize: 12,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "rights".tr(),
                          style: TextStyle(
                            fontFamily: 'Roboto Slab',
                            color: Colors.blueGrey[700],
                            fontSize: 11,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                    actionsAlignment: MainAxisAlignment.center,
                    actions: [
                      SizedBox(
                        width: 300,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.blueGrey[700]),
                          onPressed: () {
                            Navigator.of(context).pop();
                          },
                          child: Text(
                            'cdialogyes'.tr(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              );
            },
          ),
          const SizedBox(
            width: 10,
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
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Container(
              constraints: const BoxConstraints(
                maxWidth: 700,
              ),
              child: Column(
                children: [
                  const SizedBox(height: 10),
                  Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text(
                          "${'from'.tr()} $startDateFormatted ${'to'.tr()} $endDateFormatted",
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.blueGrey[700]),
                            onPressed: () {
                              _showDateRangePicker(context);
                            },
                            icon: const Icon(
                              Icons.date_range,
                              color: Colors.white,
                            ),
                            label: Text(
                              "choose".tr(),
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                            ),
                          ),
                          Card(
                            elevation: 5,
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(20),
                                color: Colors.white,
                              ),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 3),
                                child: Text(
                                  '${'totalb'.tr()}: ${nopoints ? getTotalBenefit().toStringAsFixed(0) : getTotalBenefit().toStringAsFixed(2)}',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: getTotalBenefit() < 0 ? Colors.red : Colors.green,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  soldProducts.isEmpty
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(38.0),
                            child: Text(
                              "nobenefits".tr(),
                              style: const TextStyle(fontSize: 18, color: Colors.white),
                            ),
                          ),
                        )
                      : Expanded(
                          child: ListView(
                            children: groupedProducts.entries.map((entry) {
                              final products = entry.value;
                              final productName = products[0]['name'];

                              final totalBenefits = products.fold<double>(
                                0.0,
                                (sum, product) {
                                  final price = double.parse(product['price']);
                                  final wholesalePrice = double.parse(product['wholesale_price']);
                                  final int quantity = product['quantity_sold'];
                                  return sum + (price - wholesalePrice) * quantity;
                                },
                              );

                              return Card(
                                color: Colors.white,
                                child: ExpansionTile(
                                  iconColor: Colors.green,
                                  title: Text(productName + "   -    ${products[0]['barcode']}", style: const TextStyle(fontWeight: FontWeight.bold)),
                                  subtitle: Text(
                                    "${'totalb'.tr()}: ${nopoints ? totalBenefits.toStringAsFixed(0) : totalBenefits.toStringAsFixed(2)}",
                                    style: TextStyle(color: totalBenefits<0 ? Colors.red : Colors.green),
                                  ),
                                  children: products.map<Widget>((product) {
                                    double res = ((double.parse(product['price']) - double.parse(product['wholesale_price'])) * product['quantity_sold']);
                                    return Card(
                                      color: Colors.white.withOpacity(.7),
                                      child: ListTile(
                                        title: Text("${product['purchase_time']}"),
                                        subtitle: Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text("${'price'.tr()}: ${nopoints ? double.parse(product["price"]).toStringAsFixed(0) : double.parse(product["price"]).toStringAsFixed(2)}"),
                                            Text("${'wholeprice'.tr()}: ${nopoints ? double.parse(product["wholesale_price"]).toStringAsFixed(0) : double.parse(product["wholesale_price"]).toStringAsFixed(2)}"),
                                            Text("${'quantity'.tr()}: ${product['quantity_sold']}"),
                                            Text(
                                              "${'benefits'.tr()}: ${nopoints ? res.toStringAsFixed(0) : res.toStringAsFixed(2)}",
                                              style: TextStyle(color: res<0 ? Colors.red : Colors.green),
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  }).toList(),
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
