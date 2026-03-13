package com.infinitygo.diagnosticbackend.diagnostic.domain;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import java.math.BigDecimal;
import java.time.Instant;
import java.util.UUID;

@Entity
@Table(name = "diagnostics")
public class DiagnosticRecord {

    @Id
    private UUID id;

    @Column(nullable = false, updatable = false)
    private Instant createdAt;

    @Column(nullable = false, length = 100)
    private String deviceType;

    @Column(nullable = false, length = 100)
    private String operatingSystem;

    @Column(nullable = false, length = 100)
    private String browser;

    @Column(nullable = false, length = 50)
    private String browserVersion;

    @Column(nullable = false, length = 20)
    private String language;

    @Column(nullable = false, length = 80)
    private String timezone;

    @Column(length = 100)
    private String platform;

    private Integer logicalCores;

    @Column(precision = 10, scale = 2)
    private BigDecimal memoryGigabytes;

    @Column(nullable = false, length = 50)
    private String connectionType;

    @Column(nullable = false)
    private Boolean online;

    @Column(precision = 10, scale = 2)
    private BigDecimal latencyMs;

    @Column(precision = 10, scale = 2)
    private BigDecimal jitterMs;

    @Column(precision = 10, scale = 2)
    private BigDecimal packetLossPercent;

    @Column(precision = 10, scale = 2)
    private BigDecimal downloadMbps;

    @Column(precision = 10, scale = 2)
    private BigDecimal uploadMbps;

    @Column(length = 50)
    private String speedTestProvider;

    @Column(length = 80)
    private String speedTestRegion;

    private Instant speedTestCompletedAt;

    public UUID getId() {
        return id;
    }

    public void setId(UUID id) {
        this.id = id;
    }

    public Instant getCreatedAt() {
        return createdAt;
    }

    public void setCreatedAt(Instant createdAt) {
        this.createdAt = createdAt;
    }

    public String getDeviceType() {
        return deviceType;
    }

    public void setDeviceType(String deviceType) {
        this.deviceType = deviceType;
    }

    public String getOperatingSystem() {
        return operatingSystem;
    }

    public void setOperatingSystem(String operatingSystem) {
        this.operatingSystem = operatingSystem;
    }

    public String getBrowser() {
        return browser;
    }

    public void setBrowser(String browser) {
        this.browser = browser;
    }

    public String getBrowserVersion() {
        return browserVersion;
    }

    public void setBrowserVersion(String browserVersion) {
        this.browserVersion = browserVersion;
    }

    public String getLanguage() {
        return language;
    }

    public void setLanguage(String language) {
        this.language = language;
    }

    public String getTimezone() {
        return timezone;
    }

    public void setTimezone(String timezone) {
        this.timezone = timezone;
    }

    public String getPlatform() {
        return platform;
    }

    public void setPlatform(String platform) {
        this.platform = platform;
    }

    public Integer getLogicalCores() {
        return logicalCores;
    }

    public void setLogicalCores(Integer logicalCores) {
        this.logicalCores = logicalCores;
    }

    public BigDecimal getMemoryGigabytes() {
        return memoryGigabytes;
    }

    public void setMemoryGigabytes(BigDecimal memoryGigabytes) {
        this.memoryGigabytes = memoryGigabytes;
    }

    public String getConnectionType() {
        return connectionType;
    }

    public void setConnectionType(String connectionType) {
        this.connectionType = connectionType;
    }

    public Boolean getOnline() {
        return online;
    }

    public void setOnline(Boolean online) {
        this.online = online;
    }

    public BigDecimal getLatencyMs() {
        return latencyMs;
    }

    public void setLatencyMs(BigDecimal latencyMs) {
        this.latencyMs = latencyMs;
    }

    public BigDecimal getJitterMs() {
        return jitterMs;
    }

    public void setJitterMs(BigDecimal jitterMs) {
        this.jitterMs = jitterMs;
    }

    public BigDecimal getPacketLossPercent() {
        return packetLossPercent;
    }

    public void setPacketLossPercent(BigDecimal packetLossPercent) {
        this.packetLossPercent = packetLossPercent;
    }

    public BigDecimal getDownloadMbps() {
        return downloadMbps;
    }

    public void setDownloadMbps(BigDecimal downloadMbps) {
        this.downloadMbps = downloadMbps;
    }

    public BigDecimal getUploadMbps() {
        return uploadMbps;
    }

    public void setUploadMbps(BigDecimal uploadMbps) {
        this.uploadMbps = uploadMbps;
    }

    public String getSpeedTestProvider() {
        return speedTestProvider;
    }

    public void setSpeedTestProvider(String speedTestProvider) {
        this.speedTestProvider = speedTestProvider;
    }

    public String getSpeedTestRegion() {
        return speedTestRegion;
    }

    public void setSpeedTestRegion(String speedTestRegion) {
        this.speedTestRegion = speedTestRegion;
    }

    public Instant getSpeedTestCompletedAt() {
        return speedTestCompletedAt;
    }

    public void setSpeedTestCompletedAt(Instant speedTestCompletedAt) {
        this.speedTestCompletedAt = speedTestCompletedAt;
    }
}
