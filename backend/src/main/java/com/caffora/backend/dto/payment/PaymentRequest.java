package com.caffora.backend.dto.payment;

import com.caffora.backend.model.PaymentMethod;
import jakarta.validation.constraints.NotNull;

public record PaymentRequest(
        @NotNull(message = "orderId is required")
        Long orderId,

        @NotNull(message = "method is required")
        PaymentMethod method
) {
}
