import '../models/setting_range.dart';

// Supreme DH V5 Öhlins Edition: DH38 m.1 Air / TTX22m.2 Coil.
// Sources and model-specific differences: docs/demo-ohlins-ranges.md.
const demoOhlinsRanges = <String, SettingRange>{
  'forkLsc': SettingRange(min: 0, max: 15),
  'forkHsc': SettingRange(min: 0, max: 3),
  'forkLsr': SettingRange(min: 0, max: 15),
  'shockLsc': SettingRange(min: 0, max: 16),
  'shockHsc': SettingRange(min: 1, max: 3),
  'shockLsr': SettingRange(min: 0, max: 7),
};
