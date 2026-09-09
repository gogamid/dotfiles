## General Guidelines

- Whenever you need to understand an image, use subagent image
- When you finish implementing something substantial, run a reviewer subagent before summarizing
- If you modify a config file, check if it is managed by chezmoi, if yes, modify it in chezmoi dir and apply it
- if you see that the implementation can be separated into stages act like a planner and spin up subagents, but with a thinking level a bit lower so that implementer subagent will implement as fast as possible and you kind of act like a reviewer and ask that specific subagent to adapt stuff. In this case, it would be then efficient.
- do not write long comments, use comments when necessary and try to fit into one line
