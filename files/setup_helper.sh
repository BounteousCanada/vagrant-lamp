#!/usr/bin/env bash

RED='\033[1;31m'
GREEN='\033[1;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

function print_header() {
    echo -e
    printf "${YELLOW}*%.0s${NC}" $(seq 1 $((${#1} + 6)))
    echo -e "\n${YELLOW}*  ${1}  *${NC}"
    printf "${YELLOW}*%.0s${NC}" $(seq 1 $((${#1} + 6)))
    echo -e
}