// Copyright (c) 2026 Emanuele Ciotola. All Rights Reserved.
// PROJECT: G-Scanner — See LICENSE file in root for terms.

import 'package:easy_localization/easy_localization.dart';

String formatRelativeDate(String isoDate) {
  try {
    final parsed = DateTime.parse(isoDate).toLocal();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final targetDate = DateTime(parsed.year, parsed.month, parsed.day);

    final hour = parsed.hour.toString().padLeft(2, '0');
    final minute = parsed.minute.toString().padLeft(2, '0');

    if (targetDate == today) {
      return "${'common.time.today'.tr()}, $hour:$minute";
    } else if (targetDate == yesterday) {
      return "${'common.time.yesterday'.tr()}, $hour:$minute";
    } else {
      const months = [
        'Gen',
        'Feb',
        'Mar',
        'Apr',
        'Mag',
        'Giu',
        'Lug',
        'Ago',
        'Set',
        'Ott',
        'Nov',
        'Dic',
      ];
      return "${parsed.day} ${months[parsed.month - 1]} ${parsed.year}, $hour:$minute";
    }
  } catch (e) {
    return "";
  }
}

String formatScanDate(String isoDate) {
  try {
    final parsed = DateTime.parse(isoDate).toLocal();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final targetDate = DateTime(parsed.year, parsed.month, parsed.day);

    final hour = parsed.hour.toString().padLeft(2, '0');
    final minute = parsed.minute.toString().padLeft(2, '0');
    final timeStr = "$hour:$minute";

    if (targetDate == today) {
      return "product.scanDate.today".tr(namedArgs: {"time": timeStr});
    } else if (targetDate == yesterday) {
      return "product.scanDate.yesterday".tr(namedArgs: {"time": timeStr});
    } else {
      const months = [
        'Gen',
        'Feb',
        'Mar',
        'Apr',
        'Mag',
        'Giu',
        'Lug',
        'Ago',
        'Set',
        'Ott',
        'Nov',
        'Dic',
      ];
      final dateStr =
          "${parsed.day} ${months[parsed.month - 1]} ${parsed.year}";
      return "product.scanDate.default"
          .tr(namedArgs: {"date": dateStr, "time": timeStr});
    }
  } catch (e) {
    return isoDate;
  }
}

String formatReportDate(String isoDate) {
  try {
    final parsed = DateTime.parse(isoDate).toLocal();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final targetDate = DateTime(parsed.year, parsed.month, parsed.day);

    final hour = parsed.hour.toString().padLeft(2, '0');
    final minute = parsed.minute.toString().padLeft(2, '0');
    final timeStr = "$hour:$minute";

    if (targetDate == today) {
      return "report.ui.reportDate.today".tr(namedArgs: {"time": timeStr});
    } else if (targetDate == yesterday) {
      return "report.ui.reportDate.yesterday".tr(namedArgs: {"time": timeStr});
    } else {
      const months = [
        'Gen',
        'Feb',
        'Mar',
        'Apr',
        'Mag',
        'Giu',
        'Lug',
        'Ago',
        'Set',
        'Ott',
        'Nov',
        'Dic',
      ];
      final dateStr =
          "${parsed.day} ${months[parsed.month - 1]} ${parsed.year}";
      return "report.ui.reportDate.default"
          .tr(namedArgs: {"date": dateStr, "time": timeStr});
    }
  } catch (e) {
    return isoDate;
  }
}
