
import 'dart:convert';
import 'dart:io';

import 'package:bitmaelum_flutter_plugin/bitmaelum_flutter_plugin.dart';
import 'package:bitmaelum_flutter_plugin/messages.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:rflutter_alert/rflutter_alert.dart';
import 'package:loader_overlay/loader_overlay.dart';

class MyShowMessage extends StatefulWidget {
  MyShowMessage({Key key}) : super(key: key);

  static const String routeName = "/show";

  @override
  _MyShowMessage createState() => _MyShowMessage();

}

class _MyShowMessage extends State<MyShowMessage> {
  MessageItem msg = MessageItem("", DateTime.now(), "", "", "");
  String _blockContent = "";
  String _selectedBlock = "";

  _MyShowMessage();
  
  Widget getBlocks(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(height: 10),
        DropdownButton<String>(
        iconSize: 0,
        isDense: true,
        icon: Icon(Icons.block),
        value: _selectedBlock,
        items: msg.blocks.map((BlockItem block) {
          return new DropdownMenuItem<String>(
            value: block.id,
            child: Wrap(children: [Icon(Icons.my_library_books, size: 16, color: Colors.black54), Container(width: 5), Text(block.type)]),
          );
        }).toList(),
        onChanged: (value) {
          _selectedBlock = value;
          _loadSelectedBlock(context);
        },
        )]
      );
  } 

  Widget getAttachments(BuildContext context) {
    List<Widget> choices = [];
    for (int i=0; i<msg.attachments.length; i++) {
      choices.add(ChoiceChip(
        selected: false,
        label: Wrap(children: <Widget>[
          Icon(Icons.attach_file, size: 16,),
          Text(msg.attachments[i].filename),
        ]),
        onSelected: (_) {
          _openAttachment(context, msg.attachments[i].id);
          /*
          setState(() {
            _selectedBlock = msg.blocks[i].type;
          });
          _loadSelectedBlock(context);*/
        },
      ));

      choices.add(Container(width:10));
    }

    return Wrap(children: choices);
  } 

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(
        title: Text(msg.subject),
      ),
      body: SingleChildScrollView(child: Padding(
        padding: EdgeInsets.all(10.0),
        child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Container(height: 10),
          Text(msg.fromName, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),),
          Text(msg.fromAddress),
          msg.attachments.length > 0 ? Container(height:10) : Container(),
          msg.attachments.length > 0 ? getAttachments(context) : Container(),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: <Widget>[
              msg.blocks.length>1 ? getBlocks(context) : Container(),
              Text(DateFormat.yMEd().format(msg.date) + " " + DateFormat.jms().format(msg.date)),
          ]),
          Divider(color: Colors.grey,),
          SelectableText(_blockContent),
        ]
      )))
    );
  }


  @override
  void initState() {
    super.initState();
    Future.delayed(Duration.zero, () {
      Locale myLocale = Localizations.localeOf(context);
      initializeDateFormatting(myLocale.countryCode);

      setState(() {
        msg = ModalRoute.of(context).settings.arguments;
      });
      for (var i=0; i<msg.blocks.length; i++) {
        if (msg.blocks[i].type == "default") {
          _selectedBlock = msg.blocks[i].id;
          break;
        }
      }

      _loadSelectedBlock(context);
    });
  }

  void _loadSelectedBlock(BuildContext context) async {
    context.showLoaderOverlay();
    try {
      List<int> blockBytes = await(BitmaelumClientPlugin.readBlock(msg.id, _selectedBlock));
      setState(() {
        _blockContent = String.fromCharCodes(blockBytes);
      });
    } on BitmaelumException catch(exception) {
      Alert(context: context, title: "Error", desc: exception.cause).show();
    } 

    context.hideLoaderOverlay();

  }

  void _saveAttachment(BuildContext context, attachmentID) async {
    context.showLoaderOverlay();
    String savePath = await FilePicker.platform.getDirectoryPath();
    print(savePath);
    if (savePath != "") {

      try {
        await(BitmaelumClientPlugin.saveAttachment(msg.id, attachmentID, savePath, false));
        Alert(context: context, title: "Saved", desc: "File saved").show();
      } on BitmaelumException catch(exception) {
        Alert(context: context, title: "Error", desc: exception.cause).show();
      } on Exception catch(exception) {
        Alert(context: context, title: "Error", desc: exception.toString()).show();
      }
    }
    
    context.hideLoaderOverlay();
  }

  void _openAttachment(BuildContext context, attachmentID) async {
    context.showLoaderOverlay();
    Directory tempDir = await getTemporaryDirectory();
    tempDir.create(recursive: true);

    try {
      Map res = await(BitmaelumClientPlugin.saveAttachment(msg.id, attachmentID, tempDir.path, true));
      
      OpenFile.open(res["path"]);
      
    } on BitmaelumException catch(exception) {
      Alert(context: context, title: "Error", desc: exception.cause).show();
    } on Exception catch(exception) {
      Alert(context: context, title: "Error", desc: exception.toString()).show();
    }
  
    
    context.hideLoaderOverlay();
  }


}