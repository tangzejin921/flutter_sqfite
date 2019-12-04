import 'package:flutter/cupertino.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite/sqlite_api.dart';



//数据库信息
abstract class DbInfo{
  Database _database;
  Future<Database> get database{
    if(_database == null){
      return dbPath()
          .then((path)=> openDatabase(
            path+"/"+dbName(),
            version:version(),
            onCreate: _onCreate,
            onUpgrade: onUpgrade
          )).then((database){
            this._database = database;
            return Future.value(_database);
          });
    }else{
      return Future.value(_database);
    }
  }

  DbInfo() {
  }

  Future<String> dbPath() async {
    return await getDatabasesPath();
  }

  String dbName(){
    return runtimeType.toString();
  }

  int version(){
    return 1;
  }

  Future<String> getKey() async {
    return (await dbPath())+dbName();
  }

  void _onCreate(Database db, int version){
    onUpgrade(db, 0, version);
  }

  void onUpgrade(Database db, int oldVersion, int newVersion);
}

class DefaultDbInfo extends DbInfo{
  @override
  void onUpgrade(Database db, int oldVersion, int newVersion) {

  }
}

//表信息
abstract class TabInfo {
  ///db对应那几个表
  static final Map<DbInfo,List<String>> _map = {};
  ///表里包含那些字段
  static final Map<String,List<_SqlField>> _fields = {};

  List<_SqlField> get fields{
    return _fields[tabName()];
  }
  ///做缓存，免得 dbInfo 总是遍历
  DbInfo _dbInfo;
  DbInfo get dbInfo{
    if(_dbInfo == null){
      _dbInfo = _map.entries.firstWhere((map){
        return map.value.contains(tabName());
      },orElse: (){return null;})?.key;
    }
    return _dbInfo;
  }

  bool _isExist = false;
  Future<bool> get isExist{
    if(_isExist){
      return Future.value(_isExist);
    }
    return dbInfo?.database?.then((db){
      return db.rawQuery("SELECT count(name) FROM sqlite_master where name=?",[tabName()]);
    }).then((rawQuery){
      if(rawQuery == null){
        return false;
      }else{
        int count = rawQuery?.first["count(name)"];
        return _isExist = count > 0;
      }
    });
  }

  TabInfo(){
    if(dbInfo == null){
      List<String> temp = _map[_dbInfo = onCreateDb()];
      if(temp == null){
        temp = [];
      }
      temp.add(tabName());
      _map[dbInfo] = temp;
    }
    if(!_fields.containsKey(tabName())){
      List<_SqlField> array = [];
      dynamic _thiz = this;
      Map<String,dynamic> map = _thiz.toJson();
      map.forEach((name,initValue){
        var sqlType;
        if(initValue == null){
          throw Exception("请给（$name）一个初始值");
        }else if(initValue is int){
          sqlType = "INTEGER";
        }else if(initValue is bool){
          sqlType = "BOOLEAN";
        }else if(initValue is String){
          sqlType = "TEXT";
          initValue = "'$initValue'";//这里防止字符串里有特殊字符 如 ,
        }else if(initValue is DateTime){
          sqlType = "DATETIME";
          initValue = "(NOW())";
        }else{
          throw Exception("只支持 int、bool、String、DateTime类型");
        }
        sqlType += " default $initValue";
        array.add(_SqlField(name: name,sqlType: sqlType,initValue: initValue));
      });
      _fields[tabName()] = array;
    }
    isExist.then((b){
      if(!b){
        dbInfo?.database?.then((db){
          db.execute(_onCreate());
        });
      }
    });
  }

  ///是否已经初始化过了
//  bool initFields(){
//    return _fields.containsKey(tabName());
//  }

  String tabName(){
    return runtimeType.toString();
  }
  ///创建表语句
  String _onCreate() {
    StringBuffer buffer = StringBuffer();
    buffer.write("CREATE TABLE ");
    buffer.write(tabName());
    buffer.write("(");

    for (int i = 0; i < fields.length; i++) {
      buffer.write(fields[i].name);
      buffer.write(" ");
      buffer.write(fields[i].sqlType);
      if (i != fields.length - 1) {
        buffer.write(",");
      }
    }
    buffer.write(")");
    return buffer.toString();
  }

