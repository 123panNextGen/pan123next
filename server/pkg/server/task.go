package server

import (
	"context"
	"fmt"
	"io"
	"log"
	"net/http"
	"os"
	"sync"
	"sync/atomic"
	"time"
)

type DownloadStatus string

const (
	StatusPending     DownloadStatus = "pending"
	StatusDownloading DownloadStatus = "downloading"
	StatusPaused      DownloadStatus = "paused"
	StatusCompleted   DownloadStatus = "completed"
	StatusFailed      DownloadStatus = "failed"
)

type DownloadTask struct {
	ID           string         `json:"id"`
	URL          string         `json:"url"`
	SavePath     string         `json:"save_path"`
	FileName     string         `json:"file_name"`
	TotalSize    int64          `json:"total_size"`
	Downloaded   int64          `json:"downloaded"`
	Status       DownloadStatus `json:"status"`
	Speed        int64          `json:"speed"`
	ErrorMessage string         `json:"error_message,omitempty"`
	CreatedAt    time.Time      `json:"created_at"`
	CompletedAt  *time.Time     `json:"completed_at,omitempty"`

	mu             sync.RWMutex
	cancel         chan struct{}
	cancelCtx      context.CancelFunc
	body           io.Closer
	lastBytes      int64
	lastCheck      time.Time
	done           chan struct{}
	launched       atomic.Bool // Run() goroutine 是否正在执行
	pauseRequested atomic.Bool // Pause() 已被调用，Run() 启动时优先检查
}

func NewTask(url, savePath, fileName string) *DownloadTask {
	return &DownloadTask{
		ID:        fmt.Sprintf("%d", time.Now().UnixNano()),
		URL:       url,
		SavePath:  savePath,
		FileName:  fileName,
		Status:    StatusPending,
		CreatedAt: time.Now(),
		cancel:    make(chan struct{}),
	}
}

