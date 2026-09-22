package com.caffora.backend.service;

import com.caffora.backend.dto.payment.PaymentRequest;
import com.caffora.backend.dto.payment.PaymentResponse;
import com.caffora.backend.exception.ConflictException;
import com.caffora.backend.exception.ResourceNotFoundException;
import com.caffora.backend.model.Order;
import com.caffora.backend.model.Payment;
import com.caffora.backend.model.PaymentStatus;
import com.caffora.backend.repo.OrderRepo;
import com.caffora.backend.repo.PaymentRepo;
import lombok.RequiredArgsConstructor;
import org.springframework.security.access.AccessDeniedException;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.Instant;

@Service
@RequiredArgsConstructor
@Transactional(readOnly = true)
public class PaymentService {

    private final PaymentRepo paymentRepository;
    private final OrderRepo orderRepository;

    /**
     * There is no real payment gateway integration here. This is a SIMULATED payment
     * step for the assignment: it records a Payment row against the order and marks it
     * PAID immediately. In a real system this would instead call out to a payment
     * processor (Stripe, etc.) and only mark PAID once that processor confirms success.
     */
    @Transactional
    public PaymentResponse pay(String callerEmail, boolean isAdmin, PaymentRequest request) {
        Order order = orderRepository.findById(request.orderId())
                .orElseThrow(() -> ResourceNotFoundException.of("Order", request.orderId()));
        requireOwnerOrAdmin(order, callerEmail, isAdmin);

        Payment payment = paymentRepository.findByOrderId(order.getId()).orElse(null);
        if (payment != null && payment.getStatus() == PaymentStatus.PAID) {
            throw new ConflictException("This order has already been paid for");
        }

        if (payment == null) {
            payment = Payment.builder()
                    .order(order)
                    .build();
        }
        payment.setAmount(order.getTotal());
        payment.setMethod(request.method());
        payment.setStatus(PaymentStatus.PAID);
        payment.setPaidAt(Instant.now());

        return PaymentResponse.from(paymentRepository.save(payment));
    }

    public PaymentResponse getById(Long id, String callerEmail, boolean isAdmin) {
        Payment payment = paymentRepository.findById(id)
                .orElseThrow(() -> ResourceNotFoundException.of("Payment", id));
        requireOwnerOrAdmin(payment.getOrder(), callerEmail, isAdmin);
        return PaymentResponse.from(payment);
    }

    public PaymentResponse getByOrderId(Long orderId, String callerEmail, boolean isAdmin) {
        Payment payment = paymentRepository.findByOrderId(orderId)
                .orElseThrow(() -> new ResourceNotFoundException("No payment found for order id: " + orderId));
        requireOwnerOrAdmin(payment.getOrder(), callerEmail, isAdmin);
        return PaymentResponse.from(payment);
    }

    private void requireOwnerOrAdmin(Order order, String callerEmail, boolean isAdmin) {
        if (!isAdmin && !order.getUser().getEmail().equalsIgnoreCase(callerEmail)) {
            throw new AccessDeniedException("You do not have access to this payment");
        }
    }
}
