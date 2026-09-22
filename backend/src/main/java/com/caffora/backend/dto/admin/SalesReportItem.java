package com.caffora.backend.dto.admin;

import com.caffora.backend.repo.SalesReportProjection;

import java.math.BigDecimal;

public record SalesReportItem(
        String period,
        long orderCount,
        BigDecimal grossSales
) {
    public static SalesReportItem from(SalesReportProjection projection) {
        return new SalesReportItem(
                projection.getPeriod(),
                projection.getOrderCount(),
                projection.getGrossSales()
        );
    }
}
