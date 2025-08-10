import 'package:timeago/timeago.dart' as timeago;
import 'package:intl/intl.dart';

class Time {
  // Hàm xử lý định dạng thời gian
  static formatPostTime(DateTime postTime) {
    final now = DateTime.now();

    if (postTime.year == now.year &&
        postTime.month == now.month &&
        postTime.day == now.day) {
      // Nếu là hôm nay → "x giờ trước"
      return timeago.format(postTime, locale: 'vi');
    } else {
      // Nếu không phải hôm nay → dd/MM/yyyy
      return DateFormat('dd/MM/yyyy').format(postTime);
    }
  }
}
