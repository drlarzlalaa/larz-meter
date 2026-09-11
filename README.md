# larz-meter

**Wrap any shell command with [LarzOS](https://larzos.com/larzos-linux/) wallet
metering: check the budget before it runs, run it with a real terminal, debit
the wallet only if it actually succeeds.**

LarzOS treats spending as an OS-level concern — every machine has a wallet,
spend caps per category, and a receipted ledger (`larz wallet` / `larz budget`
/ `larz spend`). `larz-aid` already uses this to guard AI gateway calls before
every completion. `larz-meter` is the same pattern, generalized to *any*
command — an API call, a paid CLI tool, a batch job — not just AI.

```sh
larz-meter --category api --price 0.10 -- curl -s https://api.example.com/report
```

- Checks `api`'s monthly budget first. Over the cap? The command never runs.
- Runs the command with stdio inherited — output streams live, interactive
  commands still work.
- Debits the wallet **only if the command exits 0**. A failed command costs
  nothing.
- Exits with the wrapped command's exit code, so it composes in `&&` chains,
  CI steps, and `set -e` scripts (a budget block exits `2`).

```
usage: larz-meter --category <cat> --price <usd> [--note TEXT] [--ref REF] [--dry-run] -- <command...>

  --category   wallet budget category to check/debit against (required)
  --price      USD amount to check and debit on success (required)
  --note       free-text note for the ledger entry (default: the command line)
  --ref        ledger ref (default: the command's first word)
  --dry-run    check the budget and print what would happen, run nothing
```

## Example

```sh
$ larz budget api 5.00
$ larz-meter --category api --price 0.10 --dry-run -- ./nightly-report.sh
larz-meter: would check 'api' ($5.00 left this month before this run), run
`./nightly-report.sh`, and debit $0.10 on success

$ larz-meter --category api --price 0.10 -- ./nightly-report.sh
... (report output) ...
larz-meter: ok - charged $0.10 to 'api'

$ larz spend api
```

## Install

On a LarzOS box (or any Debian box with the LarzOS apt repo added, see
<https://larzos.com/larzos-linux/>):

```sh
larz-pkg deb .
sudo dpkg -i dist/larz-meter_0.1.0_all.deb
```

`larz-pkg` and `dpkg-deb` come with LarzOS's `larz-system` package. This is a
real `.deb` — inspect it with `larz-pkg show .` before building.

## Why this instead of a bash wrapper

Because the budget check, the ledger, and the receipt are the OS's, not
this tool's. `larz-meter` doesn't implement metering — it just calls
`larzos/wallet`, the same module `larz-aid`, `larz pay` and `larz budget`
use. Every spend it records shows up in `larz wallet` / `larz spend`
alongside everything else the machine has spent, with the same monthly caps
and the same receipts in `/var/lib/larzos/wallet/receipts`.

## License

MIT, see [LICENSE](LICENSE).
