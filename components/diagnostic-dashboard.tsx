"use client";

import Image from "next/image";
import { useEffect, useRef, useState } from "react";
import logo from "@/assets/logo-dark-theme.png";
import styles from "./diagnostic-dashboard.module.css";

const API_BASE_URL = process.env.NEXT_PUBLIC_API_BASE_URL?.trim() || "http://localhost:8080";
const SPEEDTEST_BASE_URL =
  process.env.NEXT_PUBLIC_SPEEDTEST_BASE_URL?.trim() || "https://infinitygo-speedtest.smecrowl9.workers.dev";

type ConnectionInfo = {
  effectiveType: string;
  downlink: string;
  rtt: string;
  saveData: string;
};

type DiagnosticPayload = {
  deviceType: string;
  operatingSystem: string;
  browser: string;
  browserVersion: string;
  language: string;
  timezone: string;
  platform: string | null;
  logicalCores: number | null;
  memoryGigabytes: number | null;
  connectionType: string;
  online: boolean;
  latencyMs: number | null;
  jitterMs: number | null;
  packetLossPercent: number | null;
  downloadMbps: number | null;
  uploadMbps: number | null;
};

type DiagnosticCreatedResponse = {
  id: string;
  createdAt: string;
};

type DiagnosticData = {
  deviceType: string;
  operatingSystem: string;
  browser: string;
  browserVersion: string;
  language: string;
  timezone: string;
  platform: string;
  logicalCores: string;
  memory: string;
  connectionType: string;
  onlineStatus: string;
  connectionDetails: ConnectionInfo;
};

type SpeedTestPayload = {
  provider: string;
  region: string | null;
  latencyMs: number;
  jitterMs: number;
  packetLossPercent: number;
  downloadMbps: number;
  uploadMbps: number;
};

type SpeedTestDisplay = {
  latencyMs: string;
  jitterMs: string;
  packetLossPercent: string;
  downloadMbps: string;
  uploadMbps: string;
  provider: string;
  region: string;
};

type CollectedDiagnostic = {
  display: DiagnosticData;
  payload: DiagnosticPayload;
};

type StatusItem = {
  label: string;
  tone: "pending" | "done" | "error";
};

const initialStatuses: StatusItem[] = [
  { label: "Coletando dados do dispositivo", tone: "pending" },
  { label: "Verificando status da conexão", tone: "pending" },
  { label: "Organizando o diagnóstico inicial", tone: "pending" },
  { label: "Aguardando persistência do diagnóstico", tone: "pending" }
];

const loadingMessages = [
  "Analisando a sua rede",
  "Lendo os dados do seu dispositivo",
  "Verificando o ambiente do navegador",
  "Preparando o diagnóstico inicial"
];

const initialData: DiagnosticData = {
  deviceType: "Aguardando coleta",
  operatingSystem: "Aguardando coleta",
  browser: "Aguardando coleta",
  browserVersion: "Aguardando coleta",
  language: "Aguardando coleta",
  timezone: "Aguardando coleta",
  platform: "Aguardando coleta",
  logicalCores: "Aguardando coleta",
  memory: "Aguardando coleta",
  connectionType: "Aguardando coleta",
  onlineStatus: "Aguardando coleta",
  connectionDetails: {
    effectiveType: "Indisponível",
    downlink: "Indisponível",
    rtt: "Indisponível",
    saveData: "Indisponível"
  }
};

const initialSpeedTestDisplay: SpeedTestDisplay = {
  latencyMs: "Aguardando teste",
  jitterMs: "Aguardando teste",
  packetLossPercent: "Aguardando teste",
  downloadMbps: "Aguardando teste",
  uploadMbps: "Aguardando teste",
  provider: "Aguardando teste",
  region: "Aguardando teste"
};

type NavigatorWithConnection = Navigator & {
  connection?: {
    effectiveType?: string;
    downlink?: number;
    rtt?: number;
    saveData?: boolean;
  };
  deviceMemory?: number;
};

type PersistenceState = "idle" | "saving" | "saved" | "error";
type SpeedTestState = "unavailable" | "idle" | "running" | "saving" | "saved" | "error";

