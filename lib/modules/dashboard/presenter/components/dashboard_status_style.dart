import 'package:material_ui/material_ui.dart';
import 'package:oflite/modules/dashboard/domain/entity/dashboard_month_summary.dart';
import 'package:oflite/modules/dashboard/presenter/strings/dashboard_pt_string.dart';
import 'package:oflite/shared/common/constants/colors.dart';

/// Cor, ícone e rótulo de cada status (apresentação).
extension DashboardStatusStyle on DashboardStatus {
  Color get color => switch (this) {
    DashboardStatus.approved => statusApprovedColor,
    DashboardStatus.disapproved => statusRejectedColor,
    DashboardStatus.pending => statusPendingColor,
    DashboardStatus.finished => whiteColor,
  };

  IconData get icon => switch (this) {
    DashboardStatus.approved => Icons.check,
    DashboardStatus.disapproved => Icons.close_sharp,
    DashboardStatus.pending => Icons.pending_outlined,
    DashboardStatus.finished => Icons.circle,
  };

  String get label => switch (this) {
    DashboardStatus.approved => DashboardStrings.approved,
    DashboardStatus.disapproved => DashboardStrings.disapproved,
    DashboardStatus.pending => DashboardStrings.pending,
    DashboardStatus.finished => DashboardStrings.finished,
  };
}
