<p align="center"><img src="logo.png" alt="Proton Mail Bridge" width="120"></p>

# Proton Mail Bridge Container

Headless [Proton Mail Bridge](https://proton.me/mail/bridge) als Docker-Container, gedacht für Unraid, läuft aber überall, wo Docker läuft.
Die Bridge bindet von Haus aus nur an `127.0.0.1`. Dieser Container leitet per `socat` SMTP und IMAP auf `0.0.0.0` weiter, damit andere Geräte und Container im Netzwerk darauf zugreifen können.

[![Build & Push](https://github.com/heinrichchristopher/proton-mail-bridge-container/actions/workflows/build.yml/badge.svg)](https://github.com/heinrichchristopher/proton-mail-bridge-container/actions/workflows/build.yml)

## Features

- Offizielles Proton-`.deb` auf `debian:trixie-slim` (`linux/amd64`)
- Lauscht auf `0.0.0.0` (SMTP `2025`, IMAP `2143`)
- Läuft ohne root (UID/GID `99:100`, passend zu Unraid `nobody:users`)
- **Automatische Updates:** Eine neue Bridge-Version wird alle 6 Stunden erkannt, danach folgen Version-Bump, Git-Tag, GitHub-Release und Image-Build
- **Wöchentlicher Rebuild** (montags 03:00 UTC) ohne Cache, damit Security-Patches des Base-Images ankommen

## Image

```
ghcr.io/heinrichchristopher/proton-mail-bridge:latest
ghcr.io/heinrichchristopher/proton-mail-bridge:<bridge-version>   # z. B. 3.27.1
```

## Ports und Volumes

| Container | Zweck | Vorschlag |
|---|---|---|
| `2025/tcp` | SMTP (STARTTLS) | `2025` |
| `2143/tcp` | IMAP (STARTTLS) | `2143` |
| `/data` | Login, GPG-Key, Bridge-Konfiguration | `/mnt/user/appdata/proton-mail-bridge` |

Optionale Umgebungsvariablen: `LISTEN_SMTP_PORT` (2025), `LISTEN_IMAP_PORT` (2143).

## Einrichtung

### 1. Einmaliger Login

Der Container muss dabei gestoppt sein bzw. noch nicht existieren.

```bash
mkdir -p /mnt/user/appdata/proton-mail-bridge
chown -R 99:100 /mnt/user/appdata/proton-mail-bridge

docker run --rm -it \
  -v /mnt/user/appdata/proton-mail-bridge:/data \
  ghcr.io/heinrichchristopher/proton-mail-bridge init
```

In der Bridge-CLI:

```
>>> login      # Proton-Zugangsdaten und ggf. 2FA
>>> info       # zeigt Benutzername und Passwort für den Mail-Client
>>> exit
```

> Im Mail-Client benutzt du die **Bridge-Zugangsdaten aus `info`**, nicht dein Proton-Passwort.

### 2. Container starten

**Unraid:** *Docker → Add Container*, Repository `ghcr.io/heinrichchristopher/proton-mail-bridge:latest`, Ports `2025`/`2143`, Pfad `/data`. Alternativ das Template [`unraid/proton-mail-bridge.xml`](unraid/proton-mail-bridge.xml) nach `/boot/config/plugins/dockerMan/templates-user/` kopieren.

**Docker CLI:**

```bash
docker run -d --name proton-mail-bridge --restart unless-stopped \
  -p 2025:2025 -p 2143:2143 \
  -v /mnt/user/appdata/proton-mail-bridge:/data \
  ghcr.io/heinrichchristopher/proton-mail-bridge:latest
```

### 3. Mail-Client

| Einstellung | Wert |
|---|---|
| Server | IP/Hostname des Containers |
| IMAP | Port `2143`, STARTTLS |
| SMTP | Port `2025`, STARTTLS |
| Login | Bridge-Zugangsdaten aus `info` |

Das Zertifikat der Bridge ist selbstsigniert und muss einmalig akzeptiert werden.

## Sicherheit

Die Bridge ist über `0.0.0.0` für alle Geräte im Netzwerk erreichbar, geschützt nur durch das Bridge-Passwort. Setze die Ports **nicht** ohne weitere Absicherung ins Internet und beschränke den Zugriff ggf. per Docker-Netzwerk oder Firewall.

## Wie die Automatik funktioniert

| Workflow | Trigger | Aufgabe |
|---|---|---|
| [`check-release.yml`](.github/workflows/check-release.yml) | alle 6 Stunden | Vergleicht das neueste Release von [ProtonMail/proton-bridge](https://github.com/ProtonMail/proton-bridge) mit `VERSION`; bei neuer Version: Bump, Tag, Release, Build anstoßen |
| [`build.yml`](.github/workflows/build.yml) | Push, montags, manuell | Baut und pusht das Image nach GHCR (ohne Cache, mit frischem Base-Image) |

## Hinweise

- Die Bridge-Software gehört Proton AG. Dieses Projekt ist **inoffiziell** und nicht mit Proton verbunden. Name und Logo sind Marken der Proton AG.
- Aktuell nur `linux/amd64`.
