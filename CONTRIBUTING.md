# Contributing to SmartKheti

Thank you for your interest in contributing! This document outlines the guidelines for submitting issues, feature requests, and pull requests.

---

## Code of Conduct

Be respectful and constructive. All contributors are expected to adhere to the [Contributor Covenant](https://www.contributor-covenant.org/) code of conduct.

---

## Getting Started

1. **Fork** the repository.
2. **Clone** your fork and run git lfs install before pulling (required for TFLite model files).
3. Create a **feature branch**: git checkout -b feat/your-feature-name.
4. Make your changes and add tests where applicable.
5. Open a **pull request** against the main branch.

---

## Security Issues

> **⚠️ Do NOT open a public GitHub issue for security vulnerabilities.**

If you discover a security issue (e.g., credential exposure, injection risk in the firmware HTTP server), please contact the maintainers privately via the repository's email or security advisory feature before disclosure.

---

## Firmware Changes

- Test firmware changes on a real ESP32-S3 N16R8 board before submitting.
- Do **not** commit default or production credentials. Use placeholder values only:
  `cpp
  #define AP_SSID  "YourCustomSSID"
  #define AP_PASS  "YourStrongPassword!"
  #define SMARTKHETI_TOKEN "your-secret-token-here"
  `
- Keep AI model weights in SmartKhetiAI.h updated with matching scaler values from training.

---

## Flutter / Dart Changes

- Follow the existing code style (Dart analysis options in nalysis_options.yaml).
- Do not expose API keys, tokens, or passwords in source code or commits.
- Run lutter analyze and lutter test before submitting a PR.
- Test on a physical Android device (API 26+); the app requires camera and Wi-Fi AP connectivity.

---

## Adding AI Models

- Place new .tflite models in ssets/models/ and register them in lib/models/ai_model_registry.dart.
- Update pubspec.yaml assets list.
- Models must be INT8-quantised and compatible with the ultralytics_yolo plugin.

---

## Commit Message Style

Use [Conventional Commits](https://www.conventionalcommits.org/):

`
feat(firmware): add BLE telemetry fallback
fix(irrigation): correct valve expiry calculation
docs: update wiring reference for ESP32-S3 N16R8
`

---

## Pull Request Checklist

- [ ] No hardcoded credentials or API keys
- [ ] lutter analyze passes with no errors
- [ ] Existing tests pass
- [ ] README / docs updated if behaviour changes
- [ ] PR description explains the motivation and approach
