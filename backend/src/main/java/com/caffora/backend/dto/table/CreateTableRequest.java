package com.caffora.backend.dto.table;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;

public record CreateTableRequest(
        @NotBlank(message = "tableNumber is required")
        @Size(max = 20)
        String tableNumber
) {
}
