package com.infinitygo.diagnosticbackend.diagnostic.service;

import org.springframework.boot.context.properties.ConfigurationProperties;

@ConfigurationProperties(prefix = "app.speedtest.ookla")
public class OoklaSpeedTestProperties {

    private String binaryPath = "speedtest";
    private int serverId = 35474;
    private String providerLabel = "Ookla CLI / InfinityGO Telecom";
    private String regionLabel = "Caldas Novas/GO";
    private long timeoutSeconds = 90;

    public String getBinaryPath() {
        return binaryPath;
    }

    public void setBinaryPath(String binaryPath) {
        this.binaryPath = binaryPath;
    }

    public int getServerId() {
        return serverId;
    }

    public void setServerId(int serverId) {
        this.serverId = serverId;
    }

    public String getProviderLabel() {
        return providerLabel;
    }

    public void setProviderLabel(String providerLabel) {
        this.providerLabel = providerLabel;
    }

    public String getRegionLabel() {
        return regionLabel;
    }

    public void setRegionLabel(String regionLabel) {
        this.regionLabel = regionLabel;
    }

    public long getTimeoutSeconds() {
        return timeoutSeconds;
    }

    public void setTimeoutSeconds(long timeoutSeconds) {
        this.timeoutSeconds = timeoutSeconds;
    }
}