function detectDeviceType(userAgent: string): string {
  if (/tablet|ipad/i.test(userAgent)) {
    return "Tablet";
  }

  if (/mobi|android|iphone/i.test(userAgent)) {
    return "Celular";
  }

  return "Desktop";
}

function detectOperatingSystem(userAgent: string): string {
  if (/windows nt/i.test(userAgent)) {
    return "Windows";
  }

  if (/android/i.test(userAgent)) {
    return "Android";
  }

  if (/iphone|ipad|ipod/i.test(userAgent)) {
    return "iOS";
  }

  if (/mac os x/i.test(userAgent)) {
    return "macOS";
  }

  if (/linux/i.test(userAgent)) {
    return "Linux";
  }

  return "Não identificado";
}

function detectBrowser(userAgent: string): { name: string; version: string } {
  const browserPatterns = [
    { name: "Edge", regex: /edg\/([\d.]+)/i },
    { name: "Opera", regex: /opr\/([\d.]+)/i },
    { name: "Chrome", regex: /chrome\/([\d.]+)/i },
    { name: "Firefox", regex: /firefox\/([\d.]+)/i },
    { name: "Safari", regex: /version\/([\d.]+).*safari/i }
  ];

  for (const browser of browserPatterns) {
    const match = userAgent.match(browser.regex);
    if (match) {
      return { name: browser.name, version: match[1] };
    }
  }

  return { name: "Não identificado", version: "Indisponível" };
}

function getRequiredText(value: string | null | undefined, fallback: string): string {
  const normalizedValue = value?.trim();

  return normalizedValue ? normalizedValue : fallback;
}

function getOptionalText(value: string | null | undefined): string | null {
  const normalizedValue = value?.trim();

  return normalizedValue ? normalizedValue : null;
}

function formatMemory(memory?: number): string {
  if (typeof memory !== "number") {
    return "Indisponível";
  }

  return `${memory} GB`;
}

function formatCores(cores?: number): string {
  if (typeof cores !== "number") {
    return "Indisponível";
  }

  return `${cores} núcleos lógicos`;
}

function formatConnectionDetails(navigatorObject: NavigatorWithConnection): ConnectionInfo {
  const connection = navigatorObject.connection;

  if (!connection) {
    return {
      effectiveType: "Indisponível",
      downlink: "Indisponível",
      rtt: "Indisponível",
      saveData: "Indisponível"
    };
  }

  return {
    effectiveType: connection.effectiveType ?? "Indisponível",
    downlink: typeof connection.downlink === "number" ? `${connection.downlink} Mb/s` : "Indisponível",
    rtt: typeof connection.rtt === "number" ? `${connection.rtt} ms` : "Indisponível",
    saveData: typeof connection.saveData === "boolean" ? (connection.saveData ? "Ativado" : "Desativado") : "Indisponível"
  };
}

function buildApiUrl(path: string): string {
  return `${API_BASE_URL.replace(/\/$/, "")}${path}`;
}

function buildSpeedTestUrl(path: string): string {
  return `${SPEEDTEST_BASE_URL.replace(/\/$/, "")}${path}`;
}

function buildStatuses(persistenceState: PersistenceState): StatusItem[] {
  return [
    { label: "Coletando dados do dispositivo", tone: "done" },
    { label: "Verificando status da conexão", tone: "done" },
    { label: "Organizando o diagnóstico inicial", tone: "done" },
    {
      label:
        persistenceState === "saved"
          ? "Diagnóstico salvo no backend"
          : persistenceState === "error"
            ? "Falha ao salvar o diagnóstico"
            : persistenceState === "saving"
              ? "Persistindo diagnóstico no backend"
              : "Aguardando persistência do diagnóstico",
      tone:
        persistenceState === "saved"
          ? "done"
          : persistenceState === "error"
            ? "error"
            : "pending"
    }
  ];
}

