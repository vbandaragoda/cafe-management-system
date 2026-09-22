package com.caffora.backend.config;

import org.springframework.boot.context.properties.ConfigurationProperties;

import java.util.List;

@ConfigurationProperties(prefix = "caffora.cors")
public record CorsProperties(List<String> allowedOrigins) {
}
