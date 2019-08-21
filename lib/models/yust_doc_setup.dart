import 'package:flutter_web/material.dart';

import 'yust_doc.dart';

class YustDocSetup {

  String collectionName;
  YustDoc Function(Map<String, dynamic> json) fromJson;
  bool forUser;
  bool forEnvironment;
  bool isEnvironment;
  void Function(dynamic doc) onInit;
  void Function(dynamic doc) onMigrate;

  YustDocSetup({@required this.collectionName, this.fromJson, this.forUser = false, this.forEnvironment = false, this.isEnvironment = false, this.onInit, this.onMigrate});

}