# Security Policy

## Introduction

The Yggdrasil Engine is a mathematical and data-driven framework focused on procedural cosmology simulation for personal, non-commercial use. Security is important to maintain the integrity of the example code implementations (e.g., in Unity C# and Unreal C++). This policy outlines how to report vulnerabilities responsibly, in line with the project's [Personal Use License](LICENSE) and emphasis on preserving core invariants, intellectual property, and prior art.

Vulnerabilities may include issues in executable code that could lead to exploits, data leaks, or unintended behavior in integrated environments like game engines. The canonical mathematical models, JSON data, and documentation are not executable and are out of scope unless they indirectly enable a code-based vulnerability.

## Supported Versions

- Current version: v1.0 (as defined in core JSON schemas and docs).
- Example implementations: Tested on Unity 2022+ and Unreal 5.0+. Only the latest examples in `examples/` are actively supported for security fixes.
- Legacy/archive files are for historical purposes only and not supported.

## Reporting a Vulnerability

We encourage responsible disclosure. If you find a potential security issue:

1. **Do Not Disclose Publicly**: Avoid creating public GitHub issues, discussions, or pull requests that reveal the vulnerability. This helps prevent exploitation while we address it.
2. **Contact the Creator**: Send a detailed report to the project maintainer (Flynn) via GitHub's private messaging or by opening a draft security advisory on GitHub (if available). Include:
   - A clear description of the vulnerability.
   - Steps to reproduce (e.g., affected code in `YggdrasilAgent.cpp`).
   - Potential impact (e.g., on user systems integrating the engine).
   - Any proposed fixes or patches.
3. **Response Timeline**:
   - Acknowledgment: Within 48 hours.
   - Initial assessment: Within 7 days.
   - Fix deployment: As soon as possible, prioritized based on severity.
4. **Confidentiality**: We will keep your report confidential until a fix is released, unless you agree otherwise.

If the vulnerability affects third-party dependencies (e.g., JSON parsers in examples), we may direct you to report upstream while coordinating a project-specific patch.

## Disclosure Process

- Once fixed, we will credit you in the release notes (unless you prefer anonymity).
- Public disclosure will occur after the fix is merged into the main branch.
- Severe issues may warrant a security advisory on GitHub.

## Best Practices for Users

- Use the engine only for personal projects as per the LICENSE.
- Regularly update from the main repository.
- Review and audit example code before integrating into your own projects.
- Report any suspected issues promptly to help maintain the framework's reliability.

Thank you for helping keep the Yggdrasil Engine secure. The tree's roots depend on vigilant guardians.

— Flynn, Creator (2025)
