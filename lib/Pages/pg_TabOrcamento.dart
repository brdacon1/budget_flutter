import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:flutter/material.dart';
import 'package:oflite/Pages/GeradorOrcamento.dart';
import 'package:oflite/Pages/PdfViewPage.dart';
import 'package:oflite/Pages/pg_menuPdf.dart';
import '../Objetos/DADOS.dart';
import '../constants.dart';
import 'ListaItensOrcamento.dart';

class pg_TabOrcamento extends StatefulWidget {
  final DADOS item;
  const pg_TabOrcamento({Key? key, required this.item}) : super(key: key);

  @override
  _pg_TabOrcamentoState createState() => _pg_TabOrcamentoState();
}

class _pg_TabOrcamentoState extends State<pg_TabOrcamento> {
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
            if(widget.item.ID!.isNotEmpty) {
              _currentIndex = index;
            }
            else{
               AwesomeDialog(
                  width: we * 0.99,
                  context: context,
                  dialogBackgroundColor: Colors.cyan[50],
                  animType: AnimType.leftSlide,
                  headerAnimationLoop: false,
                  dialogType: DialogType.error,
                  showCloseIcon: false,
                 titleTextStyle: const TextStyle(
                   color: Colors.black, // Defina a cor do título
                   fontSize: 24, // Defina o tamanho da fonte do título
                   fontWeight: FontWeight.bold, // Defina o peso da fonte do título
                   // Adicione outros atributos do TextStyle conforme necessário
                 ),
                 descTextStyle: const TextStyle(
                   color: Colors.black, // Defina a cor da descrição
                   fontSize: 18, // Defina o tamanho da fonte da descrição
                   // Adicione outros atributos do TextStyle conforme necessário
                 ),
                  title: 'Erro!',
                  desc: 'Finalize o cadastro do cliente para acessar as demais etapas do orçamento!',
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
      GeradorOrcamento(item: widget.item),
      ListaItensOrcamento(item: widget.item),
      const PdfViewPage(),
      MenuPagePdf(item: widget.item),
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



