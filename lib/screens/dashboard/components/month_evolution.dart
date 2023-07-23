import 'package:oflite/models/RecentFile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

import '../../../Objetos/DADOS.dart';
import '../../../constants.dart';
import 'chart_line.dart';

class MonthEvolution extends StatefulWidget {
  final List<DADOS> items;

  const MonthEvolution({Key? key, required this.items}) : super(key: key);
  @override
  _MonthEvolution createState() => _MonthEvolution();
}

class _MonthEvolution extends State<MonthEvolution> {

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(defaultPadding),
      decoration: BoxDecoration(
        color: Theme.of(context).canvasColor,
        borderRadius: const BorderRadius.all(Radius.circular(10)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ChartLine(items: widget.items),
        ],
      ),
    );
  }
}

