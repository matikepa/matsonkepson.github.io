---
title: BFG - Git History Repo Cleaner
summary: How to use the BFG repo cleaner to permanently remove large files from Git history and optimize repository size.
date: 2024-11-11
authors:
  - Mati: author.jpeg
---

### preface

Suppose you accidentally committed a 1GB blob file. I assume you are
using [Git Large File Storage (LFS)](https://git-lfs.com/). Even after removing it from your local repository, it still
persists in your **.git** history. How can you permanently remove it?

To learn more about the bfg tool, [use this link](https://rtyley.github.io/bfg-repo-cleaner/).

### steps

First check current status.

Then, if you remove a file locally, it will still appear in the Git object history under **.git/objects**

In the picture below, we can see the complete tree with sizes in MB.

```bash
du -sm ./*
```

![pic](./2024-11-13_16-54.png)

### solution

```bash
git rm --cached GIANT_FILE              # remove blob
bfg --strip-blobs-bigger-than 500M .    # the . indicates local folder
git reflog expire --expire=now --all \
&& git gc --prune=now --aggressive      # manage reference logs and cleanup
git push --force                        # force is optional
```

Double check

```bash
du -sm ./*
```

![pic2](./2024-11-13_17-01.png)
