import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:photo_view/photo_view.dart';

class ImageHelper {
  static showavatar(String avatar) {
    return CircleAvatar(
      radius: 20,
      child: avatar.toString() == ""
          ? const Icon(Icons.person)
          : ClipOval(
              child: CachedNetworkImage(
                imageUrl: avatar.toString(), // Hiển thị ảnh từ URL
                width: 40,
                height: 40,
                fit: BoxFit.cover,
                placeholder: (context, url) => const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(),
                ),
                errorWidget: (context, url, error) => const Icon(Icons
                    .error), // Đảm bảo ảnh được hiển thị đúng kích thước trong CircleAvatar
              ),
            ),
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
