package com.caffora.backend;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.caffora.backend.dto.auth.LoginRequest;
import com.caffora.backend.dto.auth.RegisterRequest;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.test.web.servlet.MockMvc;

import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;
import static org.springframework.http.MediaType.APPLICATION_JSON;

@SpringBootTest
@AutoConfigureMockMvc
@ActiveProfiles("test")
class AuthFlowIntegrationTest {

    @Autowired
    private MockMvc mockMvc;

    @Autowired
    private ObjectMapper objectMapper;

    @Test
    void registerThenLoginThenAccessProtectedProductsEndpoint() throws Exception {
        RegisterRequest register = new RegisterRequest("Test Customer", "test.customer@example.com", "SecurePass123");

        String registerBody = mockMvc.perform(post("/api/auth/register")
                        .contentType(APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(register)))
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.token").exists())
                .andExpect(jsonPath("$.user.email").value("test.customer@example.com"))
                .andExpect(jsonPath("$.user.role").value("CUSTOMER"))
                .andReturn().getResponse().getContentAsString();

        // Duplicate registration should be rejected with 409
        mockMvc.perform(post("/api/auth/register")
                        .contentType(APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(register)))
                .andExpect(status().isConflict());

        LoginRequest login = new LoginRequest("test.customer@example.com", "SecurePass123");
        mockMvc.perform(post("/api/auth/login")
                        .contentType(APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(login)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.token").exists());

        // Wrong password should be rejected with 401
        mockMvc.perform(post("/api/auth/login")
                        .contentType(APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(new LoginRequest("test.customer@example.com", "wrong-password"))))
                .andExpect(status().isUnauthorized());

        String token = objectMapper.readTree(registerBody).get("token").asText();

        mockMvc.perform(get("/api/auth/me").header("Authorization", "Bearer " + token))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.email").value("test.customer@example.com"));

        // Product list is public, no token required
        mockMvc.perform(get("/api/products"))
                .andExpect(status().isOk());

        // Creating a product is admin-only; a plain customer token must be rejected
        mockMvc.perform(post("/api/products")
                        .header("Authorization", "Bearer " + token)
                        .contentType(APPLICATION_JSON)
                        .content("{\"name\":\"Test\",\"description\":\"desc\",\"price\":1.0,\"categoryId\":1}"))
                .andExpect(status().isForbidden());
    }

    @Test
    void unauthenticatedRequestToProtectedEndpointReturns401() throws Exception {
        mockMvc.perform(get("/api/orders/my"))
                .andExpect(status().isUnauthorized());
    }
}
