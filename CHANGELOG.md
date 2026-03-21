# Changelog

## [0.2.0](https://github.com/gi11es/deckard/compare/v0.1.9...v0.2.0) (2026-03-21)


### Features

* replace claude wrapper with persistent hooks configuration ([5e9c040](https://github.com/gi11es/deckard/commit/5e9c040c371fae78fe02ea69dc4dd2152e0e4405))


### Bug Fixes

* bypass login(1) via direct command execution ([ec3509d](https://github.com/gi11es/deckard/commit/ec3509d054e49c86b6c4dd800d4e3ad78465eec7))
* defer autosave until session restore completes ([2d1b71f](https://github.com/gi11es/deckard/commit/2d1b71f03f9af05e6fd6626e4da039fcdb10e307))
* dispatch ghostty surface calls off main thread to prevent deadlock ([255003e](https://github.com/gi11es/deckard/commit/255003e4ce032f74ac81f14e62c4f59ab1c7f373))
* drain surfaceQueue before freeing ghostty surface ([6ce3e2d](https://github.com/gi11es/deckard/commit/6ce3e2d954eb51bbaf06741e5cea45a0899ea4e2))
* prevent deadlock and crashes from rapid tab creation ([04d3568](https://github.com/gi11es/deckard/commit/04d35685b48402acd4f69668fd6ca78c21219318))
* rebuild sidebar when creating new tabs interactively ([517992d](https://github.com/gi11es/deckard/commit/517992defffb64d473ea3abc5f4d98ae770c8ab3))
* respect user's default shell for terminal tabs ([#15](https://github.com/gi11es/deckard/issues/15)) ([6760c3a](https://github.com/gi11es/deckard/commit/6760c3a9186d3ea99d2e938ea55261d0409f69ad))
* respect user's default shell for terminal tabs ([#15](https://github.com/gi11es/deckard/issues/15)) ([1cef76d](https://github.com/gi11es/deckard/commit/1cef76d7d03517c8a53a60a7d0fd267e46be6f00))
* respect user's default shell for terminal tabs ([#15](https://github.com/gi11es/deckard/issues/15)) ([f11fb9c](https://github.com/gi11es/deckard/commit/f11fb9c94743f2234bfe7636350bd9c5072f6de8))
* rewrite process monitor to use socket-based PID registration ([a29f58c](https://github.com/gi11es/deckard/commit/a29f58c0e0d4d171853af0178540df36ce633751))
* suppress "Last login" message via ghostty macos-hush-login option ([51a575b](https://github.com/gi11es/deckard/commit/51a575b6fe45a267b86c5ca511ccafb5a44a819a))
* sync sidebar dots when tabs are reordered ([e186d76](https://github.com/gi11es/deckard/commit/e186d76aa513aecda06f165f383e8024c34889bd))
* use Deckard's claude wrapper for hooks and activity detection ([43063c3](https://github.com/gi11es/deckard/commit/43063c323dde7c8743bae7cca96a5d52b3d96893))
* use register-pid script for shell-less tab spawning ([505d339](https://github.com/gi11es/deckard/commit/505d3394c3121270b709d60c330b6aa6a22d9ce5))
* use shell PID as activity tracking key instead of login PID ([b4ffa8f](https://github.com/gi11es/deckard/commit/b4ffa8fb6dbac51d3ad9d3d1432dcc9a55159a20))
* write hooks to settings.json without escaped slashes ([489e2bf](https://github.com/gi11es/deckard/commit/489e2bf4a9e2a7f09ac794e4c9dac69e526d5fb3))

## [0.1.9](https://github.com/gi11es/deckard/compare/v0.1.8...v0.1.9) (2026-03-19)


### Bug Fixes

* handle mouse visibility action for hide-while-typing ([f739da8](https://github.com/gi11es/deckard/commit/f739da8d7abacfc187a177379a378495059b2266))
* remove README from release-please extra-files ([236943c](https://github.com/gi11es/deckard/commit/236943cce8c442371aeab80f16398f308f165deb))
* use shields.io query-param format for README badge version ([afbb7c5](https://github.com/gi11es/deckard/commit/afbb7c5044e7e90856a003b32e91dcba912a0c70))
