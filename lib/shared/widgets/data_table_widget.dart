import 'package:flutter/material.dart';
import 'package:data_table_2/data_table_2.dart';

class CustomDataTable extends StatelessWidget {
  final List<DataColumn> columns;
  final List<DataRow> rows;
  final double minWidth;
  final bool showBottomBorder;

  const CustomDataTable({
    super.key,
    required this.columns,
    required this.rows,
    this.minWidth = 600,
    this.showBottomBorder = true,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: DataTable2(
        columns: columns,
        rows: rows,
        minWidth: minWidth,
        showBottomBorder: showBottomBorder,
        smRatio: 0.5,
        lmRatio: 1.5,
      ),
    );
  }
}
