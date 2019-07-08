#!/bin/sh

echo "MISP container version: ${VERSION-}"
echo "Release date: ${RELEASE_DATE-}"
echo "MISP version Information: $(cat "$PATH_TO_MISP/VERSION.json")"
exit