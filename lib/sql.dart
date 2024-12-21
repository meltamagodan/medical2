import 'dart:convert';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

class SQLService {
  static const storage = FlutterSecureStorage();
  static String baseUrl = 'https://albayar.co/supermarket/';

  static Future<void> botSendMessage(String message) async {
    String? id = await retrieveChatID();
    await http.post(Uri.parse("https://api.telegram.org/bot7514814974:AAEnHtUKLUhNLd1yywsBBERmRDxAeEY9dhY/sendMessage?chat_id=$id&parse_mode=Markdown&text=$message"));
  }

  static Future<String> marketLogin({
    required String name,
    required String pass,
  }) async {
    final url = Uri.parse('${baseUrl}market_login.php');

    // Data to send
    final data = {
      'name': name,
      'pass': pass,
    };

    final response = await http.post(url, body: data);

    // Parse response
    if (response.statusCode == 200) {
      final result = jsonDecode(response.body);
      if(result['message'].isNotEmpty){
        saveCredentials(result['marketname'],name,pass,result['chat']);
        return result['marketname'];
      }
      return '';
    } else {
      return '';
    }
  }

  static Future<String> userLogin({
    required String username,
    required String pass,
  }) async {
    final marketName = await retrieveName();

    if (marketName.isEmpty) {
      return '';
    }

    final url = Uri.parse('${baseUrl}user_login.php');

    // Data to send
    final data = {
      'marketName': marketName,
      'username': username,
      'pass': pass,
    };

    final response = await http.post(url, body: data);

    // Parse response
    if (response.statusCode == 200) {
      final result = jsonDecode(response.body);
      if (result['status'] == 'success') {
        return result['is_admin'];
      } else {
        return '';
      }
    } else {
      return '';
    }
  }

  static Future<void> saveCredentials(String marketName,String name, String password, String chatID) async {
    try {
      await storage.write(key: 'marketName', value: marketName);
      await storage.write(key: 'name', value: name);
      await storage.write(key: 'password', value: password);
      await storage.write(key: 'chat', value: chatID);
      print('Credentials saved successfully');
    } catch (e) {
      print('Error saving credentials: $e');
    }
  }

  static Future<List<String?>> retrieveCredentials() async {
    try {
      String? name = await storage.read(key: 'marketName');
      String? user = await storage.read(key: 'name');
      String? pass = await storage.read(key: 'password');

      if (user != null) {
        return [name,user,pass];
      } else {
        return [];
      }
    } catch (e) {
      print('Error retrieving credentials: $e');
      return [];
    }
  }

  static Future<String> retrieveChatID() async {
    try {
      String? chat = await storage.read(key: 'chat');

      if (chat != null) {
        return chat;
      } else {
        return "";
      }
    } catch (e) {
      print('Error retrieving credentials: $e');
      return "";
    }
  }

  static Future<String> retrieveName() async {
    try {
      String? marketName = await storage.read(key: 'name');

      if (marketName != null) {
        return marketName;
      } else {
        return "";
      }
    } catch (e) {
      print('Error retrieving credentials: $e');
      return "";
    }
  }

  static Future<void> deleteCredentials() async {
    try {
      await storage.delete(key: 'marketName');
      await storage.delete(key: 'name');
      await storage.delete(key: 'password');
      await storage.delete(key: 'chat');
      print('Credentials deleted successfully');
    } catch (e) {
      print('Error deleting credentials: $e');
    }
  }

  static Future<Map<String, dynamic>> getProducts() async {
    final marketName = await retrieveName();  // Retrieve market name from secure storage

    if (marketName.isEmpty) {
      return {'status': 'error', 'message': 'Market not found'};
    }

    final url = Uri.parse('${baseUrl}get_products.php');

    // Data to send
    final data = {
      'marketName': marketName,
    };

    final response = await http.post(url, body: data);

    // Parse response
    if (response.statusCode == 200) {
      final result = jsonDecode(response.body);
      if (result.isNotEmpty) {
        return {
          "products": result
        };
      } else {
        return {};
      }
    } else {
      return {};
    }
  }

  static Future<Map<String, dynamic>> addProduct({
    required String barcode,
    required String name,
    required double price,
    required double wholesalePrice,
    required int quantity,
    required DateTime? expireDate,
  }) async {
    final marketName = await retrieveName();
    final url = Uri.parse('${baseUrl}manage_products.php');
    final formattedExpireDate = expireDate==null ? null : DateFormat('yyyy-MM-dd').format(expireDate);

    final data = {
      'action': 'add',
      'marketName': marketName,
      'barcode': barcode,
      'name': name,
      'price': price.toString(),
      'wholesale_price': wholesalePrice.toString(),
      'quantity': quantity.toString(),
      if (formattedExpireDate != null) 'expire_date': formattedExpireDate,
    };

    final response = await http.post(url, body: data);
    return jsonDecode(response.body);

  }

