#!/bin/bash
set -euo pipefail

CONFIG_PATH="/data/options.json"

if [ ! -f "$CONFIG_PATH" ]; then
    echo "[bookclerk] ERROR: no config file found at $CONFIG_PATH"
    exit 1
fi

echo "[bookclerk] Reading configuration from Home Assistant"

AUTH_PASSWORD=$(jq -r '.auth_password // ""' "$CONFIG_PATH")
AUTO_ACQUIRE=$(jq -r '.auto_acquire // false' "$CONFIG_PATH")
OUTPUT_PATH=$(jq -r '.output_path // "Audiobooks"' "$CONFIG_PATH")
LOG_LEVEL=$(jq -r '.log_level // "info"' "$CONFIG_PATH")
PLUGIN_ISOLATION=$(jq -r '.plugin_isolation // "best-effort"' "$CONFIG_PATH")
GA_ACCESS=$(jq -r '.graphicaudio_access // "web"' "$CONFIG_PATH")
ABS_HOST=$(jq -r '.audiobookshelf_host // ""' "$CONFIG_PATH")
ABS_API_KEY=$(jq -r '.audiobookshelf_api_key // ""' "$CONFIG_PATH")

if [ -z "$AUTH_PASSWORD" ]; then
    echo "[bookclerk] ERROR: the 'auth_password' option is required — it protects the operator API (bound to 0.0.0.0 here) and encrypts stored source credentials at rest."
    exit 1
fi

export BOOKCLERK_AUTH_PASSWORD="$AUTH_PASSWORD"
# output_path may already be an absolute /media/... path (e.g. copy-pasted
# from the media share browser) — don't double-prefix it in that case.
if [[ "$OUTPUT_PATH" = /* ]]; then
    export BOOKCLERK_OUTPUT_LOCAL_ROOT="$OUTPUT_PATH"
else
    export BOOKCLERK_OUTPUT_LOCAL_ROOT="/media/${OUTPUT_PATH}"
fi
export BOOKCLERK_LOG="$LOG_LEVEL"
export RUST_LOG="$LOG_LEVEL"
export BOOKCLERK_GA_ACCESS="$GA_ACCESS"
export BOOKCLERK_PLUGIN_ISOLATION="$PLUGIN_ISOLATION"
export BOOKCLERK_MEDIA_ISOLATION="$PLUGIN_ISOLATION"

# Disabled: bookclerk's ONNX embedder (on by default) downloads/loads a MiniLM
# model synchronously inside the async /api/discover/recommendations handler
# (the Discover tab is the default post-login view) with no spawn_blocking and
# no visible timeout. Reproduced this hanging the entire daemon indefinitely —
# confirmed via an orphaned huggingface-hub .lock file next to a fully
# downloaded model blob. Falls back to a lightweight local-hash embedder
# instead, which is synchronous but cheap enough not to need offloading.
export BOOKCLERK_DISCOVERY_EMBEDDINGS_ENABLED="false"

# Audiobookshelf integration: opt-in, enabled only when a host is set.
# Passed as env (BOOKCLERK_ABS_*), never written to config.toml, matching
# how every other credential here is handled.
if [ -n "$ABS_HOST" ]; then
    export BOOKCLERK_ABS_ENABLED="true"
    export BOOKCLERK_ABS_BASE_URL="$ABS_HOST"
    if [ -n "$ABS_API_KEY" ]; then
        export BOOKCLERK_ABS_API_KEY="$ABS_API_KEY"
    else
        echo "[bookclerk] WARNING: audiobookshelf_host is set but audiobookshelf_api_key is empty — the integration requires an API key to do anything"
    fi
fi

mkdir -p "$BOOKCLERK_OUTPUT_LOCAL_ROOT"

# Rendered once. After that the file is yours — edit /data/config.toml by
# hand for anything this add-on doesn't expose as an option.
if [ ! -f /data/config.toml ]; then
    echo "[bookclerk] Writing initial /data/config.toml"
    HAS_GA=$(jq -r '(.graphicaudio_accounts // []) | length > 0' "$CONFIG_PATH")
    HAS_LIBRO=$(jq -r '(.libro_fm_accounts // []) | length > 0' "$CONFIG_PATH")
    HAS_CHIRP=$(jq -r '(.chirp_accounts // []) | length > 0' "$CONFIG_PATH")
    HAS_AUDIBLE=$(jq -r '(.audible_marketplaces // []) | length > 0' "$CONFIG_PATH")

    cat > /data/config.toml <<EOF
[library]
auto_acquire = ${AUTO_ACQUIRE}

[output.local]
root = "${BOOKCLERK_OUTPUT_LOCAL_ROOT}"

[sources.graphicaudio]
enabled = ${HAS_GA}
access = "${GA_ACCESS}"

[sources.libro]
enabled = ${HAS_LIBRO}

[sources.chirp]
enabled = ${HAS_CHIRP}

[sources.audible]
enabled = ${HAS_AUDIBLE}
EOF
fi

# --- Password-based stores: log in once per configured account. ---------
# `bookclerk auth login` upserts the stored credential, so re-running this on
# every restart is safe. A single bad account is logged and skipped instead
# of blocking the whole add-on from starting.
login_password_accounts () {
    local source="$1" json_key="$2" password_env="$3"
    local count i email password
    count=$(jq -r "(.${json_key} // []) | length" "$CONFIG_PATH")
    for ((i = 0; i < count; i++)); do
        email=$(jq -r ".${json_key}[$i].email" "$CONFIG_PATH")
        password=$(jq -r ".${json_key}[$i].password" "$CONFIG_PATH")
        echo "[bookclerk] Logging in to ${source} (${email})"
        if ! env "${password_env}=${password}" bookclerk auth login --source "$source" --email "$email"; then
            echo "[bookclerk] WARNING: login failed for ${source} account ${email} — check the credentials for this entry"
        fi
    done
}

login_password_accounts graphicaudio graphicaudio_accounts BOOKCLERK_GA_PASSWORD
login_password_accounts libro libro_fm_accounts BOOKCLERK_LIBRO_PASSWORD
login_password_accounts chirp chirp_accounts BOOKCLERK_CHIRP_PASSWORD

# --- Audible: interactive OAuth per marketplace, cannot be automated. ----
AUDIBLE_COUNT=$(jq -r '(.audible_marketplaces // []) | length' "$CONFIG_PATH")
if [ "$AUDIBLE_COUNT" -gt 0 ]; then
    echo "[bookclerk] Audible marketplaces configured: $(jq -r '.audible_marketplaces | join(", ")' "$CONFIG_PATH")"
    echo "[bookclerk] Audible logins use Amazon's interactive OAuth flow and cannot be scripted here."
    echo "[bookclerk] Open a terminal into this add-on and run one of the following per Audible account you own:"
    jq -r '.audible_marketplaces[] | "[bookclerk]   bookclerk auth login -m " + .' "$CONFIG_PATH"
fi

echo "[bookclerk] Operator token: /data/operator.token (open a terminal into this add-on and run 'cat /data/operator.token' to sign in to the web UI)"
echo "[bookclerk] Starting bookclerkd on ${BOOKCLERK_DAEMON_LISTEN}"

exec /usr/local/bin/bookclerkd
