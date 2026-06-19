# MelodyBox 本地音乐播放器开发文档

> 用途：把本文档和参考图片一起交给 Codex，让它按阶段开发。  
> 项目定位：Flutter Windows 桌面端优先，纯本地离线音乐播放器。  
> 开发原则：每次只做一个阶段，完成后必须能运行、能测试、能回滚。

---

## 1. 项目概述

### 1.1 项目名称

**MelodyBox**

### 1.2 项目类型

纯本地离线音乐播放器。

### 1.3 核心目标

做一个简约、高级、稳定的本地音乐播放器，支持导入本地音乐、音乐库管理、播放控制、收藏、播放列表、沉浸式播放页、歌词显示和基础设置。

### 1.4 不做的内容

第一版不要做以下内容：

| 不做 | 原因 |
|---|---|
| 在线音乐搜索 | 会引入版权、网络接口、数据源问题 |
| 登录注册 | 本地播放器不需要账号系统 |
| 云同步 | 会引入后端，偏离纯本地定位 |
| 社交功能 | 与本地播放器主线无关 |
| 推荐算法 | 前期没有必要 |
| 手机端同步 | 先把 Windows 端做稳定 |

### 1.5 第一版目标

第一版完成后应具备：

- 本地音频文件导入
- 音乐库列表
- 播放 / 暂停
- 上一首 / 下一首
- 进度条拖动
- 音量控制
- 播放模式切换
- 我喜欢
- 播放列表
- 最近播放
- 沉浸式播放页
- 本地歌词 `.lrc` 匹配
- 基础设置
- 本地数据库持久化

---

## 2. 技术选型

### 2.1 基础技术

| 模块 | 技术 |
|---|---|
| UI 框架 | Flutter |
| 语言 | Dart |
| 目标平台 | Windows 优先 |
| 播放内核 | media_kit |
| 文件选择 | file_picker |
| 本地数据库 | SQLite + drift |
| 本地路径 | path / path_provider |
| 状态管理 | Riverpod 或 ChangeNotifier，优先选择简单稳定方案 |
| 窗口管理 | window_manager，后期再接入 |
| 歌词解析 | 自定义 LyricService |
| 元数据读取 | 后期接入音频 metadata 读取库，第一阶段不做 |

### 2.2 技术使用边界

- 播放逻辑必须封装在 `AudioPlayerService`，页面不要直接操作底层播放器。
- 数据库操作必须封装在 Repository / DAO 层，页面不要直接写 SQL。
- UI 页面只负责展示和触发事件，不写复杂业务逻辑。
- 第一阶段不接数据库，先保证播放器核心可用。
- 后续阶段再逐步加入数据库、歌词、封面、播放列表。

---

## 3. 参考图片说明

请把参考图片单独放在项目说明同级目录，建议命名如下：

```text
docs/images/
├── ref-home.png
├── ref-library.png
├── ref-playlist.png
├── ref-settings.png
└── ref-immersive-player.png
```

图片用途：

| 图片 | 用途 |
|---|---|
| `ref-home.png` | 首页、整体布局、浅色风格、底部播放栏 |
| `ref-library.png` | 音乐库列表、歌曲表格、导入按钮 |
| `ref-playlist.png` | 播放列表管理页面 |
| `ref-settings.png` | 设置页卡片布局 |
| `ref-immersive-player.png` | 沉浸式播放页，重点参考，无左侧导航栏 |

Codex 开发时不要直接照抄图片中的所有文字和歌曲数据，只参考布局、间距、颜色、层次和交互结构。

---

## 4. UI 设计规范

### 4.1 整体风格

关键词：

- 简约
- 高级
- 浅色
- 低饱和
- 卡片式
- 毛玻璃
- 柔和阴影
- 绿色点缀
- 留白充足

### 4.2 主色

建议主色：

```text
主色：#22A96B 或 #23B26D
浅绿色背景：#EAF7F0
页面背景：#F6F8F7
文字主色：#202124
文字次色：#6B7280
边框色：#E5E7EB
卡片背景：#FFFFFF / 半透明白
```

### 4.3 组件风格

