package com.caffora.backend.model;

import jakarta.persistence.*;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;
import org.hibernate.annotations.CreationTimestamp;

import java.time.Instant;

/**
 * A physical table in the cafe, identified by a printed QR code so a dine-in customer can
 * scan it and have the order attached to that table. Named CafeTable (not "Table") to avoid
 * colliding with jakarta.persistence.Table.
 */
@Entity
@Table(name = "cafe_tables", indexes = {
        @Index(name = "idx_cafe_tables_table_number", columnList = "table_number", unique = true),
        @Index(name = "idx_cafe_tables_qr_code_value", columnList = "qr_code_value", unique = true)
})
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class CafeTable {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "table_number", nullable = false, unique = true, length = 20)
    private String tableNumber;

    @Column(name = "qr_code_value", nullable = false, unique = true, length = 255)
    private String qrCodeValue;

    @CreationTimestamp
    @Column(name = "created_at", nullable = false, updatable = false)
    private Instant createdAt;
}
