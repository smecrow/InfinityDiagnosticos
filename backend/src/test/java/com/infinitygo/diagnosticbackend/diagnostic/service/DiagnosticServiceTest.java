package com.infinitygo.diagnosticbackend.diagnostic.service;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

import com.infinitygo.diagnosticbackend.diagnostic.api.DiagnosticSubmissionRequest;
import com.infinitygo.diagnosticbackend.diagnostic.domain.DiagnosticRecord;
import com.infinitygo.diagnosticbackend.diagnostic.repository.DiagnosticRecordRepository;
import java.math.BigDecimal;
import java.util.List;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.ArgumentCaptor;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.data.domain.PageImpl;
import org.springframework.data.domain.Pageable;

@ExtendWith(MockitoExtension.class)
class DiagnosticServiceTest {

    @Mock
    private DiagnosticRecordRepository diagnosticRecordRepository;

    @InjectMocks
    private DiagnosticService diagnosticService;

    @Test
    void shouldPersistSubmittedDiagnostic() {
        when(diagnosticRecordRepository.save(any(DiagnosticRecord.class)))
            .thenAnswer(invocation -> invocation.getArgument(0, DiagnosticRecord.class));

        var response = diagnosticService.createDiagnostic(buildRequest());

        ArgumentCaptor<DiagnosticRecord> captor = ArgumentCaptor.forClass(DiagnosticRecord.class);
        verify(diagnosticRecordRepository).save(captor.capture());

        DiagnosticRecord savedRecord = captor.getValue();
        assertThat(response.id()).isNotNull();
        assertThat(response.createdAt()).isNotNull();
        assertThat(savedRecord.getDeviceType()).isEqualTo("Desktop");
        assertThat(savedRecord.getOperatingSystem()).isEqualTo("Windows");
        assertThat(savedRecord.getConnectionType()).isEqualTo("wifi");
        assertThat(savedRecord.getOnline()).isTrue();
        assertThat(savedRecord.getDownloadMbps()).isEqualByComparingTo("500.25");
    }

    @Test
    void shouldCapRecentDiagnosticListLimit() {
        DiagnosticRecord record = new DiagnosticRecord();
        record.setId(java.util.UUID.randomUUID());
        record.setCreatedAt(java.time.Instant.parse("2026-03-12T12:00:00Z"));
        record.setDeviceType("Desktop");
        record.setOperatingSystem("Windows");
        record.setBrowser("Chrome");
        record.setBrowserVersion("134.0");
        record.setLanguage("pt-BR");
        record.setTimezone("America/Sao_Paulo");
        record.setConnectionType("wifi");
        record.setOnline(true);

        when(diagnosticRecordRepository.findAllByOrderByCreatedAtDesc(any(Pageable.class)))
            .thenReturn(new PageImpl<>(List.of(record)));

        var response = diagnosticService.listRecentDiagnostics(999);

        ArgumentCaptor<Pageable> captor = ArgumentCaptor.forClass(Pageable.class);
        verify(diagnosticRecordRepository).findAllByOrderByCreatedAtDesc(captor.capture());

        assertThat(captor.getValue().getPageSize()).isEqualTo(100);
        assertThat(response).hasSize(1);
        assertThat(response.getFirst().deviceType()).isEqualTo("Desktop");
    }

    private DiagnosticSubmissionRequest buildRequest() {
        return new DiagnosticSubmissionRequest(
            "Desktop",
            "Windows",
            "Chrome",
            "134.0",
            "pt-BR",
            "America/Sao_Paulo",
            "Win32",
            8,
            new BigDecimal("16.00"),
            "wifi",
            true,
            new BigDecimal("12.40"),
            new BigDecimal("1.20"),
            new BigDecimal("0.00"),
            new BigDecimal("500.25"),
            new BigDecimal("210.10")
        );
    }
}