| 组件 | 风格 |
|---|---|
| 按钮 | 圆角，轻阴影，主按钮绿色 |
| 卡片 | 大圆角，浅阴影，轻边框 |
| 表格 | 行高充足，悬浮高亮 |
| 播放栏 | 固定底部，半透明或白色卡片 |
| 进度条 | 细线条，绿色进度 |
| 图标 | 线性图标，避免复杂彩色图标 |
| 弹窗 | 简洁，不要太厚重 |

### 4.4 字体层级

| 类型 | 建议大小 |
|---|---|
| 页面标题 | 24px - 30px |
| 卡片标题 | 18px - 22px |
| 正文 | 14px - 16px |
| 辅助信息 | 12px - 13px |
| 播放页歌曲标题 | 42px - 56px |
| 播放页歌手 | 20px - 26px |

---

## 5. 页面结构规划

### 5.1 主窗口布局

大部分页面使用：

```text
左侧导航栏 + 顶部搜索栏 + 主内容区 + 底部播放栏
```

页面包括：

- 首页
- 音乐库
- 我喜欢
- 播放列表
- 最近播放
- 设置

### 5.2 沉浸式播放页布局

沉浸式播放页单独设计：

```text
无左侧导航栏
顶部只保留应用名和窗口按钮
中间展示封面、歌曲信息、播放控制
右侧展示歌词卡片
背景使用专辑封面模糊效果
```

重点要求：

- 不要左侧栏目。
- 不要歌曲表格。
- 不要信息堆砌。
- 整体要比普通页面更高级、更安静。
- 播放页应支持返回主页面。

---

## 6. 推荐目录结构

```text
lib/
├── main.dart
├── app.dart
├── core/
│   ├── constants/
│   │   ├── app_colors.dart
│   │   └── app_constants.dart
│   ├── theme/
│   │   └── app_theme.dart
│   └── utils/
│       ├── duration_format.dart
│       └── file_utils.dart
├── data/
│   ├── db/
│   │   ├── app_database.dart
│   │   ├── tables/
│   │   │   ├── songs_table.dart
│   │   │   ├── playlists_table.dart
│   │   │   └── playlist_songs_table.dart
│   │   └── daos/
│   │       ├── song_dao.dart
│   │       └── playlist_dao.dart
│   ├── models/
│   │   ├── song.dart
│   │   ├── playlist.dart
│   │   └── lyric_line.dart
│   └── repositories/
│       ├── song_repository.dart
│       └── playlist_repository.dart
├── services/
│   ├── audio_player_service.dart
│   ├── file_import_service.dart
│   ├── metadata_service.dart
│   └── lyric_service.dart
├── state/
│   ├── player_controller.dart
│   ├── library_controller.dart
│   ├── playlist_controller.dart
│   └── settings_controller.dart
├── pages/
│   ├── main_shell_page.dart
│   ├── home_page.dart
│   ├── library_page.dart
│   ├── favorites_page.dart
│   ├── playlists_page.dart
│   ├── recent_page.dart
│   ├── settings_page.dart
│   └── immersive_player_page.dart
└── widgets/
    ├── app_sidebar.dart
    ├── app_top_bar.dart
    ├── mini_player_bar.dart
    ├── playback_controls.dart
    ├── song_list_table.dart
    ├── song_list_tile.dart
    ├── album_cover.dart
    ├── lyric_panel.dart
    └── glass_card.dart
```

---

## 7. 数据模型设计

### 7.1 Song

```dart
class Song {
  final int id;
  final String title;
  final String artist;
  final String album;
  final String filePath;
  final int durationMs;
  final String? coverPath;
  final bool isFavorite;
  final int playCount;
  final DateTime createdAt;
  final DateTime? lastPlayedAt;
  final bool isAvailable;
}
```

### 7.2 Playlist

```dart
class Playlist {
  final int id;
  final String name;
  final String? description;
  final DateTime createdAt;
  final DateTime updatedAt;
}
```

### 7.3 LyricLine

```dart
class LyricLine {
  final Duration time;
  final String text;
}
```

---

## 8. 数据库表设计

### 8.1 songs

