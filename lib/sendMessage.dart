

import 'dart:io';

import 'package:bitmaelum_flutter_plugin/bitmaelum_flutter_plugin.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:rflutter_alert/rflutter_alert.dart';
import 'package:loader_overlay/loader_overlay.dart';

class MySendMessage extends StatefulWidget {
  MySendMessage({Key key, this.title}) : super(key: key);

  static const String routeName = "/send";

  final String title;

  @override
  _MySendMessage createState() => _MySendMessage();
}

class _MySendMessage extends State<MySendMessage> {
  String _subject;
  String _recipient;
  List<String> _attachments = [];
  //final Map _blocks = new Map<String, String>();
  final Map _blocks = {"default": ""};

  Widget getBlocks(BuildContext context) {
    List<Widget> _myBlocks = [];

    for (MapEntry b in _blocks.entries) {
       _myBlocks.add(
        Container(height: 30)
      );
      _myBlocks.add(
        Text("Block: ${b.key}")
      );
      _myBlocks.add(
        TextFormField(
          autocorrect: true,
          autofocus: false,
          keyboardType: TextInputType.multiline,
          maxLines: null,
          minLines: null,
          decoration: const InputDecoration(
            icon: Icon(Icons.text_snippet),
          ),
          onChanged: (val) {
            setState(() {
              _blocks[b.key] = val;
            });
          },
        )
      );
      if (b.key != "default") {
        _myBlocks.add(
          Container(height: 5)
        );
        _myBlocks.add(
          ElevatedButton.icon(
            onPressed: () {
              setState(() {
                _blocks.remove(b.key);
              });
            }, 
            icon: Icon(Icons.cancel, size: 16),
            label: Text("Remove this block")
          )
        );
      }
      
      _myBlocks.add(
        Divider(height:5)
      );


    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: _myBlocks,
    );

  }

  Widget getAttachments(BuildContext context) {
    if (_attachments.length == 0) {
      return Container();
    }

    List<Widget> choices = [];
    for (int i=0; i<_attachments.length; i++) {
      choices.add(ChoiceChip(
        selected: false,
        label: Wrap(children: <Widget>[
          Icon(Icons.attach_file, size: 16),
          Text(File(_attachments[i]).uri.pathSegments.last),
          Container(width: 10),
          Icon(Icons.cancel, size: 16)
        ]),
        onSelected: (_) {
          setState(() {
            _attachments.removeAt(i);
          });
        },
      ));

      choices.add(Container(width:10));
    }

    return Wrap(
      children: choices,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        actions: [
          IconButton(
            icon: Icon(Icons.attach_email),
            tooltip: 'Add attachment',
            onPressed: () async {
              FilePickerResult result = await FilePicker.platform.pickFiles();
              if (result != null) {
                if (_attachments.contains(result.files.single.path)) {
                  return;
                }

                setState(() {
                  _attachments.add(result.files.single.path);
                });
              }
            },
          ),
          IconButton(
            icon: Icon(Icons.send),
            tooltip: 'Send',
            onPressed: () async {
              context.showLoaderOverlay();

              try {
                await(BitmaelumClientPlugin.sendMessage(_recipient, _subject, _blocks, _attachments));
                Navigator.pop(context);
                //Alert(context: context, title: "Sent", desc: "message sent").show();
              } on BitmaelumException catch(exception) {
                Alert(context: context, title: "Error", desc: exception.cause).show();
              } 

              context.hideLoaderOverlay();

            },
          ),
        ],
      ),
      body: SingleChildScrollView(child: Padding(
        padding: EdgeInsets.all(10.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: 
            <Widget>[
              getAttachments(context),
              TextFormField(
                autocorrect: false,
                autofocus: true,
                decoration: const InputDecoration(
                  icon: Icon(Icons.email),
                  hintText: 'johndoe!',
                  labelText: 'Recipient',
                ),
                onChanged: (val) {
                  _recipient = val;
                  return null;
                },
              ),
              TextFormField(
                autocorrect: true,
                autofocus: false,
                decoration: const InputDecoration(
                  icon: Icon(Icons.subject),
                  hintText: 'Hiya!',
                  labelText: 'Subject',
                ),
                onChanged: (val) {
                  _subject = val;
                  return null;
                },
              ),
              getBlocks(context), 
              Divider(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                ElevatedButton.icon(
                  onPressed: () {
                    if (_blocks.containsKey("default")) {
                      askForName(context);
                    } else {
                      setState(() {
                        _blocks["default"] = "";
                      });
                    }
                  }, 
                  icon: Icon(Icons.cancel, size: 16),
                  label: Text("Add new block")
                )
              ]),
            ]
        ),
      ) // This trailing comma makes auto-formatting nicer for build methods.
    ));
  }


  askForName(BuildContext context) {
    String _name ="";
    void completed() {
      setState(() {
        _blocks[_name] = "";
      });
      Navigator.pop(context);
    }

    Alert(
        context: context,
        title: "Enter the block name",
        content: Column(
          children: <Widget>[
            TextFormField(
              autocorrect: false,
              autofocus: true,
              onFieldSubmitted: (_) {completed();},
              onChanged: (val) {
                _name = val;
                return null;
              },
              obscureText: false,
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

}