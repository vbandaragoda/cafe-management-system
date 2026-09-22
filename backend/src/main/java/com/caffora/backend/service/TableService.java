package com.caffora.backend.service;

import com.caffora.backend.dto.table.CafeTableResponse;
import com.caffora.backend.dto.table.CreateTableRequest;
import com.caffora.backend.dto.table.TableLookupResponse;
import com.caffora.backend.exception.BadRequestException;
import com.caffora.backend.exception.ResourceNotFoundException;
import com.caffora.backend.model.CafeTable;
import com.caffora.backend.repo.CafeTableRepo;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;

@Service
@RequiredArgsConstructor
@Transactional(readOnly = true)
public class TableService {

    private static final String QR_PREFIX = "cafe://table/";

    private final CafeTableRepo cafeTableRepository;

    public List<CafeTableResponse> list() {
        return cafeTableRepository.findAll().stream().map(CafeTableResponse::from).toList();
    }

    @Transactional
    public CafeTableResponse create(CreateTableRequest request) {
        String tableNumber = request.tableNumber().trim();
        if (cafeTableRepository.existsByTableNumber(tableNumber)) {
            throw new BadRequestException("A table numbered '" + tableNumber + "' already exists");
        }
        CafeTable table = CafeTable.builder()
                .tableNumber(tableNumber)
                .qrCodeValue(QR_PREFIX + tableNumber)
                .build();
        return CafeTableResponse.from(cafeTableRepository.save(table));
    }

    /** Public: resolves a scanned QR value to the table it belongs to. */
    public TableLookupResponse lookup(String code) {
        CafeTable table = cafeTableRepository.findByQrCodeValue(code)
                .orElseThrow(() -> new ResourceNotFoundException("No table found for scanned code"));
        return TableLookupResponse.from(table);
    }
}
