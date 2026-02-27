# SailingMedAdvisor Crossplatform Installer

## Project Banner

| Field | Details |
| --- | --- |
| Project | `SailingMedAdvisor` |
| Maintainer | Rick Escher |
| Blog | [www.aphrodite.cat](https://www.aphrodite.cat) |
| Email | [rick@escher.ca](mailto:rick@escher.ca) |
| WhatsApp | +1-613-729-7579 (Canada) |
| Framework | Google HAI-DEF |
| Models | Google MedGemma (`4B` and `27B`) |
| Challenge Context | Kaggle MedGemma Impact Challenge |
| Primary Stack | FastAPI, SQLite, HTML/CSS/JavaScript |
| License | CC BY 4.0 (`LICENSE`) |

This installer guide supports both Windows and macOS.

```text
APPLE (macOS)                  WINDOWS
    .:'
  __:'__
.'  _  '.                    +-----+-----+
:  ( )  :                    |     |     |
'.     .'                    +-----+-----+
  `-.-'                      |     |     |
                             +-----+-----+
```

Important rule for this guide:
- One install method per platform only.
- Download ZIP, extract ZIP, run one installer script.

---

## 1) Before You Start (Both Platforms)

You need:
1. Internet connection for package/model download during setup.
2. A Hugging Face account: `https://huggingface.co/join`
3. On Windows, the installer will require Microsoft Visual C++ Redistributable (x64) for PyTorch.
   - Download link: `https://aka.ms/vs/17/release/vc_redist.x64.exe`
   - The installer now checks this automatically.
4. Acknowledge MedGemma terms on both pages:
   - `https://huggingface.co/google/medgemma-1.5-4b-it`
   - `https://huggingface.co/google/medgemma-27b-text-it`
5. A Hugging Face token (Read scope):
   - Open: `https://huggingface.co/settings/tokens`
   - Click: `Create new token`
   - In `Token name`, enter a name (example: `medgemma`)
   - In permissions/scope, select: `Read`
   - Click: `Create token`
   - Immediately copy the full token (starts with `hf_`) and save it in a local text file.
   - Important: Hugging Face will not show the full token again later.

The installer script will ask for the token when needed.

---

## 2) Download The ZIP (Both Platforms)

1. Open:
   - `https://github.com/rickeae/SailingMedAdvisor-crossplatform`
2. Click:
   - `Code` -> `Download ZIP`
3. Extract the ZIP.
4. Open the extracted folder named:
   - `SailingMedAdvisor-crossplatform`

After this step, choose your platform section below.

---

## 3) WINDOWS INSTALL

```text
__        ___ _   _ ____   _____        _____
\ \      / (_) \ | |  _ \ / _ \ \      / / __|
 \ \ /\ / /| |  \| | | | | | | \ \ /\ / /\__ \
  \ V  V / | | |\  | |_| | |_| |\ V  V / |___/
   \_/\_/  |_|_| \_|____/ \___/  \_/\_/       
```

Use this one installer script:

```bat
launch_windows_installer.cmd
```

Steps:
1. Open `SailingMedAdvisor-crossplatform` in File Explorer.
2. Double-click `launch_windows_installer.cmd`.
3. The launcher runs a built-in installer self-test first.
4. Follow prompts in the terminal window.
   - when asked for Hugging Face token, paste only the token value (starts with `hf_`)
5. When setup finishes, start the app with:
   - `launch_windows_app.cmd`
6. Open browser:
   - `http://127.0.0.1:5000`
7. In the app, verify model cache:
   - `Settings -> Offline Readiness Check -> Check cache status`

---

## 4) MACOS INSTALL

```text
 __  __    _    ____
|  \/  |  / \  / ___|
| |\/| | / _ \| |
| |  | |/ ___ \ |___
|_|  |_/_/   \_\____|
```

Use this one installer script:

```bash
./launch_macos_installer.command
```

Steps:
1. Open `SailingMedAdvisor-crossplatform` in Finder.
2. Double-click `launch_macos_installer.command`.
3. If blocked, right-click -> `Open` -> `Open`.
4. Follow prompts in the terminal window.
   - when asked for Hugging Face token, paste only the token value (starts with `hf_`)
5. When setup finishes, start the app with:
   - `launch_macos_app.command`
6. Open browser:
   - `http://127.0.0.1:5000`
7. In the app, verify model cache:
   - `Settings -> Offline Readiness Check -> Check cache status`

---

## 5) If Install Is Blocked

Windows:
- If SmartScreen appears, choose `More info` -> `Run anyway`.

macOS:
- If Gatekeeper blocks a launcher, right-click the `.command` file and choose `Open`.

If model download fails with `403`:
- Recheck that MedGemma terms were accepted on both model pages.
- Recreate token (Read scope) and rerun the same installer script.

---

## 6) Uninstall (Optional)

Windows uninstall script:
- `launch_windows_uninstall.cmd`

macOS uninstall script:
- `launch_macos_uninstall.command`

---

## Security Notes

- Do not store Hugging Face tokens in source code.
- Do not commit local secret files.
- Keep model downloads local to the user machine after terms acceptance.