| 字段 | 类型 | 说明 |
|---|---|---|
| id | integer | 主键 |
| title | text | 歌曲名 |
| artist | text | 歌手 |
| album | text | 专辑 |
| file_path | text | 文件路径，唯一 |
| duration_ms | integer | 时长 |
| cover_path | text nullable | 封面路径 |
| is_favorite | boolean | 是否喜欢 |
| play_count | integer | 播放次数 |
| created_at | datetime | 导入时间 |
| last_played_at | datetime nullable | 最近播放时间 |
| is_available | boolean | 文件是否存在 |

### 8.2 playlists

| 字段 | 类型 | 说明 |
|---|---|---|
| id | integer | 主键 |
| name | text | 播放列表名称 |
| description | text nullable | 描述 |
| created_at | datetime | 创建时间 |
| updated_at | datetime | 更新时间 |

### 8.3 playlist_songs

| 字段 | 类型 | 说明 |
|---|---|---|
| id | integer | 主键 |
| playlist_id | integer | 播放列表 id |
| song_id | integer | 歌曲 id |
| sort_order | integer | 排序 |
| added_at | datetime | 添加时间 |

### 8.4 app_settings

| 字段 | 类型 | 说明 |
|---|---|---|
| key | text | 设置项 |
| value | text | 设置值 |

---

## 9. 核心服务设计

### 9.1 AudioPlayerService

职责：

- 初始化播放器
- 播放单首歌曲
- 播放队列
- 暂停 / 继续
- 上一首 / 下一首
- 拖动进度
- 设置音量
- 设置播放模式
- 监听播放进度
- 监听当前歌曲变化

接口建议：

```dart
class AudioPlayerService {
  Future<void> init();

  Future<void> playSong(Song song);

  Future<void> playQueue({
    required List<Song> songs,
    required int startIndex,
  });

  Future<void> pause();

  Future<void> resume();

  Future<void> togglePlayPause();

  Future<void> next();

  Future<void> previous();

  Future<void> seek(Duration position);

  Future<void> setVolume(double volume);

  Future<void> setShuffleEnabled(bool enabled);

  Future<void> setLoopMode(PlayerLoopMode mode);

  Stream<Duration> get positionStream;

  Stream<Duration> get durationStream;

  Stream<bool> get playingStream;

  Stream<Song?> get currentSongStream;
}
```

### 9.2 FileImportService

职责：

- 打开文件选择器
- 过滤音频格式
- 生成 Song 对象
- 避免重复导入
- 保存到数据库

支持格式：

```text
mp3, flac, wav, m4a, aac, ogg
```

### 9.3 LyricService

职责：

- 根据歌曲路径查找同名 `.lrc`
- 解析 lrc 时间轴
- 根据当前播放进度获取当前歌词行
- 处理无歌词状态

匹配规则：

```text
歌曲：
D:/Music/日落大道.mp3

歌词：
D:/Music/日落大道.lrc
```

### 9.4 MetadataService

第一版先简单处理：

- 歌名默认使用文件名
- 歌手默认使用“未知艺术家”
- 专辑默认使用“未知专辑”
- 时长由播放器读取

后期再增强：

- 读取内嵌标题
- 读取歌手
- 读取专辑
- 读取内嵌封面

---

## 10. 页面详细说明

### 10.1 首页 HomePage

参考图片：`docs/images/ref-home.png`

功能：

- 展示本地音乐统计
- 展示最近播放
- 展示精选播放列表
- 展示部分音乐库
- 支持快速播放

页面模块：

```text
顶部搜索栏
统计卡片：歌曲数 / 歌手数 / 专辑数 / 播放列表数
最近播放横向卡片
音乐库简表
精选播放列表
底部播放栏
```

第一版可以先做静态布局，后续再接真实数据。

---

### 10.2 音乐库 LibraryPage

参考图片：`docs/images/ref-library.png`

功能：

- 展示所有导入歌曲
- 导入本地音乐
- 搜索歌曲
- 点击歌曲播放
- 收藏歌曲
- 删除歌曲记录
- 显示文件失效状态

页面模块：

```text
页面标题：音乐库
导入按钮
播放全部按钮
搜索框
歌曲表格
```

歌曲表格字段：

| 字段 | 说明 |
|---|---|
| 序号 | 当前排序 |
| 歌曲标题 | 歌名 + 封面 |
| 歌手 | 歌手 |
| 专辑 | 专辑 |
| 时长 | 音频时长 |
| 喜欢 | 收藏状态 |
| 更多 | 删除、加入播放列表、查看文件位置 |

