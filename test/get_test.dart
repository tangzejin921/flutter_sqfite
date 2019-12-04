

class Test{
  bool b;

  bool testBool(){
    return b??(){return true;}();
  }

  String get test{
    return "===";
  }
  set test(String value){
    print("set");
  }
}

void main(){
  Test test = Test();
  test.test = "test";
  print(test.test);
  print(test.test);
  print(test.b);
  print(test.testBool());

  Map<String,String> map = {};
  print(map["test"]);


}
