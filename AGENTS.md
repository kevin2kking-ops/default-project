# Project Overview

This directory ("Default Project") is a personal workspace of several independent efforts, not a single software product.

## Contents

- **sst-starter/** — SST v4 TypeScript serverless app (home: AWS, app name `sst-starter`). See `sst-starter/package.json`, `sst.config.ts`.
- **scripts/** — Automation scripts: `ai-top-monitor/`, `desktop-rotate/`, `smart-startup/`, `auto-organize-downloads.ps1`.
- **field-manual/** — HTML pages (system monitor).
- **Guardian/** — Faces / guardian (camera/security related).
- **sorry-juliet/** — HTML page (`sorry-juliet/index.html`, "For Juliet ♡").
- **BBIT_Y2S1 materials** — University (BBIT Y2S1): 3-month study plan (`.md`/`.pdf`), course details (`.csv`/`.json`/`.md`), weekly tracker, calendar reminders.
- **Stark_Wealth_Master_Plan.md**, **Stark_90_Day_Tracker.csv**, other **Stark_* files** — personal finance / wealth planning.
- **.opencode/** — OpenCode configuration (agents, commands, skills, plugins).

## Environment & Conventions

- OS: Windows (win32); shell: PowerShell 5.1.
- sst-starter: SST v4 + TypeScript, strict mode (`tsconfig.json`: target/module `ESNext`, `moduleResolution`: `Bundler`); keep handler code in `sst-starter/src/`.
- Commands: `npm run dev` (`sst dev`); `npm run deploy` (`sst deploy --stage production`). sst-starter has no `test` or `lint` scripts configured.
- Do not commit secrets. API keys live in `.opencode/opencode-key` (gitignored).

## Working Rules

- **Ask clarifying questions in plan mode when requirements are ambiguous.** The default agent is `plan` (see `opencode.jsonc`): when the ask is underspecified or has several possible readings, ask instead of guessing — wait for the user's answer before planning edits.
- **Git workflow:** work on the current branch (`master` — history is empty, no commits yet). Use clear, descriptive commit messages scoped to one change. Note that `git push` and `git reset --hard` require approval (see `opencode.jsonc` permissions).
