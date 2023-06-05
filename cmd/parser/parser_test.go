package main

import (
	"bytes"
	"flag"
	"io"
	"log"
	"os"
	"testing"

	"github.com/stretchr/testify/assert"
)

var output *bytes.Buffer

func TestMain(m *testing.M) {
	tmpfile, err := os.CreateTemp("", "deps.*.yaml")
	if err != nil {
		log.Fatal(err)
	}

	defer os.Remove(tmpfile.Name())

	content := []byte(`
binaries:
  goreleaser:
    sha256:
      arm64: ef22fb7a6e11b70cec714440b2649ac2abe6f17eb2932cfca6dbc5b15fb3b240
      x86_64: 811e0c63e347f78f3c8612a19ca8eeb564eb45f0265ce3f38aec39c8fdbcfa10
    url: https://github.com/goreleaser/goreleaser/releases/download/v1.18.2/goreleaser_Linux_amd64.tar.gz
    version: 1.18.2
`)
	if _, err = tmpfile.Write(content); err != nil {
		log.Fatal(err)
	}

	if err = tmpfile.Close(); err != nil {
		log.Fatal(err)
	}

	_ = flag.Set("input", tmpfile.Name())
	old := os.Stdout
	r, w, _ := os.Pipe()
	os.Stdout = w

	output = &bytes.Buffer{}
	go func() {
		_, _ = io.Copy(output, r)
	}()

	main()

	w.Close()

	os.Stdout = old

	os.Exit(m.Run())
}

func TestParser(t *testing.T) {
	assert.NotEmpty(t, output.String())
}

func TestContents(t *testing.T) {
	assert.Contains(t, output.String(), "binaries")
	assert.Contains(t, output.String(), "goreleaser")
}
