# Slack ↔ Claude integration (optional, opt-in)

These files harden and extend how Claude connects to Slack. They are **optional
add-ons**: nothing here is wired into `docker-compose.yml` or the default
startup path, so the core starter kit stays minimal and cloud-free. Use them
only if you want Claude to operate in Slack.

## Why this exists

An audit of the live Slack connection found it authenticating as a **personal
Owner/Admin user account** rather than a dedicated bot. That is the main
weakness:

- Actions are attributed to a human, indistinguishable from that person typing.
- The token carries **full workspace-admin scope** — far more than posting
  messages needs. A leak compromises the entire workspace, not just a bot.
- It is not least-privilege and not cleanly auditable as automation.

## Fix: a dedicated least-privilege Slack bot (`slack-app-manifest.yaml`)

1. Go to <https://api.slack.com/apps> → **Create New App** → **From an app
   manifest**.
2. Select your workspace, paste the contents of `slack-app-manifest.yaml`, and
   create the app.
3. **Install to Workspace** and copy the **Bot User OAuth Token** (`xoxb-…`).
4. Use that bot token wherever Slack is configured (n8n Slack credential, or
   your MCP/integration config) **instead of a personal user token**.
5. Invite the bot only to the channels it should act in
   (e.g. `/invite @claude` in `#ai-auto-dsp-`).

The manifest requests only: `app_mentions:read`, `chat:write`,
`channels:history`, `groups:history`, `im:history`, `im:write`, `commands`,
`users:read`. Trim any you do not need.

> For a fully local/private deployment, prefer **Socket Mode** (set
> `socket_mode_enabled: true` and drop the public `request_url`) so Slack does
> not need to reach a public URL.

## Optional: run Claude in Slack via n8n (`n8n-slack-claude-workflow.json`)

A ready-to-import workflow: **Slack Trigger → Basic LLM Chain (Anthropic Claude)
→ Reply in Slack**.

1. In n8n (`localhost:5678`) → **Workflows** → **Import from File** → choose
   `n8n-slack-claude-workflow.json`. (Import via the UI — do **not** drop it in
   `n8n/demo-data/`, which would bake a cloud integration into the core stack.)
2. Create an **Anthropic** credential (API key) and a **Slack** credential (the
   `xoxb-…` bot token above), then assign them to the nodes (the placeholder
   credential IDs will show as "not set").
3. Open **Anthropic Chat Model** and pick your model from the dropdown (it lists
   the models your API key can access).
4. The **Slack Trigger** needs to receive events. Either let the node register
   its webhook and set that URL as the app's Events request URL, or use Socket
   Mode. On a local-only host you will need a tunnel to expose the webhook.
5. Verify field paths for your event: this workflow reads the message text from
   `{{ $json.text }}` and the channel from
   `{{ $('Slack Trigger').item.json.channel }}`. Adjust if your Slack Trigger
   output nests them differently.
6. Activate the workflow and mention the bot in Slack.

> This uses the Anthropic cloud API, which is intentionally outside the
> starter kit's local/privacy-first default. It is provided here as an opt-in
> extra, not a change to the shipped stack.

## Alternative: native Claude Code in Slack

If your goal is "@Claude in Slack to do coding work" (this is how the
`claude/slack-*` session branch is created), use the official Claude Code Slack
integration rather than a broad user-token MCP. See
<https://code.claude.com/docs> for setup.
