import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../sql.dart';

class UsersPage extends StatefulWidget {
  final int level;
  final String name;

  const UsersPage({super.key, required this.level, required this.name});

  @override
  State<UsersPage> createState() => _UsersPageState();
}

class _UsersPageState extends State<UsersPage> {
  List<Map<String, dynamic>> users = [];
  List<String> info = [];
  bool isLoading = true;

  TextEditingController title = TextEditingController();
  TextEditingController pass = TextEditingController();
  TextEditingController chat = TextEditingController();

  @override
  void initState() {
    super.initState();
    loadUsers();
    loadMarket();
  }

  Future<void> loadMarket() async {
    info.clear();
    List<String?> cred = await SQLService.retrieveCredentials();
    String? id = await SQLService.retrieveChatID();
    cred.add(id);
    info = cred.whereType<String>().toList();
  }

  Future<void> _showAddUserDialog(BuildContext context, int rolelevle, String name, String pass, int id) async {
    bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AddUserDialog(
          level: widget.level,
          userLevel: rolelevle,
          name: name,
          pass: pass,
          id: id,
          button: 'updatebtn'.tr(),
          title: 'updateuser'.tr(),
        );
      },
    );
    if (confirmed == true) {
      loadUsers();
    }
  }

  Future<void> _showAddUserDialog2(BuildContext context) async {
    bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AddUserDialog(
          level: widget.level,
          userLevel: 0,
          name: "",
          pass: "",
          id: 0,
          button: 'cdialogadd'.tr(),
          title: 'adduser'.tr(),
        );
      },
    );
    if (confirmed == true) {
      loadUsers();
    }
  }

  Future<void> loadUsers() async {
    try {
      setState(() {
        isLoading = true;
      });

      Map<String, dynamic> result = await SQLService.getUsers();

      if (result['status'] == 'success') {
        setState(() {
          List<Map<String, dynamic>> userss = List<Map<String, dynamic>>.from(result['users']);
          if (widget.level != 5) {
            for (Map<String, dynamic> m in userss) {
              if (int.parse(m['is_admin']) != 5) users.add(m);
            }
          } else {
            users = userss;
          }
          isLoading = false;
        });
      } else {
        setState(() {
          users = [];
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        users = [];
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

  String getRole(int level) {
    if (level == 0) {
      return 'a0'.tr();
    } else if (level == 1) {
      return 'a1'.tr();
    } else if (level == 2) {
      return 'a2'.tr();
    } else if (level == 3) {
      return 'a3'.tr();
    } else if (level == 4) {
      return 'a4'.tr();
    }
    return 'a5'.tr();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "userspage".tr(),
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: Colors.blueGrey[900],
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () {
            Navigator.pop(context);
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
        child: isLoading
            ? const Center(
                child: CircularProgressIndicator(
                  color: Colors.white,
                ),
              )
            : Center(
                child: Padding(
                  padding: const EdgeInsets.all(18.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        constraints: const BoxConstraints(
                          maxWidth: 400,
                        ),
                        child: Column(
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.blue.shade600.withOpacity(0.5),
                                ),
                                onPressed: () {
                                  _showAddUserDialog2(context);
                                },
                                icon: const Icon(
                                  Icons.add,
                                  color: Colors.white,
                                ),
                                label: Text(
                                  "adduser".tr(),
                                  style: const TextStyle(color: Colors.white),
                                ),
                              ),
                            ),
                            Expanded(
                              child: ListView.builder(
                                itemCount: users.length,
                                itemBuilder: (context, index) {
                                  var user = users[index];
                                  int selectedRole = int.parse(user['is_admin']);

                                  return Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 18.0),
                                    child: Card(
                                      elevation: 5,
                                      margin: const EdgeInsets.symmetric(vertical: 10),
                                      child: Padding(
                                        padding: const EdgeInsets.all(18.0),
                                        child: Row(
                                          children: [
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [

                                                  Row(
                                                    children: [
                                                      Text(
                                                        "${"username".tr()}: ",
                                                      ),
                                                      Text(
                                                        "${user['name']}",
                                                        style: const TextStyle(fontWeight: FontWeight.bold),
                                                      ),
                                                    ],
                                                  ),

                                                  const SizedBox(height: 10),
                                                  if(widget.level==5 || (selectedRole==4 && user['name']==widget.name.toLowerCase()) || selectedRole<4)
                                                  Row(
                                                    children: [
                                                      Text(
                                                        "${"password".tr()}: ",
                                                      ),
                                                      Tooltip(
                                                        message: user['pass'],
                                                        child: const Text(
                                                          "********",
                                                          style: TextStyle(fontWeight: FontWeight.bold),
                                                        ),
                                                      ),
                                                    ],
                                                  ),

                                                  const SizedBox(height: 10),
                                                  Row(
                                                    children: [
                                                      Text(
                                                        "${"perm".tr()}: ",
                                                      ),
                                                      Text(
                                                        getRole(int.parse(user['is_admin'])),
                                                        style: const TextStyle(fontWeight: FontWeight.bold),
                                                      ),
                                                    ],
                                                  ),
                                                  // Save button
                                                ],
                                              ),
                                            ),
                                            Column(
                                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                              children: [
                                                if(widget.level==5 || (selectedRole==4 && user['name']==widget.name.toLowerCase()) || selectedRole<4)
                                                IconButton(
                                                  color: Colors.blue,
                                                  onPressed: () {
                                                    _showAddUserDialog(context, selectedRole, user['name'], user['pass'], int.parse(user['id']));
                                                  },
                                                  icon: const Icon(Icons.edit),
                                                ),
                                                const SizedBox(
                                                  height: 20,
                                                ),
                                                if(user['name']!=widget.name.toLowerCase())
                                                  if(widget.level==5 || selectedRole!=4)
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
                                                              "deletecu".tr(),
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
                                                        try {
                                                          await SQLService.removeUser(int.parse(user['id']));
                                                          loadUsers();
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
                                                    },
                                                    icon: const Icon(Icons.delete),
                                                  ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (widget.level == 5)
                        Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Center(
                            child: Container(
                              constraints: const BoxConstraints(
                                maxWidth: 400,
                              ),
                              child: Card(
                                elevation: 8,
                                shadowColor: Colors.blueGrey.withOpacity(0.3),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(15),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(16.0),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      // Title Section with Divider
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.center,
                                        children: [
                                          Text(
                                            "Market Information",
                                            style: TextStyle(
                                              fontSize: 24,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.blueGrey[700],
                                            ),
                                          ),
                                          const Divider(
                                            thickness: 1.5,
                                            color: Colors.blueGrey,
                                            height: 30,
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 16),

                                      // Info Rows
                                      buildInfoRow(Icons.store, "title".tr(), info[0]),
                                      buildInfoRow(Icons.account_circle, "muser".tr(), info[1]),
                                      buildPasswordRow(Icons.lock, "password".tr(), info[2]),
                                      buildInfoRow(Icons.chat, "tele".tr(), info[3]),

                                      const SizedBox(height: 10),
                                      ElevatedButton(
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.blueGrey[700],
                                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(10),
                                          ),
                                        ),
                                        onPressed: () async {
                                          title.text = info[0];
                                          pass.text = info[2];
                                          chat.text = info[3];
                                          await showDialog(
                                            context: context,
                                            builder: (BuildContext context) {
                                              return AlertDialog(
                                                title: Text('updash'.tr(),style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.blueGrey[700],
                                                ),),
                                                content: Column(
                                                  mainAxisSize: MainAxisSize.min,
                                                  children: [
                                                    TextFormField(
                                                      cursorColor: Colors.blueGrey[600],
                                                      controller: title,
                                                      decoration: InputDecoration(labelText: 'title'.tr(), focusedBorder: UnderlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Colors.blueGrey, width: 3)), labelStyle: const TextStyle(color: Colors.blueGrey)),
                                                    ),
                                                    const SizedBox(height: 10),
                                                    TextFormField(
                                                      cursorColor: Colors.blueGrey[600],
                                                      controller: pass,
                                                      decoration: InputDecoration(labelText: 'password'.tr(), focusedBorder: UnderlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Colors.blueGrey, width: 3)), labelStyle: const TextStyle(color: Colors.blueGrey)),
                                                    ),
                                                    const SizedBox(height: 10),
                                                    TextFormField(
                                                      cursorColor: Colors.blueGrey[600],
                                                      controller: chat,
                                                      keyboardType: TextInputType.number,
                                                      decoration: InputDecoration(labelText: 'tele'.tr(), focusedBorder: UnderlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Colors.blueGrey, width: 3)), labelStyle: const TextStyle(color: Colors.blueGrey)),
                                                      inputFormatters: <TextInputFormatter>[
                                                        FilteringTextInputFormatter.digitsOnly, // Only numbers allowed
                                                      ],
                                                    ),
                                                    const SizedBox(height: 10),
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
                                                    onPressed: () async {
                                                      try{
                                                        await SQLService.updateInfo(title.text, pass.text, chat.text);

                                                        Navigator.of(context).pop();
                                                      } catch (e){
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
                                                    },
                                                    child: Text(
                                                      'updatebtn'.tr(),
                                                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                                    ),
                                                  ),
                                                ],
                                              );
                                            },
                                          );
                                          await Future.delayed(const Duration(milliseconds: 500));
                                          await loadMarket();
                                          setState(() {});
                                        },
                                        child: Padding(
                                          padding: const EdgeInsets.all(4.0),
                                          child: Text("edit".tr(),style: const TextStyle(color: Colors.white,fontSize: 20,fontWeight: FontWeight.bold),),
                                        ),
                                      )
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        )
                    ],
                  ),
                ),
              ),
      ),
    );
  }
}

Widget buildInfoRow(IconData icon, String label, String content) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 8.0),
    child: Row(
      children: [
        Icon(icon, color: Colors.blueGrey[700], size: 28),
        const SizedBox(width: 12),
        Text(
          label,
          style: TextStyle(fontSize: 18, color: Colors.blueGrey[600]),
        ),
        const Spacer(),
        Text(
          content,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
        ),
      ],
    ),
  );
}

