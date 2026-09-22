package com.caffora.backend.config;

import org.springframework.boot.context.properties.ConfigurationProperties;

import java.math.BigDecimal;

@ConfigurationProperties(prefix = "caffora.pricing")
public record PricingProperties(BigDecimal taxRate, BigDecimal pickupFee) {
}