---

### 10.3 我喜欢 FavoritesPage

功能：

- 展示收藏歌曲
- 支持播放全部
- 支持取消收藏
- 支持加入播放列表

页面可复用 `SongListTable`。

---

### 10.4 播放列表 PlaylistsPage

参考图片：`docs/images/ref-playlist.png`

功能：

- 展示所有播放列表
- 新建播放列表
- 编辑播放列表名称
- 删除播放列表
- 查看某个播放列表中的歌曲
- 添加歌曲
- 移除歌曲
- 播放全部

页面结构：

```text
左侧：播放列表列表
右侧上方：当前播放列表信息
右侧下方：歌曲表格
```

---

### 10.5 最近播放 RecentPage

功能：

- 按最近播放时间展示歌曲
- 支持清空最近播放记录
- 支持继续播放

---

### 10.6 设置页 SettingsPage

参考图片：`docs/images/ref-settings.png`

功能：

- 音乐目录设置
- 自动扫描开关
- 播放设置
- 歌词设置
- 外观设置
- 缓存和存储
- 快捷键说明
- 关于 MelodyBox

设置项建议：

```text
默认音乐目录
是否启动时继续上次播放
关闭窗口时退出 / 最小化到托盘
默认播放模式
是否开启淡入淡出
是否自动匹配歌词
歌词字体大小
主题模式：浅色 / 深色 / 跟随系统
强调色
缓存目录
清理缓存
检查更新
```

---

### 10.7 沉浸式播放页 ImmersivePlayerPage

参考图片：`docs/images/ref-immersive-player.png`

这是重点页面。

要求：

- 不要左侧导航栏。
- 不要普通页面的顶部搜索栏。
- 不要歌曲表格。
- 背景使用当前封面模糊效果。
- 保留 Windows 顶部窗口按钮。
- 保留返回按钮。
- 页面布局高级简约。

页面结构：

```text
顶部：
- MelodyBox 标识
- 返回按钮
- 窗口控制按钮

主体左侧：
- 大封面
- 音频质量标签
- 进度条
- 播放控制
- 音量控制

主体中部：
- 正在播放状态
- 歌曲标题
- 歌手
- 专辑
- 喜欢 / 添加 / 更多操作

主体右侧：
- 歌词卡片
- 当前歌词高亮
- 歌词设置按钮
```

视觉要求：

- 背景要柔和，不要刺眼。
- 封面要大，但不要压迫。
- 歌词卡片半透明，边框轻。
- 当前歌词用绿色突出。
- 进度条和按钮要简洁。
- 页面整体要留白充足。

---

## 11. 底部播放栏 MiniPlayerBar

除沉浸式播放页外，其他页面都显示底部播放栏。

功能：

- 当前歌曲封面
- 歌名
- 歌手
- 喜欢按钮
- 播放 / 暂停
- 上一首 / 下一首
- 进度条
- 当前时间 / 总时长
- 音量控制
- 播放模式
- 打开沉浸式播放页

布局：

```text
左侧：封面 + 歌曲信息 + 喜欢
中间：播放控制 + 进度条
右侧：音量 + 播放队列 + 设置 + 播放模式
```

---

## 12. 开发阶段规划

### 阶段 1：最小播放 MVP

目标：能选择一首本地歌曲并播放。

功能：

- 创建 Flutter Windows 项目
- 接入 `media_kit`
- 接入 `file_picker`
- 选择单个音频文件
- 播放 / 暂停
- 显示当前进度
- 支持拖动进度条

不做：

- 数据库
- 音乐库
- 歌词
- 封面
- 播放列表
- 复杂 UI

验收：

```text
1. 启动应用
2. 点击选择音乐
3. 选择 mp3 / flac / wav 文件
4. 点击播放
5. 能听到声音
6. 暂停和继续正常
7. 进度条正常变化
8. 拖动进度条后播放位置改变
```

---

### 阶段 2：音乐库内存版

目标：能一次导入多首歌，并在列表中点击播放。

功能：

- 选择多个音频文件
- 在音乐库列表显示
- 点击某一首歌曲播放
- 当前播放歌曲高亮
- 支持播放全部

