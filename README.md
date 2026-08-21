# Matcha Wallet — Solana wallet (Flutter)

A minimalist, matcha-and-brown themed Solana wallet: create or import a
wallet, view tokens/assets with a live-value dashboard, send and receive
SOL/SPL tokens, browse transaction history, and re-enter the app with a PIN
(with optional biometric unlock).

This is delivered as a `lib/` source tree + `pubspec.yaml`, not a zipped
Flutter project with native `android/`/`ios/` folders — this sandbox can't
run `flutter create` or reach `pub.dev`, so nothing here has been
build-verified. Follow the setup steps below on your own machine.

## Setup

```bash
# 1. Scaffold a fresh Flutter project (gives you android/ ios/ etc.)
flutter create matcha_wallet
cd matcha_wallet

# 2. Replace the generated pubspec.yaml and lib/ with the ones provided here
rm -rf lib
cp -r /path/to/provided/lib .
cp /path/to/provided/pubspec.yaml .
cp /path/to/provided/.env .

# 3. Install dependencies
flutter pub get

# 4. Run
flutter run
```

### Required native permissions

**Android** (`android/app/src/main/AndroidManifest.xml`):
```xml
<uses-permission android:name="android.permission.INTERNET"/>
<uses-permission android:name="android.permission.CAMERA"/>
<uses-permission android:name="android.permission.USE_BIOMETRIC"/>
```
Also requires `minSdkVersion 23+` in `android/app/build.gradle` (for
`flutter_secure_storage` + `local_auth`).

**iOS** (`ios/Runner/Info.plist`):
```xml
<key>NSCameraUsageDescription</key>
<string>Used to scan wallet addresses</string>
<key>NSFaceIDUsageDescription</key>
<string>Used to unlock your wallet</string>
```

### RPC endpoint

Edit `.env` and point `SOLANA_RPC_URL` at your own RPC provider (Helius,
QuickNode, Triton, Alchemy, etc). The public `api.mainnet-beta.solana.com`
endpoint is rate-limited and will throttle/fail under real usage — it's a
placeholder only.

## Deploying with Codemagic

`codemagic.yaml` at the repo root defines two workflows, `android-release`
and `ios-release`. Push this project to a git repo (GitHub/GitLab/Bitbucket),
connect it in Codemagic, and it will pick the config up automatically.

### 1. Config values — no `.env` in CI

Codemagic builds never see your local `.env` file (and shouldn't — don't
commit it if you put real API keys in it). Instead, the pipeline passes
config in via `--dart-define`, read by `lib/config/app_config.dart`.

In **Codemagic → Teams → Environment variables**, create a group named
`matcha_wallet_config` with:

| Variable | Example |
|---|---|
| `SOLANA_RPC_URL` | `https://mainnet.helius-rpc.com/?api-key=...` |
| `SOLANA_WS_URL` | `wss://mainnet.helius-rpc.com/?api-key=...` |
| `COINGECKO_API_URL` | `https://api.coingecko.com/api/v3` |
| `COINGECKO_API_KEY` | *(leave blank on the free tier)* |

Mark each as **secure** if it embeds an API key. Reference the group name
in `codemagic.yaml` under `environment.groups` (already wired up).

### 2. Android signing

Easiest path — Codemagic's built-in keystore manager:
1. **Codemagic → App settings → Android code signing** → upload your
   `.jks`/`.keystore` file, key alias, and passwords. Codemagic stores it
   as the `matcha_wallet_keystore` reference used in `codemagic.yaml`.
2. Update `PACKAGE_NAME` in `codemagic.yaml` (`vars:`) to your real
   application ID, and set the matching `applicationId` in
   `android/app/build.gradle`.
