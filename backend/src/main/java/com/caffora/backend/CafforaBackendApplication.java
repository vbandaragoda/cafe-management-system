package com.caffora.backend;

import com.caffora.backend.config.AdminSeedProperties;
import com.caffora.backend.config.CorsProperties;
import com.caffora.backend.config.PricingProperties;
import com.caffora.backend.security.JwtProperties;
import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.boot.context.properties.ConfigurationPropertiesScan;

@SpringBootApplication
@ConfigurationPropertiesScan(basePackageClasses = {
        JwtProperties.class,
        CorsProperties.class,
        PricingProperties.class,
        AdminSeedProperties.class
})
public class CafforaBackendApplication {

    public static void main(String[] args) {
        SpringApplication.run(CafforaBackendApplication.class, args);
    }
}
