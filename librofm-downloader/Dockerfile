# ===== Bouwfase (Build Stage) =====
# Base image met JDK 21 op Alpine voor de bouw
FROM eclipse-temurin:21-alpine AS build

# Omgevingsvariabelen voor Gradle optimalisaties
ENV GRADLE_OPTS="-Dorg.gradle.daemon=false -Dkotlin.incremental=true -Dorg.gradle.parallel=true -Dorg.gradle.caching=true"
WORKDIR /app

# Kopieer eerst de build-configuratie voor betere Docker layer caching
COPY gradlew settings.gradle.kts build.gradle.kts gradle.properties ./
COPY gradle ./gradle

# Zorg dat gradlew uitvoerbaar is
RUN chmod +x gradlew

# Controleer Gradle versie (optioneel, goede praktijk)
RUN ./gradlew --version

# Download dependencies met BuildKit cache mount (vereist Docker BuildKit)
RUN --mount=type=cache,target=/root/.gradle ./gradlew dependencies --no-daemon --stacktrace

# Kopieer de broncode van de server module
COPY server ./server

# Bouw het project en maak de distributie (installDist) met cache mount
RUN --mount=type=cache,target=/root/.gradle ./gradlew :server:installDist --no-daemon

# ===== Runtimefase (Runtime Stage) =====
# BELANGRIJK: Argument voor de Home Assistant basis image
ARG BUILD_FROM
# Gebruik de basis image die door de HA Supervisor wordt aangeleverd via BUILD_FROM
FROM ${BUILD_FROM}

# Metadata - Normaal gesproken beheerd via config.yaml/json in HA add-ons
LABEL maintainer="Vishnu Rajeevan <github@vishnu.email>"

# Installeer runtime dependencies. jq is handig voor het lezen van /data/options.json.
# Controleer of de base image deze al bevat, maar expliciet is veiliger.
RUN apk add --no-cache \
    bash \
    curl \
    ffmpeg \
    tini \
    jq \
 && rm -rf /var/cache/* \
 && mkdir -p /var/cache/apk # -p voorkomt fouten als de map al bestaat

# Standaard omgevingsvariabelen. Deze kunnen/moeten worden overschreven
# door waarden uit /data/options.json in het run.sh script.
ENV \
    LIBRO_FM_USERNAME="" \
    LIBRO_FM_PASSWORD="" \
    DRY_RUN="false" \
    VERBOSE="false" \
    FORMAT="MP3" \
    RENAME_CHAPTERS="false" \
    WRITE_TITLE_TAG="false" \
    DEV_MODE="false" \
    SYNC_INTERVAL="d" \
    AUDIO_QUALITY="128k"

WORKDIR /app

# Kopieer het startscript en maak het uitvoerbaar
COPY scripts/run.sh ./
RUN chmod +x /app/run.sh

# Kopieer de gebouwde applicatie distributie uit de bouwfase
# De inhoud van server/build/install/server wordt naar /app/server gekopieerd
COPY --from=build /app/server/build/install/server ./server

# Gebruik tini als het entrypoint om signalen correct af te handelen
ENTRYPOINT ["/sbin/tini", "--"]

# Voer het run.sh script uit. Dit script moet de configuratie laden
# en de uiteindelijke Java applicatie starten (bv. /app/server/bin/server).
CMD ["/app/run.sh"]