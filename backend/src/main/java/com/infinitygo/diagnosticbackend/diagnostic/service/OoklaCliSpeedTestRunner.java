package com.infinitygo.diagnosticbackend.diagnostic.service;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import java.math.BigDecimal;
import java.math.RoundingMode;
import java.nio.charset.StandardCharsets;
import java.util.List;
import java.util.concurrent.TimeUnit;
import org.springframework.stereotype.Component;

@Component
public class OoklaCliSpeedTestRunner implements OoklaSpeedTestRunner {

    private static final BigDecimal BITS_PER_BYTE = BigDecimal.valueOf(8);
    private static final BigDecimal ONE_MILLION = BigDecimal.valueOf(1_000_000);

    private final ObjectMapper objectMapper;
    private final OoklaSpeedTestProperties properties;

    public OoklaCliSpeedTestRunner(ObjectMapper objectMapper, OoklaSpeedTestProperties properties) {
        this.objectMapper = objectMapper;
        this.properties = properties;
    }

    @Override
    public OoklaSpeedTestResult runSpeedTest() {
        List<String> command = List.of(
            properties.getBinaryPath(),
            "--accept-license",
            "--accept-gdpr",
            "--format=json",
            "--server-id=" + properties.getServerId()
        );

        ProcessBuilder processBuilder = new ProcessBuilder(command);
        processBuilder.redirectErrorStream(true);

        try {
            Process process = processBuilder.start();
            boolean finished = process.waitFor(properties.getTimeoutSeconds(), TimeUnit.SECONDS);

            if (!finished) {
                process.destroyForcibly();
                throw new IllegalStateException("Tempo limite excedido ao executar o Speedtest CLI da Ookla.");
            }

            String output;
            try (var inputStream = process.getInputStream()) {
                output = new String(inputStream.readAllBytes(), StandardCharsets.UTF_8).trim();
            }

            if (process.exitValue() != 0) {
                throw new IllegalStateException("O Speedtest CLI da Ookla falhou: " + summarizeOutput(output));
            }

            return parseResult(output);
        } catch (InterruptedException exception) {
            Thread.currentThread().interrupt();
            throw new IllegalStateException("A execução do Speedtest CLI da Ookla foi interrompida.", exception);
        } catch (java.io.IOException exception) {
            throw new IllegalStateException(
                "Não foi possível iniciar o Speedtest CLI da Ookla. Verifique a instalação do binário `speedtest`.",
                exception
            );
        }
    }

    private OoklaSpeedTestResult parseResult(String output) {
        String jsonOutput = extractJsonPayload(output);

        JsonNode root;
        try {
            root = objectMapper.readTree(jsonOutput);
        } catch (java.io.IOException exception) {
            throw new IllegalStateException(
                "A saída retornada pelo Speedtest CLI da Ookla não veio em JSON válido: " + summarizeOutput(output),
                exception
            );
        }

        BigDecimal latencyMs = readRequiredDecimal(root, "ping", "latency");
        BigDecimal jitterMs = readRequiredDecimal(root, "ping", "jitter");
        BigDecimal packetLossPercent = readOptionalDecimal(root.path("packetLoss"), BigDecimal.ZERO);
        BigDecimal downloadBandwidth = readRequiredDecimal(root, "download", "bandwidth");
        BigDecimal uploadBandwidth = readRequiredDecimal(root, "upload", "bandwidth");

        return new OoklaSpeedTestResult(
            properties.getProviderLabel(),
            properties.getRegionLabel(),
            normalizeMetric(latencyMs),
            normalizeMetric(jitterMs),
            normalizeMetric(packetLossPercent),
            toMbps(downloadBandwidth),
            toMbps(uploadBandwidth)
        );
    }

    private String extractJsonPayload(String output) {
        if (output == null || output.isBlank()) {
            throw new IllegalStateException("O Speedtest CLI da Ookla não retornou conteúdo para análise.");
        }

        String trimmedOutput = output.trim();
        int firstJsonBraceIndex = trimmedOutput.indexOf('{');
        int lastJsonBraceIndex = trimmedOutput.lastIndexOf('}');

        if (firstJsonBraceIndex < 0 || lastJsonBraceIndex < firstJsonBraceIndex) {
            return trimmedOutput;
        }

        return trimmedOutput.substring(firstJsonBraceIndex, lastJsonBraceIndex + 1);
    }

    private BigDecimal readRequiredDecimal(JsonNode root, String parentField, String childField) {
        JsonNode valueNode = root.path(parentField).path(childField);

        if (!valueNode.isNumber()) {
            throw new IllegalStateException(
                "O JSON retornado pelo Speedtest CLI da Ookla não contém `" + parentField + "." + childField + "`."
            );
        }

        return valueNode.decimalValue();
    }

    private BigDecimal readOptionalDecimal(JsonNode valueNode, BigDecimal fallback) {
        return valueNode.isNumber() ? valueNode.decimalValue() : fallback;
    }

    private BigDecimal toMbps(BigDecimal bandwidthBytesPerSecond) {
        return normalizeMetric(bandwidthBytesPerSecond.multiply(BITS_PER_BYTE).divide(ONE_MILLION, 6, RoundingMode.HALF_UP));
    }

    private BigDecimal normalizeMetric(BigDecimal value) {
        return value.setScale(2, RoundingMode.HALF_UP);
    }

    private String summarizeOutput(String output) {
        if (output == null || output.isBlank()) {
            return "sem detalhes na saída do processo.";
        }

        String normalizedOutput = output.replaceAll("\\s+", " ").trim();
        return normalizedOutput.length() <= 240 ? normalizedOutput : normalizedOutput.substring(0, 240) + "...";
    }
}
