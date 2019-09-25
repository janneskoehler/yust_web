import 'package:flutter/material.dart';

import '../models/yust_doc.dart';
import '../models/yust_doc_setup.dart';
import '../yust.dart';

class YustDocsBuilder<T extends YustDoc> extends StatelessWidget {
  final YustDocSetup modelSetup;
  final List<List<dynamic>> filter;
  final List<String> orderBy;
  final bool doNotWait;
  final Widget Function(List<T>) builder;
  final num limit;

  YustDocsBuilder({
    @required this.modelSetup,
    this.filter,
    this.orderBy,
    this.doNotWait = false,
    @required this.builder,
    this.limit,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<T>>(
      stream: Yust.service.getDocs<T>(
        modelSetup,
        filterList: filter,
        orderByList: orderBy,
        limit: limit,
      ),
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
