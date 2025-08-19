#!/usr/bin/env bash

rm -rf ~/.cache/hugo_cache/
rm -rf ./public
rm -rf ./resources
rm -rf .hugo_build.lock
echo '>> hugo cleanup done.'

# Run pre-commit hooks cleanup
pre-commit gc
pre-commit clean
echo '>> pre-commit cleanup done.'
