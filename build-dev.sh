#!/bin/bash
docker build -t symfony-react:7-18-8.3-dev \
 --build-arg FRONT_SCRIPT=dev \
 .
