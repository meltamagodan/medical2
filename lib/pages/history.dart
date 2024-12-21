import 'dart:io';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:supermarket/sql.dart';

class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  List<Map<String, dynamic>> purchaseHistory = [];
  DateTime selectedDate = DateTime.now(); // Default to current date
  bool isLoading = true; // Track if data is loading
  bool nopoints = false;

  @override
  void initState() {
    super.initState();
    loadPurchaseHistory();
    loadC();
  }

  Future<void> loadC() async {
    final file = File('receipt_title.txt');
    String string = await file.readAsString();
    List<String> data = string.split("\n");
    nopoints = bool.parse(data[3]);
    setState(() {

    });
  }

  String format(String dateTimeString) {
    DateTime parsedDateTime = DateTime.parse(dateTimeString);

    // Extract components
    int year = parsedDateTime.year;
    int month = parsedDateTime.month;
    int day = parsedDateTime.day;
    int hour = parsedDateTime.hour;
    int minute = parsedDateTime.minute;
    int second = parsedDateTime.second;

    // Convert to 12-hour format
    String period = hour >= 12 ? "PM" : "AM";
    int hour12 = hour % 12 == 0 ? 12 : hour % 12; // Convert 0 or 12 to 12

    // Create a more readable format
    String formattedDate = '$day/$month/$year';
    String formattedTime = '${hour12.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}:${second.toString().padLeft(2, '0')} $period';

    return "$formattedDate - $formattedTime";
  }

  Future<void> loadPurchaseHistory() async {
    try{
      setState(() {
        isLoading = true;
      });

      // Get all purchases for the selected date
      Map<String, dynamic> response = await SQLService.getPurchaseHistory(selectedDate.toString());
      if (response['status'] == 'success') {
        // Cast the purchaseHistory to List<Map<String, dynamic>>
        List<Map<String, dynamic>> historyList = List<Map<String, dynamic>>.from(response['purchaseHistory']);
        setState(() {
          purchaseHistory = historyList; // Assign the purchase history list
          isLoading = false;
        });
      } else {
        // Handle the error case
        setState(() {
          purchaseHistory = [];
          isLoading = false;
        });
      }
    }catch(e){
      setState(() {
        purchaseHistory = [];
        isLoading = false;
      });
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
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2020),
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
    );

    if (picked != null && picked != selectedDate) {
      setState(() {
        selectedDate = picked;
        loadPurchaseHistory(); // Reload purchase history for the new date
      });
    }
  }

  double calculateTotalPrice(List<dynamic> products) {
    double totalPrice = 0.0;
    for (var product in products) {
      totalPrice += double.parse(product['price']) * product['quantity'];
    }
    return totalPrice;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "hptitle".tr(),
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.blueGrey[900],
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () {
            Navigator.pop(context); // This will navigate back to the previous page.
          },
        ),
        actions: [
          ElevatedButton.icon(
            label: Text(
              "hpaction".tr(),
              style: TextStyle(
                color: Colors.blueGrey[900],
              ),
            ),
            icon: Icon(Icons.calendar_today, color: Colors.blueGrey[900]),
            onPressed: () => _selectDate(context), // Open date picker
          ),
          const SizedBox(width: 10,)
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
            constraints: const BoxConstraints(
              maxWidth: 700, // Set maximum width
            ),
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: Colors.white,
                      ), // Display loading indicator
                    )
                  : purchaseHistory.isEmpty
                      ? Center(
                          child: Text(
                            "hpno".tr(),
                            style: const TextStyle(fontSize: 18, color: Colors.white),
                          ),
                        )
                      : ListView.builder(
                          itemCount: purchaseHistory.length,
                          itemBuilder: (context, index) {
                            final transaction = purchaseHistory[index];
                            //print(transaction);
                            final transactionDate = format(transaction['date']);
                            final username = transaction['products'][0]['username'];
                            final products = transaction['products']; // Safely cast to List<dynamic>

                            final totalPrice = nopoints ? calculateTotalPrice(products).toStringAsFixed(0) : calculateTotalPrice(products).toStringAsFixed(2);

                            return Card(
                              elevation: 5,
                              margin: const EdgeInsets.symmetric(vertical: 10),
                              child: ExpansionTile(
                                iconColor: Colors.green,
                                title: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      " $transactionDate ",
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Text(
                                      username.toString(),
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.red,
                                      ),
                                    ),
                                    Text(
                                      "${"hptotal".tr()}$totalPrice",
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.green,
                                      ),
                                    ),
                                  ],
                                ),
                                children: products.map<Widget>((product) {
                                  return Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              product['productName'],
                                              style: const TextStyle(
                                                fontSize: 18,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                            Text(
                                              '${"hpprice".tr()}${double.parse(product['price']).toStringAsFixed(0)}',
                                              style: const TextStyle(
                                                fontSize: 14,
                                              ),
                                            ),
                                            Text(
                                              '${"hpquantity".tr()}${product['quantity']}',
                                              style: const TextStyle(
                                                fontSize: 14,
                                              ),
                                            ),
                                          ],
                                        ),
                                        Text(
                                          '${"hptotal".tr()}${nopoints ?  (double.parse(product['price']) * product['quantity']).toStringAsFixed(0) : (double.parse(product['price']) * product['quantity']).toStringAsFixed(2)}',
                                          style: const TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.black54,
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                }).toList(),
                              ),
                            );
                          },
                        ),
            ),
          ),
        ),
      ),
    );
  }
}
