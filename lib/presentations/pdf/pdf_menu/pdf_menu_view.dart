import 'package:flutter/material.dart';
import 'package:oflite/common/widgets/ads/banner_ad_widget.dart';
import 'package:oflite/models/customer_info.dart';
import '../../../common/constants/constants.dart';
import 'components/pdf_menu_header.dart';
import 'components/pdf_menu_card.dart';
import 'pdf_menu_view_model.dart';

class PdfMenuView extends StatefulWidget {
  final CustomerInfo item;
  const PdfMenuView({super.key, required this.item});

  @override
  State<PdfMenuView> createState() => _PdfMenuView();
}

class _PdfMenuView extends State<PdfMenuView> {
  late final PdfMenuViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = PdfMenuViewModel(item: widget.item);
    WidgetsBinding.instance.addPostFrameCallback((_) => _viewModel.inicialData());
  }

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      body: AnimatedBuilder(
        animation: _viewModel,
        builder: (context, _) {
          return Column(
            mainAxisAlignment: MainAxisAlignment.start,
            mainAxisSize: MainAxisSize.max,
            children: <Widget>[
              PdfMenuHeader(onBack: () => Navigator.pop(context, true)),
              Expanded(
                child: ListView.builder(
                  itemCount: _viewModel.menuItems.length,
                  itemBuilder: (context, index) {
                    final menuItem = _viewModel.menuItems[index];
                    return PdfMenuCard(
                      item: menuItem,
                      onTap: () => _viewModel.openOption(context, index),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
      bottomNavigationBar: const BannerAdWidget(
        adUnitId: 'ca-app-pub-5106035309089315/6550502888',
      ),
    );
  }
}
