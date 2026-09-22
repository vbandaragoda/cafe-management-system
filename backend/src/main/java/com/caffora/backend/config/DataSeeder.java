package com.caffora.backend.config;

import com.caffora.backend.model.CafeTable;
import com.caffora.backend.model.Category;
import com.caffora.backend.model.Product;
import com.caffora.backend.model.ProductStatus;
import com.caffora.backend.model.Role;
import com.caffora.backend.model.User;
import com.caffora.backend.repo.CafeTableRepo;
import com.caffora.backend.repo.CategoryRepo;
import com.caffora.backend.repo.ProductRepo;
import com.caffora.backend.repo.UserRepo;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.boot.CommandLineRunner;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Component;

import java.math.BigDecimal;
import java.util.LinkedHashMap;
import java.util.Map;

/**
 * Bootstraps the one thing the system cannot function without: an admin account to
 * sign in with on a fresh database. Also seeds starter categories, a starter menu, and
 * a handful of dine-in tables so the frontend has something to render out of the box —
 * this mirrors the original Figma design's menu data and can be edited/removed freely
 * from the admin console afterward. Deliberately does NOT seed fake orders or payments,
 * since those should only ever represent real customer activity.
 */
@Component
@RequiredArgsConstructor
@Slf4j
public class DataSeeder implements CommandLineRunner {

    private final UserRepo userRepository;
    private final CategoryRepo categoryRepository;
    private final ProductRepo productRepository;
    private final CafeTableRepo cafeTableRepository;
    private final PasswordEncoder passwordEncoder;
    private final AdminSeedProperties adminSeedProperties;

    @Override
    public void run(String... args) {
        seedAdmin();
        Map<String, Category> categories = seedCategories();
        seedProducts(categories);
        seedTables();
    }

    private void seedAdmin() {
        if (userRepository.existsByEmailIgnoreCase(adminSeedProperties.seedEmail())) {
            return;
        }
        User admin = User.builder()
                .name(adminSeedProperties.seedName())
                .email(adminSeedProperties.seedEmail())
                .passwordHash(passwordEncoder.encode(adminSeedProperties.seedPassword()))
                .role(Role.ADMIN)
                .loyaltyStatus("System Administrator")
                .enabled(true)
                .build();
        userRepository.save(admin);
        log.info("Seeded admin account: {} (change the password after first login!)", admin.getEmail());
    }

    private Map<String, Category> seedCategories() {
        Map<String, String> descriptions = new LinkedHashMap<>();
        descriptions.put("Beverages", "Coffee, tea, and other drinks");
        descriptions.put("Snacks", "Light bites and pastries");
        descriptions.put("Meals", "Sandwiches, toasts, and other mains");
        descriptions.put("Desserts", "Sweets, tarts, and cookies");

        Map<String, Category> categories = new LinkedHashMap<>();
        for (Map.Entry<String, String> entry : descriptions.entrySet()) {
            Category category = categoryRepository.findByNameIgnoreCase(entry.getKey())
                    .orElseGet(() -> categoryRepository.save(
                            Category.builder().name(entry.getKey()).description(entry.getValue()).build()));
            categories.put(entry.getKey(), category);
        }
        return categories;
    }

    private void seedProducts(Map<String, Category> categories) {
        if (productRepository.count() > 0) {
            return;
        }
        productRepository.saveAll(java.util.List.of(
                product("Craft Flat White", "Double shot of single-origin espresso with silky textured milk.",
                        "4.50", categories.get("Beverages"), 280),
                product("Cinnamon Swirl Bun", "Freshly baked sourdough bun with Ceylon cinnamon and brown sugar glaze.",
                        "3.75", categories.get("Snacks"), 280),
                product("Avocado Sourdough Toast", "Crushed Hass avocado, cherry tomatoes, and feta on organic levain.",
                        "11.50", categories.get("Meals"), 280),
                product("Pistachio Raspberry Tart", "Sweet pastry shell filled with rich pistachio cream and fresh raspberries.",
                        "6.50", categories.get("Desserts"), 280),
                product("Sourdough Chocolate Cookie", "Crispy edges with gooey, rich dark chocolate pools and flaked sea salt.",
                        "3.25", categories.get("Desserts"), 340),
                product("Iced Honey Oat Latte", "Organic oat milk combined with raw local honey and blonde roast cold brew.",
                        "5.25", categories.get("Beverages"), 340),
                product("Smoked Turkey Ciabatta", "Hand-carved turkey breast, heirloom tomatoes, pesto, and melted provolone.",
                        "12.00", categories.get("Meals"), 340),
                product("Matcha Jasmine Crepe", "Delicate matcha crepe layers with airy jasmine-infused pastry cream.",
                        "7.50", categories.get("Snacks"), 340)
        ));
        log.info("Seeded starter menu with 8 products across {} categories", categories.size());
    }

    private void seedTables() {
        if (cafeTableRepository.count() > 0) {
            return;
        }
        cafeTableRepository.saveAll(java.util.List.of(
                table("T-01"),
                table("T-02"),
                table("T-03")
        ));
        log.info("Seeded 3 dine-in tables with QR codes");
    }

    private Product product(String name, String desc, String price, Category category, int calories) {
        return Product.builder()
                .name(name)
                .description(desc)
                .price(new BigDecimal(price))
                .category(category)
                .calories(calories)
                .status(ProductStatus.AVAILABLE)
                .build();
    }

    private CafeTable table(String tableNumber) {
        return CafeTable.builder()
                .tableNumber(tableNumber)
                .qrCodeValue("cafe://table/" + tableNumber)
                .build();
    }
}
