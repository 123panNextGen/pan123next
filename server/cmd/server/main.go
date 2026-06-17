package main

import (
	"flag"
	"fmt"
	"os"
	"os/signal"
	"syscall"

	"pan123next_downloader/pkg/server"
)

func main() {
	dataDir := flag.String("data-dir", ".", "数据持久化目录")
	flag.Parse()

	port, err := server.StartServer(*dataDir)
	if err != nil {
		fmt.Fprintln(os.Stderr, "failed to start server:", err)
		os.Exit(1)
	}

	fmt.Println(port)

	sig := make(chan os.Signal, 1)
	signal.Notify(sig, syscall.SIGINT, syscall.SIGTERM)
	<-sig
	server.SaveTasks(*dataDir)
}
