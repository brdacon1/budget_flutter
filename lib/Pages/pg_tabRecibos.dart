import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:flutter/material.dart';
import 'package:oflite/Objetos/ObjectRecived.dart';
import 'package:oflite/Pages/GeradorOrcamento.dart';
import 'package:oflite/Pages/PdfViewPage.dart';
import 'package:oflite/Pages/pg_generateRecived.dart';
import 'package:oflite/Pages/pg_paymentList.dart';
import 'package:oflite/Pages/pg_pdfViewPageRecived.dart';
import '../Objetos/DADOS.dart';
import '../constants.dart';


class PageTabRecibos extends StatefulWidget {
  final DADOS item;
  final Recived recibos;
  const PageTabRecibos({Key? key, required this.item, required this.recibos}) : super(key: key);

  @override
  _PageTabRecibos createState() => _PageTabRecibos();
}

class _PageTabRecibos extends State<PageTabRecibos> {
  int _currentIndex = 0;
  double we = 0;

  void onTabTapped(int index) {
    setState(() {
      if(index == 0) {
        _currentIndex = index;
      }
      else {
        _currentIndex = index;
      }
    });
  }

  @override
  initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    we = MediaQuery.of(context).size.width;
    final List children = [
      PgGenerateRecived(item: widget.item, recibos: widget.recibos),
      PgPaymentList(item: widget.item, recibos: widget.recibos),
      PgPdfViewPageRecived(item: widget.item, recibos: widget.recibos),
    ];
    return Scaffold(
      body: children[_currentIndex],
      bottomNavigationBar: Theme(
        data: Theme.of(context).copyWith(
          canvasColor: secondaryColor, // Define a cor de fundo do BottomNavigationBar
        ),
        child: BottomNavigationBar(
          selectedItemColor: Colors.cyan[50],
          showUnselectedLabels: true,
          selectedLabelStyle: const TextStyle(fontSize: 11.0, fontWeight: FontWeight.bold),
          unselectedItemColor: Colors.grey,
          onTap: onTabTapped,
          currentIndex: _currentIndex,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.receipt_long_rounded),
              label: 'Recibo',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.payments_outlined),
              label: 'Pagamentos',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.picture_as_pdf),
              label: 'PDF',
            ),
          ],
        ),
      ),
    );
  }
}



