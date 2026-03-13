package com.infinitygo.diagnosticbackend.diagnostic.api;

import java.math.BigDecimal;

public record ExecutedSpeedTestResponse(
    String provider,
    String region,
    BigDecimal latencyMs,
    BigDecimal jitterMs,
    BigDecimal packetLossPercent,
    BigDecimal downloadMbps,
    BigDecimal uploadMbps
) {
}
