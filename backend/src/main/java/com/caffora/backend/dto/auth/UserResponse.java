package com.caffora.backend.dto.auth;

import com.caffora.backend.model.Role;
import com.caffora.backend.model.User;

public record UserResponse(
        Long id,
        String name,
        String email,
        Role role,
        String loyaltyStatus
) {
    public static UserResponse from(User user) {
        return new UserResponse(user.getId(), user.getName(), user.getEmail(), user.getRole(), user.getLoyaltyStatus());
    }
}
