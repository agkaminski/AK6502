#!/bin/sh

VVP="vvp -llog$1.txt $1"
echo $VVP
screen -dmS -X $VVP
echo "Screen started in detached mode."
