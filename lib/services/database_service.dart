import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/product.dart';
import '../models/inbound_record.dart';
import '../models/outbound_record.dart';
import '../models/employee.dart';
import '../models/activity_record.dart';
import '../models/job_type.dart';
import '../models/app_settings.dart';
import '../models/raw_material.dart';
import '../models/finished_good.dart';
import '../models/bill_of_materials.dart';
import '../models/production_record.dart';

class DatabaseService {
  static const _secureStorage = FlutterSecureStorage();
  static const _keyName = 'hive_encryption_key';

  static late Box<Product> productsBox;
  static late Box<InboundRecord> inboundBox;
  static late Box<OutboundRecord> outboundBox;
  static late Box<Employee> employeesBox;
  static late Box<ActivityRecord> activityBox;
  static late Box<JobType> jobTypesBox;
  static late Box<AppSettings> settingsBox;
  
  static late Box<RawMaterial> rawMaterialsBox;
  static late Box<FinishedGood> finishedGoodsBox;
  static late Box<BillOfMaterials> bomBox;
  static late Box<ProductionRecord> productionBox;

  static Future<void> init() async {
    // 1. Initialize Hive for Flutter
    await Hive.initFlutter();

    // 2. Register Adapters
    Hive.registerAdapter(ProductAdapter());
    Hive.registerAdapter(InboundRecordAdapter());
    Hive.registerAdapter(OutboundStatusAdapter());
    Hive.registerAdapter(OutboundRecordAdapter());
    Hive.registerAdapter(EmployeeAdapter());
    Hive.registerAdapter(ActivityRecordAdapter());
    Hive.registerAdapter(JobTypeAdapter());
    Hive.registerAdapter(AppSettingsAdapter());
    Hive.registerAdapter(RawMaterialAdapter());
    Hive.registerAdapter(FinishedGoodAdapter());
    Hive.registerAdapter(BillOfMaterialsAdapter());
    Hive.registerAdapter(BOMComponentAdapter());
    Hive.registerAdapter(ProductionRecordAdapter());
    Hive.registerAdapter(MaterialUsageAdapter());

    // 3. Get or generate encryption key
    final encryptionKey = await _getOrCreateEncryptionKey();

    // 4. Open Boxes with encryption
    productsBox = await Hive.openBox<Product>(
      'products',
      encryptionCipher: HiveAesCipher(encryptionKey),
    );
    inboundBox = await Hive.openBox<InboundRecord>(
      'inbound_records',
      encryptionCipher: HiveAesCipher(encryptionKey),
    );
    outboundBox = await Hive.openBox<OutboundRecord>(
      'outbound_records',
      encryptionCipher: HiveAesCipher(encryptionKey),
    );
    employeesBox = await Hive.openBox<Employee>(
      'employees',
      encryptionCipher: HiveAesCipher(encryptionKey),
    );
    activityBox = await Hive.openBox<ActivityRecord>(
      'activity_records',
      encryptionCipher: HiveAesCipher(encryptionKey),
    );
    jobTypesBox = await Hive.openBox<JobType>(
      'job_types',
      encryptionCipher: HiveAesCipher(encryptionKey),
    );
    settingsBox = await Hive.openBox<AppSettings>(
      'app_settings',
      encryptionCipher: HiveAesCipher(encryptionKey),
    );
    rawMaterialsBox = await Hive.openBox<RawMaterial>(
      'raw_materials',
      encryptionCipher: HiveAesCipher(encryptionKey),
    );
    finishedGoodsBox = await Hive.openBox<FinishedGood>(
      'finished_goods',
      encryptionCipher: HiveAesCipher(encryptionKey),
    );
    bomBox = await Hive.openBox<BillOfMaterials>(
      'bill_of_materials',
      encryptionCipher: HiveAesCipher(encryptionKey),
    );
    productionBox = await Hive.openBox<ProductionRecord>(
      'production_records',
      encryptionCipher: HiveAesCipher(encryptionKey),
    );

    // Initialize AppSettings if empty
    if (settingsBox.isEmpty) {
      await settingsBox.put('settings', AppSettings(isBiometricEnabled: true));
    }
  }

  static Future<List<int>> _getOrCreateEncryptionKey() async {
    final containsKey = await _secureStorage.containsKey(key: _keyName);
    if (!containsKey) {
      final key = Hive.generateSecureKey();
      await _secureStorage.write(
        key: _keyName,
        value: base64UrlEncode(key),
      );
      return key;
    } else {
      final base64Key = await _secureStorage.read(key: _keyName);
      return base64Url.decode(base64Key!);
    }
  }

  // Clear database data (used for testing or resetting data)
  static Future<void> clearAllData() async {
    await productsBox.clear();
    await inboundBox.clear();
    await outboundBox.clear();
    await employeesBox.clear();
    await activityBox.clear();
    await jobTypesBox.clear();
    await settingsBox.clear();
    await rawMaterialsBox.clear();
    await finishedGoodsBox.clear();
    await bomBox.clear();
    await productionBox.clear();
    await settingsBox.put('settings', AppSettings(isBiometricEnabled: true));
  }
}
