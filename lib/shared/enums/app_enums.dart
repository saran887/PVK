enum UserRole {
  owner,
  admin,
  sales,
  billing,
  delivery;

  static UserRole fromString(String role) {
    return UserRole.values.firstWhere(
      (e) => e.name == role.toLowerCase(),
      orElse: () => UserRole.sales,
    );
  }
}

enum OrderStatus {
  pending,
  billed,
  dispatched,
  delivered,
  cancelled;

  static OrderStatus fromString(String status) {
    return OrderStatus.values.firstWhere(
      (e) => e.name == status.toLowerCase(),
      orElse: () => OrderStatus.pending,
    );
  }
}

enum PaymentMode {
  cash,
  upi,
  online,
  cheque;

  static PaymentMode fromString(String mode) {
    return PaymentMode.values.firstWhere(
      (e) => e.name == mode.toLowerCase(),
      orElse: () => PaymentMode.cash,
    );
  }
}

enum ActionType {
  createOrder,
  editOrder,
  changeStatus,
  recordPayment,
  editRate,
  createShop,
  editShop;

  static ActionType fromString(String type) {
    return ActionType.values.firstWhere(
      (e) => e.name == type,
      orElse: () => ActionType.createOrder,
    );
  }
}
