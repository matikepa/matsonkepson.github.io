#!/usr/bin/env bash

# List folders and iterate one number further
# shellcheck disable=SC2012
NEXT_NUM=$(ls -1 content/blog/ | awk '/post[0-9]+/{num=substr($0,5)+0} END{printf "post%03d", (num?num:0)+1}')

# Prompt the user for input
echo "Please enter new post title:"
# shellcheck disable=SC2162
read TITLE

# Exchange whitespaces to hyphens
CLEANED_TITLE=$(echo "${TITLE}" | awk '{gsub(/ /, "-"); print tolower($0)}')

# Prepare folder and proper date
NEW_POST="content/blog/${NEXT_NUM}-${CLEANED_TITLE}"
mkdir -p "${NEW_POST}"
DDATE=$(date +%Y-%m-%d)

cat <<_EOF >"${NEW_POST}"/index.md
---
title: ${TITLE}
summary: Click for more ...
date: ${DDATE}
authors:

  - Mati: author.jpeg

---

## preface

---

here preface

---

## steps

here steps...
_EOF

echo
echo ">> Created new post under ${NEW_POST}"
echo ">> with date ${DDATE}"
