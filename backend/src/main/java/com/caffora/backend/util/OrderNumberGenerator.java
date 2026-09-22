package com.caffora.backend.util;

import org.springframework.stereotype.Component;

import java.security.SecureRandom;

/**
 * Generates short, kitchen-ticket-style order codes like "C408" — matching the
 * format used throughout the frontend (cart, order tracker, admin queue).
 */
@Component
public class OrderNumberGenerator {

    private static final SecureRandom RANDOM = new SecureRandom();

    public String next() {
        int number = 100 + RANDOM.nextInt(900); // 3-digit suffix, e.g. 408
        return "C" + number;
    }
}