function collectDiagnostic(navigatorObject: NavigatorWithConnection): CollectedDiagnostic {
  const userAgent = navigatorObject.userAgent;
  const browser = detectBrowser(userAgent);
  const timezone = getRequiredText(Intl.DateTimeFormat().resolvedOptions().timeZone, "UTC");
  const connectionInfo = formatConnectionDetails(navigatorObject);
  const platform = getOptionalText(navigatorObject.platform);
  const logicalCores =
    typeof navigatorObject.hardwareConcurrency === "number" ? navigatorObject.hardwareConcurrency : null;
  const memoryGigabytes = typeof navigatorObject.deviceMemory === "number" ? navigatorObject.deviceMemory : null;
  const latencyMs = typeof navigatorObject.connection?.rtt === "number" ? navigatorObject.connection.rtt : null;
  const downloadMbps =
    typeof navigatorObject.connection?.downlink === "number" ? navigatorObject.connection.downlink : null;
  const deviceType = detectDeviceType(userAgent);
  const operatingSystem = detectOperatingSystem(userAgent);
  const language = getRequiredText(navigatorObject.language, "Não identificado");
  const connectionType = getRequiredText(connectionInfo.effectiveType, "Indisponível");

  return {
    display: {
      deviceType,
      operatingSystem,
      browser: browser.name,
      browserVersion: browser.version,
      language,
      timezone,
      platform: platform ?? "Indisponível",
      logicalCores: formatCores(logicalCores ?? undefined),
      memory: formatMemory(memoryGigabytes ?? undefined),
      connectionType,
      onlineStatus: navigatorObject.onLine ? "Online" : "Offline",
      connectionDetails: connectionInfo
    },
    payload: {
      deviceType,
      operatingSystem,
      browser: browser.name,
      browserVersion: browser.version,
      language,
      timezone,
      platform,
      logicalCores,
      memoryGigabytes,
      connectionType,
      online: navigatorObject.onLine,
      latencyMs,
      jitterMs: null,
      packetLossPercent: null,
      downloadMbps,
      uploadMbps: null
    }
  };
}

function getHeaderText(value: string | null): string | null {
  const normalizedValue = value?.trim();

  return normalizedValue ? normalizedValue : null;
}

function roundMetric(value: number): number {
  return Math.round(value * 100) / 100;
}

function calculateAverage(values: number[]): number {
  return values.reduce((sum, value) => sum + value, 0) / values.length;
}

function calculateJitter(latencySamples: number[]): number {
  if (latencySamples.length < 2) {
    return 0;
  }

  const deltas = latencySamples.slice(1).map((sample, index) => Math.abs(sample - latencySamples[index]));
  return calculateAverage(deltas);
}

function formatMetric(value: number, unit: string): string {
  return `${value.toFixed(2)} ${unit}`;
}

function toMbps(bytesTransferred: number, elapsedMs: number): number {
  if (elapsedMs <= 0) {
    return 0;
  }

  return (bytesTransferred * 8) / (elapsedMs / 1000) / 1_000_000;
}

async function fetchWithTimeout(
  input: RequestInfo | URL,
  init: RequestInit,
  timeoutMs: number,
  signal: AbortSignal
): Promise<Response> {
  const controller = new AbortController();
  const timeoutId = window.setTimeout(() => {
    controller.abort();
  }, timeoutMs);
  const abortHandler = () => {
    controller.abort();
  };

  if (signal.aborted) {
    controller.abort();
  } else {
    signal.addEventListener("abort", abortHandler, { once: true });
  }

  try {
    return await fetch(input, {
      ...init,
      cache: "no-store",
      signal: controller.signal
    });
  } finally {
    window.clearTimeout(timeoutId);
    signal.removeEventListener("abort", abortHandler);
  }
}

function buildCacheBustToken(): string {
  return `${Date.now()}-${Math.random().toString(36).slice(2, 10)}`;
}

function readSpeedTestMetadata(response: Response): { provider: string | null; region: string | null } {
  return {
    provider: getHeaderText(response.headers.get("x-speedtest-provider")),
    region: getHeaderText(response.headers.get("x-speedtest-region"))
  };
}

async function measurePingSample(
  signal: AbortSignal
): Promise<{ latencyMs: number; provider: string | null; region: string | null }> {
  const startedAt = performance.now();
  const response = await fetchWithTimeout(
    buildSpeedTestUrl(`/ping?cacheBust=${buildCacheBustToken()}`),
    { method: "GET" },
    3000,
    signal
  );

  if (!response.ok && response.status !== 204) {
    throw new Error(`Ping falhou com status ${response.status}`);
  }

  const elapsedMs = performance.now() - startedAt;
  const metadata = readSpeedTestMetadata(response);

  return {
    latencyMs: elapsedMs,
    provider: metadata.provider,
    region: metadata.region
  };
}

