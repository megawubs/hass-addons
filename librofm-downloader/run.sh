#!/bin/bash
# Gebruik bash voor wat meer scripting gemak, zorg dat 'bash' en 'jq'
# zijn toegevoegd in de Dockerfile (dat hebben we gedaan).

echo "[INFO] Starting Libro.fm Sync Add-on..."

# Controleer of het configuratiebestand bestaat
CONFIG_PATH=/data/options.json
if [ ! -f "$CONFIG_PATH" ]; then
    echo "[ERROR] Configuration file $CONFIG_PATH not found. Exiting."
    exit 1
fi

# --- Configuratie Lezen ---
# Lees waarden uit options.json met jq. Gebruik 'empty' of een default als fallback.
# Voor verplichte velden, controleer of ze bestaan.

LIBRO_FM_USERNAME=$(jq --raw-output '.libro_fm_username // empty' "$CONFIG_PATH")
LIBRO_FM_PASSWORD=$(jq --raw-output '.libro_fm_password // empty' "$CONFIG_PATH")

# Valideer verplichte velden
if [ -z "$LIBRO_FM_USERNAME" ]; then
    echo "[ERROR] 'libro_fm_username' is required but not set in the configuration."
    exit 1
fi
if [ -z "$LIBRO_FM_PASSWORD" ]; then
    echo "[ERROR] 'libro_fm_password' is required but not set in the configuration."
    exit 1
fi

# Exporteer de variabelen zodat de Java/Kotlin applicatie ze kan lezen
export LIBRO_FM_USERNAME
export LIBRO_FM_PASSWORD

# Lees optionele velden, gebruik de ENV defaults uit de Dockerfile als fallback
# De 'env.VAR' syntax in jq vereist dat de ENV var bestaat (wat het doet door de Dockerfile)
export DRY_RUN=$(jq --raw-output '.dry_run // env.DRY_RUN' "$CONFIG_PATH")
export VERBOSE=$(jq --raw-output '.verbose // env.VERBOSE' "$CONFIG_PATH")
export FORMAT=$(jq --raw-output '.format // env.FORMAT' "$CONFIG_PATH")
export RENAME_CHAPTERS=$(jq --raw-output '.rename_chapters // env.RENAME_CHAPTERS' "$CONFIG_PATH")
export WRITE_TITLE_TAG=$(jq --raw-output '.write_title_tag // env.WRITE_TITLE_TAG' "$CONFIG_PATH")
export DEV_MODE=$(jq --raw-output '.dev_mode // env.DEV_MODE' "$CONFIG_PATH")
export SYNC_INTERVAL=$(jq --raw-output '.sync_interval // env.SYNC_INTERVAL' "$CONFIG_PATH")
export AUDIO_QUALITY=$(jq --raw-output '.audio_quality // env.AUDIO_QUALITY' "$CONFIG_PATH")

# --- Configuratie Loggen (Optioneel) ---
# Wees voorzichtig met het loggen van gevoelige informatie zoals wachtwoorden!
echo "[INFO] Add-on configuration loaded:"
echo "[INFO] - Username: ${LIBRO_FM_USERNAME}"
echo "[INFO] - Dry Run: ${DRY_RUN}"
echo "[INFO] - Verbose: ${VERBOSE}"
echo "[INFO] - Format: ${FORMAT}"
echo "[INFO] - Rename Chapters: ${RENAME_CHAPTERS}"
echo "[INFO] - Write Title Tag: ${WRITE_TITLE_TAG}"
echo "[INFO] - Dev Mode: ${DEV_MODE}"
echo "[INFO] - Sync Interval: ${SYNC_INTERVAL}"
echo "[INFO] - Audio Quality: ${AUDIO_QUALITY}"

# --- Applicatie Starten ---
# Gebruik 'exec' om de shell te vervangen door het server process.
# Gebruik het correcte pad naar het script dat door 'installDist' is gegenereerd.
echo "[INFO] Executing server process..."
exec /app/server/bin/server run "$@"

# "$@" geeft eventuele argumenten door die aan run.sh zijn meegegeven (normaal geen).