
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:garagelink/dashboard/constants/constants.dart';
import 'package:garagelink/dashboard/models/discussions_info_model.dart'; // <- ajout

class DiscussionInfoDetail extends StatelessWidget {
  const DiscussionInfoDetail({Key? key, required this.info}) : super(key: key);

  final DiscussionInfoModel info;

  Widget _buildAvatar(String? src) {
    if (src == null) return const SizedBox.shrink();
    final lower = src.toLowerCase();
    if (lower.endsWith('.svg')) {
      return SvgPicture.asset(
        src,
        height: 38,
        width: 38,
        fit: BoxFit.contain,
      );
    } else {
      return Image.asset(
        src,
        height: 38,
        width: 38,
        fit: BoxFit.cover,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(top: appPadding),
      padding: EdgeInsets.all(appPadding / 2),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(40),
            child: _buildAvatar(info.imageSrc),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: appPadding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    info.name ?? '',
                    style: TextStyle(
                      color: textColor,
                      fontWeight: FontWeight.w600
                    ),
                  ),
                  Text(
                    info.date ?? '',
                    style: TextStyle(
                        color: textColor.withOpacity(0.5),
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Icon(Icons.more_vert_rounded,color: textColor.withOpacity(0.5),size: 18,)
        ],
      ),
    );
  }
}