async function measureDownloadSample(
  bytes: number,
  signal: AbortSignal
): Promise<{ mbps: number; provider: string | null; region: string | null }> {
  const startedAt = performance.now();
  const response = await fetchWithTimeout(
    buildSpeedTestUrl(`/download?bytes=${bytes}&cacheBust=${buildCacheBustToken()}`),
    { method: "GET" },
    12000,
    signal
  );

  if (!response.ok) {
    throw new Error(`Download falhou com status ${response.status}`);
  }

  const metadata = readSpeedTestMetadata(response);
  const payload = await response.arrayBuffer();
  const elapsedMs = performance.now() - startedAt;

  return {
    mbps: toMbps(payload.byteLength, elapsedMs),
    provider: metadata.provider,
    region: metadata.region
  };
}

async function measureConcurrentDownloadSample(
  bytesPerRequest: number,
  parallelRequests: number,
  signal: AbortSignal
): Promise<{ mbps: number; provider: string | null; region: string | null }> {
  const startedAt = performance.now();
  const responses = await Promise.all(
    Array.from({ length: parallelRequests }, () =>
      fetchWithTimeout(
        buildSpeedTestUrl(`/download?bytes=${bytesPerRequest}&cacheBust=${buildCacheBustToken()}`),
        { method: "GET" },
        15000,
        signal
      )
    )
  );

  for (const response of responses) {
    if (!response.ok) {
      throw new Error(`Download falhou com status ${response.status}`);
    }
  }

  const firstMetadata = readSpeedTestMetadata(responses[0]);
  const payloads = await Promise.all(responses.map((response) => response.arrayBuffer()));
  const totalBytes = payloads.reduce((sum, payload) => sum + payload.byteLength, 0);
  const elapsedMs = performance.now() - startedAt;

  return {
    mbps: toMbps(totalBytes, elapsedMs),
    provider: firstMetadata.provider,
    region: firstMetadata.region
  };
}

async function measureUploadSample(
  bytes: number,
  signal: AbortSignal
): Promise<{ mbps: number; provider: string | null; region: string | null }> {
  const payload = new Uint8Array(bytes);
  const startedAt = performance.now();
  const response = await fetchWithTimeout(
    buildSpeedTestUrl(`/upload?cacheBust=${buildCacheBustToken()}`),
    {
      method: "POST",
      headers: {
        "Content-Type": "application/octet-stream"
      },
      body: payload
    },
    12000,
    signal
  );

  if (!response.ok) {
    throw new Error(`Upload falhou com status ${response.status}`);
  }

  const metadata = readSpeedTestMetadata(response);
  await response.text();
  const elapsedMs = performance.now() - startedAt;

  return {
    mbps: toMbps(payload.byteLength, elapsedMs),
    provider: metadata.provider,
    region: metadata.region
  };
}

async function measureConcurrentUploadSample(
  bytesPerRequest: number,
  parallelRequests: number,
  signal: AbortSignal
): Promise<{ mbps: number; provider: string | null; region: string | null }> {
  const payloads = Array.from({ length: parallelRequests }, () => new Uint8Array(bytesPerRequest));
  const startedAt = performance.now();
  const responses = await Promise.all(
    payloads.map((payload) =>
      fetchWithTimeout(
        buildSpeedTestUrl(`/upload?cacheBust=${buildCacheBustToken()}`),
        {
          method: "POST",
          headers: {
            "Content-Type": "application/octet-stream"
          },
          body: payload
        },
        15000,
        signal
      )
    )
  );

  for (const response of responses) {
    if (!response.ok) {
      throw new Error(`Upload falhou com status ${response.status}`);
    }
  }

  const firstMetadata = readSpeedTestMetadata(responses[0]);
  await Promise.all(responses.map((response) => response.text()));
  const totalBytes = payloads.reduce((sum, payload) => sum + payload.byteLength, 0);
  const elapsedMs = performance.now() - startedAt;

  return {
    mbps: toMbps(totalBytes, elapsedMs),
    provider: firstMetadata.provider,
    region: firstMetadata.region
  };
}

