package com.caffora.backend.repo;

import com.caffora.backend.model.Order;
import com.caffora.backend.model.OrderStatus;
import com.caffora.backend.model.User;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;

import java.time.Instant;
import java.util.List;
import java.util.Optional;

public interface OrderRepo extends JpaRepository<Order, Long> {

    List<Order> findByUserOrderByPlacedAtDesc(User user);

    Optional<Order> findByOrderNumber(String orderNumber);

    List<Order> findByStatusInOrderByPlacedAtAsc(List<OrderStatus> statuses);

    List<Order> findAllByOrderByPlacedAtDesc();

    long countByStatusIn(List<OrderStatus> statuses);

    List<Order> findByPlacedAtAfter(Instant after);

    long countByPlacedAtAfter(Instant after);

    /**
     * Reporting aggregate: order count and gross sales grouped by calendar day. Backs
     * GET /api/admin/reports/sales?range=daily. A real GROUP BY in the database, not a
     * loop-and-sum over every order pulled into Java. Native query (MySQL syntax; the
     * H2 test datasource runs in MySQL compatibility mode).
     */
    @Query(value = """
            select date_format(placed_at, '%Y-%m-%d') as period,
                   count(*) as orderCount,
                   sum(total) as grossSales
            from orders
            where status <> 'CANCELLED'
            group by date_format(placed_at, '%Y-%m-%d')
            order by period desc
            """, nativeQuery = true)
    List<SalesReportProjection> salesReportDaily();

    /**
     * Same aggregate as {@link #salesReportDaily()} but grouped by calendar month. Backs
     * GET /api/admin/reports/sales?range=monthly.
     */
    @Query(value = """
            select date_format(placed_at, '%Y-%m') as period,
                   count(*) as orderCount,
                   sum(total) as grossSales
            from orders
            where status <> 'CANCELLED'
            group by date_format(placed_at, '%Y-%m')
            order by period desc
            """, nativeQuery = true)
    List<SalesReportProjection> salesReportMonthly();
}
