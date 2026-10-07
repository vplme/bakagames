# Android builds and Google Play internal testing

Application ID: **`dev.lauver.bakagames`**. These workflows publish only to the
Google Play **internal testing** track. They do not publish to production or
change store listings, screenshots, or changelogs.

## What runs

| Workflow | Trigger | Output |
| --- | --- | --- |
| CI | PR, push to `main`, manual, or called by deployment | Analysis, app/package tests, release-script tests, debug APK |
| Deploy Android (Play internal) | `vMAJOR.MINOR.PATCH` tag or manual | Checks, signed release AAB, optional Play internal upload |

Both use Flutter **3.44.3**, Dart **3.12.2**, and Java **21** for Android builds.
Flutter is pinned in `.github/actions/setup-flutter/action.yml`. Every checkout
fetches Git LFS assets. Release checks run on the actual selected commit before
signing credentials are used. Ruby/Fastlane is installed only for uploads;
`app/android/Gemfile.lock` pins its dependencies.

Manual release modes:

- **`bootstrap`**: build a signed AAB with version code **1**, without Play API
  credentials. Use only for the first manual upload of this new app.
- **`build-only`** (default): build a signed AAB with a fresh version code, with
  no Play API credentials required.
- **`upload`**: build, save the signed AAB, then upload that exact AAB to internal
  testing. Requires Play API credentials and completion of the initial setup.

## 1. Put the workflows on GitHub