async function runSpeedTest(signal: AbortSignal): Promise<SpeedTestPayload> {
  const latencySamples: number[] = [];
  const downloadSamples: number[] = [];
  const uploadSamples: number[] = [];
  const totalPings = 8;
  let failedPings = 0;
  let provider: string | null = null;
  let region: string | null = null;

  for (let index = 0; index < totalPings; index += 1) {
    try {
      const sample = await measurePingSample(signal);
      latencySamples.push(sample.latencyMs);
      provider = provider ?? sample.provider;
      region = region ?? sample.region;
    } catch (error: unknown) {
      if (error instanceof DOMException && error.name === "AbortError") {
        throw error;
      }

      failedPings += 1;
    }
  }

  if (!latencySamples.length) {
    throw new Error("Não foi possível medir a latência com o endpoint configurado.");
  }

  for (const [bytesPerRequest, parallelRequests] of [
    [8_000_000, 3],
    [12_000_000, 4]
  ] as const) {
    const sample = await measureConcurrentDownloadSample(bytesPerRequest, parallelRequests, signal);
    downloadSamples.push(sample.mbps);
    provider = provider ?? sample.provider;
    region = region ?? sample.region;
  }

  for (const [bytesPerRequest, parallelRequests] of [
    [4_000_000, 3],
    [6_000_000, 4]
  ] as const) {
    const sample = await measureConcurrentUploadSample(bytesPerRequest, parallelRequests, signal);
    uploadSamples.push(sample.mbps);
    provider = provider ?? sample.provider;
    region = region ?? sample.region;
  }

  return {
    provider: provider ?? "edge-worker",
    region,
    latencyMs: roundMetric(calculateAverage(latencySamples)),
    jitterMs: roundMetric(calculateJitter(latencySamples)),
    packetLossPercent: roundMetric((failedPings / totalPings) * 100),
    downloadMbps: roundMetric(calculateAverage(downloadSamples)),
    uploadMbps: roundMetric(calculateAverage(uploadSamples))
  };
}

function buildSpeedTestDisplay(result: SpeedTestPayload): SpeedTestDisplay {
  return {
    latencyMs: formatMetric(result.latencyMs, "ms"),
    jitterMs: formatMetric(result.jitterMs, "ms"),
    packetLossPercent: `${result.packetLossPercent.toFixed(2)}%`,
    downloadMbps: formatMetric(result.downloadMbps, "Mb/s"),
    uploadMbps: formatMetric(result.uploadMbps, "Mb/s"),
    provider: result.provider,
    region: result.region ?? "Indisponível"
  };
}

async function persistDiagnostic(payload: DiagnosticPayload, signal: AbortSignal): Promise<DiagnosticCreatedResponse> {
  const response = await fetch(buildApiUrl("/api/diagnostics"), {
    method: "POST",
    headers: {
      "Content-Type": "application/json"
    },
    body: JSON.stringify(payload),
    signal
  });

  if (!response.ok) {
    throw new Error(`Falha ao persistir diagnóstico: ${response.status}`);
  }

  return (await response.json()) as DiagnosticCreatedResponse;
}

async function persistSpeedTestResult(
  diagnosticId: string,
  payload: SpeedTestPayload,
  signal: AbortSignal
): Promise<void> {
  const response = await fetch(buildApiUrl(`/api/diagnostics/${diagnosticId}/speedtest`), {
    method: "PATCH",
    headers: {
      "Content-Type": "application/json"
    },
    body: JSON.stringify(payload),
    signal
  });

  if (!response.ok) {
    throw new Error(`Falha ao persistir speedtest: ${response.status}`);
  }
}

