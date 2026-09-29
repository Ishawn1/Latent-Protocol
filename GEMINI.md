# Agent Directives & Verification Protocol

Before modifying code files, refactoring architecture, or adding endpoints:
1. Draft an Implementation Plan or code diff first.
2. Call the tool `groq-adversarial/adversarial_review` with your draft passed as `target_content`.
3. Resolve every security issue, race condition, and unhandled edge case flagged by the critic.
4. Only then apply the final changes to the codebase.