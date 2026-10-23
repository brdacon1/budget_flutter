import 'package:flutter/material.dart';
import 'package:oflite/shared/models/customer_info.dart';
import 'package:oflite/shared/common/constants/constants.dart';

class RecentFiles extends StatefulWidget {
  final List<CustomerInfo> items;

  const RecentFiles({Key? key, required this.items}) : super(key: key);
  @override
  _RecentFiles createState() => _RecentFiles();
}

class _RecentFiles extends State<RecentFiles> {

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(defaultPadding),
      decoration: BoxDecoration(
        color: Theme.of(context).canvasColor,
        borderRadius: const BorderRadius.all(Radius.circular(10)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Text(
            'Orçamentos recentes',
            style: TextStyle(
              color: creamColor,
              fontSize: 17,
              fontWeight: FontWeight.bold,
              letterSpacing: 2,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: defaultPadding),
          SizedBox(
            width: double.infinity,
            child: DataTable(
              columnSpacing: defaultPadding,
              columns: const [
                DataColumn(
                  label: Text("Cliente"),
                ),
                DataColumn(
                  label: Text("Data"),
                ),
                DataColumn(
                label: Text("Número"),
                ),
              ],
              rows: List.generate(
                widget.items.length >= 5 ? 5 : widget.items.length,
                    (index) => recentFileDataRow(widget.items[index]),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

DataRow recentFileDataRow(CustomerInfo fileInfo) {
  return DataRow(
    cells: [
      DataCell(
        Container(
          constraints: const BoxConstraints(maxWidth: 80),
          child: Tooltip(
            message: fileInfo.customerName!,
            child: Text(
              fileInfo.customerName!.split(' ')[0],
              softWrap: true,
              overflow: TextOverflow.fade,
            ),
          ),
        ),
      ),
      DataCell(Text(fileInfo.data!)),
      DataCell(Text(fileInfo.id!)),
    ],
  );
}
