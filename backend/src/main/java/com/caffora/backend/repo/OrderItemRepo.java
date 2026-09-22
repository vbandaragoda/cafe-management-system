package com.caffora.backend.repo;

import com.caffora.backend.model.OrderItem;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.util.List;

public interface OrderItemRepo extends JpaRepository<OrderItem, Long> {

    /**
     * Reporting aggregate: units sold and revenue per product, across all non-cancelled
     * order items, most units first. Backs GET /api/admin/reports/top-products.
     * Native query (MySQL syntax; H2 test datasource runs in MySQL compatibility mode)
     * so it can do the GROUP BY/ORDER BY/LIMIT entirely in the database rather than
     * pulling every order item into Java and summing in a loop.
     */
    @Query(value = """
            select p.id as productId,
                   p.name as productName,
                   sum(oi.quantity) as unitsSold,
                   sum(oi.quantity * oi.unit_price) as revenue
            from order_items oi
            join products p on p.id = oi.product_id
            join orders o on o.id = oi.order_id
            where o.status <> 'CANCELLED'
            group by p.id, p.name
            order by unitsSold desc
            limit :limit
            """, nativeQuery = true)
    List<TopProductProjection> topProducts(@Param("limit") int limit);
}
