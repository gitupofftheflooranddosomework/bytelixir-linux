# bytelixir-linux

Run a Bytelixir proxy node on Linux — using Bytelixir's **own sanctioned path**.

Bytelixir ships no Linux client and states in its FAQ that none is planned
("We do not plan to release Linux / Docker client. You can setup proxies on
your server using preferable proxy software, pass KYC verification through
the dashboard, and then add proxies to your account for online earning.").
This tool is that setup: it installs and manages an authenticated
HTTP/SOCKS5 proxy on your Linux server, and prints the exact string you paste
into your Bytelixir dashboard under **Proxies**.

## What this is — and what it is not

- **It is** an unofficial community tool that configures a standard,
  password-protected proxy (3proxy) on a Linux box you own.
- **It is not** the official Bytelixir app, and it is not affiliated with,
  endorsed by, or supported by Bytelixir.
- **It is not** a reverse-engineered clone of Bytelixir's app. Bytelixir
  publishes no client protocol, so there is nothing legitimate to clone.
  This tool only does what Bytelixir itself documents: run your own proxy
  software and register it in the dashboard.
- **It does not fake traffic.** Your proxy only carries traffic when
  Bytelixir's network actually routes a buyer request through it. If nobody
  routes traffic, you earn nothing — same as the official app sitting idle.
- **It does not bypass KYC.** Bytelixir requires identity verification
  before you can add proxies. An unverified account cannot add proxies,
  no matter what software you run. Do KYC first (see below).
- **It does not auto-register anything.** You paste the proxy string into
  the dashboard yourself. No dashboard automation, no credentials for your
  Bytelixir account are ever handled by this tool.

## Prerequisites

1. A Bytelixir account that has **passed KYC verification**. Check
   Dashboard → Account verification: it must not say "Not verified".
   (Unverified accounts cannot add proxies and are capped at 10 peers.)
2. A Linux server with a **residential IP you own/control**. Bytelixir
   pays for residential/mobile IPs; a datacenter IP earns less or nothing,
   and one public IP does not earn more with multiple proxies on it.
3. Debian/Ubuntu (apt) or RHEL-family (dnf) Linux, systemd, and a port you
   can open to the internet (default 3128 for HTTP, optional 1080 for
   SOCKS5). The proxy must be reachable from outside — that is the point.
4. Root access on that server.

## Quickstart

```sh
# 1. Clone and install (builds 3proxy from source, installs blx-proxy)
git clone https://github.com/gitupofftheflooranddosomework/bytelixir-linux.git
cd bytelixir-linux
chmod +x install.sh blx-proxy
sudo ./install.sh

# 2. Set up the proxy (generates a strong password, starts the service)
sudo blx-proxy setup

# 3. Copy the dashboard string it prints, then in Bytelixir:
#    Dashboard → Proxies → Add proxies → One by one → paste it.
#    Bytelixir validates the proxy (takes a couple of minutes).
```

Useful commands:

```sh
sudo blx-proxy status    # service, ports, recent log lines
sudo blx-proxy show      # print the dashboard proxy string again
sudo blx-proxy test      # prove it is NOT an open relay (see below)
sudo blx-proxy rotate    # new password (then update it in the dashboard)
sudo blx-proxy uninstall # stop everything and remove the config
```

Options for setup:

```sh
sudo blx-proxy setup --port 8080 --with-socks --socks-port 1080 \
  --user myname --host 203.0.113.10 --bandwidth-mbps 50
```

- `--port` — HTTP proxy port (default 3128).
- `--with-socks` / `--socks-port` — also run SOCKS5 (default port 1080).
  Bytelixir accepts both HTTP and SOCKS5 proxies; add each as its own
  entry in the dashboard.
- `--user` — proxy username (default `blx`; letters, digits, `_`, `-`).
- `--host` — public IP/hostname printed in the dashboard string. If
  omitted, the tool tries one IP-echo lookup (ifconfig.me) and otherwise
  prints a `<YOUR-PUBLIC-IP>` placeholder for you to replace.
- `--bandwidth-mbps` — cap in each direction (default 50; `0` = unlimited).
  The cap protects your own connection from being saturated.

## Security model — read this before you run it

Running a proxy on your home/server IP means **someone else's traffic
passes through your connection**. This tool reduces the risk, it does not
eliminate it:

- **Authentication is mandatory.** The proxy runs `auth strong`: every
  request must present the username and password. Without them, requests
  are refused. This is the difference between a private proxy and an open
  relay — and `blx-proxy test` proves it (see below).
- **Credentials live in one root-only file** (`/etc/blx-proxy/credentials`,
  mode 0600) and in the 3proxy config (also 0600). They are never written
  to this repo, to logs, or anywhere else. Rotate them any time with
  `blx-proxy rotate`.
- **Bandwidth is capped** (default 50 Mbps each way) so buyer traffic
  cannot saturate your line.
- **Everything is logged** to `/var/log/blx-proxy/3proxy.log` so you can
  audit what passed through. Read it occasionally.
- **What this tool cannot do:** it cannot vet Bytelixir's buyers. Bytelixir
  says its business clients pass KYC/AML checks, traffic is encrypted, and
  prohibited uses (spam, hacking, fraud, torrents, adult content) are
  monitored and blocked — those are Bytelixir's claims, not this tool's.
  If you are not comfortable with buyer traffic exiting via your IP, do
  not run any bandwidth-sharing software, including the official app.
  Never run this on an IP you do not own, and never run it alongside
  software that already shares your connection under a different account
  (one account per IP per network is the standing rule everywhere).

## Proving it is not an open relay

```sh
sudo blx-proxy test
```

This runs checks from the server itself (four when SOCKS is enabled):

1. A request **without** credentials through the proxy must fail
   (HTTP 407 / denied). If it succeeds, the proxy is misconfigured —
   stop it immediately (`blx-proxy uninstall`).
2. A request **with** credentials must succeed (HTTP 200 via example.com).
3. With `--with-socks`: the same two checks over SOCKS5.

If check 1 ever passes, treat the proxy as compromised and rotate
credentials before re-adding it to the dashboard.

## Earnings — honest numbers

Bytelixir's own materials claim roughly **$2–$4 per device per month** and
**$5 per proxy per month**, varying heavily with location and demand.
Independent catalog estimates are lower ($0–$3/device/month). Payouts are
**crypto only** (USDT/USDC from $5, TON $8, LTC $10, ETH $40, BTC $250)
and Bytelixir may ask for a selfie check at payout time. Treat this as
a few dollars a month on a residential IP, not income. If your IP is a
datacenter IP, expect near zero.

## Troubleshooting

- **Bytelixir says the proxy is offline:** the port must be reachable
  from the internet. Check your firewall/router port-forward, then
  `blx-proxy status` (is it listening?) and `blx-proxy test`.
- **"Cannot add proxies" in the dashboard:** your account has not passed
  KYC. Nothing on the server side fixes that.
- **Service won't start:** `journalctl -u blx-proxy -n 50` and
  `/var/log/blx-proxy/3proxy.log` have the answer; the usual cause is the
  port already being in use — re-run setup with `--port`.
- **High traffic / slow home internet:** lower `--bandwidth-mbps` and
  re-run setup, or stop the service (`systemctl stop blx-proxy`).

## Files

| File | Purpose |
| ---- | ------- |
| `install.sh` | Dependency check + build 3proxy from source + install |
| `blx-proxy` | The manager CLI (setup/status/show/rotate/test/uninstall) |
| `3proxy.cfg.template` | 3proxy config template (placeholders only, no secrets) |
| `blx-proxy.service` | systemd unit |
| `SECURITY.md` | Security notes and disclosure policy |

## License

MIT. See `LICENSE`. Bytelixir is a trademark of its owner; this project
is independent and unofficial.
