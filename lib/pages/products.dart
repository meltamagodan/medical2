import 'dart:io';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supermarket/sql.dart';

class ProductPage extends StatefulWidget {
  const ProductPage({super.key});

  @override
  State<ProductPage> createState() => _ProductPageState();
}

class _ProductPageState extends State<ProductPage> {
  final _formKey = GlobalKey<FormState>();
  String sort = '';
  String _barcode = '';
  String _oldbarcode = '';
  String _productName = '';
  double _price = 0;
  double _price2 = 0;
  int _quantity = 0;
  bool noTime = false;
  bool nopoints = false;
  DateTime? _expireDate;
  Map<String, dynamic> _products = {};
  Map<String, dynamic> _filteredProducts = {};
  TextEditingController barController = TextEditingController();
  TextEditingController searchController = TextEditingController();
  final TextEditingController nameController = TextEditingController();
  final TextEditingController barcodeController = TextEditingController();
  final TextEditingController priceController = TextEditingController();
  final TextEditingController wholesalePriceController = TextEditingController();
  final TextEditingController quantityController = TextEditingController();
  final TextEditingController expireDateController = TextEditingController();
  final TextEditingController expireDateController2 = TextEditingController();

  bool loadList = true;

  @override
  void initState() {
    super.initState();
    _loadProducts();
    loadC();
  }

  Future<void> loadC() async {
    final file = File('receipt_title.txt');
    String string = await file.readAsString();
    List<String> data = string.split("\n");
    nopoints = bool.parse(data[3]);
    setState(() {});
  }

