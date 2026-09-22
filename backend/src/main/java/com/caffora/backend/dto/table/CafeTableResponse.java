package com.caffora.backend.dto.table;

import com.caffora.backend.model.CafeTable;

import java.time.Instant;

public record CafeTableResponse(
        Long id,
        String tableNumber,
        String qrCodeValue,
        Instant createdAt
) {
    public static CafeTableResponse from(CafeTable table) {
        return new CafeTableResponse(table.getId(), table.getTableNumber(), table.getQrCodeValue(), table.getCreatedAt());
    }
}
