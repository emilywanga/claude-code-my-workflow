---
name: mixed-language-bridge
description: Understand mixed Chinese+English user prompts and writing, then execute and reply in English by default. Use when prompts are code-switched, partially translated, or ambiguous across Chinese and English; ask for clarification before proceeding when intent is unclear.
---

# Mixed-Language Bridge

Use this skill whenever the user writes in mixed Chinese and English.

## Core Behavior

1. Parse mixed-language input into a clear English task understanding.
2. Keep all replies and task processing in English by default.
3. Switch reply/output language only when the user explicitly requests Chinese or Japanese.
4. Preserve technical terms, file paths, code, math, and citation keys exactly.

## Ambiguity Protocol

Before running commands or editing files, check for ambiguity in:
- Target file or folder
- Requested action
- Scope boundaries
- Language/output requirement

If any of these are unclear, ask a short clarification question first, then continue after confirmation.

## Explicit Language Override

If the user explicitly asks:
- "reply in Chinese" or "用中文回复": reply in Chinese for that response.
- "reply in Japanese" or "日本語で": reply in Japanese for that response.
- "modify file in Chinese/Japanese": produce file edits in that requested language for the relevant text sections.

After the override task is completed, revert to English-by-default behavior.
