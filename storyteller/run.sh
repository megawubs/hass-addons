#!/usr/bin/env bash
# ==============================================================================
# Translate the Home Assistant add-on options into the environment variables
# Storyteller expects, then hand off to upstream's entrypoint.
# ==============================================================================
set -euo pipefail

readonly OPTIONS="/data/options.json"
readonly SECRET_KEY_FILE="/data/secret_key"
readonly USER_CONFIG="/config/storyteller.json"

log() { echo "[storyteller] $*"; }

option() {
    local key="${1}" default="${2-}"
    if [[ ! -f "${OPTIONS}" ]]; then
        echo "${default}"
        return
    fi
    jq -r --arg default "${default}" ".${key} // \$default" "${OPTIONS}"
}

# Storyteller signs the auth tokens that the mobile apps hold on to with this
# key, and since web-v2 it exits on startup when the key is missing. Generate
# one on first start and keep it in /data: regenerating it on every boot would
# sign everybody out, and it needs to survive add-on updates.
secret_key="$(option secret_key "")"
if [[ -n "${secret_key}" ]]; then
    printf '%s' "${secret_key}" > "${SECRET_KEY_FILE}"
elif [[ ! -s "${SECRET_KEY_FILE}" ]]; then
    log "No secret key configured, generating one."
    printf '%s' "$(head -c 32 /dev/urandom | base64)" > "${SECRET_KEY_FILE}"
fi
chmod 600 "${SECRET_KEY_FILE}"
export STORYTELLER_SECRET_KEY_FILE="${SECRET_KEY_FILE}"

# Upstream drops privileges to an unprivileged "storyteller" user by default.
# Home Assistant mounts /media, /share and the add-on config folder as root, and
# upstream deliberately refuses to chown anything outside its own data
# directory, so that user could not write to them. PUID=0 keeps the process
# running as root, which is the norm for add-ons and matches how this add-on
# behaved before.
export PUID=0
export PGID=0

# /data is the add-on's persistent volume, and is where every previous version
# of this add-on stored its library and database.
export STORYTELLER_DATA_DIR="/data"

log_level="$(option log_level info)"
export STORYTELLER_LOG_LEVEL="${log_level}"

# Storyteller coerces this one with Boolean(), which makes the *string* "false"
# truthy, so the variable has to stay unset unless the option is really on.
if [[ "$(option enable_web_reader false)" == "true" ]]; then
    log "Enabling the experimental web reader."
    export ENABLE_WEB_READER="true"
fi

auth_url="$(option auth_url "")"
if [[ -n "${auth_url}" ]]; then
    export AUTH_URL="${auth_url}"
fi

# Escape hatch for settings the add-on options do not cover: drop a JSON file in
# the add-on's config folder and Storyteller applies it on top of (and locked
# against) whatever is configured in its own UI.
if [[ -f "${USER_CONFIG}" ]]; then
    log "Found ${USER_CONFIG}, applying it on top of the UI settings."
    export STORYTELLER_CONFIG="${USER_CONFIG}"
fi

log "Starting Storyteller."
exec /usr/local/bin/entrypoint.sh "$@"
