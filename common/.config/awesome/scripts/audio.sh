#!/usr/bin/env bash

set -euo pipefail

VOLUME="${AUDIO_VOLUME:-0.80}"

get_sink_id_by_text() {
    local text="$1"

    wpctl status 2>/dev/null | awk -v text="$text" '
        /Sinks:/ {
            in_sinks = 1
            next
        }

        /Sources:/ {
            in_sinks = 0
        }

        !in_sinks {
            next
        }

        {
            line = $0
            gsub(/^[[:space:]│├─└*]+/, "", line)
        }

        index(line, text) > 0 && line ~ /^[0-9]+\./ {
            id = line
            sub(/\..*/, "", id)
            print id
            exit
        }
    '
}

get_default_sink_id() {
    wpctl status 2>/dev/null | awk '
        /Sinks:/ {
            in_sinks = 1
            next
        }

        /Sources:/ {
            in_sinks = 0
        }

        !in_sinks {
            next
        }

        /\*/ {
            line = $0
            gsub(/^[[:space:]│├─└*]+/, "", line)

            if (line ~ /^[0-9]+\./) {
                id = line
                sub(/\..*/, "", id)
                print id
                exit
            }
        }
    '
}

# PipeWire ممکن است HDMI sink را حتی پس از جداشدن کابل نگه دارد.
# بنابراین وضعیت واقعی connector را مستقیماً از kernel/DRM می‌خوانیم.
is_hdmi_connected() {
    local status_file
    local status

    shopt -s nullglob

    for status_file in /sys/class/drm/card*-HDMI-*/status; do
        status="$(<"$status_file")"

        if [ "$status" = "connected" ]; then
            return 0
        fi
    done

    return 1
}

set_sink() {
    local id="$1"
    local current_id

    [ -n "${id:-}" ] || return 1

    current_id="$(get_default_sink_id || true)"

    if [ "$current_id" != "$id" ]; then
        wpctl set-default "$id"
    fi

    wpctl set-mute "$id" 0
    wpctl set-volume "$id" "$VOLUME"
}

hdmi_id="$(get_sink_id_by_text "Digital Stereo (HDMI)" || true)"
laptop_id="$(get_sink_id_by_text "Built-in Audio Analog Stereo" || true)"

case "${1:-auto}" in
    hdmi)
        if ! is_hdmi_connected; then
            echo "HDMI display is physically disconnected." >&2
            exit 1
        fi

        if [ -z "$hdmi_id" ]; then
            echo "HDMI sink not found in PipeWire." >&2
            exit 1
        fi

        set_sink "$hdmi_id"
        ;;

    laptop)
        if [ -z "$laptop_id" ]; then
            echo "Laptop audio sink not found." >&2
            exit 1
        fi

        set_sink "$laptop_id"
        ;;

    auto)
        # معیار انتخاب HDMI: اتصال واقعی کابل، نه صرفاً باقی‌بودن Sink در wpctl.
        if is_hdmi_connected && [ -n "$hdmi_id" ]; then
            set_sink "$hdmi_id"
            echo "Audio output: HDMI (sink $hdmi_id)"
        elif [ -n "$laptop_id" ]; then
            set_sink "$laptop_id"
            echo "Audio output: laptop speakers (sink $laptop_id)"
        else
            echo "No usable audio sink found." >&2
            exit 1
        fi
        ;;

    status)
        echo "HDMI sink ID: ${hdmi_id:-not found}"
        echo "Laptop sink ID: ${laptop_id:-not found}"

        if is_hdmi_connected; then
            echo "HDMI physical state: connected"
        else
            echo "HDMI physical state: disconnected"
        fi
        ;;

    *)
        echo "Usage: $0 {auto|hdmi|laptop|status}" >&2
        exit 1
        ;;
esac

