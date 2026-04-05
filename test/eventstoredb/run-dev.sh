#!/bin/bash

export ESDB_URL="esdb://localhost:2113?tls=false&keepAliveTimeout=10000&keepAliveInterval=10000"

go run main.go