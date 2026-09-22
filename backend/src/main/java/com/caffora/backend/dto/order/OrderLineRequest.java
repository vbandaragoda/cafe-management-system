package com.caffora.backend.dto.order;

import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;

public record OrderLineRequest(
        @NotNull(message = "productId is required")
        Long productId,

        @NotNull(message = "quantity is required")
        @Min(value = 1, message = "quantity must be at least 1")
        Integer quantity,

        @Size(max = 250)
        String note
) {
}
