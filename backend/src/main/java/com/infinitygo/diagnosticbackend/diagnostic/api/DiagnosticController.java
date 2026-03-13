package com.infinitygo.diagnosticbackend.diagnostic.api;

import com.infinitygo.diagnosticbackend.diagnostic.service.DiagnosticOperations;
import jakarta.validation.Valid;
import jakarta.validation.constraints.Max;
import jakarta.validation.constraints.Min;
import java.net.URI;
import java.util.List;
import java.util.UUID;
import org.springframework.http.ResponseEntity;
import org.springframework.validation.annotation.Validated;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PatchMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

@Validated
@RestController
@RequestMapping("/api")
public class DiagnosticController {

    private final DiagnosticOperations diagnosticService;

    public DiagnosticController(DiagnosticOperations diagnosticService) {
        this.diagnosticService = diagnosticService;
    }

    @GetMapping("/health")
    public HealthResponse health() {
        return new HealthResponse("ok");
    }

    @PostMapping("/diagnostics")
    public ResponseEntity<DiagnosticCreatedResponse> createDiagnostic(
        @Valid @RequestBody DiagnosticSubmissionRequest request
    ) {
        DiagnosticCreatedResponse response = diagnosticService.createDiagnostic(request);
        URI location = URI.create("/api/admin/diagnostics/" + response.id());
        return ResponseEntity.created(location).body(response);
    }

    @PatchMapping("/diagnostics/{diagnosticId}/speedtest")
    public ResponseEntity<Void> recordSpeedTest(
        @PathVariable UUID diagnosticId,
        @Valid @RequestBody SpeedTestResultRequest request
    ) {
        diagnosticService.recordSpeedTest(diagnosticId, request);
        return ResponseEntity.noContent().build();
    }

    @GetMapping("/admin/diagnostics")
    public List<DiagnosticAdminResponse> listDiagnostics(
        @RequestParam(defaultValue = "20") @Min(1) @Max(100) Integer limit
    ) {
        return diagnosticService.listRecentDiagnostics(limit);
    }
}
