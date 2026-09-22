package com.caffora.backend.dto.admin;

import com.caffora.backend.model.Role;
import com.caffora.backend.model.User;

import java.time.Instant;

/** Deliberately excludes passwordHash — never expose it, even to admins. */
public record AdminUserResponse(
        Long id,
        String name,
        String email,
        Role role,
        Instant createdAt
) {
    public static AdminUserResponse from(User user) {
        return new AdminUserResponse(user.getId(), user.getName(), user.getEmail(), user.getRole(), user.getCreatedAt());
    }
}
