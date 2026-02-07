---
name: setting-up-python-with-uv
description: Sets up Python projects using uv for virtual environment creation and package management. Use when setting up a Python project, creating a venv, or installing Python dependencies.
---

# Setting Up Python Projects with uv

Use `uv` as the preferred tool for Python virtual environment creation and package management instead of raw `pip` or `python -m venv`.

## Prerequisites

Ensure `uv` is installed:

```bash
brew install uv
```

## Workflow

### 1. Create a virtual environment with a specific Python version

```bash
uv venv --python=3.12 .venv
```

- uv will automatically download the requested Python version if not already available.
- No need to install Python separately via brew or pyenv.

### 2. Activate the virtual environment

```bash
source .venv/bin/activate
```

### 3. Install packages

Use `uv pip install` instead of `pip install`:

```bash
uv pip install -e '.[all]'          # editable install with all extras
uv pip install -e 'packages/foo'    # editable install of a sub-package
uv pip install requests             # install a single package
uv pip install -r requirements.txt  # install from requirements file
```

### 4. Install dev/test tools

```bash
uv pip install hatch pytest ruff    # or whatever the project uses
```

## Key Rules

- Always use `uv pip install` rather than bare `pip install` when inside a uv-created venv.
- Prefer `uv venv --python=X.Y` over `brew install python@X.Y` or `pyenv install X.Y`.
- Check the project's `pyproject.toml` or `setup.cfg` for the minimum Python version (`requires-python`).
- Look for optional dependency groups (e.g., `[all]`, `[dev]`, `[test]`) and install the appropriate ones.
