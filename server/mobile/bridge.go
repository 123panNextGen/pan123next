// Package mobile 是 gomobile bind 的入口，导出给 Android/iOS 使用。
package mobile

import (
	"encoding/json"

	"pan123next_downloader/pkg/server"
)

var dataDir string

// StartServer 启动下载服务器，返回监听端口号。失败返回 0。
//
// dir: 数据持久化目录路径，由 Flutter 传入。
func StartServer(dir string) int {
	if dir == "" {
		return 0
	}
	dataDir = dir

	port, err := server.StartServer(dir)
	if err != nil {
		return 0
	}
	return port
}

// StopServer 停止下载服务器并保存任务。
func StopServer() {
	if dataDir != "" {
		server.SaveTasks(dataDir)
	}
}

// GetProgressSnapshot 返回所有活跃任务进度的 JSON 字符串。
func GetProgressSnapshot() string {
	infos := server.GlobalManager.ProgressSnapshot()
	data, _ := json.Marshal(infos)
	return string(data)
}
