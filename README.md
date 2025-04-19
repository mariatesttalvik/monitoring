# Logging, Monitoring, and Observability Guide

This project is a course site powered by [MkDocs](https://www.mkdocs.org/) and [Material for MkDocs](https://squidfunk.github.io/mkdocs-material/).

## 🧠 Where to Make Changes

- All documentation lives inside the `docs/` folder.
- The navigation and site config is defined in `mkdocs.yml`.
- Most content lives under:
  - `docs/labs/` – practical lab guides
  - `docs/lectures/` – theory and reference
  - `docs/final_project/` – final project setup
  - `docs/resources/` – extra tips, setup, and guides

## 🚀 How to Run Locally

Create a virtual environment and install dependencies:

```bash
python3 -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
```

Then serve the site:

```bash
mkdocs serve
```

It’ll open your local version at [http://127.0.0.1:8000](http://127.0.0.1:8000).

## 📦 How to Deploy

This pushes the site to the `gh-pages` branch:

```bash
mkdocs gh-deploy --clean
```

## ✅ Check Before Deploying

- Are you on the correct branch? Usually: `maria-loengud`
- Did you build with `mkdocs build` or test with `mkdocs serve`?
- Are all new or renamed files listed in `mkdocs.yml` nav?

## 🧼 .gitignore Suggestions

```gitignore
.venv/
.DS_Store
__pycache__/
site/
```