import 'package:flutter/material.dart';
import 'package:data_table_2/data_table_2.dart';
import '../../core/constants/app_colors.dart';

class CustomDataTable extends StatelessWidget {
  final List<DataColumn> columns;
  final List<DataRow> rows;
  final double minWidth;
  final bool showBottomBorder;

  const CustomDataTable({
    super.key,
    required this.columns,
    required this.rows,
    this.minWidth = 720,
    this.showBottomBorder = false,
  });

  @override
  Widget build(BuildContext context) {
return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: DataTable2(
        columns: columns,
        rows: rows,
        minWidth: minWidth,
        showBottomBorder: showBottomBorder,
        smRatio: 0.5,
        lmRatio: 1.6,
        columnSpacing: 16,
        horizontalMargin: 16,
        dividerThickness: 1,
        headingRowHeight: 52,
      ),
    );
  }
}