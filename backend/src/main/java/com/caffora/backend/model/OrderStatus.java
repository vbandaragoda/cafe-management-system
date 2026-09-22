package com.caffora.backend.model;

/**
 * Ordered so ordinal comparisons ("has this ticket progressed past X?") are meaningful,
 * mirroring the stepper on the frontend's order-tracking screen.
 */
public enum OrderStatus {
    PENDING,
    PREPARING,
    READY,
    COMPLETED,
    CANCELLED
}
