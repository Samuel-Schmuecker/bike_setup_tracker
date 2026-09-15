import 'package:path_provider/path_provider.dart';
import 'package:sembast/sembast_io.dart';

Future<Database> openBikeDatabase() async {
  final directory = await getApplicationDocumentsDirectory();
  return databaseFactoryIo.openDatabase('${directory.path}/bike_tracker_v2.db');
}
