#!/bin/bash

# TODO: Add error handling and logging
# TODO: STOP ON ANY ERROR

set -euo pipefail

NAMESPACE="${NAMESPACE:-default}"
LABEL_SELECTOR="konnect-deck"
INTERVAL="${SYNC_INTERVAL:-300}"
KONNECT_TOKEN=$(cat /secrets/konnect-token)

while true; do
  echo "[INFO] Starting deck sync..."

  TMP_DIR=$(mktemp -d)
  OUTPUT_FILE="$TMP_DIR/merged.yaml"

  echo "[INFO] Fetching ConfigMaps labeled '$LABEL_SELECTOR' in namespace '$NAMESPACE'..."

  kubectl get configmap -n konnect-reconciler -l konnect-deck -o json | \
  jq -r '.items[].data.deck + "\n---\n"' | \
  awk -v dir="$TMP_DIR" '
  BEGIN {RS="\n---\n"; i=0}
  NF {  # Only process non-empty chunks
    i++
    print > (dir "/" i ".yaml")
  }'
  
  ls "$TMP_DIR"/*.yaml

  if compgen -G "$TMP_DIR"/*.yaml > /dev/null; then
    echo "[INFO] Merging deck files..."]

    deck file merge "$TMP_DIR"/*.yaml -o "$OUTPUT_FILE"

    echo "[INFO] Running deck diff..."
    deck gateway diff $OUTPUT_FILE \
      --konnect-addr "$KONNECT_ADDR" \
      --konnect-token "$KONNECT_TOKEN" \
      --konnect-control-plane-name "$KONNECT_CONTROL_PLANE_NAME"

    echo "[INFO] Running deck sync..."
    deck gateway sync $OUTPUT_FILE \
      --konnect-addr "$KONNECT_ADDR" \
      --konnect-token "$KONNECT_TOKEN" \
      --konnect-control-plane-name "$KONNECT_CONTROL_PLANE_NAME"
  else
    echo "[WARN] No matching ConfigMaps found. Skipping this cycle."
  fi

  rm -rf "$TMP_DIR"

  echo "[INFO] Sync complete. Sleeping $INTERVAL seconds..."
  sleep "$INTERVAL"
done
