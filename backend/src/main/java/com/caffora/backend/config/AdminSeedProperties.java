package com.caffora.backend.config;

import org.springframework.boot.context.properties.ConfigurationProperties;

@ConfigurationProperties(prefix = "caffora.admin")
public record AdminSeedProperties(String seedEmail, String seedPassword, String seedName) {
}
