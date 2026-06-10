import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/services/api_service.dart';

import '../../core/models/order_model.dart';
import '../../core/models/review_model.dart';

// My orders provider
final myOrdersProvider = FutureProvider<List<OrderData>>((ref) async {
  final apiService = ref.read(apiServiceProvider);
  final response = await apiService.getMyOrders();
  return response.data;
});

// Order detail provider
final orderDetailProvider = FutureProvider.family<OrderData, int>((
  ref,
  orderId,
) async {
  final apiService = ref.read(apiServiceProvider);
  return await apiService.getOrderDetail(orderId);
});

final orderReviewProvider = FutureProvider.family<ReviewData?, int>((
  ref,
  orderId,
) async {
  final apiService = ref.read(apiServiceProvider);
  return await apiService.getOrderReview(orderId);
});

// Create order controller
final createOrderControllerProvider =
    StateNotifierProvider<CreateOrderController, CreateOrderState>((ref) {
      return CreateOrderController(ref);
    });

class CreateOrderState {
  final bool isLoading;
  final String? errorMessage;
  final OrderData? createdOrder;

  const CreateOrderState({
    this.isLoading = false,
    this.errorMessage,
    this.createdOrder,
  });

  CreateOrderState copyWith({
    bool? isLoading,
    String? errorMessage,
    OrderData? createdOrder,
  }) {
    return CreateOrderState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      createdOrder: createdOrder ?? this.createdOrder,
    );
  }
}

class CreateOrderController extends StateNotifier<CreateOrderState> {
  CreateOrderController(this._ref) : super(const CreateOrderState());

  final Ref _ref;

  Future<bool> createOrder(CreateOrderRequest request) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final apiService = _ref.read(apiServiceProvider);
      final order = await apiService.createOrder(request);
      state = state.copyWith(isLoading: false, createdOrder: order);
      // Refresh myOrdersProvider to show newly created order
      _ref.refresh(myOrdersProvider); // ignore: unused_result
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to create order: $e',
      );
      return false;
    }
  }

  void reset() {
    state = const CreateOrderState();
  }
}

// Order action controller (untuk provider accept/start/complete)
final orderActionControllerProvider =
    StateNotifierProvider<OrderActionController, OrderActionState>((ref) {
      return OrderActionController(ref);
    });

class OrderActionState {
  final bool isLoading;
  final String? errorMessage;
  final bool success;

  const OrderActionState({
    this.isLoading = false,
    this.errorMessage,
    this.success = false,
  });

  OrderActionState copyWith({
    bool? isLoading,
    String? errorMessage,
    bool? success,
  }) {
    return OrderActionState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      success: success ?? this.success,
    );
  }
}

class OrderActionController extends StateNotifier<OrderActionState> {
  OrderActionController(this._ref) : super(const OrderActionState());

  final Ref _ref;

  Future<bool> respondToOrder(int orderId, String action) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final apiService = _ref.read(apiServiceProvider);
      await apiService.respondToOrder(orderId: orderId, action: action);
      state = state.copyWith(isLoading: false, success: true);
      // Refresh orders after responding
      _ref.refresh(myOrdersProvider); // ignore: unused_result
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: 'Failed: $e');
      return false;
    }
  }

  Future<bool> startWork(int orderId) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final apiService = _ref.read(apiServiceProvider);
      await apiService.startWork(orderId);
      state = state.copyWith(isLoading: false, success: true);
      // Refresh orders after starting work
      _ref.refresh(myOrdersProvider); // ignore: unused_result
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: 'Failed: $e');
      return false;
    }
  }

  Future<bool> completeOrder(int orderId, int finalPrice) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final apiService = _ref.read(apiServiceProvider);
      await apiService.completeOrder(orderId: orderId, finalPrice: finalPrice);
      state = state.copyWith(isLoading: false, success: true);
      // Refresh orders after completing
      _ref.refresh(myOrdersProvider); // ignore: unused_result
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: 'Failed: $e');
      return false;
    }
  }

  void reset() {
    state = const OrderActionState();
  }
}
