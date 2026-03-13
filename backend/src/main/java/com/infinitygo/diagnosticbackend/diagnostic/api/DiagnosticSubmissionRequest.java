package com.infinitygo.diagnosticbackend.diagnostic.api;

import jakarta.validation.constraints.DecimalMin;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.PositiveOrZero;
import jakarta.validation.constraints.Size;
import java.math.BigDecimal;

public record DiagnosticSubmissionRequest(
    @NotBlank
    @Size(max = 100)
    String deviceType,
    @NotBlank
    @Size(max = 100)
    String operatingSystem,
    @NotBlank
    @Size(max = 100)
    String browser,
    @NotBlank
    @Size(max = 50)
    String browserVersion,
    @NotBlank
    @Size(max = 20)
    String language,
    @NotBlank
    @Size(max = 80)
    String timezone,
    @Size(max = 100)
    String platform,
    @PositiveOrZero
    Integer logicalCores,
    @DecimalMin(value = "0.0")
    BigDecimal memoryGigabytes,
    @NotBlank
    @Size(max = 50)
    String connectionType,
    @NotNull
    Boolean online,
    @DecimalMin(value = "0.0")
    BigDecimal latencyMs,
    @DecimalMin(value = "0.0")
    BigDecimal jitterMs,
    @DecimalMin(value = "0.0")
    BigDecimal packetLossPercent,
    @DecimalMin(value = "0.0")
    BigDecimal downloadMbps,
    @DecimalMin(value = "0.0")
    BigDecimal uploadMbps
) {
}
