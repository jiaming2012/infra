#!/bin/bash

export ESDB_URL="esdb://us.loclx.io:21133?tls=false&keepAliveTimeout=10000&keepAliveInterval=10000"

go run main.go