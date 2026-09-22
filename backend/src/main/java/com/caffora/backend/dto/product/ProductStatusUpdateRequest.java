package com.caffora.backend.dto.product;

import com.caffora.backend.model.ProductStatus;
import jakarta.validation.constraints.NotNull;

public record ProductStatusUpdateRequest(
        @NotNull(message = "Status is required")
        ProductStatus status
) {
}
