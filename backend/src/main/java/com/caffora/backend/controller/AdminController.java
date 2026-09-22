package com.caffora.backend.controller;

import com.caffora.backend.dto.admin.AdminUserResponse;
import com.caffora.backend.dto.admin.DashboardResponse;
import com.caffora.backend.dto.admin.SalesReportItem;
import com.caffora.backend.dto.admin.TopProductItem;
import com.caffora.backend.service.AdminService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;

/**
 * Everything under /api/admin/** is locked to ROLE_ADMIN in SecurityConfig.
 * Product/category/table/order management themselves live in their own controllers
 * (also admin-gated there); this controller is purely for admin-only aggregate views.
 */
@RestController
@RequestMapping("/api/admin")
@RequiredArgsConstructor
public class AdminController {

    private final AdminService adminService;

    @GetMapping("/dashboard")
    public ResponseEntity<DashboardResponse> dashboard() {
        return ResponseEntity.ok(adminService.dashboard());
    }

    /** Real grouped SQL aggregate over orders, by calendar day or month. */
    @GetMapping("/reports/sales")
    public ResponseEntity<List<SalesReportItem>> salesReport(
            @RequestParam(name = "range", required = false, defaultValue = "daily") String range) {
        return ResponseEntity.ok(adminService.salesReport(range));
    }

    /** Real grouped SQL aggregate joining order_items and products. */
    @GetMapping("/reports/top-products")
    public ResponseEntity<List<TopProductItem>> topProducts(
            @RequestParam(name = "limit", required = false, defaultValue = "5") int limit) {
        return ResponseEntity.ok(adminService.topProducts(limit));
    }

    @GetMapping("/users")
    public ResponseEntity<List<AdminUserResponse>> users() {
        return ResponseEntity.ok(adminService.users());
    }
}
