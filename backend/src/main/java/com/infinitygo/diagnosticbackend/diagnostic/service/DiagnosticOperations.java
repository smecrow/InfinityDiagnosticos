package com.infinitygo.diagnosticbackend.diagnostic.service;

import com.infinitygo.diagnosticbackend.diagnostic.api.DiagnosticAdminResponse;
import com.infinitygo.diagnosticbackend.diagnostic.api.DiagnosticCreatedResponse;
import com.infinitygo.diagnosticbackend.diagnostic.api.DiagnosticSubmissionRequest;
import java.util.List;

public interface DiagnosticOperations {

    DiagnosticCreatedResponse createDiagnostic(DiagnosticSubmissionRequest request);

    List<DiagnosticAdminResponse> listRecentDiagnostics(Integer requestedLimit);
}
