#!/usr/bin/env bash

CONFIG_ENV_FILE="${CONFIG_ENV_FILE:-$LIB_DIR/.env}"

load_env() {
    local env_file="${1:-$CONFIG_ENV_FILE}"

    if [[ ! -f "$env_file" ]]; then
        touch "$env_file"
    fi

    set -a
    # shellcheck disable=SC1090
    source "$env_file"
    set +a
}

save_env_var() {
    local key="$1"
    local value="$2"
    local env_file="${3:-$CONFIG_ENV_FILE}"

    if grep -q "^${key}=" "$env_file" 2>/dev/null; then
        sed -i "s|^${key}=.*|${key}=$(printf '%q' "$value")|" "$env_file"
    else
        printf '%s=%q\n' "$key" "$value" >> "$env_file"
    fi
}

ensure_project_dir() {
    load_env

    if [[ -z "${PROJECT_DIR:-}" ]]; then
        echo "PROJECT_DIR is not configured in $CONFIG_ENV_FILE" >&2

        while true; do
            read -r -p "Please enter PROJECT_DIR path: " PROJECT_DIR

            # حذف فاصله‌های اضافی اول و آخر مسیر (Trim)
            PROJECT_DIR="${PROJECT_DIR#"${PROJECT_DIR%%[![:space:]]*}"}"
            PROJECT_DIR="${PROJECT_DIR%"${PROJECT_DIR##*[![:space:]]}"}"

            # هندل کردن ~ (توسعه tilde به صورت خودکار به مسیر Home)
            PROJECT_DIR="${PROJECT_DIR/#\~/$HOME}"

            if [[ -n "$PROJECT_DIR" ]]; then
                break
            fi
            echo "Path cannot be empty. Try again." >&2
        done

        save_env_var "PROJECT_DIR" "$PROJECT_DIR"
        echo "Saved PROJECT_DIR to $CONFIG_ENV_FILE successfully!" >&2
    fi

    export PROJECT_DIR
}
