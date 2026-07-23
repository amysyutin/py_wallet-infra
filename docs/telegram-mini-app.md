# Telegram Mini App operations

The public bot is `@py_WalletBot` and the Mini App URL is
`https://pywallet.dev/telegram`. These non-secret values are configured in
`manifests/app/configmap.yaml`.

The backend accepts Telegram updates at
`https://pywallet.dev/api/telegram/webhook`. The `/start` command returns a
localized product description and a button that opens the Mini App. The backend
also validates Mini App `initData` and sends outbound daily balance messages.

## Configure BotFather

For `@py_WalletBot`, configure both the Main Mini App and menu button to open:

```text
https://pywallet.dev/telegram
```

Do not paste the bot token into BotFather configuration fields, source control,
issue trackers, CI variables that print logs, or application logs.

## Create the token secret

The application expects a Secret named `telegram-bot-secret` in namespace
`py-wallet-dev`, with `TELEGRAM_BOT_TOKEN` and `TELEGRAM_WEBHOOK_SECRET`. Both the API
Deployment and balance CronJob reference it as optional, so GitOps sync and the
website remain healthy before the secret is installed. The CronJob is committed
with `spec.suspend: true`, so it cannot run without the token. Without the token,
Telegram authentication is unavailable.

Use the newly rotated token only in your local shell. The following keeps the
token out of command-line arguments and creates the temporary file with mode
`0600`. Generate a SealedSecret without writing a plaintext manifest to the
repository:

```bash
umask 077
PY_WALLET_TELEGRAM_TOKEN_FILE="$(mktemp)"
PY_WALLET_TELEGRAM_WEBHOOK_SECRET_FILE="$(mktemp)"
trap 'rm -f "$PY_WALLET_TELEGRAM_TOKEN_FILE" "$PY_WALLET_TELEGRAM_WEBHOOK_SECRET_FILE"' EXIT
read -rsp 'Telegram bot token: ' PY_WALLET_TELEGRAM_TOKEN
echo
printf '%s' "$PY_WALLET_TELEGRAM_TOKEN" > "$PY_WALLET_TELEGRAM_TOKEN_FILE"
unset PY_WALLET_TELEGRAM_TOKEN
python3 -c 'import secrets; print(secrets.token_urlsafe(48))' > "$PY_WALLET_TELEGRAM_WEBHOOK_SECRET_FILE"
kubectl create secret generic telegram-bot-secret \
  --namespace py-wallet-dev \
  --from-file=TELEGRAM_BOT_TOKEN="$PY_WALLET_TELEGRAM_TOKEN_FILE" \
  --from-file=TELEGRAM_WEBHOOK_SECRET="$PY_WALLET_TELEGRAM_WEBHOOK_SECRET_FILE" \
  --dry-run=client -o yaml \
| kubeseal --format yaml \
  --controller-namespace kube-system \
  --controller-name sealed-secrets \
> manifests/app/sealed-telegram-bot-secret.yaml
rm -f "$PY_WALLET_TELEGRAM_TOKEN_FILE"
rm -f "$PY_WALLET_TELEGRAM_WEBHOOK_SECRET_FILE"
trap - EXIT
unset PY_WALLET_TELEGRAM_TOKEN_FILE
unset PY_WALLET_TELEGRAM_WEBHOOK_SECRET_FILE
```

Before committing, verify that the generated file contains `encryptedData` and
does not contain `stringData`, `data`, or the plaintext token. Then add the
SealedSecret filename to `manifests/app/kustomization.yaml`, commit it, and let
Argo CD sync it. Do not commit an empty Secret or a token placeholder. Confirm
that `telegram-bot-secret` exists in the cluster before enabling delivery:

```bash
kubectl -n py-wallet-dev get secret telegram-bot-secret
```

After the API rollout, the API registers the webhook automatically at startup
using the token and webhook secret from `telegram-bot-secret`. To register it
manually from a trusted shell:

```bash
cd py_wallet
python scripts/configure_telegram_webhook.py
```

Telegram will then send `/start` updates with the configured secret header.

After the SealedSecret has synced, set `spec.suspend: false` in
`telegram-daily-balance-cronjob.yaml` as a separate reviewed commit. An
imperative patch may be used for a controlled smoke test, but Git remains the
source of truth:

```bash
kubectl -n py-wallet-dev patch cronjob py-wallet-telegram-daily-balance \
  --type merge -p '{"spec":{"suspend":false}}'
```

If the cluster is unavailable, seal against an exported public certificate:

```bash
kubeseal --fetch-cert \
  --controller-namespace kube-system \
  --controller-name sealed-secrets \
> /tmp/py-wallet-sealed-secrets-cert.pem
```

Pass `--cert /tmp/py-wallet-sealed-secrets-cert.pem` to `kubeseal` on a trusted
machine. The public certificate is safe to distribute; the controller private
key is not.

## Daily balance scheduler

Once enabled, `py-wallet-telegram-daily-balance` runs every five minutes in UTC
and invokes:

```text
python -m app.jobs.telegram_daily_balance
```

The backend is responsible for selecting users whose configured local delivery
time is due and for recording idempotent delivery. The CronJob prevents
overlapping executions, has a four-minute deadline, keeps limited history, uses
a dedicated ServiceAccount with no RBAC, does not mount a Kubernetes API token,
and runs without Linux capabilities on a read-only root filesystem.

Useful checks:

```bash
kubectl -n py-wallet-dev get cronjob py-wallet-telegram-daily-balance
kubectl -n py-wallet-dev create job \
  --from=cronjob/py-wallet-telegram-daily-balance \
  telegram-balance-manual
kubectl -n py-wallet-dev logs job/telegram-balance-manual
```

Delete the one-off Job after inspection. Never print the Secret or its decoded
value while troubleshooting.

## Rotation and rollback

To rotate the token, revoke it in BotFather, repeat the sealing procedure, and
replace the committed SealedSecret. Restart the API Deployment after Argo CD
sync so all replicas read the new value. The next CronJob run automatically uses
the new Secret.

For an emergency pause that does not affect the website:

```bash
kubectl -n py-wallet-dev patch cronjob py-wallet-telegram-daily-balance \
  --type merge -p '{"spec":{"suspend":true}}'
```

Resume by setting `suspend` to `false` after the incident is resolved and the
token Secret has been verified.
