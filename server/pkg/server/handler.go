package server

import (
	"encoding/json"
	"log"
	"net"
	"net/http"
	"strings"
	"time"
)

func corsMiddleware(next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		w.Header().Set("Access-Control-Allow-Origin", "*")
		w.Header().Set("Access-Control-Allow-Methods", "GET, POST, DELETE, OPTIONS")
		w.Header().Set("Access-Control-Allow-Headers", "Content-Type")
		if r.Method == "OPTIONS" {
			w.WriteHeader(200)
			return
		}
		next.ServeHTTP(w, r)
	})
}

func jsonResponse(w http.ResponseWriter, status int, data interface{}) {
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(status)
	json.NewEncoder(w).Encode(data)
}

// StartServer 在 127.0.0.1 随机端口上启动 HTTP 服务器，返回监听端口。
func StartServer(dataDir string) (int, error) {
	LoadTasks(dataDir)

	lis, err := net.Listen("tcp", "127.0.0.1:0")
	if err != nil {
		return 0, err
	}

	port := lis.Addr().(*net.TCPAddr).Port

	mux := http.NewServeMux()
	mux.HandleFunc("/api/", func(w http.ResponseWriter, r *http.Request) {
		handleRoutes(w, r, dataDir)
	})

	srv := &http.Server{Handler: corsMiddleware(mux)}
	go srv.Serve(lis)
	return port, nil
}

func handleRoutes(w http.ResponseWriter, r *http.Request, dataDir string) {
	path := r.URL.Path

	switch {
	case path == "/api/tasks" && r.Method == "POST":
		handleAddTask(w, r, dataDir)
	case path == "/api/tasks" && r.Method == "GET":
		handleListTasks(w, r)
	case path == "/api/tasks/completed" && r.Method == "POST":
		handleClearCompleted(w, r, dataDir)
	case strings.HasPrefix(path, "/api/tasks/") && strings.HasSuffix(path, "/progress"):
		handleTaskProgress(w, r)
	case strings.HasPrefix(path, "/api/tasks/") && strings.HasSuffix(path, "/debug"):
		handleTaskDebug(w, r)
	case strings.HasPrefix(path, "/api/tasks/"):
		handleTaskAction(w, r, dataDir)
	default:
		jsonResponse(w, 404, map[string]string{"error": "not found"})
	}
}

func handleAddTask(w http.ResponseWriter, r *http.Request, dataDir string) {
	var req struct {
		URL      string `json:"url"`
		SavePath string `json:"save_path"`
		FileName string `json:"file_name"`
	}
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		jsonResponse(w, 400, map[string]string{"error": "invalid json"})
		return
	}
	if req.URL == "" || req.SavePath == "" {
		jsonResponse(w, 400, map[string]string{"error": "url and save_path required"})
		return
	}

	task := GlobalManager.AddTask(req.URL, req.SavePath, req.FileName)
	SaveTasks(dataDir)
	log.Printf("ADD task %s: %s", task.ID, req.FileName)
	jsonResponse(w, 200, task.PartialClone())
}

func handleListTasks(w http.ResponseWriter, r *http.Request) {
	tasks := GlobalManager.ListTasks()
	jsonResponse(w, 200, tasks)
}

func handleTaskAction(w http.ResponseWriter, r *http.Request, dataDir string) {
	parts := strings.Split(strings.TrimPrefix(r.URL.Path, "/api/tasks/"), "/")
	if len(parts) < 2 {
		jsonResponse(w, 400, map[string]string{"error": "invalid path"})
		return
	}

	id, action := parts[0], parts[1]

	switch r.Method + ":" + action {
	case "POST:pause":
		log.Printf("PAUSE task %s", id)
		if GlobalManager.PauseTask(id) {
			SaveTasks(dataDir)
			log.Printf("PAUSE task %s OK", id)
			jsonResponse(w, 200, map[string]string{"status": "paused"})
		} else {
			log.Printf("PAUSE task %s NOT FOUND", id)
			jsonResponse(w, 404, map[string]string{"error": "task not found"})
		}
	case "POST:resume":
		log.Printf("RESUME task %s", id)
		if GlobalManager.ResumeTask(id) {
			SaveTasks(dataDir)
			log.Printf("RESUME task %s OK", id)
			jsonResponse(w, 200, map[string]string{"status": "resumed"})
		} else {
			log.Printf("RESUME task %s NOT FOUND", id)
			jsonResponse(w, 404, map[string]string{"error": "task not found"})
		}
	case "DELETE:remove":
		log.Printf("REMOVE task %s", id)
		if GlobalManager.RemoveTask(id) {
			SaveTasks(dataDir)
			log.Printf("REMOVE task %s OK", id)
			jsonResponse(w, 200, map[string]string{"status": "removed"})
		} else {
			log.Printf("REMOVE task %s NOT FOUND", id)
			jsonResponse(w, 404, map[string]string{"error": "task not found"})
		}
	default:
		jsonResponse(w, 405, map[string]string{"error": "method or action not allowed"})
	}
}

func handleClearCompleted(w http.ResponseWriter, r *http.Request, dataDir string) {
	GlobalManager.ClearCompleted()
	SaveTasks(dataDir)
	jsonResponse(w, 200, map[string]string{"status": "cleared"})
}

func handleTaskProgress(w http.ResponseWriter, r *http.Request) {
	parts := strings.Split(strings.TrimPrefix(r.URL.Path, "/api/tasks/"), "/")
	if len(parts) < 2 || parts[1] != "progress" {
		jsonResponse(w, 400, map[string]string{"error": "invalid path"})
		return
	}

	task := GlobalManager.GetTask(parts[0])
	if task == nil {
		jsonResponse(w, 404, map[string]string{"error": "task not found"})
		return
	}

	w.Header().Set("Content-Type", "text/event-stream")
	w.Header().Set("Cache-Control", "no-cache")
	w.Header().Set("Connection", "keep-alive")

	flusher, ok := w.(http.Flusher)
	if !ok {
		jsonResponse(w, 500, map[string]string{"error": "streaming not supported"})
		return
	}

	for {
		select {
		case <-r.Context().Done():
			return
		default:
			p := task.ProgressInfo()
			data, _ := json.Marshal(p)
			w.Write([]byte("data: "))
			w.Write(data)
			w.Write([]byte("\n\n"))
			flusher.Flush()

			if task.Status == StatusCompleted || task.Status == StatusFailed {
				return
			}
			time.Sleep(200 * time.Millisecond)
		}
	}
}

func handleTaskDebug(w http.ResponseWriter, r *http.Request) {
	parts := strings.Split(strings.TrimPrefix(r.URL.Path, "/api/tasks/"), "/")
	if len(parts) < 2 || parts[1] != "debug" {
		jsonResponse(w, 400, map[string]string{"error": "invalid path"})
		return
	}

	task := GlobalManager.GetTask(parts[0])
	if task == nil {
		jsonResponse(w, 404, map[string]string{"error": "task not found"})
		return
	}

	m := task.ToMap()
	m["launched"] = task.Launched()
	m["has_done"] = task.HasDone()

	all := GlobalManager.AllTasks()
	statuses := make([]map[string]interface{}, len(all))
	for i, t := range all {
		statuses[i] = map[string]interface{}{
			"id":       t.ID,
			"status":   string(t.Status),
			"launched": t.Launched(),
			"has_done": t.HasDone(),
		}
	}
	m["all_tasks"] = statuses

	jsonResponse(w, 200, m)
}
