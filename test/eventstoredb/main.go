package main

import (
	"context"
	"fmt"
	"io"
	"log"
	"os"

	"github.com/EventStore/EventStore-Client-Go/esdb"
)

func main() {
	esdbURL := os.Getenv("ESDB_URL")

	log.Printf("Connecting to EventStoreDB at %s\n", esdbURL)

	settings, err := esdb.ParseConnectionString(esdbURL)
	if err != nil {
		panic(err)
	}

	db, err := esdb.NewClient(settings)
	if err != nil {
		panic(err)
	}

	recv, err := db.ReadAll(context.Background(), esdb.ReadAllOptions{}, 100)
	if err != nil {
		panic(err)
	}

	count := 0

	for {
		_, err := recv.Recv()
		if err != nil {
			if err == io.EOF {
				break
			}

			panic(err)
		}

		count++
	}

	fmt.Println("Successfully connected to EventStoreDB!")
	fmt.Printf("Received %d events\n", count)
}
