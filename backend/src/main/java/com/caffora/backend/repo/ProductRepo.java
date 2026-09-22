package com.caffora.backend.repo;

import com.caffora.backend.model.Product;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.util.List;

public interface ProductRepo extends JpaRepository<Product, Long> {

    List<Product> findByCategoryId(Long categoryId);

    @Query("""
            select p from Product p
            where (:categoryId is null or p.category.id = :categoryId)
              and (:search is null or lower(p.name) like lower(concat('%', :search, '%')))
            order by p.id asc
            """)
    List<Product> search(@Param("categoryId") Long categoryId, @Param("search") String search);
}