// Run 执行下载，doneCh 通知管理器任务已结束。
func (t *DownloadTask) Run(doneCh chan<- struct{}) {
	// Phase 1: Pause() 是否已经在 Run() 启动前被调用
	if t.pauseRequested.Load() {
		log.Printf("Run(%s): pause already requested, not starting", t.ID)
		t.pauseRequested.Store(false)
		doneCh <- struct{}{}
		return
	}

	// Phase 2: 先建立取消机制，确保 Pause() 在任何阶段都能中断
	ctx, cancel := context.WithCancel(context.Background())

	t.mu.Lock()
	t.cancel = make(chan struct{})
	t.cancelCtx = cancel
	ch := t.cancel
	t.mu.Unlock()

	go func() {
		select {
		case <-ch:
			cancel()
		case <-ctx.Done():
		}
	}()

	// Phase 3: 标记为已启动
	t.launched.Store(true)

	// Phase 4: 再次检查（setup 期间 Pause() 可能已被调用）
	if t.pauseRequested.Swap(false) {
		log.Printf("Run(%s): pause requested during setup, aborting", t.ID)
		cancel()
		t.launched.Store(false)
		t.mu.Lock()
		t.Status = StatusPaused
		t.Speed = 0
		t.mu.Unlock()
		doneCh <- struct{}{}
		return
	}

	// Phase 5: 只有从现在开始才让 WaitStopped 阻塞等待
	t.done = make(chan struct{})
	defer func() {
		t.launched.Store(false)
		close(t.done)
		doneCh <- struct{}{}
	}()

	t.mu.Lock()
	t.Status = StatusDownloading
	t.mu.Unlock()

	log.Printf("Run(%s): starting download", t.ID)

	file, err := os.OpenFile(t.SavePath, os.O_CREATE|os.O_WRONLY, 0644)
	if err != nil {
		t.setError("打开文件失败: " + err.Error())
		return
	}

	startBytes := int64(0)
	info, err := file.Stat()
	if err == nil {
		startBytes = info.Size()
	}
	if startBytes > 0 {
		file.Seek(startBytes, io.SeekStart)
	}

	req, err := http.NewRequestWithContext(ctx, "GET", t.URL, nil)
	if err != nil {
		cancel()
		file.Close()
		t.setError("创建请求失败: " + err.Error())
		return
	}
	req.Header.Set("User-Agent", "pan123next/2.4.0")
	if startBytes > 0 {
		req.Header.Set("Range", fmt.Sprintf("bytes=%d-", startBytes))
	}

	client := &http.Client{Timeout: 120 * time.Second}
	resp, err := client.Do(req)
	if err != nil {
		file.Close()
		cancel()
		if !t.launched.Load() {
			t.mu.Lock()
			t.Status = StatusPaused
			t.Speed = 0
			t.mu.Unlock()
		} else {
			t.setError("请求失败: " + err.Error())
		}
		return
	}

	if resp.StatusCode != 200 && resp.StatusCode != 206 {
		file.Close()
		resp.Body.Close()
		cancel()
		t.setError(fmt.Sprintf("HTTP %d", resp.StatusCode))
		return
	}

	totalSize := t.TotalSize
	if resp.ContentLength > 0 {
		totalSize = startBytes + resp.ContentLength
	}

	t.mu.Lock()
	t.TotalSize = totalSize
	t.body = resp.Body
	if startBytes > t.Downloaded {
		t.Downloaded = startBytes
	}
	t.lastBytes = t.Downloaded
	t.lastCheck = time.Now()
	t.mu.Unlock()

	buf := make([]byte, 32768)
	for {
		if !t.launched.Load() {
			log.Printf("Run(%s): pause detected (before read), exiting", t.ID)
			resp.Body.Close()
			file.Close()
			cancel()
			t.mu.Lock()
			t.Status = StatusPaused
			t.Speed = 0
			t.mu.Unlock()
			return
		}

		n, readErr := resp.Body.Read(buf)

		if !t.launched.Load() {
			log.Printf("Run(%s): pause detected (after read), exiting", t.ID)
			resp.Body.Close()
			file.Close()
			cancel()
			t.mu.Lock()
			t.Status = StatusPaused
			t.Speed = 0
			t.mu.Unlock()
			return
		}

		if n > 0 {
			if _, writeErr := file.Write(buf[:n]); writeErr != nil {
				resp.Body.Close()
				file.Close()
				cancel()
				t.setError("写入文件失败: " + writeErr.Error())
				return
			}

			t.mu.Lock()
			t.Downloaded += int64(n)
			now := time.Now()
			elapsed := now.Sub(t.lastCheck)
			if elapsed >= 800*time.Millisecond {
				t.Speed = (t.Downloaded - t.lastBytes) * 1000 / elapsed.Milliseconds()
				t.lastBytes = t.Downloaded
				t.lastCheck = now
			}
			t.mu.Unlock()
		}

		if readErr != nil {
			if readErr == io.EOF {
				resp.Body.Close()
				file.Close()
				cancel()
				if info, _ := os.Stat(t.SavePath); info != nil {
					t.mu.Lock()
					t.TotalSize = info.Size()
					t.Downloaded = info.Size()
					t.mu.Unlock()
				}
				t.markCompleted()
				return
			}
			resp.Body.Close()
			file.Close()
			cancel()
			if !t.launched.Load() {
				t.mu.Lock()
				t.Status = StatusPaused
				t.Speed = 0
				t.mu.Unlock()
				return
			}
			t.setError("读取错误: " + readErr.Error())
			return
		}
	}
}

func (t *DownloadTask) markCompleted() {
	now := time.Now()
	t.mu.Lock()
	t.Status = StatusCompleted
	t.CompletedAt = &now
	t.Speed = 0
	t.mu.Unlock()
}

func (t *DownloadTask) setError(msg string) {
	t.mu.Lock()
	t.Status = StatusFailed
	t.ErrorMessage = msg
	t.Speed = 0
	t.Downloaded = 0
	t.mu.Unlock()
}

// Pause 暂停下载。关闭 cancel channel + cancelCtx + body，并设 Status=Paused。
// 无论 Run() 是否启动，都能正确标记为暂停。
func (t *DownloadTask) Pause() {
	t.pauseRequested.Store(true)
	t.launched.Store(false)

	t.mu.Lock()
	if t.Status == StatusDownloading || t.Status == StatusPending {
		t.Status = StatusPaused
	}
	if t.cancel != nil {
		select {
		case <-t.cancel:
		default:
			close(t.cancel)
		}
	}
	cancelFn := t.cancelCtx
	b := t.body
	t.body = nil
	t.cancelCtx = nil
	t.cancel = nil
	t.mu.Unlock()

	if cancelFn != nil {
		cancelFn()
	}
	if b != nil {
		b.Close()
	}
	log.Printf("Pause(%s): done (launched=%v, cancelCtx=%v, body=%v)", t.ID, t.launched.Load(), cancelFn != nil, b != nil)
}