不做：

- 数据库
- 歌词
- 封面
- 播放列表

验收：

```text
1. 一次导入多首歌
2. 页面出现歌曲列表
3. 点击第 3 首能播放第 3 首
4. 点击播放全部能从第一首开始播放
5. 上一首 / 下一首正常
```

---

### 阶段 3：本地数据库持久化

目标：关闭软件后音乐库仍然存在。

功能：

- 接入 SQLite + drift
- 保存歌曲信息
- 启动时加载音乐库
- 防止重复导入
- 启动时检查文件是否存在
- 文件不存在时标记失效

验收：

```text
1. 导入 5 首歌
2. 关闭应用
3. 重新打开应用
4. 5 首歌仍在音乐库
5. 删除本地某个音频文件
6. 重新打开应用后该歌曲显示失效或不可播放
```

---

### 阶段 4：播放队列和播放模式

目标：播放器具备完整播放控制能力。

功能：

- 播放队列
- 上一首
- 下一首
- 顺序播放
- 列表循环
- 单曲循环
- 随机播放
- 播放结束自动下一首

验收：

```text
1. 点击音乐库第 3 首
2. 播放队列从当前列表生成
3. 下一首播放第 4 首
4. 上一首回到第 3 首
5. 单曲循环有效
6. 随机播放不会崩溃
```

---

### 阶段 5：主界面 UI 重构

目标：做出接近参考图的基础界面。

功能：

- 左侧导航栏
- 顶部搜索栏
- 首页
- 音乐库页
- 底部播放栏
- 浅色主题
- 卡片式布局

验收：

```text
1. 页面结构清晰
2. 左侧导航切换正常
3. 底部播放栏一直可见
4. 音乐库页面可导入和播放
5. UI 不出现明显溢出
```

---

### 阶段 6：收藏和我喜欢

目标：支持收藏歌曲。

功能：

- 收藏歌曲
- 取消收藏
- 我喜欢页面
- 收藏状态持久化

验收：

```text
1. 收藏一首歌
2. 进入我喜欢页面能看到
3. 取消收藏后消失
4. 关闭重开后收藏状态还在
```

---

### 阶段 7：播放列表

目标：支持用户自定义播放列表。

功能：

- 新建播放列表
- 修改播放列表名称
- 删除播放列表
- 添加歌曲到播放列表
- 从播放列表移除歌曲
- 播放列表歌曲排序

验收：

```text
1. 新建一个播放列表
2. 添加 3 首歌
3. 播放列表显示 3 首歌
4. 关闭重开后仍然存在
5. 删除播放列表后数据正确
```

---

### 阶段 8：沉浸式播放页

目标：实现高级简约的播放详情页。

功能：

- 点击底部播放栏进入沉浸式播放页
- 页面无左侧导航栏
- 背景模糊
- 大封面
- 歌曲标题
- 歌手 / 专辑
- 播放控制
- 进度条
- 音量控制
- 歌词卡片占位
- 返回主页面

验收：

```text
1. 点击底部播放栏进入播放详情页
2. 页面没有左侧导航栏
3. 能返回主页面
4. 播放 / 暂停 / 上一首 / 下一首正常
5. 背景和布局接近参考图 ref-immersive-player.png
```

---

### 阶段 9：歌词功能

目标：支持同名 `.lrc` 歌词。

功能：

- 自动查找同目录同名歌词
- 解析 lrc 时间
- 根据播放进度高亮当前歌词
- 无歌词时显示占位文案
- 歌词字体大小设置

验收：

```text
1. mp3 和 lrc 同名放在同一目录
2. 导入并播放歌曲
3. 歌词面板显示歌词
4. 当前歌词随播放进度变化
5. 拖动进度条后歌词同步更新
```

---

### 阶段 10：设置页和稳定性

目标：完善设置和异常处理。

功能：

- 默认音乐目录
- 自动扫描开关
- 启动时继续上次播放
- 默认播放模式
- 主题模式
- 歌词设置
- 清理无效歌曲
- 缓存管理

验收：

```text
1. 修改设置后关闭重开仍然生效
2. 文件不存在不会导致应用崩溃
3. 播放失败有提示
4. 路径包含中文能正常播放
5. 路径包含空格能正常播放
```

