import 'dart:math';

import 'package:firebase/firebase.dart' as fb;
import 'package:firebase/firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'models/yust_doc.dart';
import 'models/yust_doc_setup.dart';
import 'models/yust_exception.dart';
import 'models/yust_user.dart';
import 'yust.dart';

class YustService {
  final fireAuth = fb.auth();
  final firestore = fb.firestore();

  Future<void> signIn(String email, String password) async {
    if (email == null || email == '') {
      throw YustException('Die E-Mail darf nicht leer sein.');
    }
    if (password == null || password == '') {
      throw YustException('Das Passwort darf nicht leer sein.');
    }
    await fireAuth.signInWithEmailAndPassword(email, password);
  }

  Future<void> signUp(String firstName, String lastName, String email,
      String password, String passwordConfirmation) async {
    if (firstName == null || firstName == '') {
      throw YustException('Der Vorname darf nicht leer sein.');
    }
    if (lastName == null || lastName == '') {
      throw YustException('Der Nachname darf nicht leer sein.');
    }
    if (password != passwordConfirmation) {
      throw YustException('Die Passwörter stimmen nicht überein.');
    }
    final fireUser =
        await fireAuth.createUserWithEmailAndPassword(email, password);
    final user =
        YustUser(email: email, firstName: firstName, lastName: lastName)
          ..id = fireUser.user.uid;
    await Yust.service.saveDoc<YustUser>(YustUser.setup, user);
  }

  Future<void> signOut() async {
    await fireAuth.signOut();
  }

  T initDoc<T extends YustDoc>(YustDocSetup modelSetup, [T doc = null]) {
    if (doc == null) {
      doc = modelSetup.newDoc() as T;
    }
    doc.id = firestore.collection(modelSetup.collectionName).doc().id;
    doc.createdAt = DateTime.now().toIso8601String();
    if (modelSetup.forEnvironment) {
      doc.envId = Yust.store.currUser.currEnvId;
    }
    if (modelSetup.forUser) {
      doc.userId = Yust.store.currUser.id;
    }
    if (modelSetup.onInit != null) {
      modelSetup.onInit(doc);
    }
    return doc;
  }

  Stream<List<T>> getDocs<T extends YustDoc>(
    YustDocSetup modelSetup, {
    List<List<dynamic>> filterList,
    List<String> orderByList,
    num limit,
  }) {
    Query query = firestore.collection(modelSetup.collectionName);
    if (modelSetup.forEnvironment) {
      query = query.where('envId', '==', Yust.store.currUser.currEnvId);
    }
    if (modelSetup.forUser) {
      query = query.where('userId', '==', Yust.store.currUser.id);
    }
    query = _executeFilterList(query, filterList);

    query = _executeOrderByList(query, orderByList);

    if (limit != null) {
      query = query.limit(limit);
    }
    return query.onSnapshot.map((snapshot) {
      // print('Get docs: ${modelSetup.collectionName}');
      return snapshot.docs.map((docSnapshot) {
        final doc = modelSetup.fromJson(docSnapshot.data()) as T;
        if (modelSetup.onMigrate != null) {
          modelSetup.onMigrate(doc);
        }
        return doc;
      }).toList();
    });
  }

  Stream<T> getDoc<T extends YustDoc>(YustDocSetup modelSetup, String id) {
    return firestore
        .collection(modelSetup.collectionName)
        .doc(id)
        .onSnapshot
        .map((snapshot) {
      // print('Get doc: ${modelSetup.collectionName} $id');
      final doc = modelSetup.fromJson(snapshot.data()) as T;
      if (modelSetup.onMigrate != null) {
        modelSetup.onMigrate(doc);
      }
      return doc;
    });
  }

