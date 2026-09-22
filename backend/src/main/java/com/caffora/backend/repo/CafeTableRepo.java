package com.caffora.backend.repo;

import com.caffora.backend.model.CafeTable;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.Optional;

public interface CafeTableRepo extends JpaRepository<CafeTable, Long> {
    Optional<CafeTable> findByQrCodeValue(String qrCodeValue);
    boolean existsByTableNumber(String tableNumber);
}
