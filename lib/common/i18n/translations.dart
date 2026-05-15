import 'package:get/get.dart' hide Response;

class AppTranslations extends Translations {
  @override
  Map<String, Map<String, String>> get keys => {'zh_CN': zhCn};

  static const Map<String, String> zhCn = {
    // App
    'app.title': '123网盘 Next',
    'app.subtitle': 'Preview',

    // Login screen
    'login.header': '登录',
    'login.tab.password': '用户名/密码 登录',
    'login.tab.qrcode': '二维码 登录',
    'login.qrcode.placeholder': '作者其实很懒，什么都没有做呢~',
    'login.welcome': '欢迎!',
    'login.username.placeholder': '用户名(邮箱/手机号)',
    'login.password.placeholder': '密码',
    'login.remember.password': '保存密码',
    'login.auto.login': '自动登录',
    'login.button': '登录',
    'login.cancel': '取消',
    'login.failed': '登录失败',
    'login.empty.credentials': '用户名或密码不能为空',
    'login.success': '登录成功',

    // Main screen
    'main.header': '主界面',
    'main.tab.files': '文件列表',
    'main.tab.downloads': '下载',
    'main.tab.settings': '设置',

    // File list
    'file.list.title': '文件列表',
    'file.list.root': '根目录',
    'file.list.back': '上一级',
    'file.list.refresh': '刷新',
    'file.list.refresh.tooltip': '刷新文件列表',
    'file.list.new.folder': '新建文件夹',
    'file.list.new.folder.tooltip': '新建文件夹',
    'file.list.delete': '删除',
    'file.list.delete.tooltip': '删除选中文件',
    'file.list.add.folder': '添加文件夹',
    'file.list.delete.current': '删除当前目录',
    'file.list.get.link': '获取下载链接',
    'file.list.download': '下载',
    'file.list.empty': '空空如也呢...',
    'file.list.load.failed': '加载失败呜...',
    'file.list.error': '错误',
    'file.list.token.expired': 'Token 已过期且无法正常获取',
    'file.list.load.error': '加载文件列表失败',
    'file.list.success': '成功',
    'file.list.download.success': '已成功下载: {name}',
    'file.list.folder.format': '文件夹 - {size}',
    'file.list.save.path.title': '选择保存路径:',

    // File list dialogs
    'dialog.new.folder.title': '新建文件夹',
    'dialog.new.folder.label': '在当前目录下新建文件夹',
    'dialog.new.folder.placeholder': '请输入文件夹名',
    'dialog.new.folder.cancel': '取消',
    'dialog.new.folder.create': '新建',
    'dialog.trash.file.title': '删除',
    'dialog.trash.file.content': '确认删除选中文件吗?\n删除后的文件将会放入回收站中',
    'dialog.trash.file.cancel': '取消',
    'dialog.trash.file.confirm': '删除',
    'dialog.trash.current.title': '删除',
    'dialog.trash.current.content': '确认删除当前目录吗?\n删除后的文件将会放入回收站中',
    'dialog.trash.current.cancel': '取消',
    'dialog.trash.current.confirm': '删除',
    'dialog.link.title': '获取下载链接结果',
    'dialog.link.file.name': '获取文件名: ',
    'dialog.link.result': '结果',
    'dialog.link.copy': '复制',
    'dialog.link.confirm': '确定',

    // Transfer page
    'transfer.title': '传输',
    'transfer.filter.all': '全部',
    'transfer.filter.downloading': '下载',
    'transfer.filter.uploading': '上传',
    'transfer.filter.label': '过滤: ',
    'transfer.search.placeholder': '文件名',
    'transfer.add.download': '添加新下载',
    'transfer.empty.all': '暂无任务',
    'transfer.empty.downloading': '暂无下载任务',
    'transfer.empty.uploading': '暂无上传任务',
    'transfer.added.title': '已添加',
    'transfer.added.message': '下载任务已开始',
    'transfer.add.failed': '添加失败',
    'transfer.complete.title': '下载完成',

    // Add download dialog
    'add.download.title': '添加新下载',
    'add.download.url.label': '下载链接',
    'add.download.url.placeholder': 'https://example.com/file.zip',
    'add.download.path.label': '保存路径',
    'add.download.path.placeholder': '尚未选择',
    'add.download.choose': '选择',
    'add.download.cancel': '取消',
    'add.download.start': '开始下载',
    'add.download.invalid.url': '请输入合法的 URL（http/https）',
    'add.download.select.path': '请选择保存路径',
    'add.download.select.file': '请选择文件',

    // Settings
    'settings.title': '设置',
    'settings.theme.header': '切换主题',
    'settings.theme.label': '主题',
    'settings.color.label': '颜色',
    'settings.download.header': '下载设置',
    'settings.download.ask': '是否询问下载位置',
    'settings.download.default.path': '默认下载位置',
    'settings.download.path.placeholder': '请输入默认下载位置',
    'settings.choose': '选择',
    'settings.about.section': '123Pan Next',
    'settings.current.version': '当前版本: {version}',
    'settings.version.loading': '获取版本中...',
    'settings.language': '语言',

    // Theme & color labels
    'theme.dark': '暗色',
    'theme.light': '亮色',
    'color.purple': '紫色',
    'color.blue': '蓝色',
    'color.yellow': '黄色',
    'color.red': '红色',
    'color.green': '绿色',
    'color.orange': '橙色',
    'color.teal': '青色',

    // Downloader error messages (hardcoded, not from server)
    'downloader.error.remote.changed': '远端文件已变化，请删除任务后重新下载',
    'downloader.error.no.size': '无法获取文件大小',
    'downloader.error.resume.failed': '断点续传失败：HTTP {code}',
    'downloader.error.incomplete': '下载不完整：{downloaded} / {total}',
    'downloader.error.remote.size.changed': '远端文件大小已变化（{remote} != {local}），请重新下载',
    'downloader.error.remote.etag.changed': '远端文件已修改（ETag 不一致），请重新下载',

    // API hardcoded messages
    'api.login.failed': '登录失败',
    'api.delete.failed': '删除失败',
    'api.get.link.failed': '获取文件链接失败',
    'api.link.not.found': '文件链接不存在',
    'api.create.failed': '创建失败',
    'api.create.success': '创建成功',
    'api.delete.success': '删除成功',

    // Languages
    'lang.zh.cn': '中文 (简体)',
    'lang.en.us': 'English',
  };
}
