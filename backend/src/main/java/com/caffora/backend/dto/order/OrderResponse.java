package com.caffora.backend.dto.order;

import com.caffora.backend.model.Order;
import com.caffora.backend.model.OrderStatus;
import com.caffora.backend.model.PickupType;

import java.math.BigDecimal;
import java.time.Instant;
import java.util.List;

public record OrderResponse(
        Long id,
        String orderNumber,
        OrderStatus status,
        PickupType pickupType,
        BigDecimal subtotal,
        BigDecimal pickupFee,
        BigDecimal tax,
        BigDecimal total,
        List<OrderItemResponse> items,
        Instant placedAt,
        Instant readyAt,
        Instant completedAt,
        String customerName,
        Long tableId,
        String tableNumber
) {
    public static OrderResponse from(Order order) {
        return new OrderResponse(
                order.getId(),
                order.getOrderNumber(),
                order.getStatus(),
                order.getPickupType(),
                order.getSubtotal(),
                order.getPickupFee(),
                order.getTax(),
                order.getTotal(),
                order.getItems().stream().map(OrderItemResponse::from).toList(),
                order.getPlacedAt(),
                order.getReadyAt(),
                order.getCompletedAt(),
                order.getUser() != null ? order.getUser().getName() : null,
                order.getTable() != null ? order.getTable().getId() : null,
                order.getTable() != null ? order.getTable().getTableNumber() : null
        );
    }
}
