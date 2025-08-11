class Time {
  static String formatPostTime(DateTime postTime) {
    final now = DateTime.now();
    final diff = now.difference(postTime);

    if (diff.inMinutes < 1) {
      return "Vừa xong";
    } else if (diff.inMinutes < 60) {
      return "${diff.inMinutes} phút";
    } else if (diff.inHours < 24) {
      return "${diff.inHours} giờ";
    } else if (diff.inDays < 7) {
      return "${diff.inDays} ngày";
    } else {
      if (postTime.year == now.year) {
        return '${postTime.day} thg ${postTime.month}';
      } else {
        return '${postTime.day} thg ${postTime.month}, ${postTime.year}';
      }
    }
  }
}
