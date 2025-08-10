import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:photo_view/photo_view.dart';

class ImageHelper {
  static avatarAndName(String avatar, String name) {
    return ListTile(
      leading: CircleAvatar(
          radius: 20,
          child: avatar.toString() == ""
              ? const Icon(Icons.person)
              : ClipOval(
                  child: Image.network(
                    avatar.toString(), // Hiển thị ảnh từ URL
                    width: 40,
                    height: 40,
                    fit: BoxFit.cover,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) {
                        return child; // Nếu ảnh đã tải xong
                      } else {
                        return const CircularProgressIndicator(); // Hiển thị loading khi ảnh đang tải
                      }
                    },
                    errorBuilder: (context, error, stackTrace) {
                      return const Icon(Icons
                          .person); // Hiển thị icon lỗi nếu ảnh không tải được
                    }, // Đảm bảo ảnh được hiển thị đúng kích thước trong CircleAvatar
                  ),
                )),
      title: Text(name),
    );
  }

  static Widget showimage(BuildContext context, String image) {
    return GestureDetector(
      onTap: () {
        // Mở màn hình xem ảnh gốc
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => Scaffold(
              backgroundColor: Colors.black,
              body: Stack(
                children: [
                  Center(
                    child: PhotoView(
                      imageProvider: CachedNetworkImageProvider(image),
                      backgroundDecoration:
                          const BoxDecoration(color: Colors.black),
                    ),
                  ),
                  Positioned(
                    top: 40,
                    left: 16,
                    child: IconButton(
                      icon: const Icon(Icons.close,
                          color: Colors.white, size: 28),
                      onPressed: () => Navigator.pop(context),
                    ),
                  )
                ],
              ),
            ),
          ),
        );
      },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: CachedNetworkImage(
          imageUrl: image,
          width: 170,
          height: 170,
          fit: BoxFit.cover,
          placeholder: (context, url) => const SizedBox(
            width: 30,
            height: 30,
            child: CircularProgressIndicator(),
          ),
          errorWidget: (context, url, error) => const Icon(Icons.error),
        ),
      ),
    );
  }
}
