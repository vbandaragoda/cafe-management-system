package com.caffora.backend.controller;

import com.caffora.backend.dto.common.MessageResponse;
import com.caffora.backend.dto.product.ProductRequest;
import com.caffora.backend.dto.product.ProductResponse;
import com.caffora.backend.dto.product.ProductStatusUpdateRequest;
import com.caffora.backend.service.ProductService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

/** Renamed from the original MenuController (MenuItem -> Product, /api/menu -> /api/products). */
@RestController
@RequestMapping("/api/products")
@RequiredArgsConstructor
public class ProductController {

    private final ProductService productService;

    /** Public: powers the customer-facing menu page (search + category filter). */
    @GetMapping
    public ResponseEntity<List<ProductResponse>> list(
            @RequestParam(required = false) Long categoryId,
            @RequestParam(required = false) String search
    ) {
        return ResponseEntity.ok(productService.list(categoryId, search));
    }

    @GetMapping("/{id}")
    public ResponseEntity<ProductResponse> get(@PathVariable Long id) {
        return ResponseEntity.ok(productService.get(id));
    }

    @PostMapping
    public ResponseEntity<ProductResponse> create(@Valid @RequestBody ProductRequest request) {
        return ResponseEntity.status(HttpStatus.CREATED).body(productService.create(request));
    }

    @PutMapping("/{id}")
    public ResponseEntity<ProductResponse> update(@PathVariable Long id, @Valid @RequestBody ProductRequest request) {
        return ResponseEntity.ok(productService.update(id, request));
    }

    @PatchMapping("/{id}/status")
    public ResponseEntity<ProductResponse> updateStatus(@PathVariable Long id,
                                                          @Valid @RequestBody ProductStatusUpdateRequest request) {
        return ResponseEntity.ok(productService.updateStatus(id, request));
    }

    @PatchMapping("/{id}/toggle-availability")
    public ResponseEntity<ProductResponse> toggleAvailability(@PathVariable Long id) {
        return ResponseEntity.ok(productService.toggleAvailability(id));
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<MessageResponse> delete(@PathVariable Long id) {
        productService.delete(id);
        return ResponseEntity.ok(new MessageResponse("Product deleted"));
    }
}
