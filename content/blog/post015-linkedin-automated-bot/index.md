---
title: 'Build a simple LinkedIn bot for random post ideas'
description: 'Create a lightweight LinkedIn posting bot using Python and the official API, with Copilot CLI generated content examples.'
date: 2026-06-18
draft: false
author: 'Mati'
tags:
  - LinkedIn
  - Python
  - Automation
  - Copilot CLI
categories:
  - DevOps
lightgallery: true
---

## Preface

---
In modern social media, consistency is key. But posting regularly can be a chore.
Many people posting on social media failing to deliver anything but noise. So let me show you how to do it right.

You can automate LinkedIn posting, but do it the smart way: use the official API,
keep a small posting schedule, and review content before publishing to have at least some quality control.

In this post we build a minimal bot that:

1. picks a random message from a local list,
2. can generate new post ideas with Copilot CLI (GPT-5.4-Mini),
3. publishes to LinkedIn through the official UGC API.

---

## Step-by-step: LinkedIn random post bot

### 1. Create a LinkedIn app and get credentials

1. Go to [LinkedIn Developers](https://www.linkedin.com/developers/) and create an app.
2. In your app, enable products/scopes needed for posting (`w_member_social`).
3. Generate an access token (OAuth flow).
4. Get your person URN (`urn:li:person:...`).

You will use these two values in code:

- `LINKEDIN_ACCESS_TOKEN`
- `LINKEDIN_PERSON_URN`

### 2. Create project files

Create a new folder anywhere and add:

```bash
mkdir linkedin-bot && cd linkedin-bot
python3 -m venv .venv
source .venv/bin/activate
pip3 install requests python-dotenv
```

Create `.env`:

```env
LINKEDIN_ACCESS_TOKEN=your_linkedin_access_token
LINKEDIN_PERSON_URN=urn:li:person:your_person_urn
```

Create `posts.txt` (one post per line):
It should act like a small queue of pre-approved posts you can add to over time.

```text
Small systems beat big plans. Ship one useful thing today.
Automate boring tasks first. Your future self will thank you.
If your deploy takes 30 minutes, your feedback loop is broken.
Write docs like the next on-call person is you at 3 AM.
Watever you think about funny about AI slop to engage people attention. # (just don't do it. It's not worth it).
```

This can be also automated with Copilot CLI, see next section.

```bash
NEW_POST="$(copilot --model gpt-5.4-mini --allow-all-tools --prompt 'Generate 10 short LinkedIn posts for DevOps engineers. Tone: practical, no buzzwords, max 220 chars each.')"

printf "%s\n" "$NEW_POST" >> posts.txt
```

### 3. Add the bot script

Create `linkedinbot.py`:

```python
#!/usr/bin/env python3
import os
import random
from pathlib import Path

import requests
from dotenv import load_dotenv

LINKEDIN_API_URL = "https://api.linkedin.com/v2/ugcPosts"


def load_posts(file_path: str) -> list[str]:
  path = Path(file_path)
  if not path.exists():
    raise FileNotFoundError(f"Missing posts file: {file_path}")

  posts = [line.strip() for line in path.read_text(encoding="utf-8").splitlines() if line.strip()]
  if not posts:
    raise ValueError("posts.txt is empty")
  return posts


def post_to_linkedin(token: str, person_urn: str, text: str) -> None:
  headers = {
    "Authorization": f"Bearer {token}",
    "X-Restli-Protocol-Version": "2.0.0",
    "Content-Type": "application/json",
  }

  payload = {
    "author": person_urn,
    "lifecycleState": "PUBLISHED",
    "specificContent": {
      "com.linkedin.ugc.ShareContent": {
        "shareCommentary": {"text": text},
        "shareMediaCategory": "NONE",
      }
    },
    "visibility": {
      "com.linkedin.ugc.MemberNetworkVisibility": "PUBLIC",
    },
  }

  response = requests.post(LINKEDIN_API_URL, headers=headers, json=payload, timeout=20)
  if response.status_code not in (200, 201):
    raise RuntimeError(f"LinkedIn API error {response.status_code}: {response.text}")

  print("Post published successfully")
  print(response.text)


def main() -> None:
  load_dotenv()

  token = os.getenv("LINKEDIN_ACCESS_TOKEN")
  person_urn = os.getenv("LINKEDIN_PERSON_URN")

  if not token or not person_urn:
    raise EnvironmentError("Missing LINKEDIN_ACCESS_TOKEN or LINKEDIN_PERSON_URN")

  posts = load_posts("posts.txt")
  selected = random.choice(posts)

  print("Selected post:")
  print(selected)
  post_to_linkedin(token, person_urn, selected)


if __name__ == "__main__":
  main()
```

Run it:

```bash
python linkedinbot.py
```

### 4. Optional: schedule it

Use cron if you want automatic posting at fixed times.

```bash
crontab -e
```

Example (Mon/Wed/Fri at 20:30):

```cron
30 20 * * 1,3,5 cd /path/to/linkedin-bot && /path/to/linkedin-bot/.venv/bin/python linkedinbot.py >> linkedinbot.log 2>&1
```

Keep frequency low and content useful.

---

## Generate post ideas with Copilot CLI (GPT-5.4-Mini)

I use Copilot CLI to generate a batch of short drafts, then I keep only the best ones.

Example prompt in Copilot CLI:

```bash
copilot --model gpt-5.4-mini --prompt \
  "Write one LinkedIn post for DevOps engineers, practical tone, max 220 chars, no hashtags"
```

Quick workflow:

1. Generate 20 candidates with Copilot CLI.
2. Pick 5 that sound like you.
3. Save them to `posts.txt`.
4. Let the bot pick one randomly.

---

## Small hardening tips

Before you fully trust automation, add these:

1. **Dry run mode**: print post text without publishing.
2. **Minimum interval**: prevent posting too often.
3. **Content filter**: skip too-short or duplicate posts.
4. **Manual approval mode**: require Enter before publish.

Simple dry run toggle:

```python
DRY_RUN = True

if DRY_RUN:
  print("DRY RUN - not publishing")
  print(selected)
else:
  post_to_linkedin(token, person_urn, selected)
```

---

## Summary

This setup gives you a clean, minimal LinkedIn bot:

- official API,
- random post selection,
- optional Copilot CLI draft generation,
- easy scheduling.

Start small, keep quality high, and automate only what you would be happy to post manually.
