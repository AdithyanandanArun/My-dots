#!/bin/sh
if command -v fish >/dev/null 2>&1; then
    exec fish
fi
exec bash
