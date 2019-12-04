import 'package:flutter/material.dart';
import 'package:flutter_sqfite/dog.dart';
import 'package:sqflite/sqflite.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);

  final String title;

  @override
  _MyHomePageState2 createState() => _MyHomePageState2();
}

class _MyHomePageState extends State<MyHomePage> {
  List<Map<String, dynamic>> list = [];
  Database database;

  @override
  void initState() {
    _open().then((onValue)=>{});
    super.initState();
  }

  Future _open() async {
    var databasesPath = await getDatabasesPath();
    database = await openDatabase('$databasesPath/demo.db', version: 1,
      onOpen: (Database db) async {
        print("onOpen");
      },
      onCreate: (Database db, int version) async {
        await db.execute(
            "CREATE TABLE Dog (_id INTEGER PRIMARY KEY, name TEXT, age INTEGER, isMe BOOLEAN, birthDay DATETIME DEFAULT (DATETIME('now', 'localtime')))");
      },
      onUpgrade: (Database db, int oldVersion,int newVersion) async {
        print("onUpgrade");
        print(oldVersion);
        print(newVersion);
      },
    );
  }

  Future _query() async{
    list = await database.rawQuery("select * from Dog");
    setState(() {
    });
  }

  Future _insert() async {
    var rawQuery = await database.rawQuery("select count(_id) from Dog");
    var count = rawQuery.first["count(_id)"];
    await database.rawInsert("insert into Dog(name,age,isMe) values (?,?,?)",["test",count,false]);
  }

  Future _delete() async {
    var rawQuery = await database.rawQuery("select max(age) from Dog");
    var count = rawQuery.first["max(age)"];
    await database.rawDelete("delete from Dog where age=?",[count]);
  }

  Future _update() async {
    var rawQuery = await database.rawQuery("select max(age) from Dog");
    var count = rawQuery.first["max(age)"];
    await database.rawDelete("update Dog set age=? where age=?",[count+1,count]);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Column(
        children: <Widget>[
          Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: <Widget>[
              RaisedButton(
                onPressed: () async {
                  await _insert();
                  await _query();
                },
                child: Text("insert"),
              ),
              RaisedButton(
                onPressed: () async {
                  await _delete();
                  await _query();
                },
                child: Text("delete"),
              ),
              RaisedButton(
                onPressed: _query,
                child: Text("select"),
              ),
              RaisedButton(
                onPressed: () async {
                  await _update();
                  await _query();
                },
                child: Text("update"),
              )
            ],
          ),
          Expanded(
            child: ListView.builder(
              itemBuilder: _item,
              itemCount: list.length,
            ),
          ),
      ],
    ),
    );
  }

  Widget _item(BuildContext context, int index){
    Map<String, dynamic> map = list[index];
    var str = map.toString();
    return Text(str);
  }

}

class _MyHomePageState2 extends State<MyHomePage> {
  List<Map<String, dynamic>> list = [];
  Dog dog;
  @override
  void initState() {
    _open().then((onValue)=>{});
    super.initState();
  }

  Future _open() async {
    dog = new Dog();
    return Future.value();
  }

  Future _query() {
    return dog.select().then((list){
      List<Map<String,dynamic>> temp = [];
      for(Dog d in list){
        temp.add(d.toJson());
      }
      return temp;
    }).then((list){
      setState(() {
        this.list = list;
      });
    });
  }

  Future _insert() {
    dog.age++;
    dog.birthDay = DateTime.now();
    dog.insert();
    return Future.value();
  }

  Future _delete() {
    return dog.select().then((list){
      List temp = [];
      for(Dog d in list){
        temp.add(d.toJson());
      }
      return temp;
    }).then((list){
      List temp = [];
      temp.addAll(list);
      temp.sort((a,b){
        return b["age"]-a["age"];
      });
      return temp.first["age"];
    }).then((i){
      dog.delete("age=?", [i]);
    });
  }

  Future _update() {
    return dog.select().then((list){
      List temp = [];
      for(Dog d in list){
        temp.add(d.toJson());
      }
      return temp;
    }).then((list){
      List temp = [];
      temp.addAll(list);
      temp.sort((a,b){
          return b["age"]-a["age"];
        });
      return temp.first["age"];
    }).then((i){
      print(i);
      dog.age = i+1;
      dog.update("age=?", [i]);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Column(
        children: <Widget>[
          Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: <Widget>[
              RaisedButton(
                onPressed: () async {
                  await _insert();
                  await _query();
                },
                child: Text("insert"),
              ),
              RaisedButton(
                onPressed: () async {
                  await _delete();
                  await _query();
                },
                child: Text("delete"),
              ),
              RaisedButton(
                onPressed: _query,
                child: Text("select"),
              ),
              RaisedButton(
                onPressed: () async {
                  await _update();
                  await _query();
                },
                child: Text("update"),
              )
            ],
          ),
          Expanded(
            child: ListView.builder(
              itemBuilder: _item,
              itemCount: list.length,
            ),
          ),
        ],
      ),
    );
  }

  Widget _item(BuildContext context, int index){
    Map<String, dynamic> map = list[index];
    var str = map.toString();
    return Text(str);
  }

}