export default function DiagnosticDashboard() {
  const [data, setData] = useState<DiagnosticData>(initialData);
  const [isLoading, setIsLoading] = useState(true);
  const [loadingMessageIndex, setLoadingMessageIndex] = useState(0);
  const [persistenceState, setPersistenceState] = useState<PersistenceState>("idle");
  const [diagnosticId, setDiagnosticId] = useState<string | null>(null);
  const [speedTestState, setSpeedTestState] = useState<SpeedTestState>(
    SPEEDTEST_BASE_URL ? "idle" : "unavailable"
  );
  const [speedTestDisplay, setSpeedTestDisplay] = useState<SpeedTestDisplay>(initialSpeedTestDisplay);
  const [speedTestHint, setSpeedTestHint] = useState(
    SPEEDTEST_BASE_URL
      ? "Quando você iniciar o teste, a medição real será feita contra o endpoint externo configurado e o resultado será salvo neste diagnóstico."
      : "Defina NEXT_PUBLIC_SPEEDTEST_BASE_URL para habilitar a medição real de download, upload, latência, jitter e perda."
  );
  const speedTestControllerRef = useRef<AbortController | null>(null);

  useEffect(() => {
    const abortController = new AbortController();
    const navigatorObject = window.navigator as NavigatorWithConnection;
    const collectedDiagnostic = collectDiagnostic(navigatorObject);

    setData(collectedDiagnostic.display);
    setPersistenceState("saving");

    persistDiagnostic(collectedDiagnostic.payload, abortController.signal)
      .then((response) => {
        setDiagnosticId(response.id);
        setPersistenceState("saved");
      })
      .catch((error: unknown) => {
        if (error instanceof DOMException && error.name === "AbortError") {
          return;
        }

        setPersistenceState("error");
      });

    const loadingTimeout = window.setTimeout(() => {
      setIsLoading(false);
    }, 3400);

    return () => {
      abortController.abort();
      speedTestControllerRef.current?.abort();
      window.clearTimeout(loadingTimeout);
    };
  }, []);

  useEffect(() => {
    if (!isLoading) {
      return;
    }

    const interval = window.setInterval(() => {
      setLoadingMessageIndex((currentIndex) => (currentIndex + 1) % loadingMessages.length);
    }, 850);

    return () => window.clearInterval(interval);
  }, [isLoading]);

  const statuses = persistenceState === "idle" ? initialStatuses : buildStatuses(persistenceState);
  const rows = [
    { label: "Tipo de dispositivo", value: data.deviceType },
    { label: "Sistema operacional", value: data.operatingSystem },
    { label: "Navegador", value: data.browser },
    { label: "Versão do navegador", value: data.browserVersion },
    { label: "Idioma", value: data.language },
    { label: "Fuso horário", value: data.timezone },
    { label: "Plataforma reportada", value: data.platform },
    { label: "CPU", value: data.logicalCores },
    { label: "Memória aproximada do navegador", value: data.memory },
    { label: "Qualidade estimada da rede", value: data.connectionType },
    { label: "Downlink estimado pelo navegador", value: data.connectionDetails.downlink },
    { label: "RTT estimado pelo navegador", value: data.connectionDetails.rtt }
  ];

  const summaryItems = [
    { label: "Dispositivo", value: data.deviceType },
    { label: "Qualidade estimada", value: data.connectionType },
    { label: "Navegador", value: data.browser }
  ];
  const persistenceBadgeLabel =
    persistenceState === "saved"
      ? "Salvo no backend"
      : persistenceState === "error"
        ? "Falha ao persistir"
        : persistenceState === "saving"
          ? "Persistindo no backend"
          : "Preparando envio";
  const persistenceHint =
    persistenceState === "saved"
      ? "O diagnóstico inicial foi persistido com sucesso e já pode ser consultado no backend."
      : persistenceState === "error"
        ? "Não foi possível persistir o diagnóstico automaticamente. Verifique se o backend está ativo e se NEXT_PUBLIC_API_BASE_URL aponta para a API correta."
        : persistenceState === "saving"
          ? "Enviando o diagnóstico coletado para o backend da InfinityGo."
          : "O envio automático será iniciado assim que a coleta inicial terminar.";
  const speedTestBadgeLabel =
    speedTestState === "saved"
      ? "Resultado salvo"
      : speedTestState === "error"
        ? "Falha no teste"
        : speedTestState === "saving"
          ? "Salvando medição"
          : speedTestState === "running"
            ? "Executando teste"
            : speedTestState === "unavailable"
              ? "Configuração pendente"
              : "Pronto para iniciar";
  const speedTestActionLabel =
    speedTestState === "running" || speedTestState === "saving"
      ? "Executando..."
      : speedTestState === "saved"
        ? "Executar novamente"
        : "Iniciar speedtest";
  const isSpeedTestButtonDisabled =
    speedTestState === "unavailable" ||
    speedTestState === "running" ||
    speedTestState === "saving" ||
    !diagnosticId;
  const speedTestRows = [
    { label: "Latência real", value: speedTestDisplay.latencyMs },
    { label: "Jitter", value: speedTestDisplay.jitterMs },
    { label: "Perda de pacote", value: speedTestDisplay.packetLossPercent },
    { label: "Download real", value: speedTestDisplay.downloadMbps },
    { label: "Upload real", value: speedTestDisplay.uploadMbps },
    { label: "Ponto de medição", value: speedTestDisplay.region },
    { label: "Origem da medição", value: speedTestDisplay.provider }
  ];

  async function handleSpeedTest(): Promise<void> {
    if (!diagnosticId || !SPEEDTEST_BASE_URL || speedTestState === "running" || speedTestState === "saving") {
      return;
    }

    speedTestControllerRef.current?.abort();
    const controller = new AbortController();
    speedTestControllerRef.current = controller;

    setSpeedTestState("running");
    setSpeedTestHint("Executando a medição real no endpoint externo configurado. Isso pode levar alguns segundos.");

    try {
      const result = await runSpeedTest(controller.signal);

      setSpeedTestDisplay(buildSpeedTestDisplay(result));
      setSpeedTestState("saving");
      setSpeedTestHint("Medição concluída. Persistindo o resultado real no backend da InfinityGo.");

      await persistSpeedTestResult(diagnosticId, result, controller.signal);

      setSpeedTestState("saved");
      setSpeedTestHint("O resultado do speedtest foi salvo neste diagnóstico e pode ser consultado no backend.");
    } catch (error: unknown) {
      if (error instanceof DOMException && error.name === "AbortError") {
        return;
      }

      setSpeedTestState("error");
      setSpeedTestHint(
        "Não foi possível concluir o speedtest. Verifique o endpoint configurado em NEXT_PUBLIC_SPEEDTEST_BASE_URL e tente novamente."
      );
    } finally {
      speedTestControllerRef.current = null;
    }
  }

  return (
    <>
      <div className={`${styles.loadingScreen} ${!isLoading ? styles.loadingScreenHidden : ""}`}>
        <div className={styles.loadingBackdrop} />
        <div className={styles.loadingPanel}>
          <Image src={logo} alt="InfinityGo Telecomunicações" priority className={styles.loadingLogo} />
          <p className={styles.loadingKicker}>InfinityGo</p>
          <div className={styles.loadingTitleViewport}>
            <h2 key={loadingMessageIndex} className={styles.loadingTitle}>
              {loadingMessages[loadingMessageIndex]}
            </h2>
          </div>
          <p className={styles.loadingDescription}>
            Estamos coletando os primeiros sinais da sua conexão para deixar o diagnóstico pronto em
            instantes.
          </p>
          <div className={styles.loadingBar}>
            <span className={styles.loadingBarFill} />
          </div>
        </div>
      </div>

      <main className={`${styles.page} ${!isLoading ? styles.pageVisible : ""}`}>
        <section className={styles.hero}>
          <div className={styles.brandRow}>
            <Image src={logo} alt="InfinityGo Telecomunicações" priority className={styles.logo} />
            <div className={styles.brandMeta}>
              <p className={styles.kicker}>Experiência premium de diagnóstico</p>
              <div className={styles.rule} />
            </div>
          </div>

          <div className={styles.heroCopy}>
            <p className={styles.heroLead}>Diagnóstico inicial</p>
            <h1 className={styles.title}>Sua conexão analisada assim que a página abre.</h1>
            <p className={styles.description}>
              Reunimos os sinais essenciais do seu dispositivo e da sua conexão em uma experiência
              discreta, rápida e pronta para apoiar o atendimento da InfinityGo.
            </p>
          </div>

          <div className={styles.summaryRow}>
            {summaryItems.map((item, index) => (
              <article
                key={item.label}
                className={styles.summaryCard}
                style={{ animationDelay: `${0.18 + index * 0.08}s` }}
              >
                <span className={styles.summaryLabel}>{item.label}</span>
                <strong className={styles.summaryValue}>{item.value}</strong>
              </article>
            ))}
          </div>

          <div className={styles.statusPanel}>
            <div className={styles.statusHeader}>
              <span className={styles.statusHeaderLabel}>Fluxo ativo</span>
              <span className={styles.statusHeaderLine} />
            </div>
            {statuses.map((item, index) => (
              <div
                key={item.label}
                className={styles.statusItem}
                style={{ animationDelay: `${0.25 + index * 0.12}s` }}
              >
                <span
                  className={
                    item.tone === "done"
                      ? styles.statusDotDone
                      : item.tone === "error"
                        ? styles.statusDotError
                        : styles.statusDot
                  }
                />
                <span>{item.label}</span>
              </div>
            ))}
            <p
              className={
                persistenceState === "saved"
                  ? `${styles.persistenceHint} ${styles.persistenceHintSuccess}`
                  : persistenceState === "error"
                    ? `${styles.persistenceHint} ${styles.persistenceHintError}`
                    : styles.persistenceHint
              }
            >
              {persistenceHint}
            </p>
          </div>
        </section>

        <section className={styles.resultsCard}>
          <div className={styles.cardHeader}>
            <div>
              <p className={styles.cardEyebrow}>Coleta automática</p>
              <h2 className={styles.cardTitle}>Ambiente detectado</h2>
            </div>
            <div
              className={
                persistenceState === "saved"
                  ? `${styles.liveBadge} ${styles.liveBadgeSuccess}`
                  : persistenceState === "error"
                    ? `${styles.liveBadge} ${styles.liveBadgeError}`
                    : styles.liveBadge
              }
            >
              {persistenceBadgeLabel}
            </div>
          </div>

          <div className={styles.grid}>
            {rows.map((row, index) => (
              <article
                key={row.label}
                className={styles.dataTile}
                style={{ animationDelay: `${0.3 + index * 0.05}s` }}
              >
                <span className={styles.dataLabel}>{row.label}</span>
                <strong className={styles.dataValue}>{row.value}</strong>
              </article>
            ))}
          </div>

          <div className={styles.notice}>
            Os dados acima dependem do suporte do navegador e incluem estimativas fornecidas pelo próprio
            browser. Informações mais profundas da rede e testes de velocidade entram nas próximas etapas.
          </div>

          <section className={styles.speedTestSection}>
            <div className={styles.speedTestHeader}>
              <div className={styles.speedTestCopy}>
                <p className={styles.cardEyebrow}>Medição real</p>
                <h3 className={styles.speedTestTitle}>Speedtest controlado pelo seu site</h3>
              </div>
              <div
                className={
                  speedTestState === "saved"
                    ? `${styles.speedTestBadge} ${styles.speedTestBadgeSuccess}`
                    : speedTestState === "error"
                      ? `${styles.speedTestBadge} ${styles.speedTestBadgeError}`
                      : speedTestState === "unavailable"
                        ? `${styles.speedTestBadge} ${styles.speedTestBadgeMuted}`
                        : styles.speedTestBadge
                }
              >
                {speedTestBadgeLabel}
              </div>
            </div>

            <div className={styles.speedTestActionRow}>
              <p className={styles.speedTestDescription}>{speedTestHint}</p>
              <button
                type="button"
                className={isSpeedTestButtonDisabled ? styles.speedTestButtonDisabled : styles.speedTestButton}
                onClick={() => {
                  void handleSpeedTest();
                }}
                disabled={isSpeedTestButtonDisabled}
              >
                {speedTestActionLabel}
              </button>
            </div>

            <div className={styles.speedTestGrid}>
              {speedTestRows.map((row, index) => (
                <article
                  key={row.label}
                  className={styles.speedTestTile}
                  style={{ animationDelay: `${0.36 + index * 0.04}s` }}
                >
                  <span className={styles.dataLabel}>{row.label}</span>
                  <strong className={styles.dataValue}>{row.value}</strong>
                </article>
              ))}
            </div>
          </section>
        </section>
      </main>
    </>
  );
}
