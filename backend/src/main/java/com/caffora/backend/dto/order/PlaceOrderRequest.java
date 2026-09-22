package com.caffora.backend.dto.order;

import com.caffora.backend.model.PickupType;
import jakarta.validation.Valid;
import jakarta.validation.constraints.NotEmpty;

import java.util.List;

public record PlaceOrderRequest(
        @NotEmpty(message = "Your cart is empty")
        @Valid
        List<OrderLineRequest> items,

        PickupType pickupType,

        /** Optional: set when the order is placed by scanning a table's QR code (dine-in). */
        Long tableId
) {
}
