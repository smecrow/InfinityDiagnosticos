FROM maven:3.9.9-eclipse-temurin-21 AS build

WORKDIR /app

COPY pom.xml ./
COPY .mvn ./.mvn
RUN mvn -B -q -DskipTests dependency:go-offline

COPY src ./src
RUN mvn -B -DskipTests package

FROM eclipse-temurin:21-jre

WORKDIR /app

RUN apt-get update \
    && apt-get install -y --no-install-recommends curl ca-certificates \
    && arch="$(dpkg --print-architecture)" \
    && case "$arch" in \
        amd64|arm64) ;; \
        *) echo "Arquitetura sem pacote oficial validado para Ookla CLI: $arch" >&2; exit 1 ;; \
       esac \
    && curl -fsSL \
        "https://packagecloud.io/ookla/speedtest-cli/packages/ubuntu/jammy/speedtest_1.2.0.84-1.ea6b6773cf_${arch}.deb/download.deb?distro_version_id=237" \
        -o /tmp/speedtest.deb \
    && apt-get install -y --no-install-recommends /tmp/speedtest.deb \
    && rm -f /tmp/speedtest.deb \
    && rm -rf /var/lib/apt/lists/*

COPY --from=build /app/target/*.jar app.jar

EXPOSE 8080

ENTRYPOINT ["sh", "-c", "java -jar /app/app.jar --spring.profiles.active=${SPRING_PROFILES_ACTIVE:-postgres}"]