  void _loadProducts() async {
    setState(() {
      loadList = true;
    });
    try {
      final products = await SQLService.getProducts();
      setState(() {
        _products = {};
        for (var doc in products['products']) {
          var product = {
            'barcode': doc['barcode'],
            'productName': doc['name'],
            'price': double.parse(doc['price'] ?? '0'),
            'wholePrice': double.parse(doc['wholesale_price'] ?? '0'),
            'quantity': int.parse(doc['quantity'] ?? '0'),
            'expire': (doc['expire_date'] ?? '0').toString(),
          };
          _products[product['barcode']] = product;
        }
        loadList = false;
        _filteredProducts = Map.from(_products);
        _filterProducts(searchController.text);
      });
    } catch (e) {
      setState(() {
        _products = {};
        _filteredProducts = Map.from(_products);
        loadList = false;
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
                  Navigator.of(context).pop();
                },
              ),
            ],
          );
        },
      );
    }
  }

  void _filterProducts(String query) {
    setState(() {
      // Start by filtering products based on the query
      dynamic filteredProducts = _products.where((key, product) => product['productName'].toLowerCase().contains(query.toLowerCase()) || product['barcode'].contains(query)).entries.toList();

      // Apply sorting based on the "sort" string
      if (sort == "quant") {
        filteredProducts.sort((a, b) => (a.value['quantity'] as int).compareTo(b.value['quantity']));
      } else if (sort == "date") {
        filteredProducts.sort((a, b) {
          // Parse dates or handle invalid entries
          DateTime? dateA = a.value['expire'] == "0" || a.value['expire'] == null ? null : DateTime.tryParse(a.value['expire']);
          DateTime? dateB = b.value['expire'] == "0" || b.value['expire'] == null ? null : DateTime.tryParse(b.value['expire']);

          // Move invalid or null dates to the end
          if (dateA == null && dateB == null) {
            return 0; // Both are invalid
          } else if (dateA == null) {
            return 1; // a is invalid, move it to the end
          } else if (dateB == null) {
            return -1; // b is invalid, move it to the end
          } else {
            // Both dates are valid, compare them
            return dateA.compareTo(dateB);
          }
        });
      }

      // Convert the sorted list back to a map
      _filteredProducts = Map.fromEntries(filteredProducts);
      setState(() {});
    });
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

  void _addProduct() async {
    setState(() {
      loading = true;
    });
    try {
      if (_formKey.currentState!.validate()) {
        _formKey.currentState!.save();
        Map<String, dynamic> yay = await SQLService.addProduct(barcode: _barcode, name: _productName, wholesalePrice: _price2, price: _price, quantity: _quantity, expireDate: _expireDate);
        if (yay['message'] == "duplicated") {
          showDialog(
            context: context,
            builder: (BuildContext context) {
              return AlertDialog(
                title: Text(
                  'dubt'.tr(),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.red,
                  ),
                ),
                actions: <Widget>[
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueGrey[700],
                    ),
                    child: Text('cdialogyes'.tr(), style: const TextStyle(color: Colors.white)), // Customize button style
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                  ),
                ],
              );
            },
          );
        } else {
          showDialog(
            context: context,
            builder: (BuildContext context) {
              return AlertDialog(
                title: Text(
                  'added'.tr(),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
                actions: <Widget>[
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueGrey[700],
                    ),
                    child: Text('cdialogyes'.tr(), style: const TextStyle(color: Colors.white)), // Customize button style
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                  ),
                ],
              );
            },
          );
        }
        _loadProducts();
      }
    } catch (e) {
      print(e);
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
    setState(() {
      loading = false;
      _expireDate = null;
    });
  }

  void _updateProduct() async {
    setState(() {
      loadList = true;
    });
    try {
      Map<String, dynamic> yay = await SQLService.updateProduct(oldbarcode: _oldbarcode, barcode: barcodeController.text, name: nameController.text, wholesalePrice: double.parse(wholesalePriceController.text), price: double.parse(priceController.text), quantity: int.parse(quantityController.text), expire: _expireDate);
      setState(() {
        loadList = false;
      });
      if (yay['message'] == "duplicated") {
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text(
                'dubt'.tr(),
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.red,
                ),
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
      } else {
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text(
                'updated'.tr(),
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
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
    } catch (e) {
      setState(() {
        loadList = false;
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
    _loadProducts();
  }

  void _deleteProduct(String barcode) async {
    try {
      await SQLService.deleteProduct(barcode);
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text(
              'deleted'.tr(),
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
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
      _loadProducts();
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
    }
  }

  bool loading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'ptitle'.tr(),
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
              maxWidth: 1200, // Set maximum width
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Flexible(
                  child: SizedBox(
                    height: 650,
                    child: Form(
                      key: _formKey,
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Card(
                          elevation: 5,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Center(
                                  child: Text(
                                    "addproduct".tr(),
                                    style: const TextStyle(
                                      fontSize: 30,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.blueGrey,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 20),
                                TextFormField(
                                  cursorColor: Colors.blueGrey[600],
                                  decoration: InputDecoration(
                                    labelText: "barcode".tr(),
                                    labelStyle: const TextStyle(color: Colors.black),
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
                                  ),
                                  validator: (value) => value!.isEmpty ? '' : null,
                                  onSaved: (value) => _barcode = value!,
                                  controller: barController,
                                ),
                                const SizedBox(
                                  height: 10,
                                ),
                                TextFormField(
                                  cursorColor: Colors.blueGrey[600],
                                  decoration: InputDecoration(
                                    labelText: "pname".tr(),
                                    labelStyle: const TextStyle(color: Colors.black),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Colors.blueGrey, width: 3)),
                                  ),
                                  validator: (value) => value!.isEmpty ? '' : null,
                                  onSaved: (value) => _productName = value!,
                                ),
                                const SizedBox(
                                  height: 10,
                                ),
                                TextFormField(
                                  keyboardType: TextInputType.number,
                                  inputFormatters: <TextInputFormatter>[
                                    FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')), // Allows numbers and a single decimal point
                                  ],
                                  cursorColor: Colors.blueGrey[600],
                                  decoration: InputDecoration(
                                    labelText: "price".tr(),
                                    labelStyle: const TextStyle(color: Colors.black),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Colors.blueGrey, width: 3)),
                                  ),
                                  validator: (value) => value!.isEmpty ? '' : null,
                                  onSaved: (value) => _price = double.parse(value!),
                                ),
                                const SizedBox(
                                  height: 10,
                                ),
                                TextFormField(
                                  keyboardType: TextInputType.number,
                                  inputFormatters: <TextInputFormatter>[
                                    FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')), // Allows numbers and a single decimal point
                                  ],
                                  cursorColor: Colors.blueGrey[600],
                                  decoration: InputDecoration(
                                    labelText: "wholeprice".tr(),
                                    labelStyle: const TextStyle(color: Colors.black),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Colors.blueGrey, width: 3)),
                                  ),
                                  validator: (value) => value!.isEmpty ? '' : null,
                                  onSaved: (value) => _price2 = double.parse(value!),
                                ),
                                const SizedBox(
                                  height: 10,
                                ),
                                TextFormField(
                                  keyboardType: TextInputType.number,
                                  inputFormatters: <TextInputFormatter>[
                                    FilteringTextInputFormatter.digitsOnly, // Only numbers allowed
                                  ],
                                  cursorColor: Colors.blueGrey[600],
                                  decoration: InputDecoration(
                                    labelText: "quantity".tr(),
                                    labelStyle: const TextStyle(color: Colors.black),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Colors.blueGrey, width: 3)),
                                  ),
                                  validator: (value) => value!.isEmpty ? '' : null,
                                  onSaved: (value) => _quantity = int.parse(value!),
                                ),
                                const SizedBox(height: 10),
                                Row(
                                  children: [
                                    Flexible(
                                      child: TextFormField(
                                        controller: expireDateController,
                                        cursorColor: Colors.blueGrey[600],
                                        decoration: InputDecoration(
                                          labelText: "expire_date".tr(),
                                          labelStyle: const TextStyle(color: Colors.black),
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(10),
                                          ),
                                          focusedBorder: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(10),
                                            borderSide: const BorderSide(color: Colors.blueGrey, width: 3),
                                          ),
                                        ),
                                        readOnly: true,
                                        enabled: noTime,
                                        onTap: () async {
                                          DateTime? pickedDate = await showDatePicker(
                                            context: context,
                                            initialDate: DateTime.now(),
                                            firstDate: DateTime(2024),
                                            lastDate: DateTime(2101),
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
                                          if (pickedDate != null) {
                                            expireDateController.text = DateFormat('yyyy-MM-dd').format(pickedDate);
                                            _expireDate = pickedDate;
                                          }
                                        },
                                      ),
                                    ),
                                    Checkbox(
                                      activeColor: Colors.blueGrey[700],
                                      value: noTime,
                                      onChanged: (e) {
                                        setState(() {
                                          noTime = !noTime;
                                          expireDateController.text = "";
                                        });
                                        _expireDate = null;
                                      },
                                    )
                                  ],
                                ),
                                const SizedBox(height: 20),
                                Center(
                                  child: ElevatedButton(
                                    onPressed: () {
                                      if (!loading) {
                                        _addProduct();
                                      }
                                    },
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
                                              'cdialogadd'.tr(),
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
                const Padding(
                  padding: EdgeInsets.all(8.0),
                  child: ColoredBox(
                    color: Colors.grey,
                    child: SizedBox(
                      width: 1,
                      height: 2000,
                    ),
                  ),
                ),
                Flexible(
                  flex: 2,
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Text(
                          "products".tr(),
                          style: const TextStyle(
                            fontSize: 30,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: TextField(
                          cursorColor: Colors.blueGrey[600],
                          style: const TextStyle(color: Colors.white),
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
                          onChanged: (value) => _filterProducts(value),
                        ),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          const SizedBox(width: 15),
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: sort == 'date' ? Colors.green : Colors.blueGrey[700],
                            ),
                            onPressed: () {
                              sort = sort != 'date' ? 'date' : '';

                              _filterProducts(searchController.text);
                            },
                            label: Text(
                              'sortd'.tr(),
                              style: const TextStyle(color: Colors.white),
                            ),
                            icon: const Icon(
                              Icons.date_range,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(width: 10),
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: sort == 'quant' ? Colors.green : Colors.blueGrey[700],
                            ),
                            onPressed: () {
                              sort = sort != 'quant' ? 'quant' : '';
                              _filterProducts(searchController.text);
                            },
                            label: Text(
                              'sortq'.tr(),
                              style: const TextStyle(color: Colors.white),
                            ),
                            icon: const Icon(Icons.inventory, color: Colors.white),
                          ),
                        ],
                      ),
                      if (loadList)
                        const Center(
                          child: CircularProgressIndicator(
                            color: Colors.white,
                          ),
                        ),
                      if (!loadList)
                        Expanded(
                          child: ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            itemCount: _filteredProducts.length,
                            itemBuilder: (context, index) {
                              String barcode = _filteredProducts.keys.elementAt(index);
                              final product = _filteredProducts[barcode];

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
                                              product['productName'],
                                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
                                            ),
                                            Row(
                                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                              children: [
                                                Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    Row(
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
                                                    Row(
                                                      children: [
                                                        Text(
                                                          "${"quantity".tr()}: ",
                                                        ),
                                                        Text(
                                                          product['quantity'].toString(),
                                                          style: TextStyle(
                                                            fontWeight: FontWeight.bold,
                                                            color: product['quantity'] as int > 40
                                                                ? Colors.black
                                                                : product['quantity'] as int > 0
                                                                    ? Colors.orange
                                                                    : Colors.red,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                    if (product['expire'].toString() != "0")
                                                      Row(
                                                        children: [
                                                          Text(
                                                            "${'expire_date'.tr()}: ",
                                                          ),
                                                          Text(
                                                            product['expire'].toString(),
                                                            style: TextStyle(fontWeight: FontWeight.bold, color: getColorBasedOnDate(DateTime.tryParse(product['expire']) ?? DateTime.now())),
                                                          ),
                                                        ],
                                                      ),
                                                  ],
                                                ),
                                                Column(
                                                  crossAxisAlignment: CrossAxisAlignment.end,
                                                  children: [
                                                    Row(
                                                      children: [
                                                        Text(
                                                          "${"price".tr()}: ",
                                                        ),
                                                        Text(
                                                          "${nopoints ? (product['price']).toStringAsFixed(0) : product['price']}",
                                                          style: TextStyle(color: Colors.blueGrey[700], fontWeight: FontWeight.bold),
                                                        ),
                                                      ],
                                                    ),
                                                    Row(
                                                      children: [
                                                        Text(
                                                          "${"wholeprice".tr()}: ",
                                                        ),
                                                        Text(
                                                          "${nopoints ? (product['wholePrice']).toStringAsFixed(0) : product['wholePrice']}",
                                                          style: TextStyle(color: Colors.blueGrey[700], fontWeight: FontWeight.bold),
                                                        ),
                                                      ],
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
                                      Row(
                                        children: [
                                          IconButton(
                                            color: Colors.blue,
                                            onPressed: () {
                                              nameController.text = product['productName'];
                                              _oldbarcode = product['barcode'];
                                              barcodeController.text = product['barcode'];
                                              priceController.text = nopoints ? (product['price']).toStringAsFixed(0) : product['price'].toString();
                                              wholesalePriceController.text = nopoints ? (product['wholePrice']).toStringAsFixed(0) : product['wholePrice'].toString();
                                              quantityController.text = product['quantity'].toString();
                                              bool check = true;
                                              if (product['expire'].toString() != "0") {
                                                _expireDate = DateTime.parse(product['expire']);
                                                expireDateController2.text = product['expire'].toString();
                                              } else {
                                                check = false;
                                                _expireDate = null;
                                                expireDateController2.text = "";
                                              }

                                              showDialog(
                                                context: context,
                                                builder: (BuildContext context) {
                                                  return StatefulBuilder(
                                                    builder: (context, setState) => AlertDialog(
                                                      title: Text(
                                                        'pupdate'.tr(),
                                                        style: TextStyle(
                                                          fontWeight: FontWeight.bold,
                                                          color: Colors.blueGrey[700],
                                                        ),
                                                      ),
                                                      content: Column(
                                                        mainAxisSize: MainAxisSize.min,
                                                        children: [
                                                          TextFormField(
                                                            cursorColor: Colors.blueGrey[600],
                                                            controller: barcodeController,
                                                            decoration: InputDecoration(labelText: 'barcode'.tr(), focusedBorder: UnderlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Colors.blueGrey, width: 3)), labelStyle: const TextStyle(color: Colors.blueGrey)),
                                                          ),
                                                          const SizedBox(height: 10),
                                                          TextFormField(
                                                            cursorColor: Colors.blueGrey[600],
                                                            controller: nameController,
                                                            decoration: InputDecoration(labelText: 'pname'.tr(), focusedBorder: UnderlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Colors.blueGrey, width: 3)), labelStyle: const TextStyle(color: Colors.blueGrey)),
                                                          ),
                                                          const SizedBox(height: 10),
                                                          TextFormField(
                                                            cursorColor: Colors.blueGrey[600],
                                                            controller: priceController,
                                                            keyboardType: TextInputType.number,
                                                            decoration: InputDecoration(labelText: 'price'.tr(), focusedBorder: UnderlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Colors.blueGrey, width: 3)), labelStyle: const TextStyle(color: Colors.blueGrey)),
                                                            inputFormatters: <TextInputFormatter>[
                                                              FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')), // Allows numbers and a single decimal point
                                                            ],
                                                          ),
                                                          const SizedBox(height: 10),
                                                          TextFormField(
                                                            cursorColor: Colors.blueGrey[600],
                                                            controller: wholesalePriceController,
                                                            keyboardType: TextInputType.number,
                                                            inputFormatters: <TextInputFormatter>[
                                                              FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')), // Allows numbers and a single decimal point
                                                            ],
                                                            decoration: InputDecoration(labelText: 'wholeprice'.tr(), focusedBorder: UnderlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Colors.blueGrey, width: 3)), labelStyle: const TextStyle(color: Colors.blueGrey)),
                                                          ),
                                                          const SizedBox(height: 10),
                                                          TextFormField(
                                                            cursorColor: Colors.blueGrey[600],
                                                            controller: quantityController,
                                                            keyboardType: TextInputType.number,
                                                            inputFormatters: <TextInputFormatter>[
                                                              FilteringTextInputFormatter.digitsOnly, // Only numbers allowed
                                                            ],
                                                            decoration: InputDecoration(
                                                              labelText: 'quantity'.tr(),
                                                              focusedBorder: UnderlineInputBorder(
                                                                borderRadius: BorderRadius.circular(10),
                                                                borderSide: const BorderSide(color: Colors.blueGrey, width: 3),
                                                              ),
                                                              labelStyle: const TextStyle(color: Colors.blueGrey),
                                                            ),
                                                          ),
                                                          const SizedBox(height: 10),
                                                          Row(
                                                            children: [
                                                              Flexible(
                                                                child: TextFormField(
                                                                  enabled: check,
                                                                  controller: expireDateController2,
                                                                  cursorColor: Colors.blueGrey[600],
                                                                  decoration: InputDecoration(
                                                                    labelText: "expire_date".tr(),
                                                                    focusedBorder: UnderlineInputBorder(
                                                                      borderRadius: BorderRadius.circular(10),
                                                                      borderSide: const BorderSide(color: Colors.blueGrey, width: 3),
                                                                    ),
                                                                    labelStyle: const TextStyle(color: Colors.blueGrey),
                                                                  ),
                                                                  readOnly: true,
                                                                  onTap: () async {
                                                                    DateTime? pickedDate = await showDatePicker(
                                                                      context: context,
                                                                      initialDate: DateTime.now(),
                                                                      firstDate: DateTime(2024),
                                                                      lastDate: DateTime(2101),
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
                                                                    if (pickedDate != null) {
                                                                      expireDateController2.text = DateFormat('yyyy-MM-dd').format(pickedDate);
                                                                      _expireDate = pickedDate;
                                                                    }
                                                                  },
                                                                ),
                                                              ),
                                                              Checkbox(
                                                                activeColor: Colors.blueGrey[700],
                                                                value: check,
                                                                onChanged: (e) {
                                                                  setState(() {
                                                                    check = !check;
                                                                    expireDateController2.text = "";
                                                                    _expireDate = null;
                                                                  });
                                                                },
                                                              )
                                                            ],
                                                          ),
                                                        ],
                                                      ),
                                                      actions: [
                                                        TextButton(
                                                          onPressed: () {
                                                            Navigator.of(context).pop();
                                                          },
                                                          child: Text(
                                                            'cdialogno'.tr(),
                                                            style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                                                          ),
                                                        ),
                                                        TextButton(
                                                          style: ElevatedButton.styleFrom(
                                                            backgroundColor: Colors.blueAccent,
                                                          ),
                                                          onPressed: () {
                                                            if (barcodeController.text.isNotEmpty && nameController.text.isNotEmpty && priceController.text.isNotEmpty && wholesalePriceController.text.isNotEmpty) {
                                                              _updateProduct();
                                                              Navigator.of(context).pop();
                                                            }
                                                          },
                                                          child: Text(
                                                            'updatebtn'.tr(),
                                                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  );
                                                },
                                              );
                                            },
                                            icon: const Icon(Icons.edit),
                                          ),
                                          const SizedBox(
                                            width: 10,
                                          ),
                                          IconButton(
                                            color: Colors.red,
                                            onPressed: () async {
                                              bool? confirmed = await showDialog<bool>(
                                                context: context,
                                                builder: (context) {
                                                  return AlertDialog(
                                                    title: Text(
                                                      'cdialogttitle'.tr(),
                                                      style: TextStyle(
                                                        fontWeight: FontWeight.bold,
                                                        color: Colors.blueGrey[700], // Customize the color
                                                      ),
                                                    ),
                                                    content: Text(
                                                      "deletec".tr(),
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
                                                          backgroundColor: Colors.red,
                                                        ),
                                                        onPressed: () {
                                                          Navigator.of(context).pop(true);
                                                        },
                                                        child: Text('delete'.tr(), style: const TextStyle(color: Colors.white)),
                                                      ),
                                                    ],
                                                  );
                                                },
                                              );

                                              if (confirmed == true) {
                                                _deleteProduct(product['barcode']);
                                              }
                                            },
                                            icon: const Icon(Icons.delete),
                                          ),
                                        ],
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
              ],
            ),
          ),
        ),
      ),
    );
  }
}

extension MapUtils<K, V> on Map<K, V> {
  Map<K, V> where(bool Function(K, V) condition) {
    Map<K, V> result = {};
    for (var element in entries) {
      if (condition(element.key, element.value)) {
        result[element.key] = element.value;
      }
    }
    return result;
  }
}
