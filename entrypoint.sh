#!/usr/bin/env bash
set -euo pipefail

export GNUPGHOME="${HOME}/.gnupg"
mkdir -p "$GNUPGHOME"; chmod 700 "$GNUPGHOME"

# First start: create GPG key + password store (bridge uses `pass` as keychain)
if [ ! -d "${HOME}/.password-store" ]; then
  echo "Initialising GPG key and password store ..."
  gpg --batch --passphrase '' --quick-gen-key ProtonMailBridge default default never
  pass init ProtonMailBridge
fi

case "${1:-run}" in
  init)
    echo "Interactive bridge CLI. Type 'login', follow the prompts, then 'exit'."
    exec protonmail-bridge --cli
    ;;
  run)
    # Forward 0.0.0.0:LISTEN_* -> 127.0.0.1:BRIDGE_*
    socat TCP-LISTEN:"${LISTEN_SMTP_PORT}",fork,reuseaddr TCP:127.0.0.1:"${BRIDGE_SMTP_PORT}" &
    socat TCP-LISTEN:"${LISTEN_IMAP_PORT}",fork,reuseaddr TCP:127.0.0.1:"${BRIDGE_IMAP_PORT}" &
    exec protonmail-bridge --noninteractive
    ;;
  *)
    exec "$@"
    ;;
esac
