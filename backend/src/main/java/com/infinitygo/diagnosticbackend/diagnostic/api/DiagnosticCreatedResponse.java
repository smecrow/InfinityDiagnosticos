package com.infinitygo.diagnosticbackend.diagnostic.api;

import java.time.Instant;
import java.util.UUID;

public record DiagnosticCreatedResponse(
    UUID id,
    Instant createdAt
) {
}
