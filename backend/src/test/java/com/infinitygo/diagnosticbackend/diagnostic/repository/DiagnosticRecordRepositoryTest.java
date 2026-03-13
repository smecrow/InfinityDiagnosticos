package com.infinitygo.diagnosticbackend.diagnostic.repository;

import static org.assertj.core.api.Assertions.assertThat;

import com.infinitygo.diagnosticbackend.diagnostic.domain.DiagnosticRecord;
import java.math.BigDecimal;
import java.time.Instant;
import java.util.UUID;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.orm.jpa.DataJpaTest;
import org.springframework.data.domain.PageRequest;
import org.springframework.test.context.ActiveProfiles;

@DataJpaTest
@ActiveProfiles("test")
class DiagnosticRecordRepositoryTest {

    @Autowired
    private DiagnosticRecordRepository diagnosticRecordRepository;

    @Test
    void shouldReturnNewestDiagnosticsFirst() {
        diagnosticRecordRepository.save(buildRecord(Instant.parse("2026-03-10T10:15:30Z"), "Desktop"));
        diagnosticRecordRepository.save(buildRecord(Instant.parse("2026-03-11T10:15:30Z"), "Celular"));

        var result = diagnosticRecordRepository.findAllByOrderByCreatedAtDesc(PageRequest.of(0, 10));

        assertThat(result.getContent()).hasSize(2);
        assertThat(result.getContent().getFirst().getDeviceType()).isEqualTo("Celular");
        assertThat(result.getContent().get(1).getDeviceType()).isEqualTo("Desktop");
    }

    private DiagnosticRecord buildRecord(Instant createdAt, String deviceType) {
        DiagnosticRecord record = new DiagnosticRecord();
        record.setId(UUID.randomUUID());
        record.setCreatedAt(createdAt);
        record.setDeviceType(deviceType);
        record.setOperatingSystem("Windows");
        record.setBrowser("Chrome");
        record.setBrowserVersion("134.0");
        record.setLanguage("pt-BR");
        record.setTimezone("America/Sao_Paulo");
        record.setPlatform("Win32");
        record.setLogicalCores(8);
        record.setMemoryGigabytes(new BigDecimal("16.00"));
        record.setConnectionType("4g");
        record.setOnline(true);
        record.setLatencyMs(new BigDecimal("15.30"));
        record.setJitterMs(new BigDecimal("1.20"));
        record.setPacketLossPercent(new BigDecimal("0.00"));
        record.setDownloadMbps(new BigDecimal("300.50"));
        record.setUploadMbps(new BigDecimal("120.10"));
        return record;
    }
}
