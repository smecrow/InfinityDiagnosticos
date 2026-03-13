package com.infinitygo.diagnosticbackend.diagnostic.api;

import java.math.BigDecimal;
import java.time.Instant;
import java.util.UUID;

public record DiagnosticAdminResponse(
    UUID id,
    Instant createdAt,
    String deviceType,
    String operatingSystem,
    String browser,
    String browserVersion,
    String language,
    String timezone,
    String platform,
    Integer logicalCores,
    BigDecimal memoryGigabytes,
    String connectionType,
    Boolean online,
    BigDecimal latencyMs,
    BigDecimal jitterMs,
    BigDecimal packetLossPercent,
    BigDecimal downloadMbps,
    BigDecimal uploadMbps
) {
}
