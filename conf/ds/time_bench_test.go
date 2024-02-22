package ds_test

import (
	"embed"
	"os"
	"os/exec"
	"testing"
)

//go:embed time.lua
var timeLua embed.FS

func Benchmark_lua_ensure_time(b *testing.B) {
	f, _ := os.CreateTemp("/tmp", "")
	bytes, _ := timeLua.ReadFile("time.lua")
	f.Write(bytes)
	// write from embed.FS to file
	for i := 0; i < b.N; i++ {
		cmd := exec.Command("lua", f.Name())
		//cmd.Stdout = os.Stdout
		//cmd.Stderr = os.Stdout
		err := cmd.Run()
		if err != nil {
			b.Fatal(err)
		}
	}
}
