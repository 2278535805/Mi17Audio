#!/bin/sh
MODDIR=${0%/*}
chmod +x "$MODDIR/hyper-audio"
exec "$MODDIR/hyper-audio"
