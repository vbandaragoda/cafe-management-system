package com.caffora.backend.service;

import com.caffora.backend.dto.category.CategoryRequest;
import com.caffora.backend.dto.category.CategoryResponse;
import com.caffora.backend.exception.ResourceNotFoundException;
import com.caffora.backend.model.Category;
import com.caffora.backend.repo.CategoryRepo;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;

@Service
@RequiredArgsConstructor
@Transactional(readOnly = true)
public class CategoryService {

    private final CategoryRepo categoryRepository;

    public List<CategoryResponse> list() {
        return categoryRepository.findAll().stream().map(CategoryResponse::from).toList();
    }

    @Transactional
    public CategoryResponse create(CategoryRequest request) {
        Category category = Category.builder()
                .name(request.name())
                .description(request.description())
                .build();
        return CategoryResponse.from(categoryRepository.save(category));
    }

    @Transactional
    public CategoryResponse update(Long id, CategoryRequest request) {
        Category category = findOrThrow(id);
        category.setName(request.name());
        category.setDescription(request.description());
        return CategoryResponse.from(category);
    }

    @Transactional
    public void delete(Long id) {
        if (!categoryRepository.existsById(id)) {
            throw ResourceNotFoundException.of("Category", id);
        }
        // If any products still reference this category, the FK constraint rejects the
        // delete and DataIntegrityViolationException bubbles up to GlobalExceptionHandler,
        // which turns it into a 409 Conflict — the same delete-blocked-by-references
        // pattern used for products/orders elsewhere in this codebase.
        categoryRepository.deleteById(id);
    }

    private Category findOrThrow(Long id) {
        return categoryRepository.findById(id)
                .orElseThrow(() -> ResourceNotFoundException.of("Category", id));
    }
}
