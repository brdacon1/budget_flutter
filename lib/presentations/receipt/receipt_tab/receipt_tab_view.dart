import 'package:flutter/material.dart';
import 'package:oflite/models/receipt.dart';
import 'package:oflite/presentations/payment/payment_list/payment_list_view.dart';
import 'package:oflite/presentations/pdf/pdf_receipt/pdf_receipt_view.dart';
import '../../../models/customer_info.dart';
import '../../../common/constants/constants.dart';


class ReceiptTabView extends StatefulWidget {
  final CustomerInfo item;
  final Receipt recibos;
  const ReceiptTabView({Key? key, required this.item, required this.recibos}) : super(key: key);

  @override
  State<ReceiptTabView> createState() => _ReceiptTabView();
}

class _ReceiptTabView extends State<ReceiptTabView> {
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
      ReceiptTabView(item: widget.item, recibos: widget.recibos),
      PaymentListView(item: widget.item, recibos: widget.recibos),
      PdfReceiptView(item: widget.item, receipt: widget.recibos),
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



