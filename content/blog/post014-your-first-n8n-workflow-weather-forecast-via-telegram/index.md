---
title: 'Your first n8n workflow: weather forecast via Telegram'
description: 'Learn how to create your first n8n workflow that sends a daily weather forecast via Telegram.'
date: 2026-02-28
draft: true
author: 'Mati'
tags:
  - n8n
  - Telegram
  - Workflow
categories:
  - DevOps
lightgallery: true
---

## Preface

---

In the [previous post]({{< ref "blog/post013-step-into-n8n-automation-local-setup-with-dockerfile" >}})
we set up n8n locally with Docker Compose. The instance is running, but an automation tool without
a workflow is just an empty canvas.

In this post we will build a small, practical workflow: a scheduled job that fetches the current
weather from the OpenWeatherMap API and sends you a summary via Telegram. It covers three core
n8n concepts — triggers, HTTP requests, and third-party integrations — so you will have a solid
foundation to create more complex automations on your own.

---

## Your first workflow: weather forecast via Telegram

Now that n8n is running, let's build something useful — a workflow that checks the weather
and sends you a message on Telegram. It takes about five minutes.

### What you need first

1. **A Telegram bot** — open Telegram, search for `@BotFather`, send `/newbot`, follow the prompts.
   You will get an API token like `123456:ABC-DEF1234`. Save it.
2. **Your Telegram chat ID** — send any message to your new bot, then open
   `https://api.telegram.org/bot<YOUR_TOKEN>/getUpdates` in a browser.
   Look for `"chat":{"id":123456789}` — that number is your chat ID.
3. **An OpenWeatherMap API key** — sign up at [openweathermap.org](https://openweathermap.org/api),
   the free tier is enough. You will get an API key from your account dashboard.

### Build the workflow step by step

Open n8n at `http://localhost:5678` and click **Add workflow**. Then add nodes one by one:

#### 1. Schedule Trigger

This starts the workflow automatically. Click the canvas, search for **Schedule Trigger**
and add it. Set it to run once a day (or every hour — whatever you prefer).

#### 2. HTTP Request — get the weather

Add an **HTTP Request** node and connect it to the trigger. Configure it like this:

| Field  | Value                                                                                      |
| ------ | ------------------------------------------------------------------------------------------ |
| Method | GET                                                                                        |
| URL    | `https://api.openweathermap.org/data/2.5/weather?q=Vienna&units=metric&appid=YOUR_API_KEY` |

Replace `Vienna` with your city and `YOUR_API_KEY` with the key from OpenWeatherMap.

Click **Test step** to make sure you get a JSON response with temperature, description, etc.

#### 3. Telegram — send the message

Add a **Telegram** node and connect it to the HTTP Request node.

First, set up the credentials:

- Click **Credential to connect with** → **Create New**
- Paste your bot token from BotFather

Then fill in the fields:

| Field   | Value                                     |
| ------- | ----------------------------------------- |
| Chat ID | Your chat ID (the number you got earlier) |
| Text    | See the message template below            |

For the **Text** field, click the expression editor (the little `=` icon) and paste:

```text
🌤 Weather in {{ $json.name }}:
🌡 Temperature: {{ $json.main.temp }}°C (feels like {{ $json.main.feels_like }}°C)
💧 Humidity: {{ $json.main.humidity }}%
📝 {{ $json.weather[0].description }}
```

#### 4. Test and activate

Click **Test workflow** to run it once. You should receive a Telegram message within a few seconds.
If it works, toggle the **Active** switch in the top-right corner so n8n runs it on schedule.

That's it — you now have an automated daily weather report on Telegram,
built entirely on your local machine.

---

## Summary

The weather-to-Telegram workflow
shows how easy it is to wire up APIs visually — from here you can connect anything:
notifications, databases, webhooks, CI/CD events, and more.