  Stream<T> getFirstDoc<T extends YustDoc>(
      YustDocSetup modelSetup, List<List<dynamic>> filterList) {
    var query = firestore.collection(modelSetup.collectionName);
    if (modelSetup.forEnvironment) {
      query = query.where('envId', '==', Yust.store.currUser.currEnvId);
    }
    if (modelSetup.forUser) {
      query = query.where('userId', '==', Yust.store.currUser.id);
    }
    query = _executeFilterList(query, filterList);
    return query.onSnapshot.map<T>((snapshot) {
      if (snapshot.docs.length > 0) {
        final doc = modelSetup.fromJson(snapshot.docs[0].data()) as T;
        if (modelSetup.onMigrate != null) {
          modelSetup.onMigrate(doc);
        }
        return doc;
      } else {
        return null;
      }
    });
  }

  Future<void> saveDoc<T extends YustDoc>(
      YustDocSetup modelSetup, T doc) async {
    var collection = firestore.collection(modelSetup.collectionName);
    if (doc.createdAt == null) {
      doc.createdAt = DateTime.now().toIso8601String();
    }
    if (doc.userId == null && modelSetup.forUser) {
      doc.userId = Yust.store.currUser.id;
    }
    if (doc.envId == null && modelSetup.forEnvironment) {
      doc.envId = Yust.store.currUser.currEnvId;
    }

    if (doc.id != null) {
      await collection.doc(doc.id).set(doc.toJson());
    } else {
      var ref = await collection.add(doc.toJson());
      doc.id = ref.id;
      await ref.set(doc.toJson());
    }
  }

  Future<void> deleteDoc<T extends YustDoc>(
      YustDocSetup modelSetup, T doc) async {
    var docRef = firestore.collection(modelSetup.collectionName).doc(doc.id);
    await docRef.delete();
  }

  void showAlert(BuildContext context, String title, String message) {
    showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text(title),
            content: Text(message),
            actions: <Widget>[
              FlatButton(
                child: Text("OK"),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
            ],
          );
        });
  }

  Future<bool> showConfirmation(
      BuildContext context, String title, String action) {
    return showDialog<bool>(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text(title),
            actions: <Widget>[
              FlatButton(
                child: Text(action),
                onPressed: () {
                  Navigator.of(context).pop(true);
                },
              ),
              FlatButton(
                child: Text("Abbrechen"),
                onPressed: () {
                  Navigator.of(context).pop(false);
                },
              ),
            ],
          );
        });
  }

  Future<String> showTextFieldDialog(
      BuildContext context, String title, String placeholder, String action) {
    final controller = TextEditingController();
    return showDialog<String>(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text(title),
            content: TextField(
              controller: controller,
              decoration: InputDecoration(hintText: placeholder),
            ),
            actions: <Widget>[
              FlatButton(
                child: Text(action),
                onPressed: () {
                  Navigator.of(context).pop(controller.text);
                },
              ),
              FlatButton(
                child: Text("Abbrechen"),
                onPressed: () {
                  Navigator.of(context).pop(null);
                },
              ),
            ],
          );
        });
  }

  String formatDate(String isoDate) {
    var now = DateTime.parse(isoDate);
    var formatter = DateFormat('dd.MM.yyyy');
    return formatter.format(now);
  }

  String formatTime(String isoDate) {
    var now = DateTime.parse(isoDate);
    var formatter = DateFormat('HH:mm');
    return formatter.format(now);
  }

  String randomString({int length = 8}) {
    final rnd = new Random();
    const chars = "abcdefghijklmnopqrstuvwxyz0123456789";
    var result = "";
    for (var i = 0; i < length; i++) {
      result += chars[rnd.nextInt(chars.length)];
    }
    return result;
  }

  Query _executeFilterList(Query query, List<List<dynamic>> filterList) {
    if (filterList != null) {
      for (var filter in filterList) {
        query = query.where(filter[0], filter[1], filter[2]);
      }
    }
    return query;
  }

  Query _executeOrderByList(Query query, List<String> orderByList) {
    if (orderByList != null) {
      orderByList.asMap().forEach((index, orderBy) {
        if (orderBy != 'DESC') {
          var sorting = 'asc';
          if (index + 1 < orderByList.length &&
              orderByList[index + 1] == 'DESC') {
            sorting = 'desc';
          }
          query = query.orderBy(orderBy, sorting);
        }
      });
    }
    return query;
  }
}
