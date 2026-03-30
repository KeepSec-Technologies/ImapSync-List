#!/bin/bash

usage() {
  echo "Usage: $0 -s SRC_HOST -d DST_HOST -f ACCOUNTS_FILE [-l LOG_DIR]"
  echo "  -s  Source IMAP host"
  echo "  -d  Destination IMAP host"
  echo "  -f  Accounts file (email|password per line)"
  echo "  -l  Log directory (default: ./logs)"
  exit 1
}

LOG_DIR="./logs"

while getopts "s:d:f:l:h" opt; do
  case $opt in
    s) SRC_HOST="$OPTARG" ;;
    d) DST_HOST="$OPTARG" ;;
    f) ACCOUNTS_FILE="$OPTARG" ;;
    l) LOG_DIR="$OPTARG" ;;
    h) usage ;;
    *) usage ;;
  esac
done

[[ -z "$SRC_HOST" || -z "$DST_HOST" || -z "$ACCOUNTS_FILE" ]] && usage
[[ ! -f "$ACCOUNTS_FILE" && ! -e "$ACCOUNTS_FILE" ]] && { echo "Error: file not found: $ACCOUNTS_FILE"; exit 1; }

mkdir -p "$LOG_DIR"
FAILED=()

while IFS='|' read -r EMAIL PASS; do
  [[ -z "$EMAIL" || "$EMAIL" == \#* ]] && continue

  # Strip carriage returns and newlines
  EMAIL=$(echo "$EMAIL" | tr -d '\r\n')
  PASS=$(echo "$PASS" | tr -d '\r\n')

  echo "[$( date '+%Y-%m-%d %H:%M:%S')] Syncing: $EMAIL"

  PASSFILE1=$(mktemp)
  PASSFILE2=$(mktemp)
  printf '%s' "$PASS" > "$PASSFILE1"
  printf '%s' "$PASS" > "$PASSFILE2"

  imapsync \
    --host1 "$SRC_HOST" \
    --user1 "$EMAIL" \
    --passfile1 "$PASSFILE1" \
    --host2 "$DST_HOST" \
    --user2 "$EMAIL" \
    --passfile2 "$PASSFILE2" \
    --ssl1 --ssl2 \
    --logfile "$LOG_DIR/${EMAIL}.log" \
    --nofoldersizes \
    --delete2duplicates \
    2>&1 | tee -a "$LOG_DIR/master.log"

  if [ "${PIPESTATUS[0]}" -ne 0 ]; then
    FAILED+=("$EMAIL")
  fi

  rm -f "$PASSFILE1" "$PASSFILE2"

  echo "Done: $EMAIL"
  echo "---"
done < "$ACCOUNTS_FILE"

echo ""
echo "=============================="
echo "SYNC COMPLETE"
echo "=============================="
if [ ${#FAILED[@]} -eq 0 ]; then
  echo "All accounts synced successfully."
else
  echo "Failed accounts (${#FAILED[@]}):"
  for f in "${FAILED[@]}"; do
    echo "  - $f"
  done
fi