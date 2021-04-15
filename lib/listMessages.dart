import 'package:bitmaelum_flutter_client/showMessage.dart';
import 'package:bitmaelum_flutter_plugin/bitmaelum_flutter_plugin.dart';
import 'package:bitmaelum_flutter_plugin/messages.dart';
import 'package:flutter/material.dart';
import 'package:rflutter_alert/rflutter_alert.dart';
import 'package:loader_overlay/loader_overlay.dart';

class MyMessage {
  MessageItem item;

  MyMessage(this.item);

  MyMessage.fromMessageItem(MessageItem m) {
    item = m;
  }

  Widget buildTitle(BuildContext context) => Column(
    mainAxisAlignment: MainAxisAlignment.start,
    crossAxisAlignment: CrossAxisAlignment.start,
    children: <Widget>[
      Row(children: <Widget>[
          Icon(Icons.account_circle, size: 30),
          Container(width: 5),
          Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(item.fromName, style: TextStyle(fontWeight: FontWeight.bold)), 
              Text(item.fromAddress, style: TextStyle(fontSize: 12, color: Colors.black26))
          ])
        ]),
      Container(height: 10), 
      Row(children: <Widget>[
        item.blocks.length > 1 ? Icon(Icons.my_library_books, size: 15, color: Colors.grey,) : Container(),
        item.blocks.length > 1 ? Container(width: 10) : Container(),
        item.attachments.length > 0 ? Icon(Icons.attachment, size: 15, color: Colors.grey,) : Container(),
        item.attachments.length > 0 ? Container(width: 10) : Container(),
        Flexible(child: Text(item.subject, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 19))),
      ])
    ],
  );
  Widget buildSubtitle(BuildContext context) => Column(
    mainAxisAlignment: MainAxisAlignment.start,
    crossAxisAlignment: CrossAxisAlignment.start,
    children: <Widget>[
      Container(height: 10),
      Text(item.date.toLocal().toString(), style: TextStyle(fontSize: 12)),
    ],
    );

}

class MyListMessage extends StatefulWidget {
  MyListMessage({Key key, this.title}) : super(key: key);

  static const String routeName = "/list";

  final String title;

  @override
  _MyListMessage createState() => _MyListMessage();

}

class _MyListMessage extends State<MyListMessage> {
  List<MyMessage> _msgs;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: _msgs != null ? Scrollbar(isAlwaysShown: true, child: ListView.separated(
        itemCount: _msgs.length,
        itemBuilder: (context, index) {
          final msg = _msgs[index];

          return ListTile(
              title: msg.buildTitle(context),
              subtitle: msg.buildSubtitle(context),
              trailing: Icon(Icons.keyboard_arrow_right),
              onTap: () {
                Navigator.pushNamed(context, MyShowMessage.routeName, arguments: msg.item);
              }
            );
        },
        separatorBuilder: (context, index) {
          return Divider();
        },
      )) : Container(),
    );
  }

  @override
  void initState() {
    super.initState();
    _listMessages(context);
  }

  void _listMessages(BuildContext context) async {
    context.showLoaderOverlay();
    try {

      var listMsgs = await(BitmaelumClientPlugin.listMessages(DateTime.utc(1989, 11, 9), 1));
      Iterable l = listMsgs;

      setState(() {
        _msgs = List<MyMessage>.from(l.map((m)=> MyMessage.fromMessageItem(m)));
      });

    } on BitmaelumException catch(exception) {
      Alert(context: context, title: "Error", desc: exception.cause).show();
    } 

    context.hideLoaderOverlay();

  }

  void _openMessage(MessageItem msg) async {
    context.showLoaderOverlay();

    context.hideLoaderOverlay();
  }


}