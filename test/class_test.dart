
import 'dart:core';


class TestClass{
  TestClass(){
    print("1111");
  }
}

class Test2Class extends TestClass{

}

void main() {
  int i=0;
  String s="s";
  bool b = false;

  print(i.runtimeType);
  print(s.runtimeType);
  print(b.runtimeType);


  TestClass testClass = Test2Class();
  var type = testClass.runtimeType.toString();
  print(type);
  print(testClass.toString());
}