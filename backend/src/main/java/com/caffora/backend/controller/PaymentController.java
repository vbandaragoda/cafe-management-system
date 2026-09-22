package com.caffora.backend.controller;

import com.caffora.backend.dto.payment.PaymentRequest;
import com.caffora.backend.dto.payment.PaymentResponse;
import com.caffora.backend.security.UserPrincipal;
import com.caffora.backend.service.PaymentService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/payments")
@RequiredArgsConstructor
public class PaymentController {

    private final PaymentService paymentService;

    /** Any authenticated user: pay for one of their own orders (simulated, no real gateway). */
    @PostMapping
    public ResponseEntity<PaymentResponse> pay(@AuthenticationPrincipal UserPrincipal principal,
                                                @Valid @RequestBody PaymentRequest request) {
        PaymentResponse response = paymentService.pay(principal.getUsername(), isAdmin(principal), request);
        return ResponseEntity.status(HttpStatus.CREATED).body(response);
    }

    /** Owner of the related order, or Admin. */
    @GetMapping("/{id}")
    public ResponseEntity<PaymentResponse> getById(@AuthenticationPrincipal UserPrincipal principal,
                                                     @PathVariable Long id) {
        return ResponseEntity.ok(paymentService.getById(id, principal.getUsername(), isAdmin(principal)));
    }

    /** Owner of the related order, or Admin. */
    @GetMapping("/order/{orderId}")
    public ResponseEntity<PaymentResponse> getByOrderId(@AuthenticationPrincipal UserPrincipal principal,
                                                          @PathVariable Long orderId) {
        return ResponseEntity.ok(paymentService.getByOrderId(orderId, principal.getUsername(), isAdmin(principal)));
    }

    private boolean isAdmin(UserPrincipal principal) {
        return principal.getAuthorities().stream()
                .anyMatch(a -> a.getAuthority().equals("ROLE_ADMIN"));
    }
}
