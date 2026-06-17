package server

import (
	"log"
	"sync"
	"time"
)

type DownloadManager struct {
	mu            sync.RWMutex
	tasks         []*DownloadTask
	maxConcurrent int
	activeCount   int
	doneCh        chan struct{}
}

var GlobalManager = &DownloadManager{
	maxConcurrent: 3,
	doneCh:        make(chan struct{}, 100),
}

func (m *DownloadManager) AddTask(url, savePath, fileName string) *DownloadTask {
	task := NewTask(url, savePath, fileName)
	m.mu.Lock()
	m.tasks = append(m.tasks, task)
	m.mu.Unlock()
	m.tryDispatch()
	return task
}

func (m *DownloadManager) PauseTask(id string) bool {
	m.mu.RLock()
	var task *DownloadTask
	for _, t := range m.tasks {
		if t.ID == id {
			task = t
			break
		}
	}
	m.mu.RUnlock()
	if task == nil {
		return false
	}
	task.Pause()
	// 等待 Run() goroutine 真正退出。由于 done channel 在 Run() 设置的时机
	// 可能晚于 Pause() 调用，这里采用轮询 Launched() 而非 WaitStopped()。
	for i := 0; i < 500; i++ {
		if !task.Launched() {
			log.Printf("PauseTask(%s): Run stopped after %dms", id, i*10)
			return true
		}
		time.Sleep(10 * time.Millisecond)
	}
	log.Printf("PauseTask(%s): Run did not stop after 5s, force returning", id)
	return true
}

func (m *DownloadManager) ResumeTask(id string) bool {
	m.mu.RLock()
	var task *DownloadTask
	for _, t := range m.tasks {
		if t.ID == id {
			task = t
			break
		}
	}
	m.mu.RUnlock()
	if task == nil {
		return false
	}
	task.Resume()
	m.tryDispatch()
	return true
}

func (m *DownloadManager) RemoveTask(id string) bool {
	m.mu.RLock()
	var task *DownloadTask
	for _, t := range m.tasks {
		if t.ID == id {
			task = t
			break
		}
	}
	m.mu.RUnlock()
	if task == nil {
		return false
	}

	task.Pause()
	for i := 0; i < 500; i++ {
		if !task.Launched() {
			break
		}
		time.Sleep(10 * time.Millisecond)
	}

	m.mu.Lock()
	defer m.mu.Unlock()
	for i, t := range m.tasks {
		if t.ID == id {
			m.tasks = append(m.tasks[:i], m.tasks[i+1:]...)
			return true
		}
	}
	return false
}

func (m *DownloadManager) ClearCompleted() {
	m.mu.Lock()
	defer m.mu.Unlock()
	remaining := make([]*DownloadTask, 0, len(m.tasks))
	for _, t := range m.tasks {
		if t.Status != StatusCompleted {
			remaining = append(remaining, t)
		}
	}
	m.tasks = remaining
}

func (m *DownloadManager) ListTasks() []map[string]interface{} {
	m.mu.RLock()
	defer m.mu.RUnlock()
	result := make([]map[string]interface{}, len(m.tasks))
	for i, t := range m.tasks {
		result[i] = t.PartialClone()
	}
	return result
}

func (m *DownloadManager) GetTask(id string) *DownloadTask {
	m.mu.RLock()
	defer m.mu.RUnlock()
	for _, t := range m.tasks {
		if t.ID == id {
			return t
		}
	}
	return nil
}

func (m *DownloadManager) RestoreTasks(tasks []*DownloadTask) {
	m.mu.Lock()
	m.tasks = tasks
	m.mu.Unlock()
}

// ---- 调度 ----

func (m *DownloadManager) tryDispatch() {
	m.mu.Lock()
	defer m.mu.Unlock()

	for _, t := range m.tasks {
		if m.activeCount >= m.maxConcurrent {
			break
		}
		if t.Status == StatusPending {
			m.activeCount++
			go m.runTask(t)
		}
	}
}

func (m *DownloadManager) runTask(t *DownloadTask) {
	t.Run(m.doneCh)
	m.mu.Lock()
	m.activeCount--
	m.mu.Unlock()
	m.tryDispatch()
}

// ---- 快照 ----

func (m *DownloadManager) ProgressSnapshot() []ProgressInfo {
	m.mu.RLock()
	defer m.mu.RUnlock()
	infos := make([]ProgressInfo, 0, len(m.tasks))
	for _, t := range m.tasks {
		if t.Status == StatusDownloading || t.Status == StatusPending {
			infos = append(infos, t.ProgressInfo())
		}
	}
	return infos
}

func (m *DownloadManager) AllTasks() []*DownloadTask {
	m.mu.RLock()
	defer m.mu.RUnlock()
	clone := make([]*DownloadTask, len(m.tasks))
	copy(clone, m.tasks)
	return clone
}