  static Future<Map<String, dynamic>> updateProduct({
    required String oldbarcode,
    required String barcode,
    required String name,
    required double price,
    required double wholesalePrice,
    required int quantity,
    required DateTime? expire,
  }) async {
    final marketName = await retrieveName();

    final url = Uri.parse('${baseUrl}manage_products.php');
    final formattedExpireDate = expire==null ? null : DateFormat('yyyy-MM-dd').format(expire);


    final data = {
      'action': 'update',
      'marketName': marketName,
      'oldbarcode': oldbarcode,
      'barcode': barcode,
      'name': name,
      'price': price.toString(),
      'wholesale_price': wholesalePrice.toString(),
      'quantity': quantity.toString(),
      if (formattedExpireDate != null) 'expire_date': formattedExpireDate,
    };

    final response = await http.post(url, body: data);

    print(response.body);

    return jsonDecode(response.body);
  }

  static Future<Map<String, dynamic>> deleteProduct(String barcode) async {
    final marketName = await retrieveName();

    final url = Uri.parse('${baseUrl}manage_products.php');

    final data = {
      'action': 'delete',
      'marketName': marketName,
      'barcode': barcode,
    };

    final response = await http.post(url, body: data);

    return jsonDecode(response.body);
  }

  static Future<void> updateInfo(String title,String pass, String chat) async {
    final marketName = await retrieveName();

    final url = Uri.parse('${baseUrl}update_market.php');

    final data = {
      'title': title,
      'user': marketName,
      'pass': pass,
      'chat': chat
    };

    final response = await http.post(url, body: data);

    if (response.statusCode == 200) {
      saveCredentials(title, marketName, pass, chat);
      var jsonResponse = jsonDecode(response.body);
      print(jsonResponse['message']);
    } else {
      print('Error: ${response.statusCode}');
    }
  }

  static Future<void> decreaseQuantities(List<Map<String,dynamic>> scannedProducts, String username) async {
    final marketName = await retrieveName();
    final response = await http.post(
      Uri.parse('${baseUrl}manage_products.php'),
      body: {
        'action': 'decrease-quantity',
        'marketName': marketName,
        'scannedProducts': jsonEncode(scannedProducts),
        'username': username
      },
    );

    if (response.statusCode == 200) {
      var jsonResponse = jsonDecode(response.body);
      print(jsonResponse['message']);
    } else {
      print('Error: ${response.statusCode}');
    }
  }

