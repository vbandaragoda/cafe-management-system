package com.caffora.backend.dto.admin;

import java.math.BigDecimal;

public record DashboardResponse(
        BigDecimal todaysGrossSales,
        long activeOrderCount,
        long pendingCount,
        long preparingCount,
        long readyCount,
        double avgPrepMinutes
) {
}
