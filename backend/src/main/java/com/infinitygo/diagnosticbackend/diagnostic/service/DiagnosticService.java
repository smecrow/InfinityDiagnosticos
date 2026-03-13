package com.infinitygo.diagnosticbackend.diagnostic.service;

import com.infinitygo.diagnosticbackend.diagnostic.api.DiagnosticAdminResponse;
import com.infinitygo.diagnosticbackend.diagnostic.api.DiagnosticCreatedResponse;
import com.infinitygo.diagnosticbackend.diagnostic.api.DiagnosticSubmissionRequest;
import com.infinitygo.diagnosticbackend.diagnostic.api.ExecutedSpeedTestResponse;
import com.infinitygo.diagnosticbackend.diagnostic.api.SpeedTestResultRequest;
import com.infinitygo.diagnosticbackend.diagnostic.domain.DiagnosticRecord;
import com.infinitygo.diagnosticbackend.diagnostic.repository.DiagnosticRecordRepository;
import java.time.Instant;
import java.util.List;
import java.util.UUID;
import org.springframework.data.domain.PageRequest;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.server.ResponseStatusException;

import static org.springframework.http.HttpStatus.NOT_FOUND;
import static org.springframework.http.HttpStatus.SERVICE_UNAVAILABLE;

@Service
public class DiagnosticService implements DiagnosticOperations {

    private static final int DEFAULT_LIMIT = 20;
    private static final int MAX_LIMIT = 100;

    private final DiagnosticRecordRepository diagnosticRecordRepository;
    private final OoklaSpeedTestRunner ooklaSpeedTestRunner;

    public DiagnosticService(
        DiagnosticRecordRepository diagnosticRecordRepository,
        OoklaSpeedTestRunner ooklaSpeedTestRunner
    ) {
        this.diagnosticRecordRepository = diagnosticRecordRepository;
        this.ooklaSpeedTestRunner = ooklaSpeedTestRunner;
    }

    @Transactional
    @Override
    public DiagnosticCreatedResponse createDiagnostic(DiagnosticSubmissionRequest request) {
        DiagnosticRecord record = new DiagnosticRecord();
        record.setId(UUID.randomUUID());
        record.setCreatedAt(Instant.now());
        record.setDeviceType(trim(request.deviceType()));
        record.setOperatingSystem(trim(request.operatingSystem()));
        record.setBrowser(trim(request.browser()));
        record.setBrowserVersion(trim(request.browserVersion()));
        record.setLanguage(trim(request.language()));
        record.setTimezone(trim(request.timezone()));
        record.setPlatform(trimToNull(request.platform()));
        record.setLogicalCores(request.logicalCores());
        record.setMemoryGigabytes(request.memoryGigabytes());
        record.setConnectionType(trim(request.connectionType()));
        record.setOnline(request.online());
        record.setLatencyMs(request.latencyMs());
        record.setJitterMs(request.jitterMs());
        record.setPacketLossPercent(request.packetLossPercent());
        record.setDownloadMbps(request.downloadMbps());
        record.setUploadMbps(request.uploadMbps());

        DiagnosticRecord savedRecord = diagnosticRecordRepository.save(record);
        return new DiagnosticCreatedResponse(savedRecord.getId(), savedRecord.getCreatedAt());
    }

    @Transactional
    @Override
    public ExecutedSpeedTestResponse executeSpeedTest(UUID diagnosticId) {
        DiagnosticRecord record = diagnosticRecordRepository.findById(diagnosticId)
            .orElseThrow(() -> new ResponseStatusException(NOT_FOUND, "Diagnóstico não encontrado."));

        OoklaSpeedTestResult result;
        try {
            result = ooklaSpeedTestRunner.runSpeedTest();
        } catch (IllegalStateException exception) {
            throw new ResponseStatusException(SERVICE_UNAVAILABLE, exception.getMessage(), exception);
        }

        applySpeedTestResult(
            record,
            result.provider(),
            result.region(),
            result.latencyMs(),
            result.jitterMs(),
            result.packetLossPercent(),
            result.downloadMbps(),
            result.uploadMbps()
        );

        diagnosticRecordRepository.save(record);

        return new ExecutedSpeedTestResponse(
            record.getSpeedTestProvider(),
            record.getSpeedTestRegion(),
            record.getLatencyMs(),
            record.getJitterMs(),
            record.getPacketLossPercent(),
            record.getDownloadMbps(),
            record.getUploadMbps()
        );
    }

    @Transactional
    @Override
    public void recordSpeedTest(UUID diagnosticId, SpeedTestResultRequest request) {
        DiagnosticRecord record = diagnosticRecordRepository.findById(diagnosticId)
            .orElseThrow(() -> new ResponseStatusException(NOT_FOUND, "Diagnóstico não encontrado."));

        applySpeedTestResult(
            record,
            request.provider(),
            request.region(),
            request.latencyMs(),
            request.jitterMs(),
            request.packetLossPercent(),
            request.downloadMbps(),
            request.uploadMbps()
        );

        diagnosticRecordRepository.save(record);
    }

    @Transactional(readOnly = true)
    @Override
    public List<DiagnosticAdminResponse> listRecentDiagnostics(Integer requestedLimit) {
        int normalizedLimit = normalizeLimit(requestedLimit);

        return diagnosticRecordRepository.findAllByOrderByCreatedAtDesc(PageRequest.of(0, normalizedLimit))
            .stream()
            .map(this::toAdminResponse)
            .toList();
    }

    private DiagnosticAdminResponse toAdminResponse(DiagnosticRecord record) {
        return new DiagnosticAdminResponse(
            record.getId(),
            record.getCreatedAt(),
            record.getSpeedTestCompletedAt(),
            record.getDeviceType(),
            record.getOperatingSystem(),
            record.getBrowser(),
            record.getBrowserVersion(),
            record.getLanguage(),
            record.getTimezone(),
            record.getPlatform(),
            record.getLogicalCores(),
            record.getMemoryGigabytes(),
            record.getConnectionType(),
            record.getOnline(),
            record.getLatencyMs(),
            record.getJitterMs(),
            record.getPacketLossPercent(),
            record.getDownloadMbps(),
            record.getUploadMbps(),
            record.getSpeedTestProvider(),
            record.getSpeedTestRegion()
        );
    }

    private int normalizeLimit(Integer requestedLimit) {
        if (requestedLimit == null || requestedLimit < 1) {
            return DEFAULT_LIMIT;
        }

        return Math.min(requestedLimit, MAX_LIMIT);
    }

    private String trim(String value) {
        return value.trim();
    }

    private void applySpeedTestResult(
        DiagnosticRecord record,
        String provider,
        String region,
        java.math.BigDecimal latencyMs,
        java.math.BigDecimal jitterMs,
        java.math.BigDecimal packetLossPercent,
        java.math.BigDecimal downloadMbps,
        java.math.BigDecimal uploadMbps
    ) {
        record.setLatencyMs(latencyMs);
        record.setJitterMs(jitterMs);
        record.setPacketLossPercent(packetLossPercent);
        record.setDownloadMbps(downloadMbps);
        record.setUploadMbps(uploadMbps);
        record.setSpeedTestProvider(trim(provider));
        record.setSpeedTestRegion(trimToNull(region));
        record.setSpeedTestCompletedAt(Instant.now());
    }

    private String trimToNull(String value) {
        if (value == null) {
            return null;
        }

        String trimmed = value.trim();
        return trimmed.isEmpty() ? null : trimmed;
    }
}
