import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:bitmaelum_flutter_client/sendMessage.dart';
import 'package:bitmaelum_flutter_client/showMessage.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:bitmaelum_flutter_plugin/bitmaelum_flutter_plugin.dart';
import 'package:loader_overlay/loader_overlay.dart';
import 'package:rflutter_alert/rflutter_alert.dart';
import 'package:select_dialog/select_dialog.dart';

import 'listMessages.dart';

const platform = const MethodChannel('bitmaelum.network/client');

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    var routes = <String, WidgetBuilder>{
      MySendMessage.routeName: (BuildContext context) => new MySendMessage(title: "Send Message"),
      MyListMessage.routeName: (BuildContext context) => new MyListMessage(title: "List Messages"),
      MyShowMessage.routeName: (BuildContext context) => new MyShowMessage(),
    };

    return GlobalLoaderOverlay(
      useDefaultLoading: true,
      child: MaterialApp(
      title: 'BitMaelum',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: new MyHomePage(title: 'BitMaelum'),
      routes : routes,
    ));
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);

  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  String _accountName;
  String _accountAddress;

  bool _profileLoaded = false;

  File _fileVault;
  String _password;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: _profileLoaded ? MainAxisAlignment.start : MainAxisAlignment.center,
          children: _profileLoaded ? 
            <Widget>[
            Column(
              mainAxisAlignment: MainAxisAlignment.start,
              children: <Widget>[
                Container(
                  margin: const EdgeInsets.only(top: 20.0),
                  child: Text(_accountName, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 30)),
                ),
                Container(
                  margin: const EdgeInsets.only(top: 10.0),
                  child: Text(_accountAddress, style: TextStyle(fontSize: 15)),
                ),
              ],
            ),
            Expanded( child: Column (
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Container(
                  margin: const EdgeInsets.only(bottom: 10.0),
                  child: ElevatedButton.icon(
                    icon: Icon(Icons.send),
                    label: Text("Send a Message"),
                    onPressed: () {Navigator.pushNamed(context, '/send');} 
                  ),
                ),
                Container(
                  margin: const EdgeInsets.only(bottom: 10.0),
                  child: ElevatedButton.icon(
                    icon: Icon(Icons.mail),
                    label: Text("List Inbox"),
                    onPressed: () {Navigator.pushNamed(context, '/list');} 
                  ),
                ),
              ]
            ))]
            :
            <Widget>[
              Container(
                margin: const EdgeInsets.only(bottom: 10.0),
                child: ElevatedButton.icon(
                  label:  Text("Load a profile from a vault"),
                  icon: Icon(Icons.file_upload),
                  onPressed: _loadVault
                ),
              ),
              Container(
                margin: const EdgeInsets.only(bottom: 10.0),
                child: ElevatedButton.icon(
                  label: Text("Enter a mnemonic"),
                  icon: Icon(Icons.text_snippet),
                  onPressed: () {askForMnemonic(context);}
                ),
              ),
              Container(
                margin: const EdgeInsets.only(bottom: 10.0),
                child: ElevatedButton.icon(
                  icon: Icon(Icons.lock),
                  label: Text("Enter a private key"),
                  onPressed: (){askForPrivateKey(context);}
                ),
              ),
            ],
        ),
      ) // This trailing comma makes auto-formatting nicer for build methods.
    );
  }


  askForPassword(BuildContext context) {
    void completed() {
      _openVault(_fileVault.path, _password);
      Navigator.pop(context);
    }
    Alert(
        context: context,
        title: "Enter your password",
        content: Column(
          children: <Widget>[
            TextFormField(
              autocorrect: false,
              autofocus: true,
              onFieldSubmitted: (_) => {completed()},
              onChanged: (val) {
                _password = val;
                return null;
              },
              obscureText: true,
            ),
          ],
        ),
        buttons: [
          DialogButton(
            onPressed: () => Navigator.pop(context),
            color: Colors.white,
            child: Text(
              "Cancel",
              style: TextStyle(color: Colors.black, fontSize: 20),
            ),
          ),
          DialogButton(
            onPressed: completed,
            child: Text(
              "Open",
              style: TextStyle(color: Colors.white, fontSize: 20),
            ),
          )
        ]).show();
  }


  askForMnemonic(BuildContext context) {

    var _mnemonic;

    Alert(
        context: context,
        title: "Enter your details",
        content: Column(
          children: <Widget>[
            TextFormField(
              autocorrect: false,
              autofocus: true,
              decoration: const InputDecoration(
                icon: Icon(Icons.email),
                hintText: 'johndoe!',
                labelText: 'BitMaelum Address',
              ),
              onChanged: (val) {
                _accountAddress = val;
                return null;
              },
            ),

            TextFormField(
              autocorrect: false,
              autofocus: true,
              decoration: const InputDecoration(
                icon: Icon(Icons.person),
                hintText: 'John Doe',
                labelText: 'Name',
              ),
              onChanged: (val) {
                _accountName = val;
                return null;
              },
            ),

            TextFormField(
              autocorrect: false,
              autofocus: true,
              decoration: const InputDecoration(
                icon: Icon(Icons.text_snippet),
                hintText: 'ed25519 rocket sword same pacific...',
                labelText: 'Mnemonic',
              ),
              onChanged: (val) {
                _mnemonic = val;
                return null;
              },
            ),
          ],
        ),
        buttons: [
          DialogButton(
            onPressed: () => Navigator.pop(context),
            color: Colors.white,
            child: Text(
              "Cancel",
              style: TextStyle(color: Colors.black, fontSize: 20),
            ),
          ),
          DialogButton(
            onPressed: () {
              () async {
                try {
                  await(BitmaelumClientPlugin.setClientFromMnemonic(_accountAddress, _accountName, _mnemonic));

                  setState(() {
                    _profileLoaded = true;
                  });
                } on BitmaelumException catch(exception) {
                  Alert(context: context, title: "Error", desc: exception.cause).show();
                }

              }();

               Navigator.pop(context);
            },
            child: Text(
              "Open",
              style: TextStyle(color: Colors.white, fontSize: 20),
            ),
          )
        ]).show();
  }

  askForPrivateKey(BuildContext context) {

    var _privk;

    Alert(
        context: context,
        title: "Enter your details",
        content: Column(
          children: <Widget>[
            TextFormField(
              autocorrect: false,
              autofocus: true,
              decoration: const InputDecoration(
                icon: Icon(Icons.email),
                hintText: 'johndoe!',
                labelText: 'BitMaelum Address',
              ),
              onChanged: (val) {
                _accountAddress = val;
                return null;
              },
            ),

            TextFormField(
              autocorrect: false,
              autofocus: true,
              decoration: const InputDecoration(
                icon: Icon(Icons.person),
                hintText: 'John Doe',
                labelText: 'Name',
              ),
              onChanged: (val) {
                _accountName = val;
                return null;
              },
            ),

            TextFormField(
              autocorrect: false,
              autofocus: true,
              decoration: const InputDecoration(
                icon: Icon(Icons.text_snippet),
                hintText: 'ed25519 MC4CA.......',
                labelText: 'Private Key',
              ),
              onChanged: (val) {
                _privk = val;
                return null;
              },
            ),
          ],
        ),
        buttons: [
          DialogButton(
            onPressed: () => Navigator.pop(context),
            color: Colors.white,
            child: Text(
              "Cancel",
              style: TextStyle(color: Colors.black, fontSize: 20),
            ),
          ),
          DialogButton(
            onPressed: () {
              () async {
                try {
                  await(BitmaelumClientPlugin.setClientFromPrivateKey(_accountAddress, _accountName, _privk));
                  setState(() {
                    _profileLoaded = true;
                  });
                } on BitmaelumException catch(exception) {
                  Alert(context: context, title: "Error", desc: exception.cause).show();
                }

              }();

               Navigator.pop(context);
            },
            child: Text(
              "Open",
              style: TextStyle(color: Colors.white, fontSize: 20),
            ),
          )
        ]).show();
  }

  void _loadVault() async {
    FilePickerResult result = await FilePicker.platform.pickFiles();

    if(result != null) {
      _fileVault = File(result.files.single.path);


      askForPassword(context);
    } else {
      // User canceled the picker
    }
  }

  void _openVault(String filePath, String password) async {
    try {
      var result = await(BitmaelumClientPlugin.openVault(filePath, password));
      var _accounts = result as List;
      print (_accounts);

      SelectDialog.showModal<dynamic>(
        context,
        label: "Select account to import",
        //selectedValue: _accounts[0],
        items: _accounts,
        itemBuilder: (BuildContext context, dynamic item, bool isSelected) {
          return Container(
            decoration: !isSelected
                ? null
                : BoxDecoration(
                    borderRadius: BorderRadius.circular(5),
                    color: Colors.white,
                    border: Border.all(
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
            child: ListTile(
              selected: isSelected,
              title: Text(item["name"]),
              subtitle: Text(item["address"]),
            ),
          );
        },  
        onChange: (dynamic selected) async {
          try {
            await(BitmaelumClientPlugin.setClientFromVault(selected["address"]));
            setState(() {
              _accountName = selected["name"];
              _accountAddress = selected["address"];
              _profileLoaded = true;
            });
          } on BitmaelumException catch(exception) {
            Alert(context: context, title: "Error", desc: exception.cause).show();
          }
        },
      );
    } on BitmaelumException catch (exception)  {
      Alert(context: context, title: "Error", desc: exception.cause).show();
    }
  }

}
