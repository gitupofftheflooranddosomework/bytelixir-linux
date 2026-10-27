# Security notes

## Design

- **No open relay, by construction.** The proxy runs 3proxy with
  `auth strong` and a single generated user. Requests without valid
  credentials are refused. `blx-proxy test` proves this on every install;
  if that test ever fails, stop the service immediately.
- **Credentials are root-only.** `/etc/blx-proxy/credentials` and the
  rendered `/etc/blx-proxy/3proxy.cfg` are mode 0600. The repository
  template contains placeholders only — a rendered config must never be
  committed (see `.gitignore`).
- **Bandwidth is capped** by default (50 Mbps each way) to protect the
  host connection. Raise it deliberately, not by accident.
- **Logs are local.** `/var/log/blx-proxy/3proxy.log` records proxied
  requests on your server. Review it; it is the audit trail for what
  passed through your IP.

## Limits of this tool

- This tool cannot vet Bytelixir's buyers or their traffic. Bytelixir
  states its business clients pass KYC/AML checks and that prohibited
  uses (spam, hacking, fraud, torrents, adult content) are monitored and
  blocked. Those are Bytelixir's claims. If buyer traffic exiting via
  your IP is not acceptable to you or your ISP, do not run this tool —
  or the official app.
- This tool does not harden your whole server. Keep the host patched,
  keep SSH key-only, and do not expose anything else on the proxy port.
- 3proxy is built from upstream source pinned in `install.sh`. If a
  3proxy security issue is published, update the pin, rebuild, and
  re-run `blx-proxy test`.

## Reporting issues

Open a GitHub issue describing the behavior (never paste credentials or
log lines containing them). For credential exposure: rotate immediately
with `blx-proxy rotate` and update the dashboard entry.