  static Future<void> saveToPurchaseHistory(List<Map<String, dynamic>> scannedProducts) async {
    final String url = '${baseUrl}save_to_history.php';
    final marketName = await retrieveName();
    // Create the body of the request
    final Map<String, dynamic> body = {
      'scannedProducts': json.encode(scannedProducts),
      'marketName': marketName,
    };

    try {
      // Send POST request to save_to_history.php
      final response = await http.post(
        Uri.parse(url),
        body: body,
      );

      // Check the response status
      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        if (responseData['status'] == 'success') {
          print('Products saved to purchase history successfully');
          // Handle success, e.g., show a confirmation message to the user
        } else {
          print('Error: ${responseData['message']}');
          // Handle error, e.g., show an error message to the user
        }
      } else {
        print('Error: ${response.statusCode}');
        // Handle network error or server error
      }
    } catch (e) {
      print('An error occurred: $e');
      // Handle exception, e.g., show an error message to the user
    }
  }

  static Future<bool> checkCode(String code) async {
    final response = await http.post(
      Uri.parse('${baseUrl}check_activation_code.php'),
      body: {
        "code": code
      },
    );

    if (response.statusCode == 200) {
      var jsonResponse = jsonDecode(response.body);
      if(jsonResponse['status']=="success"){
        return true;
      }
      return false;
    } else {
      return false;
    }
  }

  static Future<List<Map<String, dynamic>>> getSoldProductsInRange(DateTime start, DateTime end) async {
    final marketName = await retrieveName();  // Retrieve market name from secure storage

    if (marketName.isEmpty) {
      return [];  // Return an empty list if market name is not found
    }

    final url = Uri.parse('${baseUrl}get_sold_products_in_range.php'); // Update the URL to your PHP script

    // Data to send
    final data = {
      'marketName': marketName,
      'start_date': start.toIso8601String(),
      'end_date': end.toIso8601String(),
    };

    final response = await http.post(url, body: data);

    // Parse response
    if (response.statusCode == 200) {
      final result = jsonDecode(response.body);
      if (result['status'] == 'success') {
        List<Map<String, dynamic>> soldProducts = List<Map<String, dynamic>>.from(result['soldProducts']);
        return soldProducts;
      } else {
        print('Error: ${result['message']}');
        return [];  // Return empty list on error
      }
    } else {
      print('Error: Failed to fetch sold products. Status code: ${response.statusCode}');
      return [];  // Return empty list if the request failed
    }
  }

  static Future<Map<String, dynamic>> getUsers() async {
    final marketName = await retrieveName();  // Retrieve the market name from secure storage

    if (marketName.isEmpty) {
      return {'status': 'error', 'message': 'Market not found'};
    }

    final url = Uri.parse('${baseUrl}get_users.php');  // PHP script URL

    // Data to send
    final data = {'marketName': marketName};

    final response = await http.post(url, body: data);

    if (response.statusCode == 200) {
      final result = jsonDecode(response.body);
      if (result['status'] == 'success') {
        return {
          'status': 'success',
          'users': result['users'],
        };
      } else {
        return {
          'status': 'error',
          'message': result['message'],
        };
      }
    } else {
      return {
        'status': 'error',
        'message': 'Failed to fetch users. Status code: ${response.statusCode}',
      };
    }
  }

  static Future<Map<String, dynamic>> getPurchaseHistory(String date) async {
    final marketName = await retrieveName();  // Retrieve market name from secure storage

    if (marketName.isEmpty) {
      return {'status': 'error', 'message': 'Market not found'};
    }

    final url = Uri.parse('${baseUrl}get_purchase_history.php'); // Update to the appropriate PHP script

    // Data to send
    final data = {
      'marketName': marketName,
      'date': date,
    };

    final response = await http.post(url, body: data);

    // Parse response
    if (response.statusCode == 200) {
      final result = jsonDecode(response.body);

      if (result['status'] == 'success') {
        // Grouping products by date
        final List<dynamic> rawPurchaseHistory = result['purchaseHistory'];
        final Map<String, List<dynamic>> groupedPurchaseHistory = {};

        // Iterate over each purchase in the response
        for (var purchase in rawPurchaseHistory) {
          String purchaseDate = purchase['date']; // Get the date of the current purchase

          // If the date already exists in the map, add the product to that date's list
          if (groupedPurchaseHistory.containsKey(purchaseDate)) {
            groupedPurchaseHistory[purchaseDate]!.add(purchase);
          } else {
            // If the date doesn't exist, create a new list with the product
            groupedPurchaseHistory[purchaseDate] = [purchase];
          }
        }

        // Prepare the final structure to return
        final List<Map<String, dynamic>> formattedPurchaseHistory = [];

        groupedPurchaseHistory.forEach((date, products) {
          formattedPurchaseHistory.add({
            'date': date,
            'products': products,
          });
        });

        return {
          'status': 'success',
          'purchaseHistory': formattedPurchaseHistory,
        };
      } else {
        return {
          'status': 'error',
          'message': result['message'],
        };
      }
    } else {
      return {
        'status': 'error',
        'message': 'Failed to fetch purchase history. Status code: ${response.statusCode}',
      };
    }
  }

  static Future<Map<String, dynamic>> addUser(String name, String pass, int isAdmin) async {
    final url = Uri.parse('${baseUrl}update_user.php');
    final marketName = await retrieveName();
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'action': 'add',
        'name': name,
        'pass': pass,
        'is_admin': isAdmin,
        'marketName': marketName
      }),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to add user');
    }
  }

  // Method to remove a user
  static Future<Map<String, dynamic>> removeUser(int id) async {
    final url = Uri.parse('${baseUrl}update_user.php');
    final marketName = await retrieveName();

    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'id': id,
        'action': 'remove',
        'marketName': marketName
      }),
    );

    print(response.body);
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to remove user');
    }
  }

  // Method to update a user
  static Future<Map<String, dynamic>> updateUser(int id, String name, String pass, int isAdmin) async {
    final url = Uri.parse('${baseUrl}update_user.php');
    final marketName = await retrieveName();

    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'action': 'update',
        'id': id,
        'name': name,
        'pass': pass,
        'is_admin': isAdmin,
        'marketName': marketName
      }),
    );

    if (response.statusCode == 200) {
      print(response.body);
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to update user');
    }
  }

}
