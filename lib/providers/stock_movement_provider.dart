import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../models/stock_movement.dart';
import '../services/database_service.dart';

class StockMovementState {
  final List<StockMovement> movements;
  final bool isLoading;

  StockMovementState({
    required this.movements,
    this.isLoading = false,
  });

  StockMovementState copyWith({
    List<StockMovement>? movements,
    bool? isLoading,
  }) {
    return StockMovementState(
      movements: movements ?? this.movements,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class StockMovementNotifier extends StateNotifier<StockMovementState> {
  StockMovementNotifier() : super(StockMovementState(movements: [])) {
    loadMovements();
  }

  void loadMovements() {
    if (!DatabaseService.isOperationalOpen) return;
    state = state.copyWith(isLoading: true);
    final allMovements = DatabaseService.stockMovementsBox.values.toList();
    // Sort chronologically descending (newest first)
    allMovements.sort((a, b) => b.date.compareTo(a.date));
    state = StockMovementState(movements: allMovements, isLoading: false);
  }

  Future<void> logMovement({
    required String itemId,
    required String itemName,
    required String itemType,
    required String type,
    required double quantity,
    required double previousStock,
    required double newStock,
    required double unitCost,
    String? notes,
  }) async {
    if (!DatabaseService.isOperationalOpen) return;
    final operatorName = DatabaseService.settingsBox.get('settings')?.profileName ?? 'Admin';
    final movement = StockMovement(
      id: const Uuid().v4(),
      itemId: itemId,
      itemName: itemName,
      itemType: itemType,
      type: type,
      quantity: quantity,
      previousStock: previousStock,
      newStock: newStock,
      unitCost: unitCost,
      operatorName: operatorName,
      date: DateTime.now(),
      notes: notes,
    );
    await DatabaseService.stockMovementsBox.put(movement.id, movement);
    loadMovements();
  }
}

final stockMovementProvider = StateNotifierProvider<StockMovementNotifier, StockMovementState>((ref) {
  return StockMovementNotifier();
});