---

### 阶段 11：封面和元数据增强

目标：歌曲信息更完整。

功能：

- 读取音频内嵌标题
- 读取歌手
- 读取专辑
- 读取封面
- 没有封面时显示默认封面
- 手动编辑歌曲信息

验收：

```text
1. 有内嵌封面的歌曲能显示封面
2. 没有封面的歌曲显示默认封面
3. 没有歌手时显示未知艺术家
4. 编辑歌曲信息后能保存
```

---

### 阶段 12：打包发布

目标：生成可运行 Windows 应用。

功能：

- 应用图标
- 应用名称
- release 构建
- 安装包
- 运行说明
- 更新日志

验收：

```text
1. flutter build windows 成功
2. release 版本能打开
3. 没有 Flutter 开发环境的电脑也能运行
4. 音乐导入和播放正常
```

---

## 13. Codex 开发规则

每次让 Codex 开发时必须遵守：

1. 每次只做一个阶段。
2. 不要提前做后面阶段的功能。
3. 不要重写整个项目。
4. 不要删除已经可用的功能。
5. 修改前先检查当前目录结构。
6. 修改后必须给出运行命令。
7. 修改后必须给出测试步骤。
8. 出现依赖冲突时先说明原因，不要盲目换技术栈。
9. UI 优化不能破坏播放逻辑。
10. 播放逻辑、数据库逻辑、页面 UI 必须分层。

---

## 14. 给 Codex 的总提示词

第一次创建项目时使用：

```text
我要从零开始开发一个 Flutter Windows 本地音乐播放器，项目名 MelodyBox。

请严格阅读并遵守我提供的《MelodyBox 本地音乐播放器开发文档》。

当前只完成阶段 1：最小播放 MVP。

要求：
1. 使用 Flutter 开发 Windows 桌面应用。
2. 使用 media_kit 作为播放内核。
3. 使用 file_picker 选择本地音频文件。
4. 支持选择一首 mp3 / flac / wav 文件。
5. 支持播放、暂停、继续播放。
6. 显示当前播放进度和总时长。
7. 支持拖动进度条。
8. 播放逻辑封装到 AudioPlayerService。
9. 页面只做最小可用 UI，不要做复杂界面。
10. 不要接数据库。
11. 不要做歌词。
12. 不要做封面。
13. 不要做播放列表。
14. 不要做托盘。
15. 不要一次性开发后续阶段。

完成后请告诉我：
1. 修改了哪些文件。
2. 如何运行。
3. 如何测试。
4. 当前还有哪些限制。
```

---

## 15. 阶段 2 Codex 提示词

```text
继续开发 MelodyBox。

请严格基于现有代码继续，不要重写整个项目。

当前只完成阶段 2：音乐库内存版。

要求：
1. 支持一次选择多个音频文件。
2. 将选择的歌曲显示在音乐库列表中。
3. 点击列表中的歌曲可以播放。
4. 当前播放歌曲需要高亮。
5. 支持播放全部。
6. 支持上一首 / 下一首。
7. 歌曲信息暂时可以从文件名生成。
8. 播放逻辑仍然由 AudioPlayerService 管理。
9. 页面不要直接操作底层播放器。
10. 不要接数据库。
11. 不要做歌词。
12. 不要做封面。
13. 不要做复杂 UI。

完成后请告诉我：
1. 修改了哪些文件。
2. 如何运行。
3. 如何测试。
4. 是否影响阶段 1 的播放功能。
```

---

## 16. 阶段 3 Codex 提示词

```text
继续开发 MelodyBox。

请严格基于现有代码继续，不要重写整个项目。

当前只完成阶段 3：本地数据库持久化。

要求：
1. 使用 SQLite + drift 保存音乐库。
2. 保存字段包括：id、title、artist、album、filePath、durationMs、coverPath、isFavorite、playCount、createdAt、lastPlayedAt、isAvailable。
3. 启动应用时从数据库加载音乐库。
4. 关闭应用后重新打开，音乐库仍然存在。
5. 防止重复导入同一个 filePath。
6. 启动时检查文件是否存在。
7. 文件不存在时标记为不可用，不要让应用崩溃。
8. 数据库操作封装到 Repository / DAO。
9. 页面不要直接操作数据库。
10. 不要做歌词。
11. 不要做封面读取。
12. 不要做播放列表。

完成后请告诉我：
1. 新增了哪些依赖。
2. 修改了哪些文件。
3. 数据库表结构是什么。
4. 如何运行代码生成。
5. 如何测试持久化。
```

