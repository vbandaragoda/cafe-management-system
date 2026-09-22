package com.caffora.backend.service;

import com.caffora.backend.config.PricingProperties;
import com.caffora.backend.dto.order.OrderLineRequest;
import com.caffora.backend.dto.order.OrderResponse;
import com.caffora.backend.dto.order.PlaceOrderRequest;
import com.caffora.backend.model.CafeTable;
import com.caffora.backend.model.Product;
import com.caffora.backend.model.ProductStatus;
import com.caffora.backend.model.Order;
import com.caffora.backend.model.OrderItem;
import com.caffora.backend.model.OrderStatus;
import com.caffora.backend.model.PickupType;
import com.caffora.backend.model.User;
import com.caffora.backend.exception.BadRequestException;
import com.caffora.backend.exception.ResourceNotFoundException;
import com.caffora.backend.repo.CafeTableRepo;
import com.caffora.backend.repo.ProductRepo;
import com.caffora.backend.repo.OrderRepo;
import com.caffora.backend.repo.UserRepo;
import com.caffora.backend.util.OrderNumberGenerator;
import lombok.RequiredArgsConstructor;
import org.springframework.security.access.AccessDeniedException;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.time.Duration;
import java.time.Instant;
import java.util.List;

@Service
@RequiredArgsConstructor
@Transactional(readOnly = true)
public class OrderService {

    private static final List<OrderStatus> ACTIVE_STATUSES =
            List.of(OrderStatus.PENDING, OrderStatus.PREPARING, OrderStatus.READY);

    private final OrderRepo orderRepository;
    private final ProductRepo productRepository;
    private final UserRepo userRepository;
    private final CafeTableRepo cafeTableRepository;
    private final OrderNumberGenerator orderNumberGenerator;
    private final PricingProperties pricingProperties;

    @Transactional
    public OrderResponse placeOrder(String userEmail, PlaceOrderRequest request) {
        User user = userRepository.findByEmailIgnoreCase(userEmail)
                .orElseThrow(() -> new IllegalStateException("Authenticated user vanished mid-request"));

        Order order = Order.builder()
                .orderNumber(uniqueOrderNumber())
                .user(user)
                .status(OrderStatus.PENDING)
                .pickupType(request.pickupType() != null ? request.pickupType() : PickupType.COUNTER)
                .build();

        if (request.tableId() != null) {
            CafeTable table = cafeTableRepository.findById(request.tableId())
                    .orElseThrow(() -> ResourceNotFoundException.of("CafeTable", request.tableId()));
            order.setTable(table);
        }

        BigDecimal subtotal = BigDecimal.ZERO;
        for (OrderLineRequest line : request.items()) {
            Product product = productRepository.findById(line.productId())
                    .orElseThrow(() -> ResourceNotFoundException.of("Product", line.productId()));

            if (product.getStatus() == ProductStatus.SOLD_OUT) {
                throw new BadRequestException("'" + product.getName() + "' is currently sold out");
            }

            OrderItem orderItem = OrderItem.builder()
                    .product(product)
                    .itemName(product.getName())
                    .unitPrice(product.getPrice())
                    .quantity(line.quantity())
                    .note(line.note())
                    .build();
            order.addItem(orderItem);

            subtotal = subtotal.add(product.getPrice().multiply(BigDecimal.valueOf(line.quantity())));
        }

        BigDecimal pickupFee = pricingProperties.pickupFee();
        BigDecimal tax = subtotal.multiply(pricingProperties.taxRate()).setScale(2, RoundingMode.HALF_UP);
        BigDecimal total = subtotal.add(pickupFee).add(tax);

        order.setSubtotal(subtotal.setScale(2, RoundingMode.HALF_UP));
        order.setPickupFee(pickupFee.setScale(2, RoundingMode.HALF_UP));
        order.setTax(tax);
        order.setTotal(total.setScale(2, RoundingMode.HALF_UP));

        return OrderResponse.from(orderRepository.save(order));
    }

    public List<OrderResponse> myOrders(String userEmail) {
        User user = userRepository.findByEmailIgnoreCase(userEmail)
                .orElseThrow(() -> new IllegalStateException("Authenticated user vanished mid-request"));
        return orderRepository.findByUserOrderByPlacedAtDesc(user).stream()
                .map(OrderResponse::from)
                .toList();
    }

    public OrderResponse getForUser(Long orderId, String userEmail, boolean isAdmin) {
        Order order = findOrThrow(orderId);
        if (!isAdmin && !order.getUser().getEmail().equalsIgnoreCase(userEmail)) {
            throw new AccessDeniedException("You do not have access to this order");
        }
        return OrderResponse.from(order);
    }

    /** Admin: full order queue, optionally filtered to just the active (kitchen-relevant) statuses. */
    public List<OrderResponse> queue(boolean activeOnly) {
        List<Order> orders = activeOnly
                ? orderRepository.findByStatusInOrderByPlacedAtAsc(ACTIVE_STATUSES)
                : orderRepository.findAllByOrderByPlacedAtDesc();
        return orders.stream().map(OrderResponse::from).toList();
    }

    @Transactional
    public OrderResponse updateStatus(Long orderId, OrderStatus newStatus) {
        Order order = findOrThrow(orderId);
        order.setStatus(newStatus);
        Instant now = Instant.now();
        if (newStatus == OrderStatus.READY && order.getReadyAt() == null) {
            order.setReadyAt(now);
        }
        if (newStatus == OrderStatus.COMPLETED && order.getCompletedAt() == null) {
            order.setCompletedAt(now);
        }
        return OrderResponse.from(order);
    }

    public double averagePrepMinutes() {
        List<Order> completed = orderRepository.findAll().stream()
                .filter(o -> o.getReadyAt() != null)
                .toList();
        if (completed.isEmpty()) {
            return 0.0;
        }
        long totalSeconds = completed.stream()
                .mapToLong(o -> Duration.between(o.getPlacedAt(), o.getReadyAt()).getSeconds())
                .sum();
        return Math.round((totalSeconds / 60.0 / completed.size()) * 10) / 10.0;
    }

    Order findOrThrow(Long orderId) {
        return orderRepository.findById(orderId)
                .orElseThrow(() -> ResourceNotFoundException.of("Order", orderId));
    }

    private String uniqueOrderNumber() {
        String candidate;
        int attempts = 0;
        do {
            candidate = orderNumberGenerator.next();
            attempts++;
        } while (orderRepository.findByOrderNumber(candidate).isPresent() && attempts < 20);
        return candidate;
    }
}
