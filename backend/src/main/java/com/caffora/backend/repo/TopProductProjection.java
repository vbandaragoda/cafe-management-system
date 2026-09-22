package com.caffora.backend.repo;

import java.math.BigDecimal;

/**
 * Interface-based projection for the native top-products aggregate query in
 * {@link OrderItemRepo}. Property names must match the native query's column aliases.
 */
public interface TopProductProjection {
    Long getProductId();
    String getProductName();
    Long getUnitsSold();
    BigDecimal getRevenue();
}
