package com.caffora.backend.repo;

import java.math.BigDecimal;

/**
 * Interface-based projection for the native daily/monthly sales aggregate queries in
 * {@link OrderRepo}. Property names must match the native query's column aliases.
 */
public interface SalesReportProjection {
    String getPeriod();
    Long getOrderCount();
    BigDecimal getGrossSales();
}
