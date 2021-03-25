import 'main.dart' as original_main;
import 'package:bitmaelum_flutter_plugin/bitmaelum_flutter_plugin.dart';

// This file is the default main entry-point for go-flutter application.
void main() {
  BitmaelumClientPlugin.bindingEnabled = false;
  original_main.main();
}
