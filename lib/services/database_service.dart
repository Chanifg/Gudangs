import 'dart:convert';
import 'package:crypto/crypto.dart';
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
import '../models/stock_movement.dart';
import '../models/audit_log.dart';

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
  static late Box<StockMovement> stockMovementsBox;
  static late Box<AuditLog> auditLogsBox;

  static bool _isOperationalOpen = false;
  static bool get isOperationalOpen => _isOperationalOpen;

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
    Hive.registerAdapter(StockMovementAdapter());
    Hive.registerAdapter(AuditLogAdapter());

    // 3. Get base key
    final baseKey = await _getOrCreateEncryptionKey();

    // 4. Open settingsBox only (statically encrypted with secure storage base key)
    settingsBox = await Hive.openBox<AppSettings>(
      'app_settings',
      encryptionCipher: HiveAesCipher(baseKey),
    );

    // Initialize AppSettings if empty
    if (settingsBox.isEmpty) {
      await settingsBox.put('settings', AppSettings(isBiometricEnabled: true));
    }
  }

  // Open operational database boxes dynamically using derived key from PIN
  static Future<void> openOperationalBoxes(String pin) async {
    if (_isOperationalOpen) return;

    final baseKey = await _getOrCreateEncryptionKey();
    
    // Derive a dynamic 32-byte (256-bit) encryption key from BaseKey + PIN using SHA-256
    final pinBytes = utf8.encode(pin);
    final combinedBytes = [...baseKey, ...pinBytes];
    final derivedKey = sha256.convert(combinedBytes).bytes;

    productsBox = await Hive.openBox<Product>(
      'products',
      encryptionCipher: HiveAesCipher(derivedKey),
    );
    inboundBox = await Hive.openBox<InboundRecord>(
      'inbound_records',
      encryptionCipher: HiveAesCipher(derivedKey),
    );
    outboundBox = await Hive.openBox<OutboundRecord>(
      'outbound_records',
      encryptionCipher: HiveAesCipher(derivedKey),
    );
    employeesBox = await Hive.openBox<Employee>(
      'employees',
      encryptionCipher: HiveAesCipher(derivedKey),
    );
    activityBox = await Hive.openBox<ActivityRecord>(
      'activity_records',
      encryptionCipher: HiveAesCipher(derivedKey),
    );
    jobTypesBox = await Hive.openBox<JobType>(
      'job_types',
      encryptionCipher: HiveAesCipher(derivedKey),
    );
    rawMaterialsBox = await Hive.openBox<RawMaterial>(
      'raw_materials',
      encryptionCipher: HiveAesCipher(derivedKey),
    );
    finishedGoodsBox = await Hive.openBox<FinishedGood>(
      'finished_goods',
      encryptionCipher: HiveAesCipher(derivedKey),
    );
    bomBox = await Hive.openBox<BillOfMaterials>(
      'bill_of_materials',
      encryptionCipher: HiveAesCipher(derivedKey),
    );
    productionBox = await Hive.openBox<ProductionRecord>(
      'production_records',
      encryptionCipher: HiveAesCipher(derivedKey),
    );
    stockMovementsBox = await Hive.openBox<StockMovement>(
      'stock_movements',
      encryptionCipher: HiveAesCipher(derivedKey),
    );
    auditLogsBox = await Hive.openBox<AuditLog>(
      'audit_logs',
      encryptionCipher: HiveAesCipher(derivedKey),
    );

    _isOperationalOpen = true;
  }

  // Close operational database boxes when logging out or auto-locking
  static Future<void> closeOperationalBoxes() async {
    if (!_isOperationalOpen) return;

    await productsBox.close();
    await inboundBox.close();
    await outboundBox.close();
    await employeesBox.close();
    await activityBox.close();
    await jobTypesBox.close();
    await rawMaterialsBox.close();
    await finishedGoodsBox.close();
    await bomBox.close();
    await productionBox.close();
    await stockMovementsBox.close();
    await auditLogsBox.close();

    _isOperationalOpen = false;
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
    await rawMaterialsBox.clear();
    await finishedGoodsBox.clear();
    await bomBox.clear();
    await productionBox.clear();
    await stockMovementsBox.clear();
    await auditLogsBox.clear();
  }

  // Seed database with realistic dummy data for development/testing
  static Future<void> seedDummyData() async {
    // 1. Reset all boxes first
    await clearAllData();

    final now = DateTime.now();
    final oneDayAgo = now.subtract(const Duration(days: 1));
    final twoDaysAgo = now.subtract(const Duration(days: 2));
    final threeDaysAgo = now.subtract(const Duration(days: 3));

    // 2. Job Types
    final jt1 = JobType(id: 'jt-jahit', name: 'Jahit', ratePerUnit: 5000.0, createdAt: threeDaysAgo, updatedAt: threeDaysAgo);
    final jt2 = JobType(id: 'jt-pack', name: 'Packing', ratePerUnit: 1500.0, createdAt: threeDaysAgo, updatedAt: threeDaysAgo);
    final jt3 = JobType(id: 'jt-fin', name: 'Finishing', ratePerUnit: 2000.0, createdAt: threeDaysAgo, updatedAt: threeDaysAgo);
    await jobTypesBox.putAll({jt1.id: jt1, jt2.id: jt2, jt3.id: jt3});

    // 3. Employees
    final emp1 = Employee(id: 'emp-budi', fullName: 'Budi Santoso', phoneNumber: '081234567890', position: 'Operator Jahit', createdAt: threeDaysAgo, updatedAt: threeDaysAgo);
    final emp2 = Employee(id: 'emp-siti', fullName: 'Siti Aminah', phoneNumber: '081298765432', position: 'Operator Packing', createdAt: threeDaysAgo, updatedAt: threeDaysAgo);
    final emp3 = Employee(id: 'emp-joko', fullName: 'Joko Widodo', phoneNumber: '081311223344', position: 'Helper Gudang', createdAt: threeDaysAgo, updatedAt: threeDaysAgo);
    await employeesBox.putAll({emp1.id: emp1, emp2.id: emp2, emp3.id: emp3});

    // 4. Raw Materials
    final rm1 = RawMaterial(id: 'rm-katun', name: 'Kain Katun', sku: 'RM-KTN-01', unit: 'meter', currentStock: 150.0, defaultUnitCost: 25000.0, createdAt: threeDaysAgo, updatedAt: threeDaysAgo);
    final rm2 = RawMaterial(id: 'rm-kancing', name: 'Kancing', sku: 'RM-KCG-02', unit: 'pcs', currentStock: 500.0, defaultUnitCost: 500.0, createdAt: threeDaysAgo, updatedAt: threeDaysAgo);
    final rm3 = RawMaterial(id: 'rm-benang', name: 'Benang', sku: 'RM-BNG-03', unit: 'roll', currentStock: 30.0, defaultUnitCost: 15000.0, createdAt: threeDaysAgo, updatedAt: threeDaysAgo);
    final rm4 = RawMaterial(id: 'rm-kotak', name: 'Kotak Kemasan', sku: 'RM-BOX-04', unit: 'pcs', currentStock: 120.0, defaultUnitCost: 3000.0, createdAt: threeDaysAgo, updatedAt: threeDaysAgo);
    await rawMaterialsBox.putAll({rm1.id: rm1, rm2.id: rm2, rm3.id: rm3, rm4.id: rm4});

    // 5. Finished Goods
    final fg1 = FinishedGood(id: 'fg-kemeja', name: 'Kemeja Premium', sku: 'FG-KEM-01', unit: 'pcs', currentStock: 15.0, defaultUnitPrice: 85000.0, lastHPP: 46000.0, createdAt: threeDaysAgo, updatedAt: threeDaysAgo);
    final fg2 = FinishedGood(id: 'fg-kaos', name: 'Kaos Polos', sku: 'FG-KAS-02', unit: 'pcs', currentStock: 30.0, defaultUnitPrice: 45000.0, lastHPP: 23750.0, createdAt: threeDaysAgo, updatedAt: threeDaysAgo);
    await finishedGoodsBox.putAll({fg1.id: fg1, fg2.id: fg2});

    // 6. Bill of Materials (BOM)
    final bom1 = BillOfMaterials(
      id: 'bom-kemeja',
      name: 'Formula Kemeja Premium',
      finishedGoodId: fg1.id,
      finishedGoodName: fg1.name,
      components: [
        BOMComponent(rawMaterialId: rm1.id, rawMaterialName: rm1.name, rawMaterialUnit: rm1.unit, quantityPerUnit: 1.5),
        BOMComponent(rawMaterialId: rm2.id, rawMaterialName: rm2.name, rawMaterialUnit: rm2.unit, quantityPerUnit: 8.0),
        BOMComponent(rawMaterialId: rm3.id, rawMaterialName: rm3.name, rawMaterialUnit: rm3.unit, quantityPerUnit: 0.1),
        BOMComponent(rawMaterialId: rm4.id, rawMaterialName: rm4.name, rawMaterialUnit: rm4.unit, quantityPerUnit: 1.0),
      ],
      createdAt: threeDaysAgo,
      updatedAt: threeDaysAgo,
    );
    final bom2 = BillOfMaterials(
      id: 'bom-kaos',
      name: 'Formula Kaos Polos',
      finishedGoodId: fg2.id,
      finishedGoodName: fg2.name,
      components: [
        BOMComponent(rawMaterialId: rm1.id, rawMaterialName: rm1.name, rawMaterialUnit: rm1.unit, quantityPerUnit: 0.8),
        BOMComponent(rawMaterialId: rm3.id, rawMaterialName: rm3.name, rawMaterialUnit: rm3.unit, quantityPerUnit: 0.05),
        BOMComponent(rawMaterialId: rm4.id, rawMaterialName: rm4.name, rawMaterialUnit: rm4.unit, quantityPerUnit: 1.0),
      ],
      createdAt: threeDaysAgo,
      updatedAt: threeDaysAgo,
    );
    await bomBox.putAll({bom1.id: bom1, bom2.id: bom2});

    // 7. Inbound Records
    final in1 = InboundRecord(id: 'in-1', productId: rm1.id, productName: rm1.name, productSku: rm1.sku, quantity: 200.0, pricePerUnit: 25000.0, totalCost: 5000000.0, date: threeDaysAgo, notes: 'Restock kain awal bulan', createdAt: threeDaysAgo);
    final in2 = InboundRecord(id: 'in-2', productId: rm2.id, productName: rm2.name, productSku: rm2.sku, quantity: 600.0, pricePerUnit: 500.0, totalCost: 300000.0, date: threeDaysAgo, notes: 'Kancing supplier lokal', createdAt: threeDaysAgo);
    final in3 = InboundRecord(id: 'in-3', productId: rm3.id, productName: rm3.name, productSku: rm3.sku, quantity: 40.0, pricePerUnit: 15000.0, totalCost: 600000.0, date: twoDaysAgo, notes: 'Benang jahit tambahan', createdAt: twoDaysAgo);
    final in4 = InboundRecord(id: 'in-4', productId: rm4.id, productName: rm4.name, productSku: rm4.sku, quantity: 150.0, pricePerUnit: 3000.0, totalCost: 450000.0, date: twoDaysAgo, notes: 'Kotak kardus kemasan', createdAt: twoDaysAgo);
    await inboundBox.putAll({in1.id: in1, in2.id: in2, in3.id: in3, in4.id: in4});

    // 8. Production Records
    final prod1 = ProductionRecord(
      id: 'prod-1',
      bomId: bom1.id,
      bomName: bom1.name,
      finishedGoodId: fg1.id,
      finishedGoodName: fg1.name,
      quantityProduced: 10.0,
      materialsUsed: [
        MaterialUsage(rawMaterialId: rm1.id, rawMaterialName: rm1.name, rawMaterialUnit: rm1.unit, quantityUsed: 15.0, unitCostAtTime: 25000.0, totalCost: 375000.0),
        MaterialUsage(rawMaterialId: rm2.id, rawMaterialName: rm2.name, rawMaterialUnit: rm2.unit, quantityUsed: 80.0, unitCostAtTime: 500.0, totalCost: 40000.0),
        MaterialUsage(rawMaterialId: rm3.id, rawMaterialName: rm3.name, rawMaterialUnit: rm3.unit, quantityUsed: 1.0, unitCostAtTime: 15000.0, totalCost: 15000.0),
        MaterialUsage(rawMaterialId: rm4.id, rawMaterialName: rm4.name, rawMaterialUnit: rm4.unit, quantityUsed: 10.0, unitCostAtTime: 3000.0, totalCost: 30000.0),
      ],
      totalMaterialCost: 460000.0,
      hpp: 46000.0,
      date: twoDaysAgo,
      note: 'Produksi batch kemeja premium pertama',
      createdAt: twoDaysAgo,
    );
    final prod2 = ProductionRecord(
      id: 'prod-2',
      bomId: bom2.id,
      bomName: bom2.name,
      finishedGoodId: fg2.id,
      finishedGoodName: fg2.name,
      quantityProduced: 20.0,
      materialsUsed: [
        MaterialUsage(rawMaterialId: rm1.id, rawMaterialName: rm1.name, rawMaterialUnit: rm1.unit, quantityUsed: 16.0, unitCostAtTime: 25000.0, totalCost: 400000.0),
        MaterialUsage(rawMaterialId: rm3.id, rawMaterialName: rm3.name, rawMaterialUnit: rm3.unit, quantityUsed: 1.0, unitCostAtTime: 15000.0, totalCost: 15000.0),
        MaterialUsage(rawMaterialId: rm4.id, rawMaterialName: rm4.name, rawMaterialUnit: rm4.unit, quantityUsed: 20.0, unitCostAtTime: 3000.0, totalCost: 60000.0),
      ],
      totalMaterialCost: 475000.0,
      hpp: 23750.0,
      date: oneDayAgo,
      note: 'Produksi batch kaos polos',
      createdAt: oneDayAgo,
    );
    await productionBox.putAll({prod1.id: prod1, prod2.id: prod2});

    // 9. Outbound Records
    final out1 = OutboundRecord(id: 'out-1', productId: fg1.id, productName: fg1.name, productSku: fg1.sku, quantity: 5.0, sellingPricePerUnit: 85000.0, totalValue: 425000.0, destination: 'Toko Jaya Mandiri', status: OutboundStatus.terkirim, date: oneDayAgo, notes: 'Kirim via kurir toko', createdAt: oneDayAgo, updatedAt: oneDayAgo);
    final out2 = OutboundRecord(id: 'out-2', productId: fg2.id, productName: fg2.name, productSku: fg2.sku, quantity: 10.0, sellingPricePerUnit: 45000.0, totalValue: 450000.0, destination: 'Reseller Depok', status: OutboundStatus.terkirim, date: now, notes: 'Gojek instant', createdAt: now, updatedAt: now);
    await outboundBox.putAll({out1.id: out1, out2.id: out2});

    // 10. Activity Records
    final act1 = ActivityRecord(id: 'act-1', employeeId: emp1.id, employeeName: emp1.fullName, jobTypeId: jt1.id, jobTypeName: jt1.name, units: 15.0, ratePerUnit: jt1.ratePerUnit, estimatedWage: 75000.0, date: twoDaysAgo, notes: 'Jahit kemeja', createdAt: twoDaysAgo);
    final act2 = ActivityRecord(id: 'act-2', employeeId: emp2.id, employeeName: emp2.fullName, jobTypeId: jt2.id, jobTypeName: jt2.name, units: 30.0, ratePerUnit: jt2.ratePerUnit, estimatedWage: 45000.0, date: oneDayAgo, notes: 'Packing kemeja & kaos', createdAt: oneDayAgo);
    final act3 = ActivityRecord(id: 'act-3', employeeId: emp3.id, employeeName: emp3.fullName, jobTypeId: jt3.id, jobTypeName: jt3.name, units: 20.0, ratePerUnit: jt3.ratePerUnit, estimatedWage: 40000.0, date: now, notes: 'Finishing pakaian', createdAt: now);
    await activityBox.putAll({act1.id: act1, act2.id: act2, act3.id: act3});
  }
}
