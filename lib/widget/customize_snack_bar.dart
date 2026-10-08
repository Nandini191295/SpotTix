import 'package:flutter/material.dart';

class customisedSnackbar{
 showSnackBar(BuildContext context, String  message,{Color bgColor=Colors.red}){
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(
      message,
      style:TextStyle(
        color: Color.fromRGBO(255, 255, 255, 1)
        ),
      ),
      backgroundColor: bgColor,
    ),
  );
 }
}