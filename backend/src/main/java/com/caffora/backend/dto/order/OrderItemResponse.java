package com.caffora.backend.dto.order;

import com.caffora.backend.model.OrderItem;

import java.math.BigDecimal;

public record OrderItemResponse(
        Long id,
        Long productId,
        String name,
        BigDecimal unitPrice,
        Integer quantity,
        String note,
        BigDecimal lineTotal
) {
    public static OrderItemResponse from(OrderItem item) {
        return new OrderItemResponse(
                item.getId(),
                item.getProduct() != null ? item.getProduct().getId() : null,
                item.getItemName(),
                item.getUnitPrice(),
                item.getQuantity(),
                item.getNote(),
                item.lineTotal()
        );
    }
}
