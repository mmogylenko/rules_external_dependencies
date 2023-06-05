package main

import (
	"flag"
	"fmt"
	"log"
	"os"

	jsoniter "github.com/json-iterator/go"
	"gopkg.in/yaml.v2"
)

var (
	input = flag.String("input", "", "Input YAML file")
)

func main() {
	flag.Parse()

	if *input == "" {
		log.Fatal("Please provide an input file using the -input flag")
	}

	src, err := os.ReadFile(*input)

	if err != nil {
		log.Fatal("Error reading YAML file:", err.Error())
	}

	var data map[string]interface{}

	err = yaml.Unmarshal(src, &data)
	if err != nil {
		log.Fatal("Error parsing YAML file:", err.Error())
	}

	for key, value := range data {
		j, err := jsoniter.Marshal(value)
		if err != nil {
			log.Fatal("Error marshaling to JSON:", err.Error())
		}

		fmt.Printf("%s = %s\n", key, string(j))
	}
}
