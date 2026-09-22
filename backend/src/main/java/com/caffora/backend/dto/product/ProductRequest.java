package com.caffora.backend.dto.product;

import com.caffora.backend.model.ProductStatus;
import jakarta.validation.constraints.DecimalMin;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.PositiveOrZero;
import jakarta.validation.constraints.Size;

import java.math.BigDecimal;

public record ProductRequest(
        @NotBlank(message = "Name is required")
        @Size(max = 150)
        String name,

        @NotBlank(message = "Description is required")
        @Size(max = 500)
        String description,

        @NotNull(message = "Price is required")
        @DecimalMin(value = "0.0", inclusive = true, message = "Price cannot be negative")
        BigDecimal price,

        @NotNull(message = "Category is required")
        Long categoryId,

        @PositiveOrZero(message = "Calories cannot be negative")
        Integer calories,

        String imageUrl,

        ProductStatus status
) {
}
