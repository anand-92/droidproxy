---
description: Summon the Challenger droid (Gemini) to review code, decisions, and design
---

Launch the challenger-gemini droid to review the current code changes, decisions, or design being discussed in this conversation.

Steps:
1. Gather context: run `git diff` (or use the recent conversation context) to understand what's being reviewed.
2. Use the Task tool to launch the subagent:
   - `challenger-gemini` 
3. Pass it the relevant code, design decisions, or architecture being discussed.
4. Once it responds, present a summary of findings and actionable items.

Keep the summary concise and actionable. Focus on real issues, not nitpicks.
