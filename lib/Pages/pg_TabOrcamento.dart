import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:flutter/material.dart';
import 'package:oflite/Pages/GeradorOrcamento.dart';
import 'package:oflite/Pages/PdfViewPage.dart';
import 'package:oflite/Pages/pg_menuPdf.dart';
import '../Objetos/DADOS.dart';
import '../constants.dart';
import 'ListaItensOrcamento.dart';

class TabItem {
  final IconData icon;
  final String title;

  TabItem({required this.icon, required this.title});
}

class PgTabOrcamento extends StatefulWidget {
  final DADOS item;
  const PgTabOrcamento({Key? key, required this.item}) : super(key: key);

  @override
  _PgTabOrcamentoState createState() => _PgTabOrcamentoState();
}

class _PgTabOrcamentoState extends State<PgTabOrcamento>
    with AutomaticKeepAliveClientMixin {
  int _currentIndex = 0;
  double we = 0;

  @override
  bool get wantKeepAlive => true;

  final List<TabItem> _tabItems = [
    TabItem(icon: Icons.person, title: 'Cliente'),
    TabItem(icon: Icons.list, title: 'Itens'),
    TabItem(icon: Icons.picture_as_pdf, title: 'PDF'),
    TabItem(icon: Icons.more_horiz, title: 'Opções'),
  ];

  void onTabTapped(int index) {
    if (index == 0) {
      setState(() {
        _currentIndex = index;
      });
    } else {
      if (widget.item.ID!.isNotEmpty) {
        setState(() {
          _currentIndex = index;
        });
      } else {
        // Exibir AwesomeDialog quando o ID do cliente estiver vazio
        AwesomeDialog(
          width: we * 0.99,
          context: context,
          dialogBackgroundColor: Colors.cyan[50],
          animType: AnimType.leftSlide,
          headerAnimationLoop: false,
          dialogType: DialogType.error,
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
          title: 'Erro!',
          desc:
          'Finalize o cadastro do cliente para acessar as demais etapas do orçamento!',
          btnOkOnPress: () async {},
          btnOkIcon: Icons.check_circle,
        ).show();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    we = MediaQuery.of(context).size.width;
    final List<Widget> children = [
      GeradorOrcamento(item: widget.item),
      ListaItensOrcamento(item: widget.item),
      const PdfViewPage(),
      MenuPagePdf(item: widget.item),
    ];
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: children,
      ),
      bottomNavigationBar: Theme(
        data: Theme.of(context).copyWith(
          canvasColor: secondaryColor,
          // Define a posição do texto abaixo dos ícones
          bottomNavigationBarTheme: BottomNavigationBarThemeData(
            selectedLabelStyle: const TextStyle(
              fontSize: 11.0,
              fontWeight: FontWeight.bold,
            ),
            unselectedLabelStyle: const TextStyle(
              fontSize: 11.0,
              fontWeight: FontWeight.normal,
            ),
            type: BottomNavigationBarType.fixed,
            showSelectedLabels: true,
            showUnselectedLabels: true,
            selectedItemColor: Colors.cyan[50],
            unselectedItemColor: Colors.grey,
            selectedIconTheme: IconThemeData(size: 20),
          ),
        ),
        child: BottomNavigationBar(
          selectedItemColor: Colors.cyan[50],
          unselectedItemColor: Colors.grey,
          onTap: onTabTapped,
          currentIndex: _currentIndex,
          items: _tabItems
              .map(
                (tabItem) => BottomNavigationBarItem(
              icon: Icon(tabItem.icon),
              label: tabItem.title,
            ),
          )
              .toList(),
        ),
      ),
    );
  }
}
