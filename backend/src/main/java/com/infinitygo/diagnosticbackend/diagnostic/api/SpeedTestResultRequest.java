package com.infinitygo.diagnosticbackend.diagnostic.api;

import jakarta.validation.constraints.DecimalMin;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;
import java.math.BigDecimal;

public record SpeedTestResultRequest(
    @NotBlank
    @Size(max = 50)
    String provider,
    @Size(max = 80)
    String region,
    @NotNull
    @DecimalMin(value = "0.0")
    BigDecimal latencyMs,
    @NotNull
    @DecimalMin(value = "0.0")
    BigDecimal jitterMs,
    @NotNull
    @DecimalMin(value = "0.0")
    BigDecimal packetLossPercent,
    @NotNull
    @DecimalMin(value = "0.0")
    BigDecimal downloadMbps,
    @NotNull
    @DecimalMin(value = "0.0")
    BigDecimal uploadMbps
) {
}