  ///任何一个表调用将关闭数据库
  void close(){
    List<String> list;
    if(dbInfo != null){
      dbInfo?.database?.then((db){db.close();});
      list  = _map.remove(dbInfo);
      _dbInfo = null;
    }
    if(list == null){
      list = [tabName()];
    }
    list.forEach((item)=>_fields.remove(item));
  }
  /// 插入
  Future<int> insert({String where,List<dynamic> arguments}){
    return dbInfo?.database.then((db){
      Map<String, dynamic> map = toSqlJson();
      StringBuffer keys = StringBuffer("(");
      StringBuffer values = StringBuffer(" values (");

      var list = map.entries.toList();
      for(int i = 0;i < list.length;i++){
        if(i == list.length -1){
          keys.write(list[i].key);
          keys.write(")");
          values.write("?");
          values.write(")");
        }else{
          keys.write(list[i].key);
          keys.write(",");
          values.write("?");
          values.write(",");
        }
      }
      keys.write(values);
      print(map.values);
      return db.rawInsert("insert into "+tabName()+keys.toString()+_where(where),map.values.toList());
    });
  }
  /// 删除
  Future<int> delete(String where,List<dynamic> arguments){
    return dbInfo?.database.then((db){
      return db.rawDelete("delete from "+tabName()+" "+_where(where),arguments);
    });
  }
  /// 查找
  Future<List<dynamic>> select({String where,List<dynamic> arguments}){
    return dbInfo?.database.then((db){
      return db.rawQuery("select * from "+tabName()+" "+_where(where),arguments);
    }).then((List<Map<String, dynamic>> listMap){
      List<String> bools = [];
      List<String> times = [];
      //遍历找出需要转换的字段
      fields.forEach((item){
        if(item.sqlType.contains("BOOLEAN")){
          bools.add(item.name);
        }else if(item.sqlType.contains("DATETIME")){
          times.add(item.name);
        }
      });
      return {bools,times,listMap};
    }).then((set){
      List<dynamic> list = [];
      dynamic _thiz = this;
      List<String> bools = set.elementAt(0);
      List<String> times = set.elementAt(1);
      List<Map<String, dynamic>> listMap = set.elementAt(2);
      listMap.forEach((map){
        map = map.map((k,v){
          if(bools.contains(k)){
            return MapEntry(k, v==0?false:true);
          }else if(times.contains(k)){
            return MapEntry(k, DateTime.fromMillisecondsSinceEpoch(v));
          }else{
            return MapEntry(k, v);
          }
        });
        var item = _thiz.fromJson(map);
        list.add(item);
      });
      return list;
    });
  }
  //更新
  Future<int> update(String where,List<dynamic> arguments){
    return dbInfo?.database.then((db){
//      StringBuffer keys = StringBuffer("(");
//      var list = map.entries.toList();
//      for(int i = 0;i < list.length;i++){
//        if(i == list.length -1){
//          keys.write(list[i].key);
//          keys.write("=");
//          keys.write(list[i].value);
//        }else{
//          keys.write(list[i].key);
//          keys.write("=");
//          keys.write(list[i].value);
//          keys.write(",");
//        }
//      }
      return db.update(
          tabName(),
          toSqlJson(),
          where: _where(where).replaceFirst("where",""),
          whereArgs: arguments
      );
    });
  }


  Future<int> count(){
    return dbInfo?.database.then((db){
        return db.rawQuery("select count(*) from "+tabName())
      .then((list){
        return list.first["count(*)"];
      });
    });
  }

  String _where(String where){
    if(where == null){
      where = "";
    }
    where = where.toLowerCase();
    if(where.isEmpty){
      return where;
    }else if(!where.contains("where")){
      where = " where "+where;
    }else if(where.startsWith("where")){
      where = where.replaceFirst("where", " where");
    }
    return where;
  }

  DbInfo onCreateDb(){
    return DefaultDbInfo();
  }


  Map<String, dynamic> toSqlJson(){
    dynamic _thiz = this;
    Map<String,dynamic> map = _thiz.toJson();
    return map.map((k,v){
      if(v is DateTime){
        return MapEntry(k,v.millisecondsSinceEpoch);
      }
      return MapEntry(k,v);
    });
  }

}


class _SqlField{
  _SqlField({this.name,this.type,this.sqlType,this.initValue});
  ///字段名
  String name;
  ///字段类型
  Type type;
  ///sql的字段类型
  String sqlType;
  ///初始值
  Object initValue;
}


class Dog extends TabInfo {
  DateTime _id = DateTime.now();
  String name = "name";
  int age = 0;
  bool isMe = false;
  DateTime birthDay = DateTime.now();

  Dog() {
  }

  Dog fromJson(Map<String, dynamic> json) {
    return Dog()
      .._id = json["_id"]
      ..name = json["name"]
      ..age = json["age"]
      ..isMe = json["isMe"]
      ..birthDay = json["birthDay"];
  }

  Map<String, dynamic> toJson() {
    return {
      "_id": DateTime.now(),
      "name": name,
      "age": age,
      "isMe": isMe,
      "birthDay": birthDay
    };
  }

  @override
  String toString() {
    return super.toString();
  }

}


