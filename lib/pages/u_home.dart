import 'dart:io';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart' as intl;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:supermarket/pages/products.dart';
import 'package:supermarket/sql.dart';
import 'package:window_manager/window_manager.dart';

import 'history.dart';

class UserHome extends StatefulWidget {
  final String name;
  final String level;

  const UserHome({super.key, required this.name, required this.level});

  @override
  State<UserHome> createState() => _UserHomeState();
}

class _UserHomeState extends State<UserHome> with WindowListener {
  final List<Map<String, dynamic>> scannedProducts = [];
  Map<String, dynamic> _productData = {};
  TextEditingController searchController = TextEditingController();
  TextEditingController searchController2 = TextEditingController();
  TextEditingController quantController = TextEditingController();
  Map<String, dynamic> _filteredProducts = {};
  bool loading = false;
  bool nopoints = false;
  String scannedCode = '';
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    loadC();
    WindowManager.instance.setPreventClose(true);
    WindowManager.instance.addListener(this);
    _loadProducts();
  }

  @override
  void dispose() {
    WindowManager.instance.removeListener(this);
    super.dispose();
  }

  Future<void> loadC() async {
    final file = File('receipt_title.txt');
    String string = await file.readAsString();
    List<String> data = string.split("\n");
    nopoints = bool.parse(data[3]);
    setState(() {
      
    });
  }

  @override
  Future<void> onWindowClose() async {
    try {
      await SQLService.botSendMessage("🔴 User _`${widget.name}`_ logged out.");
      exit(0);
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
                child: Text('cdialogyes'.tr(), style: const TextStyle(color: Colors.white)),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
            ],
          );
        },
      );
    }
  }

  Color getColorBasedOnDate(DateTime inputDate) {
    final currentDate = DateTime.now();
    int differenceInDays = inputDate.difference(currentDate).inDays;

    if (differenceInDays > 30) {
      return Colors.black;
    } else if (differenceInDays <= 30 && differenceInDays > 0) {
      return Colors.orange;
    } else {
      return Colors.red;
    }
  }

  void _onKey(KeyEvent event) async {
    if (event is KeyDownEvent) {
      final key = event.logicalKey;

      // Check if the Enter key is pressed (to indicate scanning is complete)
      if (key == LogicalKeyboardKey.enter) {
        var product1 = _productData[scannedCode];

        if (product1 != null && product1['quantity'] != '0') {
          DateTime expireDate = DateTime.parse(product1['expire_date']);
          DateTime today = DateTime.now();
          if (expireDate.isBefore(today) || expireDate.isAtSameMomentAs(today)) {
            bool? res = await showDialog<bool>(
              context: context,
              builder: (context) {
                return AlertDialog(
                  title: Text(
                    'expired'.tr(),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.red, // Customize the color
                    ),
                  ),
                  content: Text(
                    'expiredd'.tr(),
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).pop(false);
                      },
                      child: Text('cdialogno'.tr(), style: const TextStyle(color: Colors.red)),
                    ),
                    TextButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blueAccent,
                      ),
                      onPressed: () {
                        Navigator.of(context).pop(true);
                      },
                      child: Text('cdialogadd'.tr(), style: const TextStyle(color: Colors.white)),
                    ),
                  ],
                );
              },
            );
            if (res == null || !res) {
              scannedCode = '';
              return;
            }
          }

          int index1 = scannedProducts.indexWhere((p) => p['barcode'] == scannedCode);

          if (index1 != -1) {
            if (scannedProducts[index1]['quantity'].toString() != product1['quantity'].toString()) {
              setState(() {
                scannedProducts[index1]['quantity']++;
              });
            }
          } else {
            setState(() {
              scannedProducts.add({
                'barcode': scannedCode,
                'name': product1['name'],
                'price': double.parse(product1['price'].toString()),
                'wholePrice': double.parse(product1['wholesale_price'].toString()),
                'quantity': 1,
                'max': int.parse(product1['quantity']),
              });
            });
          }
        } else {
          showDialog<bool>(
            context: context,
            builder: (context) {
              return AlertDialog(
                title: Text(
                  'otitle'.tr(),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.red, // Customize the color
                  ),
                ), // Or use any relevant translation
                content: Text(
                  'otitled'.tr(),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                actions: [
                  TextButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueGrey[700],
                    ),
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    child: Text('cdialogyes'.tr(), style: const TextStyle(color: Colors.white)),
                  ),
                ],
              );
            },
          );
        }
        scannedCode = '';
      } else {
        setState(() {
          scannedCode += event.character ?? '';
        });
      }
    }
  }

  Future<void> _loadProducts() async {
    try {
      if (dialogSetState != null) {
        dialogSetState!(() {
          loading = true;
        });
      }

      var data = await SQLService.getProducts();

      _productData = {for (var product in data['products']) product['barcode'].toString(): product};
      _filterProducts(searchController.text);
      if (dialogSetState != null) {
        dialogSetState!(() {
          loading = false;
        });
      }
    } catch (e) {
      if (dialogSetState != null) {
        dialogSetState!(() {
          loading = false;
        });
      }
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
                child: Text('cdialogyes'.tr(), style: const TextStyle(color: Colors.white)),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
            ],
          );
        },
      );
    }
  }

  double calculateTotalPrice() {
    double total = 0;
    for (var product in scannedProducts) {
      total += product['price'] * product['quantity'];
    }
    return total;
  }

  void _filterProducts(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredProducts = Map.from(_productData);
      } else {
        _filteredProducts = _productData.where((key, product) => product['name'].toLowerCase().contains(query.toLowerCase()) || product['barcode'].contains(query)).map((key, value) => MapEntry(key, value));
      }
    });
  }

  Future<void> printThermalReceiptAR(List<Map<String, dynamic>> products, double totalPrice) async {
    final pdf = pw.Document();
    final arabicFont = pw.Font.ttf(await rootBundle.load('assets/fonts/Cairo-Regular.ttf'));

    final file = File('receipt_title.txt');
    String string = await file.readAsString();
    List<String> data = string.split("\n");

    // Format the date
    String formattedDate = intl.DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now());

    pdf.addPage(
      pw.Page(
        pageFormat: const PdfPageFormat(80 * PdfPageFormat.mm, double.infinity), // Set receipt width
        build: (context) => pw.Directionality(
          textDirection: pw.TextDirection.rtl,
          child: pw.Padding(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.center,
              children: [
                // Market name at the top
                pw.Text(
                  data[0], // Replace with your market name
                  style: pw.TextStyle(
                    fontSize: 20,
                    fontWeight: pw.FontWeight.bold,
                    font: arabicFont,
                  ),
                ),
                pw.SizedBox(height: 20),
                pw.Divider(),
                pw.SizedBox(height: 10),
                pw.Text(
                  'التاريخ: $formattedDate', // Date in Arabic
                  style: pw.TextStyle(font: arabicFont, fontSize: 8),
                ),
                pw.SizedBox(height: 10),
                // Table of items
                pw.TableHelper.fromTextArray(
                  headers: [
                    'الإجمالي',
                    'العدد',
                    'السعر',
                    'المنتج',
                  ],
                  data: products.map((product) {
                    return [
                      nopoints ?  ((product['price'] * product['quantity']).toStringAsFixed(0)) : ((product['price'] * product['quantity']).toStringAsFixed(2)),
                      product['quantity'].toString(),
                      '${nopoints ? product['price'].toStringAsFixed(0) : product['price'].toStringAsFixed(1)}',
                      product['name'],
                    ];
                  }).toList(),
                  headerStyle: pw.TextStyle(
                    fontWeight: pw.FontWeight.bold,
                    fontSize: 8,
                    font: arabicFont,
                  ),
                  cellStyle: pw.TextStyle(font: arabicFont, fontSize: 8),
                  cellAlignment: pw.Alignment.center,
                  columnWidths: {
                    0: const pw.FlexColumnWidth(1), // Product name column width
                    1: const pw.FlexColumnWidth(1),
                    2: const pw.FlexColumnWidth(1),
                    3: const pw.FlexColumnWidth(2),
                  },
                ),
                pw.SizedBox(height: 10),
                // Total price section
                pw.Align(
                  alignment: pw.Alignment.centerLeft,
                  child: pw.Text(
                    'المجموع الكلي: ${nopoints ? totalPrice.toStringAsFixed(0) : totalPrice.toStringAsFixed(2)}',
                    style: pw.TextStyle(
                      fontSize: 10,
                      fontWeight: pw.FontWeight.bold,
                      font: arabicFont,
                    ),
                  ),
                ),
                pw.SizedBox(height: 10),
                pw.Divider(),
                pw.SizedBox(height: 10),
                if (data[1].isNotEmpty)
                  pw.Align(
                    alignment: pw.Alignment.center,
                    child: pw.Text(
                      'رقم الهاتف: ${data[1]}',
                      style: pw.TextStyle(
                        fontSize: 10,
                        fontWeight: pw.FontWeight.bold,
                        font: arabicFont,
                      ),
                    ),
                  ),
                pw.SizedBox(height: 1),
                if (data[2].isNotEmpty)
                  pw.Align(
                    alignment: pw.Alignment.center,
                    child: pw.Text(
                      'الايميل: ${data[2]}',
                      style: pw.TextStyle(
                        fontSize: 10,
                        fontWeight: pw.FontWeight.bold,
                        font: arabicFont,
                      ),
                    ),
                  ),
                pw.SizedBox(height: 10),
                pw.Align(
                  alignment: pw.Alignment.center,
                  child: pw.Text(
                    'شكرا على قدومكم',
                    style: pw.TextStyle(
                      fontSize: 9,
                      fontWeight: pw.FontWeight.bold,
                      font: arabicFont,
                    ),
                  ),
                ),
              ],
            ),
            padding: const pw.EdgeInsets.all(3),
          ),
        ),
      ),
    );

    await Printing.layoutPdf(onLayout: (format) async => pdf.save());
    setState(() {
      scannedProducts.clear();
    });
  }

  Future<void> printThermalReceiptEN(List<Map<String, dynamic>> products, double totalPrice) async {
    final pdf = pw.Document();
    final arabicFont = pw.Font.ttf(await rootBundle.load('assets/fonts/Cairo-Regular.ttf'));

    final file = File('receipt_title.txt');
    String string = await file.readAsString();
    List<String> data = string.split("\n");

    // Format the date
    String formattedDate = intl.DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now());

    pdf.addPage(
      pw.Page(
        pageFormat: const PdfPageFormat(80 * PdfPageFormat.mm, double.infinity), // Set receipt width
        build: (context) => pw.Directionality(
          textDirection: pw.TextDirection.rtl,
          child: pw.Padding(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.center,
              children: [
                // Market name at the top
                pw.Text(
                  data[0], // Replace with your market name
                  style: pw.TextStyle(
                    font: arabicFont,
                    fontSize: 20,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 20),
                pw.Divider(),
                pw.SizedBox(height: 10),
                pw.Text(
                  'Date: $formattedDate', // Date in Arabic
                  style: pw.TextStyle(font: arabicFont, fontSize: 8),
                ),
                pw.SizedBox(height: 10),
                // Table of items
                pw.TableHelper.fromTextArray(
                  headers: [
                    'Product',
                    'Price',
                    'Quantity',
                    'Total',
                  ],
                  data: products.map((product) {
                    return [
                      product['name'],
                      '${nopoints ? product['price'].toStringAsFixed(0) : product['price'].toStringAsFixed(1)}',
                      product['quantity'].toString(),
                      nopoints ?  ((product['price'] * product['quantity']).toStringAsFixed(0)) : ((product['price'] * product['quantity']).toStringAsFixed(2)),
                    ];
                  }).toList(),
                  headerStyle: pw.TextStyle(
                    font: arabicFont,
                    fontWeight: pw.FontWeight.bold,
                    fontSize: 8,
                  ),
                  cellStyle: pw.TextStyle(font: arabicFont, fontSize: 8),
                  cellAlignment: pw.Alignment.center,
                  columnWidths: {
                    0: const pw.FlexColumnWidth(2),
                    1: const pw.FlexColumnWidth(1),
                    2: const pw.FlexColumnWidth(1),
                    3: const pw.FlexColumnWidth(1),
                  },
                ),
                pw.SizedBox(height: 10),
                // Total price section
                pw.Align(
                  alignment: pw.Alignment.centerRight,
                  child: pw.Text(
                    'Total Price: ${nopoints ? totalPrice.toStringAsFixed(0) : totalPrice.toStringAsFixed(2)}',
                    style: pw.TextStyle(
                      font: arabicFont,
                      fontSize: 10,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ),
                pw.SizedBox(height: 10),
                pw.Divider(),
                pw.SizedBox(height: 10),
                if (data[1].isNotEmpty)
                  pw.Align(
                    alignment: pw.Alignment.center,
                    child: pw.Text(
                      'Phone NO: ${data[1]}',
                      style: pw.TextStyle(
                        font: arabicFont,
                        fontSize: 10,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                  ),
                pw.SizedBox(height: 1),
                if (data[2].isNotEmpty)
                  pw.Align(
                    alignment: pw.Alignment.center,
                    child: pw.Text(
                      'Email: ${data[2]}',
                      style: pw.TextStyle(
                        font: arabicFont,
                        fontSize: 10,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                  ),
                pw.SizedBox(height: 10),
                pw.Align(
                  alignment: pw.Alignment.center,
                  child: pw.Text(
                    'Thank You Come Again',
                    style: pw.TextStyle(
                      font: arabicFont,
                      fontSize: 9,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            padding: const pw.EdgeInsets.all(3),
          ),
        ),
      ),
    );

    await Printing.layoutPdf(onLayout: (format) async => pdf.save());
    setState(() {
      scannedProducts.clear();
    });
  }

  Future<void> printThermalReceiptTR(List<Map<String, dynamic>> products, double totalPrice) async {
    final pdf = pw.Document();
    final arabicFont = pw.Font.ttf(await rootBundle.load('assets/fonts/Cairo-Regular.ttf'));

    final file = File('receipt_title.txt');
    String string = await file.readAsString();
    List<String> data = string.split("\n");

    // Tarihi formatla
    String formattedDate = intl.DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now());

    pdf.addPage(
      pw.Page(
        pageFormat: const PdfPageFormat(80 * PdfPageFormat.mm, double.infinity), // Makbuz genişliğini ayarla
        build: (context) => pw.Directionality(
          textDirection: pw.TextDirection.rtl,
          child: pw.Padding(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.center,
              children: [
                // En üstteki market adı
                pw.Text(
                  data[0], // Market adınızla değiştirin
                  style: pw.TextStyle(
                    fontSize: 20,
                    fontWeight: pw.FontWeight.bold,
                    font: arabicFont,
                  ),
                ),
                pw.SizedBox(height: 20),
                pw.Divider(),
                pw.SizedBox(height: 10),
                pw.Text(
                  'Tarih: $formattedDate', // Tarih
                  style: pw.TextStyle(font: arabicFont, fontSize: 8),
                ),
                pw.SizedBox(height: 10),
                // Ürün tablosu
                pw.TableHelper.fromTextArray(
                  headers: [
                    'Ürün',
                    'Fiyat',
                    'Miktar',
                    'Toplam',
                  ],
                  data: products.map((product) {
                    return [
                      product['name'],
                      '${nopoints ? product['price'].toStringAsFixed(0) : product['price'].toStringAsFixed(1)}',
                      product['quantity'].toString(),
                      nopoints ?  ((product['price'] * product['quantity']).toStringAsFixed(0)) : ((product['price'] * product['quantity']).toStringAsFixed(2)),
                    ];
                  }).toList(),
                  headerStyle: pw.TextStyle(
                    font: arabicFont,
                    fontWeight: pw.FontWeight.bold,
                    fontSize: 8,
                  ),
                  cellStyle: pw.TextStyle(font: arabicFont, fontSize: 8),
                  cellAlignment: pw.Alignment.center,
                  columnWidths: {
                    0: const pw.FlexColumnWidth(2), // Ürün adı sütun genişliği
                    1: const pw.FlexColumnWidth(1),
                    2: const pw.FlexColumnWidth(1),
                    3: const pw.FlexColumnWidth(1),
                  },
                ),
                pw.SizedBox(height: 10),
                // Toplam fiyat bölümü
                pw.Align(
                  alignment: pw.Alignment.centerRight,
                  child: pw.Text(
                    'Toplam Fiyat: ${nopoints ? totalPrice.toStringAsFixed(0) : totalPrice.toStringAsFixed(2)}',
                    style: pw.TextStyle(
                      font: arabicFont,
                      fontSize: 10,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ),
                pw.SizedBox(height: 10),
                pw.Divider(),
                pw.SizedBox(height: 10),
                if (data[1].isNotEmpty)
                  pw.Align(
                    alignment: pw.Alignment.center,
                    child: pw.Text(
                      'Telefon No: ${data[1]}',
                      style: pw.TextStyle(
                        font: arabicFont,
                        fontSize: 10,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                  ),
                pw.SizedBox(height: 1),
                if (data[2].isNotEmpty)
                  pw.Align(
                    alignment: pw.Alignment.center,
                    child: pw.Text(
                      'E-posta: ${data[2]}',
                      style: pw.TextStyle(
                        font: arabicFont,
                        fontSize: 10,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                  ),
                pw.SizedBox(height: 10),
                pw.Align(
                  alignment: pw.Alignment.center,
                  child: pw.Text(
                    'Teşekkürler, yine bekleriz',
                    style: pw.TextStyle(
                      font: arabicFont,
                      fontSize: 9,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            padding: const pw.EdgeInsets.all(3),
          ),
        ),
      ),
    );

    await Printing.layoutPdf(onLayout: (format) async => pdf.save());
    setState(() {
      scannedProducts.clear();
    });
  }

  Future<void> _saveTitleToFile(String title) async {
    final file = File('receipt_title.txt');
    await file.writeAsString(title);
    setState(() {

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
              height: 270,
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
                          child: Text("ctype".tr()),
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

  void Function(void Function())? dialogSetState;

  @override
  Widget build(BuildContext context) {
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
                try {
                  await SQLService.botSendMessage("🔴 User _`${widget.name}`_ logged out.");
                  WindowManager.instance.setPreventClose(false);
                  Navigator.pop(context);
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
                            child: Text('cdialogyes'.tr(), style: const TextStyle(color: Colors.white)),
                            onPressed: () {
                              Navigator.of(context).pop();
                            },
                          ),
                        ],
                      );
                    },
                  );
                }
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
          if (widget.level == "1" || widget.level == "3")
            ElevatedButton(
              onPressed: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const HistoryPage(),
                  ),
                );
                _loadProducts();
              },
              child: Text(
                "historybtn".tr(),
                style: TextStyle(color: Colors.blueGrey[700], fontWeight: FontWeight.bold),
              ),
            ),
          const SizedBox(width: 20),
          if (widget.level == "2" || widget.level == "3")
            ElevatedButton(
              onPressed: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ProductPage(),
                  ),
                );
                _loadProducts();
              },
              child: Text(
                "productsbtn".tr(),
                style: TextStyle(color: Colors.blueGrey[700], fontWeight: FontWeight.bold),
              ),
            ),
          const SizedBox(width: 20),
          IconButton(
            icon: const Icon(
              Icons.settings,
              color: Colors.white,
            ),
            onPressed: () {
              _showSettingsDialog();
            },
          ),
          const SizedBox(width: 10),
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
          const SizedBox(
            width: 10,
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
              Colors.blueGrey.shade900,
              Colors.white,
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.only(left: 16.0, right: 16, top: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  constraints: const BoxConstraints(
                    maxWidth: 850,
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent),
                            onPressed: () async {
                              await showDialog(
                                context: context,
                                builder: (context) {
                                  return StatefulBuilder(
                                    builder: (context, setState2) {
                                      dialogSetState = setState2;
                                      return Dialog(
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(15),
                                        ),
                                        backgroundColor: Colors.transparent.withOpacity(0.3),
                                        child: Container(
                                          constraints: const BoxConstraints(
                                            maxWidth: 600,
                                          ),
                                          child: Column(
                                            children: [
                                              Card(
                                                elevation: 5,
                                                child: Padding(
                                                  padding: const EdgeInsets.all(8.0),
                                                  child: Row(
                                                    children: [
                                                      Flexible(
                                                        child: Padding(
                                                          padding: const EdgeInsets.all(16.0),
                                                          child: TextField(
                                                            cursorColor: Colors.blueGrey[600],
                                                            controller: searchController,
                                                            decoration: InputDecoration(
                                                              hintText: 'searchfor'.tr(),
                                                              hintStyle: const TextStyle(color: Colors.grey),
                                                              prefixIcon: const Icon(
                                                                Icons.search,
                                                                color: Colors.grey,
                                                              ),
                                                              border: OutlineInputBorder(
                                                                borderRadius: BorderRadius.circular(10),
                                                              ),
                                                              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Colors.blueGrey, width: 3)),
                                                            ),
                                                            onChanged: (value) {
                                                              _filterProducts(value);
                                                              setState2(() {});
                                                            },
                                                          ),
                                                        ),
                                                      ),
                                                      IconButton(
                                                        onPressed: () {
                                                          _loadProducts();
                                                        },
                                                        icon: loading
                                                            ? const SizedBox(
                                                                height: 15,
                                                                width: 15,
                                                                child: CircularProgressIndicator(
                                                                  color: Colors.blueGrey,
                                                                  strokeWidth: 2.5,
                                                                ),
                                                              )
                                                            : const Icon(
                                                                Icons.refresh,
                                                                color: Colors.blueGrey,
                                                              ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                              Expanded(
                                                child: ListView.builder(
                                                  padding: const EdgeInsets.symmetric(horizontal: 16),
                                                  itemCount: _filteredProducts.length,
                                                  itemBuilder: (context, index) {
                                                    String barcode = _filteredProducts.keys.elementAt(index);
                                                    final product = _filteredProducts[barcode];
                                                    String enteredBarcode = product['barcode'];

                                                    return Card(
                                                      elevation: 3,
                                                      margin: const EdgeInsets.symmetric(vertical: 8),
                                                      child: Padding(
                                                        padding: const EdgeInsets.all(18.0),
                                                        child: Row(
                                                          children: [
                                                            Flexible(
                                                              child: Column(
                                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                                children: [
                                                                  Text(
                                                                    product['name'],
                                                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
                                                                  ),
                                                                  Column(
                                                                    children: [
                                                                      Row(
                                                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                                        children: [
                                                                          SizedBox(
                                                                            width: 200,
                                                                            child: Row(
                                                                              children: [
                                                                                Text(
                                                                                  "${"barcode".tr()}: ",
                                                                                ),
                                                                                Text(
                                                                                  product['barcode'],
                                                                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                                                                ),
                                                                              ],
                                                                            ),
                                                                          ),
                                                                          Row(
                                                                            children: [
                                                                              Text(
                                                                                "${"quantity".tr()}: ",
                                                                              ),
                                                                              Text(
                                                                                product['quantity'],
                                                                                style: TextStyle(
                                                                                    fontWeight: FontWeight.bold,
                                                                                    color: int.parse(product['quantity']) > 40
                                                                                        ? Colors.black
                                                                                        : int.parse(product['quantity']) > 0
                                                                                            ? Colors.orange
                                                                                            : Colors.red),
                                                                              ),
                                                                            ],
                                                                          ),
                                                                          Row(
                                                                            children: [
                                                                              Text(
                                                                                "${"price".tr()}: ",
                                                                              ),
                                                                              Text(
                                                                                "${nopoints ? double.parse(product['price']).toStringAsFixed(0) : product['price']}",
                                                                                style: TextStyle(color: Colors.blueGrey[700], fontWeight: FontWeight.bold),
                                                                              ),
                                                                            ],
                                                                          ),
                                                                        ],
                                                                      ),
                                                                      Row(
                                                                        children: [
                                                                          Text(
                                                                            "${"expire_date".tr()}: ",
                                                                          ),
                                                                          Text(
                                                                            "${product['expire_date']}",
                                                                            style: TextStyle(color: getColorBasedOnDate(DateTime.parse(product['expire_date'])), fontWeight: FontWeight.bold),
                                                                          ),
                                                                        ],
                                                                      ),
                                                                    ],
                                                                  ),
                                                                ],
                                                              ),
                                                            ),
                                                            const SizedBox(
                                                              width: 10,
                                                            ),
                                                            IconButton(
                                                              color: Colors.blue,
                                                              onPressed: () async {
                                                                var product1 = _productData[enteredBarcode];
                                                                DateTime expireDate = DateTime.parse(product1['expire_date']);
                                                                DateTime today = DateTime.now();

                                                                if (product1['quantity'] != '0') {
                                                                  if (expireDate.isBefore(today) || expireDate.isAtSameMomentAs(today)) {
                                                                    bool? res = await showDialog<bool>(
                                                                      context: context,
                                                                      builder: (context) {
                                                                        return AlertDialog(
                                                                          title: Text(
                                                                            'expired'.tr(),
                                                                            style: const TextStyle(
                                                                              fontWeight: FontWeight.bold,
                                                                              color: Colors.red, // Customize the color
                                                                            ),
                                                                          ),
                                                                          content: Text(
                                                                            'expiredd'.tr(),
                                                                            style: const TextStyle(fontWeight: FontWeight.bold),
                                                                          ),
                                                                          actions: [
                                                                            TextButton(
                                                                              onPressed: () {
                                                                                Navigator.of(context).pop(false);
                                                                              },
                                                                              child: Text('cdialogno'.tr(), style: const TextStyle(color: Colors.red)),
                                                                            ),
                                                                            TextButton(
                                                                              style: ElevatedButton.styleFrom(
                                                                                backgroundColor: Colors.blueAccent,
                                                                              ),
                                                                              onPressed: () {
                                                                                Navigator.of(context).pop(true);
                                                                              },
                                                                              child: Text('cdialogadd'.tr(), style: const TextStyle(color: Colors.white)),
                                                                            ),
                                                                          ],
                                                                        );
                                                                      },
                                                                    );

                                                                    if (res == null || !res) {
                                                                      return;
                                                                    }
                                                                  }

                                                                  int index1 = scannedProducts.indexWhere((p) => p['barcode'] == enteredBarcode);

                                                                  if (index1 != -1) {
                                                                    if (scannedProducts[index1]['quantity'].toString() != product1['quantity'].toString()) {
                                                                      setState(() {
                                                                        scannedProducts[index1]['quantity']++;
                                                                      });
                                                                    }
                                                                  } else {
                                                                    setState(() {
                                                                      scannedProducts.add({
                                                                        'barcode': enteredBarcode,
                                                                        'name': product1['name'],
                                                                        'price': double.parse(product1['price'].toString()),
                                                                        'wholePrice': double.parse(product1['wholesale_price'].toString()),
                                                                        'quantity': 1,
                                                                        'max': int.parse(product1['quantity']),
                                                                      });
                                                                    });
                                                                  }

                                                                  dialogSetState = null;
                                                                  Navigator.pop(context);
                                                                } else {
                                                                  showDialog<bool>(
                                                                    context: context,
                                                                    builder: (context) {
                                                                      return AlertDialog(
                                                                        title: Text(
                                                                          'otitle'.tr(),
                                                                          style: const TextStyle(
                                                                            fontWeight: FontWeight.bold,
                                                                            color: Colors.red, // Customize the color
                                                                          ),
                                                                        ), // Or use any relevant translation
                                                                        content: Text(
                                                                          'otitled'.tr(),
                                                                          style: const TextStyle(fontWeight: FontWeight.bold),
                                                                        ),
                                                                        actions: [
                                                                          TextButton(
                                                                            style: ElevatedButton.styleFrom(
                                                                              backgroundColor: Colors.blueGrey[700],
                                                                            ),
                                                                            onPressed: () {
                                                                              Navigator.of(context).pop();
                                                                            },
                                                                            child: Text('cdialogyes'.tr(), style: const TextStyle(color: Colors.white)),
                                                                          ),
                                                                        ],
                                                                      );
                                                                    },
                                                                  );
                                                                }
                                                              },
                                                              icon: const Icon(Icons.add),
                                                            ),
                                                          ],
                                                        ),
                                                      ),
                                                    );
                                                  },
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      );
                                    },
                                  );
                                },
                              ).then((_) {
                                dialogSetState = null;
                              });
                            },
                            child: Text(
                              "addproduct".tr(),
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                            ),
                          ),
                          SizedBox(
                            width: 300,
                            child: KeyboardListener(
                              focusNode: _focusNode,
                              onKeyEvent: _onKey,
                              autofocus: true,
                              child: const SizedBox(),
                            ),
                          ),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
                            onPressed: () {
                              setState(() {
                                scannedProducts.clear();
                                _loadProducts();
                              });
                            },
                            child: Text(
                              "clearlist".tr(),
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                            ),
                          ),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                            onPressed: () async {
                              if (scannedProducts.isNotEmpty) {
                                bool? confirmed = await showDialog<bool>(
                                  context: context,
                                  builder: (context) {
                                    return AlertDialog(
                                      title: Text(
                                        'cdialogttitle'.tr(),
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.green,
                                        ),
                                      ),
                                      content: Text(
                                        'cdialogcontent'.tr(),
                                        style: const TextStyle(fontWeight: FontWeight.bold),
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed: () {
                                            Navigator.of(context).pop(false);
                                          },
                                          child: Text('cdialogno'.tr(), style: const TextStyle(color: Colors.red)),
                                        ),
                                        TextButton(
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.green,
                                          ),
                                          onPressed: () {
                                            Navigator.of(context).pop(true);
                                          },
                                          child: Text('cdialogyes'.tr(), style: const TextStyle(color: Colors.white)),
                                        ),
                                      ],
                                    );
                                  },
                                );

                                if (confirmed == true) {
                                  try {
                                    await SQLService.decreaseQuantities(scannedProducts, widget.name);
                                    double totalPrice = calculateTotalPrice();
                                    Locale currentLocale = context.locale;

                                    if (currentLocale.languageCode == "en") {
                                      await printThermalReceiptEN(scannedProducts, totalPrice);
                                    } else if (currentLocale.languageCode == "ar") {
                                      await printThermalReceiptAR(scannedProducts, totalPrice);
                                    } else {
                                      await printThermalReceiptTR(scannedProducts, totalPrice);
                                    }

                                    setState(() {
                                      scannedProducts.clear();
                                    });
                                    _loadProducts();
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
                                              child: Text('cdialogyes'.tr(), style: const TextStyle(color: Colors.white)),
                                              onPressed: () {
                                                Navigator.of(context).pop();
                                              },
                                            ),
                                          ],
                                        );
                                      },
                                    );
                                  }
                                }
                              }
                            },
                            child: Text(
                              "done".tr(),
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        height: 600,
                        child: Card(
                          elevation: 5,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: Column(
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    SizedBox(width: 300, child: Text("pname".tr(), style: const TextStyle(fontWeight: FontWeight.bold))),
                                    SizedBox(width: 80, child: Text("price".tr(), style: const TextStyle(fontWeight: FontWeight.bold))),
                                    SizedBox(width: 160, child: Text("quantity".tr(), style: const TextStyle(fontWeight: FontWeight.bold))),
                                    SizedBox(width: 90, child: Text("total".tr(), style: const TextStyle(fontWeight: FontWeight.bold))),
                                    const SizedBox(width: 0, child: Text("")),
                                  ],
                                ),
                                const Divider(
                                  thickness: 2,
                                  color: Colors.grey,
                                ),
                                Expanded(
                                  child: ListView.builder(
                                    itemCount: scannedProducts.length,
                                    itemBuilder: (context, index) {
                                      final product = scannedProducts[index];
                                      return Padding(
                                        padding: const EdgeInsets.symmetric(vertical: 10),
                                        child: Column(
                                          children: [
                                            Row(
                                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                              children: [
                                                SizedBox(
                                                  width: 300,
                                                  child: Text(
                                                    product['name'],
                                                    style: const TextStyle(
                                                      fontSize: 18,
                                                      fontWeight: FontWeight.w500,
                                                    ),
                                                  ),
                                                ),
                                                SizedBox(
                                                  width: 120,
                                                  child: Row(
                                                    mainAxisAlignment: MainAxisAlignment.end,
                                                    children: [
                                                      Text(
                                                        '${nopoints ? (product['price']).toStringAsFixed(0) : product['price'].toString()}',
                                                        style: const TextStyle(fontSize: 16),
                                                      ),
                                                      IconButton(
                                                        icon: const Icon(Icons.edit, color: Colors.blue),
                                                        onPressed: () {
                                                          String num = product['price'].toString();
                                                          showDialog(
                                                            context: context,
                                                            builder: (context) {
                                                              return AlertDialog(
                                                                title: Text(
                                                                  'changeprice'.tr(),
                                                                  style: const TextStyle(
                                                                    fontWeight: FontWeight.bold,
                                                                    color: Colors.blue, // Customize the color
                                                                  ),
                                                                ),
                                                                content: TextField(
                                                                  keyboardType: TextInputType.number,
                                                                  inputFormatters: <TextInputFormatter>[
                                                                    FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')), // Allows numbers and a single decimal point
                                                                  ],
                                                                  cursorColor: Colors.blueGrey,
                                                                  onChanged: (value) {
                                                                    num = value;
                                                                  },
                                                                  decoration: InputDecoration(
                                                                    focusedBorder: UnderlineInputBorder(
                                                                      borderRadius: BorderRadius.circular(10),
                                                                      borderSide: const BorderSide(color: Colors.blueGrey, width: 3),
                                                                    ),
                                                                  ),
                                                                ),
                                                                actions: [
                                                                  TextButton(
                                                                    onPressed: () {
                                                                      Navigator.of(context).pop();
                                                                    },
                                                                    child: Text(
                                                                      'cdialogno'.tr(),
                                                                      style: const TextStyle(
                                                                        color: Colors.red,
                                                                        fontWeight: FontWeight.bold,
                                                                      ),
                                                                    ),
                                                                  ),
                                                                  TextButton(
                                                                    style: ElevatedButton.styleFrom(
                                                                      backgroundColor: Colors.blueAccent,
                                                                    ),
                                                                    onPressed: () {
                                                                      if (num.isNotEmpty) {
                                                                        product['price'] = double.parse(num);
                                                                        setState(() {});
                                                                        Navigator.of(context).pop();
                                                                      }
                                                                    },
                                                                    child: Text(
                                                                      'cdialogyes'.tr(),
                                                                      style: const TextStyle(
                                                                        color: Colors.white,
                                                                        fontWeight: FontWeight.bold,
                                                                      ),
                                                                    ),
                                                                  ),
                                                                ],
                                                              );
                                                            },
                                                          );
                                                        },
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                                const SizedBox(
                                                  width: 10,
                                                ),
                                                SizedBox(
                                                  width: 180,
                                                  child: Row(
                                                    children: [
                                                      IconButton(
                                                        color: Colors.red,
                                                        onPressed: () {
                                                          if (product['quantity'] != 1) {
                                                            setState(() {
                                                              product['quantity']--;
                                                            });
                                                          }
                                                        },
                                                        icon: const Icon(Icons.remove_circle_outline),
                                                      ),
                                                      SizedBox(width: 60, child: Center(child: Text("${product['quantity']}/${product['max']}"))),
                                                      IconButton(
                                                        color: Colors.blue,
                                                        onPressed: () {
                                                          setState(() {
                                                            if (product['quantity'] != product['max']) {
                                                              product['quantity']++;
                                                            } else {
                                                              showDialog<bool>(
                                                                  context: context,
                                                                  builder: (context) {
                                                                    return AlertDialog(
                                                                      title: Text(
                                                                        'notitle'.tr(),
                                                                        style: const TextStyle(
                                                                          fontWeight: FontWeight.bold,
                                                                          color: Colors.red, // Customize the color
                                                                        ),
                                                                      ),
                                                                      actions: [
                                                                        TextButton(
                                                                          style: ElevatedButton.styleFrom(
                                                                            backgroundColor: Colors.blueGrey[700],
                                                                          ),
                                                                          onPressed: () {
                                                                            Navigator.of(context).pop();
                                                                          },
                                                                          child: Text('cdialogyes'.tr(), style: const TextStyle(color: Colors.white)),
                                                                        ),
                                                                      ],
                                                                    );
                                                                  });
                                                            }
                                                          });
                                                        },
                                                        icon: const Icon(Icons.add_circle_outline_outlined),
                                                      ),
                                                      IconButton(
                                                        color: Colors.blue,
                                                        onPressed: () async {
                                                          quantController.text = product['quantity'].toString();
                                                          await showDialog(
                                                              context: context,
                                                              builder: (context) {
                                                                return AlertDialog(
                                                                  content: Row(
                                                                    mainAxisAlignment: MainAxisAlignment.start,
                                                                    crossAxisAlignment: CrossAxisAlignment.start,
                                                                    children: [
                                                                      Text(
                                                                        "${'quantity'.tr()}: ",
                                                                        style: const TextStyle(
                                                                          fontSize: 30,
                                                                          fontWeight: FontWeight.bold,
                                                                          color: Colors.blue, // Customize the color
                                                                        ),
                                                                      ),
                                                                      SizedBox(
                                                                        width: 100,
                                                                        child: TextField(
                                                                          cursorColor: Colors.blueGrey[600],
                                                                          controller: quantController,
                                                                          keyboardType: TextInputType.number,
                                                                          inputFormatters: <TextInputFormatter>[
                                                                            FilteringTextInputFormatter.digitsOnly,
                                                                          ],
                                                                          decoration: InputDecoration(
                                                                            hintStyle: const TextStyle(color: Colors.grey),
                                                                            suffixText: "/${product['max']}",
                                                                            suffixStyle: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
                                                                            border: OutlineInputBorder(
                                                                              borderRadius: BorderRadius.circular(10),
                                                                            ),
                                                                            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Colors.blueGrey, width: 3)),
                                                                          ),
                                                                        ),
                                                                      ),
                                                                    ],
                                                                  ),
                                                                  actions: [
                                                                    TextButton(
                                                                      style: ElevatedButton.styleFrom(
                                                                        backgroundColor: Colors.blueGrey[700],
                                                                      ),
                                                                      onPressed: () {
                                                                        Navigator.of(context).pop();
                                                                      },
                                                                      child: Text('cdialogyes'.tr(), style: const TextStyle(color: Colors.white)),
                                                                    ),
                                                                  ],
                                                                );
                                                              });
                                                          setState(() {
                                                            if (quantController.text.isNotEmpty) {
                                                              if (int.parse(quantController.text) > product['max']) {
                                                                product['quantity'] = product['max'];
                                                              } else if (int.parse(quantController.text) < 2) {
                                                                product['quantity'] = 1;
                                                              } else {
                                                                product['quantity'] = int.parse(quantController.text);
                                                              }
                                                            }
                                                          });
                                                        },
                                                        icon: const Icon(Icons.edit),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                                SizedBox(
                                                  width: 120,
                                                  child: Text(
                                                    textAlign: context.locale.languageCode=="ar" ? TextAlign.left : TextAlign.right,
                                                    '${nopoints ? (product['price'] * product['quantity']).toStringAsFixed(0) : (product['price'] * product['quantity']).toStringAsFixed(2)}',
                                                    style: const TextStyle(
                                                      fontSize: 16,
                                                    ),
                                                  ),
                                                ),
                                                IconButton(
                                                  icon: const Icon(Icons.delete, color: Colors.red),
                                                  onPressed: () {
                                                    scannedProducts.removeAt(index);
                                                    setState(() {});
                                                  },
                                                ),
                                              ],
                                            ),
                                            const Divider(
                                              thickness: 0.2,
                                              height: 0,
                                              color: Colors.black,
                                            ),
                                          ],
                                        ),
                                      );
                                    },
                                  ),
                                ),
                                const Divider(
                                  thickness: 2,
                                  color: Colors.grey,
                                ),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      "${"total".tr()}: ",
                                      style: const TextStyle(fontSize: 18),
                                    ),
                                    Text(
                                      nopoints ? calculateTotalPrice().toStringAsFixed(0) : calculateTotalPrice().toStringAsFixed(2),
                                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
