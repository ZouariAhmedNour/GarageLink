

import 'package:garagelink/dashboard/constants/constants.dart';
import 'package:garagelink/dashboard/models/analytic_info_model.dart';
import 'package:garagelink/dashboard/models/discussions_info_model.dart';
import 'package:garagelink/dashboard/models/referal_info_model.dart';

List analyticData = [
  AnalyticInfo(
    title: "Réparations du mois",
    count: 48,
    svgSrc: "assets/icons/repair.svg",
    color: primaryColor,
  ),
  AnalyticInfo(
    title: "Véhicules en attente",
    count: 12,
    svgSrc: "assets/icons/car.svg",
    color: orange,
  ),
  AnalyticInfo(
    title: "Clients actifs",
    count: 320,
    svgSrc: "assets/icons/client.svg",
    color: purple,
  ),
  AnalyticInfo(
    title: "Pièces en stock",
    count: 1520,
    svgSrc: "assets/icons/parts.svg",
    color: green,
  ),
];


List recentActivities = [
  DiscussionInfoModel(
    imageSrc: "assets/icons/repair.svg",
    name: "Réparation terminée - Peugeot 208",
    date: "11 Août 2025",
  ),
  DiscussionInfoModel(
    imageSrc: "assets/icons/invoice.svg",
    name: "Facture en attente - Renault Clio",
    date: "10 Août 2025",
  ),
  DiscussionInfoModel(
    imageSrc: "assets/icons/appointment.svg",
    name: "Nouveau RDV - Ford Transit",
    date: "10 Août 2025",
  ),
  DiscussionInfoModel(
    imageSrc: "assets/icons/repair.svg",
    name: "Réparation en cours - Citroën C3",
    date: "9 Août 2025",
  ),
];

List referalData = [
  ReferalInfoModel(
    title: "Facebook",
    count: 234,
    svgSrc: "assets/icons/Facebook.svg",
    color: primaryColor,
  ),
  ReferalInfoModel(
    title: "Twitter",
    count: 234,
    svgSrc: "assets/icons/Twitter.svg",
    color: primaryColor,
  ),
  ReferalInfoModel(
    title: "Linkedin",
    count: 234,
    svgSrc: "assets/icons/Linkedin.svg",
    color: primaryColor,
  ),

  ReferalInfoModel(
    title: "Dribble",
    count: 234,
    svgSrc: "assets/icons/Dribbble.svg",
    color: red,
  ),
];
