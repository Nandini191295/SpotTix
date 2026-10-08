import "dart:developer";
import "package:dummy_firebase/controller/user_controller.dart";
import "package:dummy_firebase/view/bottom_navigation_bar.dart";
import "package:dummy_firebase/view/dummy_navi.dart";
import "package:dummy_firebase/view/login_screen.dart";
import "package:flutter/material.dart";
class splashScreen
 extends StatefulWidget {
  const splashScreen
  ({super.key});

  @override
  State<splashScreen> createState() => _splashScreenState();
}

class _splashScreenState extends State<splashScreen> with TickerProviderStateMixin {
  //LOGO
  AnimationController? logoController;
  Tween<Offset>? tweenOffset;
  Animation<Offset>? logoAnimation;
  //TeXT
  AnimationController? textController;
  Animation<double>? textAnimation;
  @override
  initState(){
    super.initState();
    //LOGO
    logoController=AnimationController(
      vsync:this,
      duration:Duration(seconds: 2),
    );
    tweenOffset=Tween<Offset>(
      begin: Offset(2, 0),
      end: Offset(0.0, 0),

    );
    logoAnimation=tweenOffset!.animate(CurvedAnimation(parent: logoController!, curve: Curves.linear));
    logoController!.forward();
    logoController!.addListener((){
      if(logoController!.isCompleted){
        log("logo complete");
        textController!.forward();

      }

    });

    //TEXT

    textController=AnimationController(vsync: this,
    duration: Duration(seconds: 2),);
    textAnimation=CurvedAnimation(parent: textController!, curve: Curves.bounceOut);
      }



  navigatetoScreen(BuildContext context){
    Future.delayed(Duration(seconds:4),() async{
      UserController userControllerobj=UserController();
      await userControllerobj.getSharedPrefData();
      log("IS USRR LOGGED IN : ${userControllerobj.isUserLoggedIn}");
      if(userControllerobj.isUserLoggedIn){
        //home screen
        Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (context){
          return BottomNavigationScreen();
        }));
        
      }else{
         Navigator.pushReplacement(context,
       MaterialPageRoute(builder: (context){
        return LoginPage();
    },
    ),
      );

      }
     
    });

  }

  @override
  Widget build(BuildContext context) {
    navigatetoScreen(context);
    return Scaffold(
      backgroundColor: Color.fromRGBO(255, 255, 255, 1),
      body:Container(
        width:MediaQuery.of(context).size.width,
       height:MediaQuery.of(context).size.height,
       child: Container(
        width:MediaQuery.of(context).size.width,
        child: Column(
          children: [
            SlideTransition(position: logoAnimation!,
            child: Padding(
              padding: const EdgeInsets.only(top:300.0),
              child: Image.asset("asset/mm.jpg",height:150,width: 200,),
            ),),
            ScaleTransition(scale:textAnimation!,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [

              Text("Spot",style: TextStyle(fontSize: 30,
              fontWeight: FontWeight.w900,
              color:Color.fromRGBO(131, 73, 232, 1), ),),
              Text("Tix",style: TextStyle(fontSize: 30,
              fontWeight: FontWeight.w900,
              color:Color.fromRGBO(83, 36, 166, 1), ),)
            ],),)
          ],
        ),

       ),

      ),

    );
  }
}