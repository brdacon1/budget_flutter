import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:flutter/material.dart';
import 'package:oflite/presentations/budget/budget_creator/budget_creator_view.dart';
import 'package:oflite/presentations/pdf/pdf_budget/pdf_budget_view.dart';
import 'package:oflite/presentations/pdf/pdf_menu/pdf_menu_view.dart';
import '../../../models/customer_info.dart';
import '../../../common/constants/constants.dart';
import '../budget_list_items/budget_list_items_view.dart';

class BudgetTabView extends StatefulWidget {
  final CustomerInfo item;
  const BudgetTabView({Key? key, required this.item}) : super(key: key);

  @override
  State<BudgetTabView> createState() => _BudgetTabView();
}

class _BudgetTabView extends State<BudgetTabView> {
  int _currentIndex = 0;
  double we = 0;

  void onTabTapped(int index) {
    setState(() {
        if(index == 0)
        {
          _currentIndex = index;
        }
        else
        {
            if(widget.item.id!.isNotEmpty) {
              _currentIndex = index;
            }
            else{
               AwesomeDialog(
                  width: we * 0.99,
                  context: context,
                  dialogBackgroundColor: Colors.cyan[50],
                  animType: AnimType.leftSlide,
                  headerAnimationLoop: false,
                  dialogType: DialogType.warning,
                  showCloseIcon: false,
                 titleTextStyle: const TextStyle(
                   color: Colors.black,
                   fontSize: 24,
                   fontWeight: FontWeight.bold,
                 ),
                 descTextStyle: const TextStyle(
                   color: Colors.black,
                   fontSize: 18,
                 ),
                  title: 'Ainda não!',
                  desc: 'É necessário cadastrar o cliente colocando pelo menos o nome e clicar no botão "Continuar"',
                  btnOkOnPress: () async {},
                  btnOkIcon: Icons.check_circle,).show();
            }
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
      BudgetCreatorView(item: widget.item),
      BudgetListItemsView(item: widget.item),
      const PdfBudgetView(),
      PdfMenuView(item: widget.item),
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
              icon: Icon(Icons.person),
              label: 'Cliente',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.list),
              label: 'Itens',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.picture_as_pdf),
              label: 'PDF',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.more_horiz),
              label: 'Mais',
            ),
          ],
        ),
      ),
    );
  }
}



