package com.caffora.backend.dto.admin;

import com.caffora.backend.repo.TopProductProjection;

import java.math.BigDecimal;

public record TopProductItem(
        Long productId,
        String productName,
        long unitsSold,
        BigDecimal revenue
) {
    public static TopProductItem from(TopProductProjection projection) {
        return new TopProductItem(
                projection.getProductId(),
                projection.getProductName(),
                projection.getUnitsSold(),
                projection.getRevenue()
        );
    }
}
