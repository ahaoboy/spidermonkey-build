get_latest_version() {
    local url="https://product-details.mozilla.org/1.0/firefox_history_development_releases.json"
    local json_data
    json_data=$(curl -s -f "$url")
    if [ $? -ne 0 ]; then
        echo "Error: Failed to fetch data from $url" >&2
        return 1
    fi

    if ! command -v jq >/dev/null 2>&1; then
        echo "Error: jq is required but not installed" >&2
        return 1
    fi

    local latest_version=""
    local latest_timestamp=0

    local versions
    versions=$(echo "$json_data" | jq -r 'to_entries[] | [.key, .value] | join(" ")')

    while read -r version date; do
        local timestamp
        timestamp=$(date -d "$date" +%s 2>/dev/null || date -jf "%Y-%m-%d" "$date" +%s 2>/dev/null)
        if [ $? -ne 0 ]; then
            echo "Warning: Could not parse date '$date' for version '$version'" >&2
            continue
        fi

        if [ "$timestamp" -gt "$latest_timestamp" ]; then
            latest_timestamp=$timestamp
            latest_version=$version
        fi
    done <<< "$versions"

    if [ -z "$latest_version" ]; then
        echo "Error: No valid versions found" >&2
        return 1
    fi

    echo "$latest_version"
}

# 调用函数并处理返回值
if version=$(get_latest_version); then
    echo "Latest Firefox development version: $version"
else
    exit 1
fi

ZIP_NAME="$1"
TARGET="$2"
URL="https://archive.mozilla.org/pub/firefox/releases/$version/jsshell/${ZIP_NAME}"

echo $URL

curl -L -o "spidermonkey-${TARGET}.zip" "$URL"
