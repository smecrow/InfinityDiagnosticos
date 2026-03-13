package com.infinitygo.diagnosticbackend.diagnostic.api;

import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.when;
import static org.springframework.http.MediaType.APPLICATION_JSON;
import static org.springframework.security.test.web.servlet.request.SecurityMockMvcRequestPostProcessors.httpBasic;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.patch;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.header;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import com.infinitygo.diagnosticbackend.config.SecurityConfig;
import com.infinitygo.diagnosticbackend.diagnostic.service.DiagnosticOperations;
import java.time.Instant;
import java.util.List;
import java.util.UUID;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.WebMvcTest;
import org.springframework.context.annotation.Import;
import org.springframework.boot.test.mock.mockito.MockBean;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.test.web.servlet.MockMvc;

@WebMvcTest(DiagnosticController.class)
@Import(SecurityConfig.class)
@ActiveProfiles("test")
class DiagnosticControllerTest {

    @Autowired
    private MockMvc mockMvc;

    @MockBean
    private DiagnosticOperations diagnosticService;

    @Test
    void shouldCreateDiagnosticWithoutAuthentication() throws Exception {
        UUID diagnosticId = UUID.fromString("b54e2ee3-064b-4a69-8886-36d5f5a0a2b8");

        when(diagnosticService.createDiagnostic(any()))
            .thenReturn(new DiagnosticCreatedResponse(diagnosticId, Instant.parse("2026-03-12T12:30:00Z")));

        mockMvc.perform(post("/api/diagnostics")
                .contentType(APPLICATION_JSON)
                .content("""
                    {
                      "deviceType": "Desktop",
                      "operatingSystem": "Windows",
                      "browser": "Chrome",
                      "browserVersion": "134.0",
                      "language": "pt-BR",
                      "timezone": "America/Sao_Paulo",
                      "platform": "Win32",
                      "logicalCores": 8,
                      "memoryGigabytes": 16.0,
                      "connectionType": "wifi",
                      "online": true,
                      "latencyMs": 12.4,
                      "jitterMs": 1.2,
                      "packetLossPercent": 0.0,
                      "downloadMbps": 500.25,
                      "uploadMbps": 210.1
                    }
                    """))
            .andExpect(status().isCreated())
            .andExpect(header().string("Location", "/api/admin/diagnostics/" + diagnosticId))
            .andExpect(jsonPath("$.id").value(diagnosticId.toString()))
            .andExpect(jsonPath("$.createdAt").value("2026-03-12T12:30:00Z"));
    }

    @Test
    void shouldRejectInvalidDiagnosticPayload() throws Exception {
        mockMvc.perform(post("/api/diagnostics")
                .contentType(APPLICATION_JSON)
                .content("""
                    {
                      "deviceType": "",
                      "operatingSystem": "Windows",
                      "browser": "Chrome",
                      "browserVersion": "134.0",
                      "language": "pt-BR",
                      "timezone": "America/Sao_Paulo",
                      "connectionType": "wifi",
                      "online": true
                    }
                    """))
            .andExpect(status().isBadRequest());
    }

    @Test
    void shouldExecuteSpeedTestWithoutAuthentication() throws Exception {
        UUID diagnosticId = UUID.fromString("2db4fef8-8937-47bc-b661-9f9d871b86d2");

        when(diagnosticService.executeSpeedTest(diagnosticId))
            .thenReturn(new ExecutedSpeedTestResponse(
                "Ookla CLI / InfinityGO Telecom",
                "Caldas Novas/GO",
                new java.math.BigDecimal("14.21"),
                new java.math.BigDecimal("1.47"),
                new java.math.BigDecimal("0.00"),
                new java.math.BigDecimal("921.88"),
                new java.math.BigDecimal("468.34")
            ));

        mockMvc.perform(post("/api/diagnostics/{diagnosticId}/speedtest", diagnosticId))
            .andExpect(status().isOk())
            .andExpect(jsonPath("$.provider").value("Ookla CLI / InfinityGO Telecom"))
            .andExpect(jsonPath("$.region").value("Caldas Novas/GO"))
            .andExpect(jsonPath("$.downloadMbps").value(921.88));
    }

    @Test
    void shouldRecordSpeedTestWithoutAuthentication() throws Exception {
        UUID diagnosticId = UUID.fromString("2db4fef8-8937-47bc-b661-9f9d871b86d2");

        mockMvc.perform(patch("/api/diagnostics/{diagnosticId}/speedtest", diagnosticId)
                .contentType(APPLICATION_JSON)
                .content("""
                    {
                      "provider": "Ookla CLI / InfinityGO Telecom",
                      "region": "Caldas Novas/GO",
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
    void shouldRejectInvalidSpeedTestPayload() throws Exception {
        UUID diagnosticId = UUID.fromString("2db4fef8-8937-47bc-b661-9f9d871b86d2");

        mockMvc.perform(patch("/api/diagnostics/{diagnosticId}/speedtest", diagnosticId)
                .contentType(APPLICATION_JSON)
                .content("""
                    {
                      "provider": "",
                      "latencyMs": -1,
                      "jitterMs": 2.1,
                      "packetLossPercent": 0.0,
                      "downloadMbps": 412.3,
                      "uploadMbps": 198.7
                    }
                    """))
            .andExpect(status().isBadRequest());
    }

    @Test
    void shouldRequireAuthenticationForAdminListing() throws Exception {
        mockMvc.perform(get("/api/admin/diagnostics"))
            .andExpect(status().isUnauthorized());
    }

    @Test
    void shouldAllowAdminListingWithValidCredentials() throws Exception {
        UUID diagnosticId = UUID.fromString("6b552c52-407f-4b53-a80a-d43a1ed7033d");

        when(diagnosticService.listRecentDiagnostics(20))
            .thenReturn(List.of(new DiagnosticAdminResponse(
                diagnosticId,
                Instant.parse("2026-03-12T11:00:00Z"),
                Instant.parse("2026-03-12T11:02:00Z"),
                "Desktop",
                "Windows",
                "Chrome",
                "134.0",
                "pt-BR",
                "America/Sao_Paulo",
                "Win32",
                8,
                new java.math.BigDecimal("16.00"),
                "wifi",
                true,
                new java.math.BigDecimal("12.40"),
                new java.math.BigDecimal("1.20"),
                new java.math.BigDecimal("0.00"),
                new java.math.BigDecimal("500.25"),
                new java.math.BigDecimal("210.10"),
                "Ookla CLI / InfinityGO Telecom",
                "Caldas Novas/GO"
            )));

        mockMvc.perform(get("/api/admin/diagnostics").with(httpBasic("admin", "secret123")))
            .andExpect(status().isOk())
            .andExpect(jsonPath("$[0].id").value(diagnosticId.toString()))
            .andExpect(jsonPath("$[0].connectionType").value("wifi"))
            .andExpect(jsonPath("$[0].speedTestProvider").value("Ookla CLI / InfinityGO Telecom"));
    }
}