---

## 17. 阶段 8 沉浸式播放页 Codex 提示词

```text
继续开发 MelodyBox。

当前只完成阶段 8：沉浸式播放页。

请参考 docs/images/ref-immersive-player.png。

要求：
1. 新建 ImmersivePlayerPage。
2. 点击底部播放栏可以进入沉浸式播放页。
3. 沉浸式播放页不要显示左侧导航栏。
4. 页面顶部只保留 MelodyBox 标识、返回按钮和窗口控制区域。
5. 主体展示大封面、歌曲标题、歌手、专辑、播放状态。
6. 展示播放 / 暂停 / 上一首 / 下一首 / 随机 / 循环按钮。
7. 展示进度条和当前时间 / 总时长。
8. 展示音量控制。
9. 右侧展示歌词卡片，但歌词内容可以先用占位数据。
10. 背景使用当前封面或默认背景的模糊效果。
11. 风格要高级、简约、浅色、毛玻璃、留白充足。
12. 不要做真实歌词解析，歌词解析留到阶段 9。
13. 不要破坏主页面和底部播放栏。

完成后请告诉我：
1. 修改了哪些文件。
2. 如何进入播放详情页。
3. 如何返回主页面。
4. 播放控制是否仍然正常。
```

---

## 18. 质量检查清单

每个阶段完成后都检查：

```text
flutter pub get
flutter analyze
flutter run -d windows
```

人工检查：

- 应用能启动
- 控制台没有明显报错
- 播放不会崩溃
- 页面没有明显 overflow
- 关闭重开功能符合预期
- 旧功能没有被破坏

---

## 19. 常见风险和处理

### 19.1 播放失败

可能原因：

- 文件格式不支持
- 路径有中文或空格处理不当
- 文件被移动或删除
- 播放器未初始化
- Windows 音频依赖缺失

处理：

- 捕获异常
- 显示友好提示
- 不让应用崩溃
- 跳过不可播放歌曲

### 19.2 数据库和 UI 混在一起

错误做法：

```text
页面组件里直接写数据库增删改查
```

正确做法：

```text
Page -> Controller -> Repository -> DAO -> Database
```

### 19.3 一次性做太多功能

错误做法：

```text
第一轮就做播放、数据库、歌词、封面、播放列表、托盘、打包
```

正确做法：

```text
每次只做一个阶段
每个阶段都有验收标准
```

### 19.4 UI 好看但功能坏了

处理原则：

- UI 重构前确认播放功能可用。
- UI 重构后必须重新测试播放、暂停、切歌、进度条。
- 播放服务不要和页面强绑定。

---

## 20. 最终项目亮点

完成后可以在简历或面试中这样描述：

```text
MelodyBox 是一个基于 Flutter 的纯本地离线音乐播放器，使用 media_kit 实现本地音频播放，使用 SQLite + drift 实现音乐库、收藏和播放列表持久化。项目将播放控制、文件导入、歌词解析、数据库访问和页面展示进行分层封装，支持本地歌曲导入、播放队列、播放模式切换、歌词同步和沉浸式播放页。
```

技术亮点：

- Flutter Windows 桌面端应用
- 纯本地离线，无需后端
- media_kit 播放内核封装
- SQLite 本地持久化
- 播放队列和播放模式管理
- 本地 `.lrc` 歌词解析
- 沉浸式播放页 UI
- 文件失效和异常播放处理
- 分层架构，便于维护和扩展

---

## 21. 建议开发顺序总览

```text
1. 单首歌曲播放
2. 多歌曲导入
3. 音乐库持久化
4. 播放队列和播放模式
5. 主界面 UI
6. 我喜欢
7. 播放列表
8. 沉浸式播放页
9. 歌词同步
10. 设置页
11. 封面和元数据
12. 打包发布
```

不要跳阶段。
不要一开始追求完整。
先稳定，再好看，再高级。
