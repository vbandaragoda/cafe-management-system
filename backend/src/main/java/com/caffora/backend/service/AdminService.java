package com.caffora.backend.service;

import com.caffora.backend.dto.admin.AdminUserResponse;
import com.caffora.backend.dto.admin.DashboardResponse;
import com.caffora.backend.dto.admin.SalesReportItem;
import com.caffora.backend.dto.admin.TopProductItem;
import com.caffora.backend.exception.BadRequestException;
import com.caffora.backend.model.Order;
import com.caffora.backend.model.OrderStatus;
import com.caffora.backend.repo.OrderItemRepo;
import com.caffora.backend.repo.OrderRepo;
import com.caffora.backend.repo.UserRepo;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.time.Instant;
import java.time.LocalDate;
import java.time.ZoneOffset;
import java.util.List;

@Service
@RequiredArgsConstructor
@Transactional(readOnly = true)
public class AdminService {

    private final OrderRepo orderRepository;
    private final OrderItemRepo orderItemRepository;
    private final UserRepo userRepository;
    private final OrderService orderService;

    public DashboardResponse dashboard() {
        Instant startOfToday = LocalDate.now(ZoneOffset.UTC).atStartOfDay().toInstant(ZoneOffset.UTC);
        List<Order> todaysOrders = orderRepository.findByPlacedAtAfter(startOfToday);

        BigDecimal grossSales = todaysOrders.stream()
                .filter(o -> o.getStatus() != OrderStatus.CANCELLED)
                .map(Order::getTotal)
                .reduce(BigDecimal.ZERO, BigDecimal::add);

        // Active-order counts intentionally ignore the "today" cutoff: a ticket from
        // last night that's still "Preparing" should still show up on the live queue.
        List<Order> allOrders = orderRepository.findAll();
        long pending = countByStatus(allOrders, OrderStatus.PENDING);
        long preparing = countByStatus(allOrders, OrderStatus.PREPARING);
        long ready = countByStatus(allOrders, OrderStatus.READY);

        return new DashboardResponse(
                grossSales,
                pending + preparing + ready,
                pending,
                preparing,
                ready,
                orderService.averagePrepMinutes()
        );
    }

    /**
     * Multi-table calculation #1: order count and gross sales grouped by day or by month,
     * computed entirely in the database via GROUP BY (see OrderRepo.salesReportDaily /
     * salesReportMonthly), not by pulling every order into Java and summing in a loop.
     */
    public List<SalesReportItem> salesReport(String range) {
        String normalized = range == null ? "daily" : range.trim().toLowerCase();
        return switch (normalized) {
            case "daily" -> orderRepository.salesReportDaily().stream().map(SalesReportItem::from).toList();
            case "monthly" -> orderRepository.salesReportMonthly().stream().map(SalesReportItem::from).toList();
            default -> throw new BadRequestException("range must be 'daily' or 'monthly'");
        };
    }

    /**
     * Multi-table calculation #2: units sold and revenue per product, joining order_items
     * and products and grouping by product (see OrderItemRepo.topProducts).
     */
    public List<TopProductItem> topProducts(int limit) {
        int safeLimit = limit < 1 ? 5 : limit;
        return orderItemRepository.topProducts(safeLimit).stream().map(TopProductItem::from).toList();
    }

    public List<AdminUserResponse> users() {
        return userRepository.findAll().stream().map(AdminUserResponse::from).toList();
    }

    private long countByStatus(List<Order> orders, OrderStatus status) {
        return orders.stream().filter(o -> o.getStatus() == status).count();
    }
}
