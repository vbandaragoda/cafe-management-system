package com.caffora.backend.service;

import com.caffora.backend.dto.product.ProductRequest;
import com.caffora.backend.dto.product.ProductResponse;
import com.caffora.backend.dto.product.ProductStatusUpdateRequest;
import com.caffora.backend.exception.BadRequestException;
import com.caffora.backend.model.Category;
import com.caffora.backend.model.Product;
import com.caffora.backend.model.ProductStatus;
import com.caffora.backend.exception.ResourceNotFoundException;
import com.caffora.backend.repo.CategoryRepo;
import com.caffora.backend.repo.ProductRepo;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;

/** Renamed from the original MenuService (MenuItem -> Product). */
@Service
@RequiredArgsConstructor
@Transactional(readOnly = true)
public class ProductService {

    private final ProductRepo productRepository;
    private final CategoryRepo categoryRepository;

    public List<ProductResponse> list(Long categoryId, String search) {
        return productRepository.search(categoryId, blankToNull(search)).stream()
                .map(ProductResponse::from)
                .toList();
    }

    public ProductResponse get(Long id) {
        return ProductResponse.from(findOrThrow(id));
    }

    @Transactional
    public ProductResponse create(ProductRequest request) {
        Category category = resolveCategory(request.categoryId());
        Product product = Product.builder()
                .name(request.name())
                .description(request.description())
                .price(request.price())
                .category(category)
                .calories(request.calories() != null ? request.calories() : 0)
                .imageUrl(request.imageUrl())
                .status(request.status() != null ? request.status() : ProductStatus.AVAILABLE)
                .build();
        return ProductResponse.from(productRepository.save(product));
    }

    @Transactional
    public ProductResponse update(Long id, ProductRequest request) {
        Product product = findOrThrow(id);
        product.setName(request.name());
        product.setDescription(request.description());
        product.setPrice(request.price());
        product.setCategory(resolveCategory(request.categoryId()));
        if (request.calories() != null) {
            product.setCalories(request.calories());
        }
        product.setImageUrl(request.imageUrl());
        if (request.status() != null) {
            product.setStatus(request.status());
        }
        return ProductResponse.from(product);
    }

    @Transactional
    public ProductResponse updateStatus(Long id, ProductStatusUpdateRequest request) {
        Product product = findOrThrow(id);
        product.setStatus(request.status());
        return ProductResponse.from(product);
    }

    @Transactional
    public ProductResponse toggleAvailability(Long id) {
        Product product = findOrThrow(id);
        product.setStatus(product.getStatus() == ProductStatus.AVAILABLE ? ProductStatus.SOLD_OUT : ProductStatus.AVAILABLE);
        return ProductResponse.from(product);
    }

    @Transactional
    public void delete(Long id) {
        if (!productRepository.existsById(id)) {
            throw ResourceNotFoundException.of("Product", id);
        }
        // If any order_items still reference this product, the FK constraint rejects the
        // delete and DataIntegrityViolationException bubbles up to GlobalExceptionHandler,
        // which turns it into a 409 Conflict — same pattern used everywhere else in this
        // codebase for delete-blocked-by-references, no extra existence checks needed here.
        productRepository.deleteById(id);
    }

    Product findOrThrow(Long id) {
        return productRepository.findById(id)
                .orElseThrow(() -> ResourceNotFoundException.of("Product", id));
    }

    private Category resolveCategory(Long categoryId) {
        return categoryRepository.findById(categoryId)
                .orElseThrow(() -> new BadRequestException("No category found with id: " + categoryId));
    }

    private String blankToNull(String s) {
        return (s == null || s.isBlank()) ? null : s.trim();
    }
}