// Password row with tooltip
Widget buildPasswordRow(IconData icon, String label, String content) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 8.0),
    child: Row(
      children: [
        Icon(icon, color: Colors.blueGrey[700], size: 28),
        const SizedBox(width: 12),
        Text(
          label,
          style: TextStyle(fontSize: 18, color: Colors.blueGrey[600]),
        ),
        const Spacer(),
        Tooltip(
          message: content,
          child: const Text(
            "********",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
          ),
        ),
      ],
    ),
  );
}

class AddUserDialog extends StatefulWidget {
  final String name, pass, button, title;
  final int userLevel, id, level;

  const AddUserDialog({super.key, required this.userLevel, required this.name, required this.pass, required this.id, required this.button, required this.title, required this.level});

  @override
  State<AddUserDialog> createState() => _AddUserDialogState();
}

class _AddUserDialogState extends State<AddUserDialog> {
  TextEditingController nameController = TextEditingController();
  TextEditingController passController = TextEditingController();
  int selectedRole = 0;

  @override
  void initState() {
    nameController = TextEditingController(text: widget.name);
    passController = TextEditingController(text: widget.pass);
    selectedRole = widget.userLevel;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        widget.title,
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: Colors.blueGrey[700], // Customize the color
        ),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Username field
            TextField(
              inputFormatters: [
                FilteringTextInputFormatter.deny(RegExp(r'\s')), // Deny spaces
              ],
              cursorColor: Colors.blueGrey,
              controller: nameController,
              decoration: InputDecoration(
                labelText: 'username'.tr(),
                labelStyle: const TextStyle(color: Colors.black),
                border: const OutlineInputBorder(),
                focusedBorder: const OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.blueGrey, width: 2), // Change the focused border color here
                ),
              ),
            ),
            const SizedBox(height: 10),

            // Password field
            TextField(
              cursorColor: Colors.blueGrey,
              controller: passController,
              decoration: InputDecoration(
                labelText: 'password'.tr(),
                labelStyle: const TextStyle(color: Colors.black),
                border: const OutlineInputBorder(),
                focusedBorder: const OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.blueGrey, width: 2), // Change the focused border color here
                ),
              ),
            ),
            const SizedBox(height: 10),

            if (widget.userLevel < 5)
              if((widget.userLevel== 4 && widget.level == 5) || widget.userLevel < 4 )
              DropdownButtonFormField<int>(
                value: widget.userLevel,
                decoration: InputDecoration(
                  focusedBorder: const OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.blueGrey, width: 2), // Change the focused border color here
                  ),
                  labelText: 'perm'.tr(),
                  labelStyle: const TextStyle(color: Colors.black),
                  border: const OutlineInputBorder(),
                  focusColor: Colors.blueGrey,
                ),
                items: [
                  DropdownMenuItem(
                    value: 0,
                    child: Text('a0'.tr()),
                  ),
                  DropdownMenuItem(
                    value: 1,
                    child: Text('a1'.tr()),
                  ),
                  DropdownMenuItem(
                    value: 2,
                    child: Text('a2'.tr()),
                  ),
                  DropdownMenuItem(
                    value: 3,
                    child: Text('a3'.tr()),
                  ),
                  if(widget.level == 5)
                  DropdownMenuItem(
                    value: 4,
                    child: Text('a4'.tr()),
                  ),
                ],
                onChanged: (value) {
                  setState(() {
                    selectedRole = value!;
                  });
                },
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop(false);
          },
          child: Text(
            'cdialogno'.tr(),
            style: const TextStyle(color: Colors.red),
          ),
        ),
        TextButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blueAccent,
          ),
          onPressed: () async {
            try {
              if (widget.button == "Add") {
                await SQLService.addUser(nameController.text, passController.text, selectedRole);
              } else {
                await SQLService.updateUser(widget.id, nameController.text, passController.text, selectedRole);
              }
            } catch (e) {/**/}
            Navigator.of(context).pop(true);
          },
          child: Text(
            widget.button,
            style: const TextStyle(color: Colors.white),
          ),
        ),
      ],
    );
  }
}