// WaitStopped 阻塞等待下载协程确认退出。如果 Run() 从未启动则立即返回。
func (t *DownloadTask) WaitStopped() {
	t.mu.RLock()
	done := t.done
	t.mu.RUnlock()
	if done == nil {
		return
	}
	<-done
}

func (t *DownloadTask) Resume() {
	t.pauseRequested.Store(false)
	t.launched.Store(false)
	t.mu.Lock()
	defer t.mu.Unlock()
	if t.Status == StatusPaused || t.Status == StatusFailed {
		t.Status = StatusPending
		t.ErrorMessage = ""
	}
	t.cancel = nil
	t.cancelCtx = nil
	t.body = nil
	t.done = nil
}

func (t *DownloadTask) Launched() bool {
	return t.launched.Load()
}

func (t *DownloadTask) HasDone() bool {
	t.mu.RLock()
	defer t.mu.RUnlock()
	select {
	case <-t.done:
		return true
	default:
		return false
	}
}

// ---- 序列化 ----

func (t *DownloadTask) ToMap() map[string]interface{} {
	t.mu.RLock()
	defer t.mu.RUnlock()

	m := map[string]interface{}{
		"id":            t.ID,
		"url":           t.URL,
		"save_path":     t.SavePath,
		"file_name":     t.FileName,
		"total_size":    t.TotalSize,
		"downloaded":    t.Downloaded,
		"status":        string(t.Status),
		"speed":         t.Speed,
		"error_message": t.ErrorMessage,
		"created_at":    t.CreatedAt.Format(time.RFC3339),
	}
	if t.CompletedAt != nil {
		m["completed_at"] = t.CompletedAt.Format(time.RFC3339)
	}
	return m
}

func TaskFromMap(m map[string]interface{}) *DownloadTask {
	t := &DownloadTask{
		ID:           getString(m, "id"),
		URL:          getString(m, "url"),
		SavePath:     getString(m, "save_path"),
		FileName:     getString(m, "file_name"),
		Status:       DownloadStatus(getString(m, "status")),
		ErrorMessage: getString(m, "error_message"),
		TotalSize:    getInt64(m, "total_size"),
		Downloaded:   getInt64(m, "downloaded"),
		Speed:        getInt64(m, "speed"),
	}
	if created, ok := m["created_at"].(string); ok {
		t.CreatedAt, _ = time.Parse(time.RFC3339, created)
	}
	if completed, ok := m["completed_at"].(string); ok {
		if tm, err := time.Parse(time.RFC3339, completed); err == nil {
			t.CompletedAt = &tm
		}
	}
	return t
}

func getString(m map[string]interface{}, key string) string {
	if v, ok := m[key]; ok {
		if s, ok := v.(string); ok {
			return s
		}
	}
	return ""
}

func getInt64(m map[string]interface{}, key string) int64 {
	switch v := m[key].(type) {
	case float64:
		return int64(v)
	case int64:
		return v
	}
	return 0
}

type ProgressInfo struct {
	ID         string  `json:"id"`
	Downloaded int64   `json:"downloaded"`
	TotalSize  int64   `json:"total_size"`
	Speed      int64   `json:"speed"`
	Status     string  `json:"status"`
	Progress   float64 `json:"progress"`
}

func (t *DownloadTask) ProgressInfo() ProgressInfo {
	t.mu.RLock()
	defer t.mu.RUnlock()
	p := ProgressInfo{
		ID:         t.ID,
		Downloaded: t.Downloaded,
		TotalSize:  t.TotalSize,
		Speed:      t.Speed,
		Status:     string(t.Status),
	}
	if t.TotalSize > 0 {
		p.Progress = float64(t.Downloaded) / float64(t.TotalSize)
	}
	return p
}

func (t *DownloadTask) PartialClone() map[string]interface{} {
	t.mu.RLock()
	defer t.mu.RUnlock()

	return map[string]interface{}{
		"id":            t.ID,
		"url":           t.URL,
		"save_path":     t.SavePath,
		"file_name":     t.FileName,
		"total_size":    t.TotalSize,
		"downloaded":    t.Downloaded,
		"status":        string(t.Status),
		"speed":         t.Speed,
		"error_message": t.ErrorMessage,
		"created_at":    t.CreatedAt.Format(time.RFC3339),
	}
}
