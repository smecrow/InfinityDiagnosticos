package com.infinitygo.diagnosticbackend.diagnostic.service;

import com.infinitygo.diagnosticbackend.diagnostic.api.DiagnosticAdminResponse;
import com.infinitygo.diagnosticbackend.diagnostic.api.DiagnosticCreatedResponse;
import com.infinitygo.diagnosticbackend.diagnostic.api.DiagnosticSubmissionRequest;
import com.infinitygo.diagnosticbackend.diagnostic.api.ExecutedSpeedTestResponse;
import com.infinitygo.diagnosticbackend.diagnostic.api.SpeedTestResultRequest;
import java.util.List;
import java.util.UUID;

public interface DiagnosticOperations {

    DiagnosticCreatedResponse createDiagnostic(DiagnosticSubmissionRequest request);

    ExecutedSpeedTestResponse executeSpeedTest(UUID diagnosticId);

    void recordSpeedTest(UUID diagnosticId, SpeedTestResultRequest request);

    List<DiagnosticAdminResponse> listRecentDiagnostics(Integer requestedLimit);
}
