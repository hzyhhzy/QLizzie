# QLizzie | [中文版](README.zh-CN.md)

QLizzie is a Qt 6 AI analysis interface for Go, Gomoku, Hex, and similar board games, mainly targeting KataGo/KataGomo-style engines, with functionality and visual style inspired by LizzieYZY.

## Screenshots

### Go Analysis

![QLizzie Go analysis screenshot](docs/images/screenshot-go.png)

### Hex Analysis

![QLizzie Hex analysis screenshot](docs/images/screenshot-hex.png)

## Overview

QLizzie is a desktop analysis board built with Qt 6. It focuses on a clean 2D board, engine candidate visualization, a Lizzie-like left analysis panel, and a game tree workflow for reviewing variations across multiple board games.

The project references LizzieYZY for feature direction and visual behavior, but it is a separate Qt 6 implementation. It was built through an iterative Codex vibe-coding workflow.

## Features

- Go, Gomoku, Hex, Connect6, Reversi, hexagonal Go variants, Ataxx, Breakthrough, and free-grid analysis modes
- Scalable 2D board with multiple coordinate formats, stones, move numbers, and candidate markers
- Hex triangle-grid and filled-hex-cell board presentations, including rotated/flipped display modes
- Win-line/path highlighting for Gomoku and Hex
- GTP engine integration, including KataGo/KataGomo-style `kata-analyze`
- Engine preset list for switching between multiple engine commands and rule defaults
- Candidate list, winrate, visits, score/draw-rate display, ranking labels, and variation preview
- Per-node analysis cache in the game tree for previously analyzed positions
- Game tree navigation, node deletion, branch handling, and SGF loading/saving
- Engine communication log
- English and Chinese UI

## Build

Requirements:

- Qt 6.4+
- CMake
- A C++17-capable compiler, such as MSVC on Windows

Example build:

```powershell
cmake -S . -B build/qlizzie
cmake --build build/qlizzie --config Release
```

The executable is generated under the selected build directory, for example:

```text
build/qlizzie/app/Release/qlizzie.exe
```

### Linux (Ubuntu/Debian)

Install the required Qt 6 development packages:

```bash
sudo apt install \
    cmake \
    qt6-base-dev \
    qt6-base-dev-tools \
    qt6-declarative-dev \
    qml6-module-qtquick \
    qml6-module-qtquick-window \
    qml6-module-qtquick-controls \
    qml6-module-qtquick-layouts \
    qml6-module-qtquick-dialogs \
    qml6-module-qtquick-templates \
    qml6-module-qtqml-workerscript
```

Then build and run:

```bash
cmake -S . -B build/qlizzie
cmake --build build/qlizzie --config Release -j4
./build/qlizzie/app/qlizzie
```

## Engine

QLizzie communicates with GTP-compatible AI engines. Engine presets can store a name, command line, rule type, default board size, komi, and Hex coordinate compatibility settings.

For KataGo/KataGomo-style analysis, use an engine command that starts GTP mode and points to your config and model files. QLizzie is primarily developed and tested around KataGo-family `kata-analyze` output.

## Relationship To LizzieYZY

QLizzie is not LizzieYZY and is not affiliated with the LizzieYZY project. LizzieYZY is used as a reference for the expected analysis workflow, candidate display behavior, and overall interface feel.

## Friendly Links

- [LizzieYZY](https://github.com/yzyray/lizzieyzy)
- [Lizzie3D](https://github.com/hzyhhzy/Lizzie3D)

## License

QLizzie is released under the GNU General Public License v3.0. See [LICENSE](LICENSE).
