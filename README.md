# LaborMovel

import 'package:flutter/material.dart';

void main() {
  runApp(Tela());
}

class Tela extends StatefulWidget {
  const Tela({super.key});

  @override
  State<Tela> createState() => _TelaState();
}

class _TelaState extends State<Tela> {
  var val1 = TextEditingController();
  var val2 = TextEditingController();
  double total =0;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: Text("Calculadora"),
        ),
        body: body(),
      ),
    );
  }

 Widget body() {
    return Column(
      children: [
        TextField(
          decoration: InputDecoration(
            labelText: "valor 1",
          ),
          controller: val1,
          
        ),
        TextField(
          decoration: InputDecoration(
            labelText: "valor 2",
          ), controller: val2,
        ),
        TextField(),
        ElevatedButton(
          onPressed: calcular,
          child: Text("Calcular"),
        ),
        Text(total.toString()),
      ],
    );
  }

  calcular() {
    total = double.parse(val1.text) + double.parse(val2.text);
    setState(() {});
  }
}