3. If you don't have a keystore yet: `keytool -genkey -v -keystore
   release.jks -keyalg RSA -keysize 2048 -validity 10000 -alias matcha`.

### 3. iOS signing

Uses Codemagic's automatic signing (`ios_signing` block), which needs an
**App Store Connect API key** added under **Codemagic → Teams → Integrations
→ Apple Developer Portal**. Once connected, `app-store-connect
fetch-signing-files` in the workflow handles provisioning profiles and
certificates for you — set `bundle_identifier` to match your Xcode project
and App Store Connect app record.

If you'd rather manage certificates manually, replace the `ios_signing`
block and the "Fetch signing files" step with Codemagic's manual
certificate/profile references — see Codemagic's iOS code signing docs for
the exact YAML shape, since it depends on how you store your `.p12`/`.mobileprovision` files.

### 4. First build checklist

- [ ] Repo pushed with `pubspec.yaml`, `lib/`, `codemagic.yaml` at the root
      (this project has **no** `android/`/`ios/` folders yet — run
      `flutter create .` locally once, commit those folders, *then* push,
      or Codemagic has nothing to build)
- [ ] `matcha_wallet_config` env group created with your real RPC URL
- [ ] Android keystore uploaded, `PACKAGE_NAME` / `applicationId` aligned
- [ ] Apple Developer integration connected, bundle ID matches
- [ ] `.env` is in `.gitignore` if you ever put real secrets in it locally

## Architecture

```
lib/
  theme/app_theme.dart          Matcha × brown design system (colors, type, components)
  models/                       TokenAsset, WalletTransaction
  services/
    secure_storage_service.dart  Keychain/Keystore-backed storage, PIN hashing, lockout
    solana_service.dart          RPC calls: balances, SPL accounts, transfers, tx history
    price_service.dart           CoinGecko price feed for USD valuations
  providers/
    auth_provider.dart           PIN/biometric session state, lockout logic
    wallet_provider.dart         Wallet lifecycle, balances, send/receive, refresh
  screens/
    splash_screen.dart           Routes to onboarding / PIN setup / lock gate
    app_lock_gate.dart           Re-locks on app background/resume
    onboarding/                  Welcome, create wallet (mnemonic reveal), import wallet
    auth/                        PIN setup, PIN login/unlock
    dashboard/                   Portfolio tab (totals, allocation chart, asset list), token detail
    send/, receive/              Transfers, QR code display/scan
    history/                     Transaction history
    settings/                    Security toggles, reveal phrase, disconnect
  widgets/                       Reusable PIN keypad, buttons, asset tile
```

## Security model

- **Keys never leave the device.** Mnemonic and private key are written only
  to `flutter_secure_storage`, which uses iOS Keychain / Android Keystore
  (`EncryptedSharedPreferences`) — never plain prefs, never sent to any
  server.
- **PIN is never stored in plaintext.** It's salted (random 16-byte salt per
  install) and hashed with SHA-256; only the hash is persisted. Verification
  uses a constant-time comparison to reduce timing side-channels.
- **Brute-force lockout.** 5 failed PIN attempts triggers a 5-minute
  cooldown, tracked in secure storage so it survives app restarts.
- **Re-lock on background.** `AppLockGate` observes app lifecycle and forces
  PIN/biometric re-entry every time the app resumes from background —
  not just on cold start.
- **Optional biometric unlock** (Face ID / Touch ID / Android biometrics)
  via `local_auth`, gated behind an explicit user toggle in Settings — PIN
  is always the fallback.
- **Watch-only mode.** Importing by public address alone loads a
  read-only wallet that can view balances/history but the UI disables
  Send and the signer path (`WalletProvider._requireSigner`) throws if
  called anyway.
- **Recovery phrase hygiene.** The phrase is blurred-by-default behind a
  "tap to reveal" step during wallet creation, and can only be re-viewed
  later from Settings, one explicit tap at a time — never logged, never
  auto-copied.

### Hardening to consider before production

- Swap the public RPC endpoint for an authenticated provider (see above).
- Add jailbreak/root detection if targeting high-risk users.
- Add app-level screenshot/screen-recording blocking on the recovery-phrase
  and PIN screens (`FLAG_SECURE` on Android, an overlay on iOS).
- Consider a hardware-backed key derivation step (e.g. Android StrongBox /
  iOS Secure Enclave-wrapped keys) rather than storing raw key bytes, if
  your threat model requires it.
- Add certificate pinning for RPC/price-feed hosts.
- Rate-limit and validate all recipient addresses client-side before
  broadcasting (already done for format; consider added confirmation for
  first-time addresses).

## Design language

Flat surfaces, no gradients/glow, generous whitespace, one accent
(matcha green) used sparingly against warm cream/parchment/espresso
neutrals. Serif numerals for balances, clean sans for UI chrome. Icons are
plain Material outline glyphs — no emoji anywhere in the UI.

## Known limitations in this reference build

- SPL token metadata (name/logo) isn't resolved from a token list/registry
  yet — unknown tokens show a generic glyph and truncated mint as the
  symbol. Wiring up the Solana Token List or Jupiter's token API is a
  natural next step.
- Transaction history resolves direction/amount lazily per-row (tap to
  load) to avoid one RPC call per signature on first paint — swap for a
  batched `getParsedTransactions` call if you want it eager.
- No swap functionality (not in scope of this ask) — send/receive/track
  only.
- Package API surfaces (`solana`, `mobile_scanner`, etc.) move between
  versions; pin the versions in `pubspec.yaml` and check each package's
  changelog if `flutter pub get` reports breaking changes.