Review and merge these changes into `main` in
[vplme/bakagames](https://github.com/vplme/bakagames). A manual workflow becomes
available in the Actions UI after its definition is on the default branch.
Let **CI** finish successfully; its run has a downloadable debug APK artifact.

## 2. Create and back up the upload key

Run this on your own Linux machine. It prompts for the password and certificate
details; no password needs to be placed in a shell command or sent in chat.

```bash
mkdir -p "$HOME/.local/share/bakagames-signing"
chmod 700 "$HOME/.local/share/bakagames-signing"
keytool -genkeypair -v \
  -keystore "$HOME/.local/share/bakagames-signing/upload-keystore.jks" \
  -storetype JKS -alias upload -keyalg RSA -keysize 2048 -validity 10000
chmod 600 "$HOME/.local/share/bakagames-signing/upload-keystore.jks"
```

Choose a strong keystore password. At the key-password prompt, press Enter to
use the same password, or record a separate one. Back up the keystore and both
passwords in a secure location. Keep this key for subsequent BakaGames uploads.
This is the **upload key**; Google will manage the app-signing key through Play
App Signing. See [Flutter's signing guide](https://docs.flutter.dev/deployment/android#sign-the-app).

## 3. Add GitHub signing secrets

Open the repository's **Settings → Environments → New environment** and create
**`play-internal`**. Under its **Environment secrets**, add:

| Secret | Value |
| --- | --- |
| `ANDROID_KEYSTORE_BASE64` | Base64-encoded contents of the upload keystore |
| `ANDROID_KEYSTORE_PASSWORD` | Keystore password |
| `ANDROID_KEY_ALIAS` | `upload` |
| `ANDROID_KEY_PASSWORD` | Key password, possibly the same as the keystore password |

If you have GitHub CLI installed and authenticated, send the keystore directly
to the secret without printing it:

```bash
base64 -w0 "$HOME/.local/share/bakagames-signing/upload-keystore.jks" |
  gh secret set ANDROID_KEYSTORE_BASE64 --env play-internal --repo vplme/bakagames
```

Otherwise, encode it into a private local file and copy its single-line contents
into the GitHub secret field; remove the temporary encoded file afterwards:

```bash
(umask 077; base64 -w0 "$HOME/.local/share/bakagames-signing/upload-keystore.jks" >
  "$HOME/.local/share/bakagames-signing/upload-keystore.base64")
```

Configure the environment's deployment branch/tag rules to allow **`main`** and
**`v*` tags**. If your GitHub plan offers required reviewers, you can add one;
the workflows do not require it. Restrict who can push release tags. A tag push
automatically requests an upload, so do not push release tags until step 6 is
complete. See [GitHub environment secrets](https://docs.github.com/en/actions/how-tos/write-workflows/choose-what-workflows-do/use-secrets).

## 4. Build your first signed bundle

In **Actions → Deploy Android (Play internal) → Run workflow**:

1. Select branch **`main`**.
2. Set version to **`1.0.0`**.
3. Set mode to **`bootstrap`**.
4. Run the workflow and wait for the checks and release job to finish.
5. Download the **`android-release-1.0.0-1-…`** artifact from the run summary.
6. Extract it. You need **`app-release.aab`**, not the artifact ZIP or debug APK.

The artifact also contains `release.json` with the commit/version and
`SHA256SUMS`. From the extracted directory, `sha256sum -c SHA256SUMS` verifies
the bundle checksum. No Play service account is needed for this step.

## 5. Create the Play app and upload the first release

In [Google Play Console](https://play.google.com/console/):

1. Choose **Create app**, name it **Baka Games**, and choose its language,
   game classification, and free/paid setting. Complete the required declarations.
2. Open **Testing → Internal testing** (it may appear under **Test and release**).
3. Create a release and follow the Play App Signing setup, allowing Google to
   generate/manage the app-signing key.
4. Upload the extracted `app-release.aab`. Verify the package is
   **`dev.lauver.bakagames`** and the version is **`1.0.0`**, code **`1`**.
5. Complete whatever app/account setup the Console requires before rollout,
   then save, review, and roll out the release to internal testing.
6. On the internal track's **Testers** page, add an email list or Google Group,
   include your Google account, save, and copy the opt-in link.
7. Open that link with an eligible tester account and install through Google Play
   once processing completes. If a locally installed debug build has a different
   signature, uninstall it first; uninstalling clears its local game progress.

Fastlane requires an initial manually uploaded build before using `supply`:
[first-upload prerequisite](https://docs.fastlane.tools/actions/upload_to_play_store/#quick-start).
Do not use `bootstrap` again after version code 1 has been uploaded. If you need
another manual bundle, use `build-only` for a fresh version code.

## 6. Give the pipeline Play API access

Follow [Google's API setup](https://developers.google.com/android-publisher/getting_started):

1. Choose/create a Google Cloud project and enable **Google Play Android
   Developer API**.
2. In **IAM & Admin → Service Accounts**, create a BakaGames release service
   account. Download a JSON key through **Keys → Add key → Create new key**.
3. In Play Console **Users and permissions**, invite the service account's email.
   Give it access to **Baka Games**, including app information read access and
   **Release apps to testing tracks**. It does not need production-release or
   financial permissions. You manage tester membership yourself in the Console.
4. Add environment secret **`PLAY_SERVICE_ACCOUNT_JSON_BASE64`** to the same
   GitHub **`play-internal`** environment. For example:

   ```bash
   base64 -w0 /absolute/path/to/service-account.json |
     gh secret set PLAY_SERVICE_ACCOUNT_JSON_BASE64 --env play-internal --repo vplme/bakagames
   ```

   Keep the downloaded key private; do not commit it. As with the keystore,
   the GitHub UI also accepts a single-line base64 value.

Google no longer requires linking the developer account to a Cloud project;
enable the API and grant the service account Play Console access as above.

## 7. Verify the first automated update

Run **Deploy Android (Play internal)** manually on `main`, version **`1.0.1`**,
mode **`upload`**. Check that:

- The workflow passes its analysis, tests, and APK build before signing.
- The AAB artifact exists even if the later Play upload fails.
- Play Console shows the new bundle on **internal testing**, with the matching
  version code from the Actions summary/artifact.
- Your tester account can update the existing Play installation and retains its
  game progress. Confirm launch and basic gameplay on a physical Android device.

Once this works, ordinary releases can use a tag on a reviewed commit:

```bash
git tag v1.0.2
git push origin v1.0.2
```

The tag determines the visible version. For manual runs, the version input does;
the pipeline overrides `pubspec.yaml` at build time without editing it.

## Version numbers, retries, and failures

Normal version codes are UTC seconds since **2020-01-01**. The deployment
workflow serializes runs across all refs, and resolves the code inside the
release job. A later rebuilt release gets a larger code, including on a rerun;
it does not depend on which versions are still visible on the internal track.
Keep all future Android uploads on this numbering scheme. An old artifact or a
manually assigned larger number can invalidate the expected upload order.
The script validates Play's maximum version-code bound.

If an upload fails, first check Play Console: it may have accepted the bundle
before reporting an error. Rerun the failed release job (which rebuilds with a
fresh code), or start a new manual `upload` run. Do not keep retrying an already
accepted AAB. The bootstrap bundle is the deliberate exception with fixed code 1.

GitHub's concurrency group prevents overlapping deployments; it is not a durable
queue of every pushed tag. A newer pending run can replace an older pending run.
Release one version at a time and inspect Actions when pushing multiple tags.

Missing secrets fail before the build. Invalid keystore passwords/aliases fail
during signing. A 403 from Play usually means API/permission setup needs checking.
If Play says only draft releases are allowed, finish the first manual rollout
and required Console setup; this lane deliberately creates completed internal
releases, not drafts. Do not automatically retry arbitrary Play errors as drafts.

Temporary credential files live under the runner's temporary directory and are
removed in an `always()` cleanup step. The artifact contains only the signed
bundle, checksum, and release metadata. Release artifacts last 30 days; debug
APKs last 14 days.

For a local signed build, set `ANDROID_KEYSTORE_PATH` to an absolute path,
`ANDROID_KEYSTORE_PASSWORD`, `ANDROID_KEY_ALIAS`, `ANDROID_KEY_PASSWORD`, and
`REQUIRE_ANDROID_RELEASE_SIGNING=true` in your environment, then build from
`app/`. Without signing variables, local release builds retain debug signing;
they cannot be uploaded to Play. CI release builds explicitly require upload
signing and cannot silently fall back.
