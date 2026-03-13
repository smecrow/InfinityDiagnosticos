"use client";

import Image from "next/image";
import { useEffect, useRef, useState } from "react";
import logo from "@/assets/logo-dark-theme.png";
import styles from "./diagnostic-dashboard.module.css";

const API_BASE_URL = process.env.NEXT_PUBLIC_API_BASE_URL?.trim() || "http://localhost:8080";

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
type SpeedTestState = "idle" | "running" | "saved" | "error";

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

function formatMetric(value: number, unit: string): string {
  return `${value.toFixed(2)} ${unit}`;
}

function waitForDelay(delayMs: number, signal: AbortSignal): Promise<void> {
  return new Promise((resolve, reject) => {
    const timeoutId = window.setTimeout(() => {
      signal.removeEventListener("abort", abortHandler);
      resolve();
    }, delayMs);

    const abortHandler = () => {
      window.clearTimeout(timeoutId);
      reject(new DOMException("Operação cancelada", "AbortError"));
    };

    if (signal.aborted) {
      abortHandler();
      return;
    }

    signal.addEventListener("abort", abortHandler, { once: true });
  });
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

async function persistDiagnosticWithRetry(
  payload: DiagnosticPayload,
  signal: AbortSignal
): Promise<DiagnosticCreatedResponse> {
  const maxAttempts = 8;
  const retryDelayMs = 2000;
  let lastError: unknown;

  for (let attempt = 1; attempt <= maxAttempts; attempt += 1) {
    try {
      return await persistDiagnostic(payload, signal);
    } catch (error: unknown) {
      if (error instanceof DOMException && error.name === "AbortError") {
        throw error;
      }

      lastError = error;

      if (attempt === maxAttempts) {
        throw lastError;
      }

      await waitForDelay(retryDelayMs, signal);
    }
  }

  throw lastError ?? new Error("Falha ao persistir diagnóstico.");
}

async function executeSpeedTest(diagnosticId: string, signal: AbortSignal): Promise<SpeedTestPayload> {
  const response = await fetch(buildApiUrl(`/api/diagnostics/${diagnosticId}/speedtest`), {
    method: "POST",
    signal
  });

  if (!response.ok) {
    throw new Error(`Falha ao executar speedtest: ${response.status}`);
  }

  return (await response.json()) as SpeedTestPayload;
}

export default function DiagnosticDashboard() {
  const [data, setData] = useState<DiagnosticData>(initialData);
  const [isLoading, setIsLoading] = useState(true);
  const [loadingMessageIndex, setLoadingMessageIndex] = useState(0);
  const [persistenceState, setPersistenceState] = useState<PersistenceState>("idle");
  const [diagnosticId, setDiagnosticId] = useState<string | null>(null);
  const [speedTestState, setSpeedTestState] = useState<SpeedTestState>("idle");
  const [speedTestDisplay, setSpeedTestDisplay] = useState<SpeedTestDisplay>(initialSpeedTestDisplay);
  const [speedTestHint, setSpeedTestHint] = useState(
    "Quando você iniciar o teste, o backend executará o Speedtest CLI da Ookla no servidor da InfinityGO em Caldas Novas/GO e salvará o resultado neste diagnóstico."
  );
  const speedTestControllerRef = useRef<AbortController | null>(null);

  useEffect(() => {
    const abortController = new AbortController();
    const navigatorObject = window.navigator as NavigatorWithConnection;
    const collectedDiagnostic = collectDiagnostic(navigatorObject);

    setData(collectedDiagnostic.display);
    setPersistenceState("saving");

    persistDiagnosticWithRetry(collectedDiagnostic.payload, abortController.signal)
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
        : speedTestState === "running"
          ? "Executando teste"
          : "Pronto para iniciar";
  const speedTestActionLabel =
    speedTestState === "running"
      ? "Executando..."
      : speedTestState === "saved"
        ? "Executar novamente"
        : "Iniciar speedtest";
  const isSpeedTestButtonDisabled = speedTestState === "running" || !diagnosticId;
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
    if (!diagnosticId || speedTestState === "running") {
      return;
    }

    speedTestControllerRef.current?.abort();
    const controller = new AbortController();
    speedTestControllerRef.current = controller;

    setSpeedTestState("running");
    setSpeedTestHint("Executando o Speedtest CLI da Ookla no backend contra o servidor da InfinityGO. Isso pode levar alguns segundos.");

    try {
      const result = await executeSpeedTest(diagnosticId, controller.signal);

      setSpeedTestDisplay(buildSpeedTestDisplay(result));
      setSpeedTestState("saved");
      setSpeedTestHint("O resultado do speedtest foi salvo neste diagnóstico e pode ser consultado no backend.");
    } catch (error: unknown) {
      if (error instanceof DOMException && error.name === "AbortError") {
        return;
      }

      setSpeedTestState("error");
      if (error instanceof Error && error.message.startsWith("Falha ao executar speedtest")) {
        setSpeedTestHint(
          "Não foi possível concluir o speedtest. Verifique se o backend está ativo e se o Speedtest CLI da Ookla está disponível no ambiente."
        );
      } else {
        setSpeedTestHint("Não foi possível concluir o speedtest neste momento. Tente novamente em alguns instantes.");
      }
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
