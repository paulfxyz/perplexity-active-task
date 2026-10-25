# Contributing

Focused bug fixes, clearer documentation, and native usability improvements are welcome. Keep the project small: it is a window onto the website, not an alternative task backend.

## Development

Build on macOS with Xcode Command Line Tools. Node.js 22 and the development-only jsdom package are used for JavaScript/DOM tests; the native release has no third-party runtime dependencies.

```sh
npm ci
npm test
mkdir -p build
xcrun swiftc Sources/Behavior.swift tests/WindowBehaviorTests.swift -o build/behavior-tests
build/behavior-tests
bash scripts/build.sh
```

Run the real app to check keyboard behavior, settings, window focus, and frame restoration. Tests and fixture screenshots do not replace authenticated website acceptance.

## Pull requests

- **Keep scope clear:** Explain the problem, change, and checks performed. Distinguish automated tests from manual observations.
- **Preserve native behavior:** Floating and inactive dimming are independent, with full opacity restored on focus.
- **Respect website boundaries:** No cookie import, undocumented credential extraction, provider-policy bypass, private API probing, or broad navigation-hiding rules.
- **Keep estimates honest:** Read only explicitly labelled credits, preserve original values, disclose the rate, and distinguish session spending from available pool equivalents.
- **Protect private data:** Use synthetic examples. Never commit browser state, passwords, API keys, private task titles, or signed-in screenshots without permission.
- **Synchronize releases:** Keep `Info.plist`, changelog, release notes, and installation notes aligned. Tagging `vX.Y.Z` must match the bundle version.
- **Disclose AI assistance honestly:** AI-assisted contributions are welcome; contributors remain responsible for understanding and checking their changes.

Contributions are licensed under this project's [MIT license](LICENSE). See [screenshot instructions](docs/SCREENSHOTS.md) for reproducible documentation images.
