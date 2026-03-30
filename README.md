# ImapSync List

A Bash wrapper around [imapsync](https://imapsync.lamiral.info/) that batch-migrates IMAP mailboxes from a list of accounts stored in a CSV/pipe-delimited file.

## Features

- Syncs multiple accounts in sequence from a single accounts file
- Writes per-account log files and an aggregated `master.log`
- Stores passwords in temporary files (never passed on the command line) and removes them after each sync
- Reports a summary of failed accounts at the end
- Terminal summary listing any accounts that failed

## Requirements

- `imapsync` must be installed and available on `$PATH`

## Usage

```bash
./imapsync-list.sh -s SRC_HOST -d DST_HOST -f ACCOUNTS_FILE [-l LOG_DIR]
```

| Flag | Description | Required |
|------|-------------|----------|
| `-s` | Source IMAP hostname | Yes |
| `-d` | Destination IMAP hostname | Yes |
| `-f` | Path to the accounts file | Yes |
| `-l` | Log output directory (default: `./logs`) | No |

## Accounts File Format

One account per line, pipe-delimited:

```
email@example.com|password123
another@example.com|s3cur3pass
# Lines starting with # are ignored
```

CSV files in the `csv/` directory follow this same format.

## Example

```bash
./imapsync-list.sh \
  -s mail.source.com \
  -d mail.destination.com \
  -f csv/example.com.csv \
  -l logs_example/
```

## Notes

- Both source and destination connections use SSL (`--ssl1 --ssl2`)
- Duplicate messages on the destination are removed (`--delete2duplicates`)
- Folder size calculations are skipped for speed (`--nofoldersizes`)

Those can be modified in the script if needed. Always test with a single account first to ensure the desired behavior before running a full batch.
