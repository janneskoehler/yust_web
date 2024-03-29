import 'package:flutter_web/material.dart';

import '../models/yust_doc.dart';
import '../models/yust_doc_setup.dart';
import '../yust.dart';

class YustDocsBuilder<T extends YustDoc> extends StatelessWidget {
  
  final YustDocSetup modelSetup;
  final List<List<dynamic>> filter;
  final List<String> orderBy;
  final bool doNotWait;
  final Widget Function(List<T>) builder;

  YustDocsBuilder({@required this.modelSetup, this.filter, this.orderBy, this.doNotWait = false, @required this.builder});
  
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<T>>(
      stream: Yust.service.getDocs<T>(modelSetup, filterList: filter, orderByList: orderBy),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          throw snapshot.error;
        }
        if (snapshot.connectionState == ConnectionState.waiting && !doNotWait) {
          return Center(child: CircularProgressIndicator());
        }
        return builder(snapshot.data ?? []);
      },
    );
  }

}