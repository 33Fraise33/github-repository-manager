# OpenCode V2 agent review loop

Six agent definitions for the agreed model allocation:

| File | Model | Reasoning | When it runs |
| --- | --- | --- | --- |
| orchestrator.md | openai/gpt-6-luna | low | Main conversation and coordination |
| planner.md | openai/gpt-6.1-sol | high | Before implementation; again if replanning is needed |
| implementer.md | openai/gpt-6.1-sol | medium | Implementation and repairs |
| functional-reviewer.md | openai/gpt-6.1-sol | high | Every reviewed revision |
| security-reviewer.md | openai/gpt-6.1-sol | high | Every reviewed revision |
| security-deep-review.md | openai/gpt-6-astra | high | When a security-sensitive change or uncertain risk triggers escalation |

These files target **OpenCode V2**, as discussed. V1 has different configuration
keys and tool names; do not mix the formats.

## Install

1. Copy the six files in `.opencode/agents/` into your repository's
   `.opencode/agents/` directory. Alternatively, use `~/.config/opencode/agents/`
   for agents shared across projects.
2. Merge `opencode.example.jsonc` into your project's `opencode.jsonc`, preserving
   your existing settings. If no config exists, copy it to `opencode.jsonc`.
   The example filename is not automatically loaded as project configuration.
3. In the target project, open `/models` and confirm the three provider/model IDs
   are available with your connected account. The files use the agreed IDs;
   they do not establish access to these models. If your provider exposes different
   IDs, update the agent frontmatter and matching provider/model config together.
4. Start a new session with orchestrator. For an existing session, select both
   the orchestrator agent and the Luna model with the low variant explicitly.

The example config makes orchestrator the default and defines the low/medium/high
variants explicitly. V2 model variants carry the reasoning settings; the earlier
top-level `reasoningEffort` examples mixed V1 and V2 conventions. The root Luna
model also has low reasoning configured because the V2 root default does not retain
a variant. Existing sessions keep their selected agent and model.

## Behavior

The orchestrator obtains a plan and acceptance criteria, then calls the implementer.
Fresh functional and security reviewers inspect each completed revision. Astra
adds an independent gate for important trust boundaries, including authentication,
authorization, payments, secrets, cryptography, tenant isolation, file handling,
user-controlled URLs, query generation, execution, and sensitive-data exposure.
Uncertain risk also triggers Astra. Once triggered, Astra stays required for that task.

All required reviewers must approve the same current revision. A repair invalidates
every earlier approval. The implementer continues in the same child session where
possible; reviewers get fresh sessions. There are at most three repair cycles after
the first implementation, giving up to four reviewed revisions. Failure or missing
review evidence cannot count as approval.

The planner and reviewers have file-inspection access and only five exact Git
commands. They cannot edit through the editing tools or run arbitrary shell
commands. Diffs disable external helpers and text conversion. Review includes
staged, unstaged, and relevant untracked files. Reviewers request test execution
from the implementer and distinguish reported test evidence from static inspection.

The implementer has edit and shell access for coding and verification. Conventional
Git commit/push commands are denied, and its instructions prohibit publication and
workarounds. General shell access is powerful; these rules are not an operating-system
sandbox or a complete command blacklist.

The workflow is driven by agent instructions. Markdown prompts do not provide a
deterministic acceptance gate; enforce mandatory merge/deployment checks in CI or
an external controller if that is required. This loop revises the current change;
it does not train models or automatically rewrite its own agent definitions.

## Validation

The supplied frontmatter and JSON configuration were parsed locally and checked
for agent-name consistency, model variants, and intended permission rules.
No OpenCode executable or authenticated model catalog was available in the creation
environment, so live agent launches and account-specific model access were not tested.

## Official references

- [V2 agents](https://opencode.ai/v2/docs/agents/): agent locations, modes, models, and defaults.
- [V2 models](https://opencode.ai/v2/docs/models/): variants, settings, availability, and session selection.
- [V2 permissions](https://opencode.ai/v2/docs/permissions/): rule order, action names, and shell limitations.
- [V2 tools](https://opencode.ai/v2/docs/tools/): file inspection and continuing a child with sessionID.

Documentation checked on 2026-09-30.
