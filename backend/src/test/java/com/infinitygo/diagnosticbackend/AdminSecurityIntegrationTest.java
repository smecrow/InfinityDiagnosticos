package com.infinitygo.diagnosticbackend;

import static org.mockito.Mockito.when;
import static org.springframework.security.test.web.servlet.request.SecurityMockMvcRequestPostProcessors.httpBasic;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.patch;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import com.infinitygo.diagnosticbackend.diagnostic.api.DiagnosticAdminResponse;
import com.infinitygo.diagnosticbackend.diagnostic.service.DiagnosticOperations;
import java.math.BigDecimal;
import java.time.Instant;
import java.util.List;
import java.util.UUID;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.boot.test.mock.mockito.MockBean;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.test.web.servlet.MockMvc;

@SpringBootTest
@AutoConfigureMockMvc
@ActiveProfiles("test")
class AdminSecurityIntegrationTest {

    @Autowired
    private MockMvc mockMvc;

    @MockBean
    private DiagnosticOperations diagnosticService;

    @Test
    void shouldExposeHealthEndpointWithoutAuthentication() throws Exception {
        mockMvc.perform(get("/api/health"))
            .andExpect(status().isOk())
            .andExpect(jsonPath("$.status").value("ok"));
    }

    @Test
    void shouldRejectAdminEndpointWithoutCredentials() throws Exception {
        mockMvc.perform(get("/api/admin/diagnostics"))
            .andExpect(status().isUnauthorized());
    }

    @Test
    void shouldAllowPublicSpeedTestRecording() throws Exception {
        mockMvc.perform(patch("/api/diagnostics/{diagnosticId}/speedtest", UUID.fromString("9a543e5e-1f57-4920-a9f0-e14d95cf9f0c"))
                .contentType("application/json")
                .content("""
                    {
                      "provider": "cloudflare-worker",
                      "region": "GRU",
                      "latencyMs": 18.4,
                      "jitterMs": 2.1,
                      "packetLossPercent": 0.0,
                      "downloadMbps": 412.3,
                      "uploadMbps": 198.7
                    }
                    """))
            .andExpect(status().isNoContent());
    }

    @Test
    void shouldAllowAdminEndpointWithValidCredentials() throws Exception {
        when(diagnosticService.listRecentDiagnostics(20))
            .thenReturn(List.of(new DiagnosticAdminResponse(
                UUID.fromString("40ba410c-f0f5-4c07-b932-89c6f09229f6"),
                Instant.parse("2026-03-12T13:00:00Z"),
                Instant.parse("2026-03-12T13:02:00Z"),
                "Desktop",
                "Windows",
                "Chrome",
                "134.0",
                "pt-BR",
                "America/Sao_Paulo",
                "Win32",
                8,
                new BigDecimal("16.00"),
                "wifi",
                true,
                new BigDecimal("12.40"),
                new BigDecimal("1.20"),
                new BigDecimal("0.00"),
                new BigDecimal("500.25"),
                new BigDecimal("210.10"),
                "cloudflare-worker",
                "GRU"
            )));

        mockMvc.perform(get("/api/admin/diagnostics").with(httpBasic("admin", "secret123")))
            .andExpect(status().isOk())
            .andExpect(jsonPath("$[0].browser").value("Chrome"));
    }
}
