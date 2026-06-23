class DownloadConfig {
  static const int defaultChunkSize = 100 * 1024 * 1024; // 100MB
  static const int defaultMaxConcurrentChunks = 3;
  static const int defaultMaxConcurrentTasks = 3;
  static const int defaultMaxRetries = 3;
  static const int defaultSingleStreamThreshold = 10 * 1024 * 1024;

  int chunkSize;
  int maxConcurrentChunks;
  int maxConcurrentTasks;
  int maxRetries;
  int singleStreamThreshold;

  DownloadConfig({
    this.chunkSize = defaultChunkSize,
    this.maxConcurrentChunks = defaultMaxConcurrentChunks,
    this.maxConcurrentTasks = defaultMaxConcurrentTasks,
    this.maxRetries = defaultMaxRetries,
    this.singleStreamThreshold = defaultSingleStreamThreshold,
  });
}
