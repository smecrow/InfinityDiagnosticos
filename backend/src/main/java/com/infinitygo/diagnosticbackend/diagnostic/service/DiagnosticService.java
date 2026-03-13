package com.infinitygo.diagnosticbackend.diagnostic.service;

import com.infinitygo.diagnosticbackend.diagnostic.api.DiagnosticAdminResponse;
import com.infinitygo.diagnosticbackend.diagnostic.api.DiagnosticCreatedResponse;
import com.infinitygo.diagnosticbackend.diagnostic.api.DiagnosticSubmissionRequest;
import com.infinitygo.diagnosticbackend.diagnostic.domain.DiagnosticRecord;
import com.infinitygo.diagnosticbackend.diagnostic.repository.DiagnosticRecordRepository;
import java.time.Instant;
import java.util.List;
import java.util.UUID;
import org.springframework.data.domain.PageRequest;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
public class DiagnosticService implements DiagnosticOperations {

    private static final int DEFAULT_LIMIT = 20;
    private static final int MAX_LIMIT = 100;

    private final DiagnosticRecordRepository diagnosticRecordRepository;

    public DiagnosticService(DiagnosticRecordRepository diagnosticRecordRepository) {
        this.diagnosticRecordRepository = diagnosticRecordRepository;
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
            record.getUploadMbps()
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

    private String trimToNull(String value) {
        if (value == null) {
            return null;
        }

        String trimmed = value.trim();
        return trimmed.isEmpty() ? null : trimmed;
    }
}
