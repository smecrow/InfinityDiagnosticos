package com.infinitygo.diagnosticbackend.diagnostic.service;

import java.math.BigDecimal;

public record OoklaSpeedTestResult(
    String provider,
    String region,
    BigDecimal latencyMs,
    BigDecimal jitterMs,
    BigDecimal packetLossPercent,
    BigDecimal downloadMbps,
    BigDecimal uploadMbps
) {
}
