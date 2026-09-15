#!/usr/bin/env bash

flutter format .
flutter packages pub publish --dry-run
flutter packages pub publish -v