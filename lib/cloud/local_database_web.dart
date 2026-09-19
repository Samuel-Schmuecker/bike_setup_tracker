import 'package:sembast_web/sembast_web.dart';
import 'cloud_config.dart';

Future<Database> openBikeDatabase() =>
    databaseFactoryWeb.openDatabase(CloudConfig.databaseName);
