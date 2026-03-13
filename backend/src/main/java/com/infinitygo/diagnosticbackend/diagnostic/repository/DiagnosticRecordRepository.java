package com.infinitygo.diagnosticbackend.diagnostic.repository;

import com.infinitygo.diagnosticbackend.diagnostic.domain.DiagnosticRecord;
import java.util.UUID;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;

public interface DiagnosticRecordRepository extends JpaRepository<DiagnosticRecord, UUID> {

    Page<DiagnosticRecord> findAllByOrderByCreatedAtDesc(Pageable pageable);
}
