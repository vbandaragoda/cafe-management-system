package com.caffora.backend.security;

import org.springframework.boot.context.properties.ConfigurationProperties;

@ConfigurationProperties(prefix = "caffora.jwt")
public record JwtProperties(String secret, long expirationMs, String issuer) {
}
