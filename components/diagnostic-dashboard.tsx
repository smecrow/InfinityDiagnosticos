"use client";

import Image from "next/image";
import { useEffect, useState } from "react";
import logo from "@/assets/logo-dark-theme.png";
import styles from "./diagnostic-dashboard.module.css";

type ConnectionInfo = {
  effectiveType: string;
  downlink: string;
  rtt: string;
  saveData: string;
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

type StatusItem = {
  label: string;
  done: boolean;
};

const initialStatuses: StatusItem[] = [
  { label: "Coletando dados do dispositivo", done: false },
  { label: "Verificando status da conexão", done: false },
  { label: "Organizando o diagnóstico inicial", done: false }
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

type NavigatorWithConnection = Navigator & {
  connection?: {
    effectiveType?: string;
    downlink?: number;
    rtt?: number;
    saveData?: boolean;
  };
  deviceMemory?: number;
};

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

function formatMemory(memory?: number): string {
  if (!memory) {
    return "Indisponível";
  }

  return `${memory} GB`;
}

function formatCores(cores?: number): string {
  if (!cores) {
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

export default function DiagnosticDashboard() {
  const [statuses, setStatuses] = useState(initialStatuses);
  const [data, setData] = useState<DiagnosticData>(initialData);
  const [isLoading, setIsLoading] = useState(true);
  const [loadingMessageIndex, setLoadingMessageIndex] = useState(0);

  useEffect(() => {
    const navigatorObject = window.navigator as NavigatorWithConnection;
    const userAgent = navigatorObject.userAgent;
    const browser = detectBrowser(userAgent);
    const timezone = Intl.DateTimeFormat().resolvedOptions().timeZone;
    const connectionInfo = formatConnectionDetails(navigatorObject);

    setStatuses([
      { label: "Coletando dados do dispositivo", done: true },
      { label: "Verificando status da conexão", done: true },
      { label: "Organizando o diagnóstico inicial", done: true }
    ]);

    setData({
      deviceType: detectDeviceType(userAgent),
      operatingSystem: detectOperatingSystem(userAgent),
      browser: browser.name,
      browserVersion: browser.version,
      language: navigatorObject.language || "Indisponível",
      timezone: timezone || "Indisponível",
      platform: navigatorObject.platform || "Indisponível",
      logicalCores: formatCores(navigatorObject.hardwareConcurrency),
      memory: formatMemory(navigatorObject.deviceMemory),
      connectionType: connectionInfo.effectiveType,
      onlineStatus: navigatorObject.onLine ? "Online" : "Offline",
      connectionDetails: connectionInfo
    });

    const loadingTimeout = window.setTimeout(() => {
      setIsLoading(false);
    }, 3400);

    return () => window.clearTimeout(loadingTimeout);
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

  const rows = [
    { label: "Tipo de dispositivo", value: data.deviceType },
    { label: "Sistema operacional", value: data.operatingSystem },
    { label: "Navegador", value: data.browser },
    { label: "Versão do navegador", value: data.browserVersion },
    { label: "Idioma", value: data.language },
    { label: "Fuso horário", value: data.timezone },
    { label: "Plataforma reportada", value: data.platform },
    { label: "CPU", value: data.logicalCores },
    { label: "Memória RAM", value: data.memory },
    { label: "Conexão reportada", value: data.connectionType },
    { label: "Status online", value: data.onlineStatus },
    { label: "Downlink reportado", value: data.connectionDetails.downlink },
    { label: "RTT reportado", value: data.connectionDetails.rtt },
    { label: "Economia de dados", value: data.connectionDetails.saveData }
  ];

  const summaryItems = [
    { label: "Status", value: data.onlineStatus },
    { label: "Conexão", value: data.connectionType },
    { label: "Navegador", value: data.browser }
  ];

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
                <span className={item.done ? styles.statusDotDone : styles.statusDot} />
                <span>{item.label}</span>
              </div>
            ))}
          </div>
        </section>

        <section className={styles.resultsCard}>
          <div className={styles.cardHeader}>
            <div>
              <p className={styles.cardEyebrow}>Coleta automática</p>
              <h2 className={styles.cardTitle}>Ambiente detectado</h2>
            </div>
            <div className={styles.liveBadge}>Atualizado agora</div>
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
            Os dados acima dependem do suporte do navegador. Informações mais profundas da rede e testes de
            velocidade entram nas próximas etapas.
          </div>
        </section>
      </main>
    </>
  );
}
