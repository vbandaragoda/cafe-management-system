package com.caffora.backend.dto.product;

import com.caffora.backend.model.Product;
import com.caffora.backend.model.ProductStatus;

import java.math.BigDecimal;

public record ProductResponse(
        Long id,
        String name,
        String description,
        BigDecimal price,
        Long categoryId,
        String categoryName,
        Integer calories,
        String imageUrl,
        ProductStatus status
) {
    public static ProductResponse from(Product product) {
        return new ProductResponse(
                product.getId(),
                product.getName(),
                product.getDescription(),
                product.getPrice(),
                product.getCategory() != null ? product.getCategory().getId() : null,
                product.getCategory() != null ? product.getCategory().getName() : null,
                product.getCalories(),
                product.getImageUrl(),
                product.getStatus()
        );
    }
}
