
import 'package:flutter/material.dart';
import 'package:garagelink/MecanicienScreens/dashboard/constants/constants.dart';
import 'package:garagelink/MecanicienScreens/dashboard/data/data.dart';


import 'discussion_info_detail.dart';

class Discussions extends StatelessWidget {
  const Discussions({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 540,
      padding: EdgeInsets.all(appPadding),
      decoration: BoxDecoration(
        color: Colors.white, 
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 6,
            offset: Offset(0, 3), 
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Suivi',
                style: TextStyle(
                  color: textColor,
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                ),
              ),
              Text(
                'View All',
                style: TextStyle(
                  color: textColor.withOpacity(0.5),
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ],
          ),
          SizedBox(
            height: appPadding,
          ),
          Expanded(
            child: ListView.builder(
              physics: NeverScrollableScrollPhysics(),
              shrinkWrap: true,
              itemCount: recentActivities.length,
              itemBuilder: (context, index) => DiscussionInfoDetail(info: recentActivities[index],),
            ),
          )
        ],
      ),
    );
  }
}
