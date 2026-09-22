package com.caffora.backend.dto.table;

import com.caffora.backend.model.CafeTable;

public record TableLookupResponse(
        Long id,
        String tableNumber
) {
    public static TableLookupResponse from(CafeTable table) {
        return new TableLookupResponse(table.getId(), table.getTableNumber());
    }
}
