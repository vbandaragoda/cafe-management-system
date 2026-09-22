package com.caffora.backend.controller;

import com.caffora.backend.dto.table.CafeTableResponse;
import com.caffora.backend.dto.table.CreateTableRequest;
import com.caffora.backend.dto.table.TableLookupResponse;
import com.caffora.backend.service.TableService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/tables")
@RequiredArgsConstructor
public class TableController {

    private final TableService tableService;

    /** Admin: list every table with its QR code value, so it can be printed/displayed. */
    @GetMapping
    public ResponseEntity<List<CafeTableResponse>> list() {
        return ResponseEntity.ok(tableService.list());
    }

    /** Admin: register a new table; the QR code value is generated server-side. */
    @PostMapping
    public ResponseEntity<CafeTableResponse> create(@Valid @RequestBody CreateTableRequest request) {
        return ResponseEntity.status(HttpStatus.CREATED).body(tableService.create(request));
    }

    /**
     * Public: a customer who just scanned a QR code isn't necessarily authenticated yet,
     * so this resolves the scanned code independently of login.
     */
    @GetMapping("/lookup")
    public ResponseEntity<TableLookupResponse> lookup(@RequestParam String code) {
        return ResponseEntity.ok(tableService.lookup(code));
    }
}
