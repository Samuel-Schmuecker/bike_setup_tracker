import 'package:sembast_web/sembast_web.dart';

Future<Database> openBikeDatabase() =>
    databaseFactoryWeb.openDatabase('bike_tracker_v2');
