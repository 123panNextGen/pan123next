package server

import (
	"encoding/json"
	"os"
	"path/filepath"
)

const tasksFile = "download_tasks.json"

func SaveTasks(dir string) {
	tasks := GlobalManager.AllTasks()
	data := make([]map[string]interface{}, len(tasks))
	for i, t := range tasks {
		data[i] = t.ToMap()
	}
	b, err := json.MarshalIndent(data, "", "  ")
	if err != nil {
		return
	}
	os.WriteFile(filepath.Join(dir, tasksFile), b, 0644)
}

func LoadTasks(dir string) {
	b, err := os.ReadFile(filepath.Join(dir, tasksFile))
	if err != nil {
		return
	}
	var raw []map[string]interface{}
	if err := json.Unmarshal(b, &raw); err != nil {
		return
	}
	tasks := make([]*DownloadTask, 0, len(raw))
	for _, m := range raw {
		t := TaskFromMap(m)
		if t.Status == StatusDownloading {
			t.Status = StatusPaused
		}
		tasks = append(tasks, t)
	}
	GlobalManager.RestoreTasks(tasks)
}

func defaultDataDir() string {
	exe, err := os.Executable()
	if err != nil {
		return "."
	}
	return filepath.Dir(exe)
}
