#!/bin/bash

# Download Script
wget https://raw.githubusercontent.com/laveracloudsolutions/github-pipeline-library/refs/heads/main/.scripts/build_and_push.sh -O /tmp/build_and_push.sh

# Exec Script
chmod +x /tmp/build_and_push.sh
/tmp/build_and_push.sh