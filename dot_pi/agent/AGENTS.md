## General Guidelines

- Whenever you need to understand an image, use subagent image
- When you finish implementing something substantial, run a reviewer subagent before summarizing
- If you modify a config file, check if it is managed by chezmoi, if yes, modify it in chezmoi dir and apply it
- In modern Go, prefer `new(expression)` over temporary variables when creating pointers to values

## Response Style

- prefer short human readable responses
- No em dashes
- No markdown tables, use lists instead
- no emojis
