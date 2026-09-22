package com.caffora.backend.controller;

import com.caffora.backend.dto.order.OrderResponse;
import com.caffora.backend.dto.order.OrderStatusUpdateRequest;
import com.caffora.backend.dto.order.PlaceOrderRequest;
import com.caffora.backend.security.UserPrincipal;
import com.caffora.backend.service.OrderService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/orders")
@RequiredArgsConstructor
public class OrderController {

    private final OrderService orderService;

    /** Customer (or Admin, ordering for themselves): place a new order from the current cart. */
    @PostMapping
    public ResponseEntity<OrderResponse> placeOrder(@AuthenticationPrincipal UserPrincipal principal,
                                                      @Valid @RequestBody PlaceOrderRequest request) {
        OrderResponse response = orderService.placeOrder(principal.getUsername(), request);
        return ResponseEntity.status(HttpStatus.CREATED).body(response);
    }

    /** Customer: their own order history, most recent first. */
    @GetMapping("/my")
    public ResponseEntity<List<OrderResponse>> myOrders(@AuthenticationPrincipal UserPrincipal principal) {
        return ResponseEntity.ok(orderService.myOrders(principal.getUsername()));
    }

    /** Customer (own order) or Admin: single order detail, used by the live tracker. */
    @GetMapping("/{id}")
    public ResponseEntity<OrderResponse> getOne(@AuthenticationPrincipal UserPrincipal principal,
                                                 @PathVariable Long id) {
        boolean isAdmin = principal.getAuthorities().stream()
                .anyMatch(a -> a.getAuthority().equals("ROLE_ADMIN"));
        return ResponseEntity.ok(orderService.getForUser(id, principal.getUsername(), isAdmin));
    }

    /** Admin: full order list — the "Manage Orders" screen. */
    @GetMapping
    public ResponseEntity<List<OrderResponse>> all(
            @RequestParam(name = "active", required = false, defaultValue = "false") boolean activeOnly) {
        return ResponseEntity.ok(orderService.queue(activeOnly));
    }

    /**
     * Admin: cycles a kitchen ticket through Pending -> Preparing -> Ready -> Completed.
     * Mapped to both PATCH (this codebase's original convention) and PUT (the assignment
     * spec's literal verb) so either satisfies the same handler.
     */
    @RequestMapping(value = "/{id}/status", method = {RequestMethod.PATCH, RequestMethod.PUT})
    public ResponseEntity<OrderResponse> updateStatus(@PathVariable Long id,
                                                        @Valid @RequestBody OrderStatusUpdateRequest request) {
        return ResponseEntity.ok(orderService.updateStatus(id, request.status()));
    }
}
