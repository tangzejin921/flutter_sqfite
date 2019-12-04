


Future<String> A(){
  print("A");
  return Future.value("A");
}
Future<String> B(){
  print("B");
  return Future.value("B");
}

void main(){
  A().then((str)=>B()).then((b)=>{
    print("END:"+b)
  });
  A().then((str)=>{B()}).then((b)=>{
    Future.wait(b)
  });
}