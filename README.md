# 元气提词器

一款简洁优雅的 iOS 提词器应用，帮助您在视频拍摄、演讲、直播时更加自信流畅。

## 功能特点

### 核心功能
- **台词管理** - 创建、编辑、保存多个台词草稿
- **悬浮提词** - 画中画风格的悬浮窗口，不遮挡拍摄画面
- **自动滚动** - 可自定义滚动速度，自动滚动台词
- **智能高亮** - 当前阅读位置自动高亮显示

### 自定义选项
- **滚动速度** - 0.1 - 1.0 可调节，适应不同语速
- **字体大小** - 16 - 48 可调节，远距离也能清晰看见
- **文字旋转** - 支持 0°/90°/180°/270° 旋转，适应不同拍摄角度
- **颜色主题** - 8 种颜色可选，适应不同环境光线

### 手势控制
- **单击** - 暂停/继续滚动
- **双击** - 重新开始滚动

## 技术栈

- **SwiftUI** - 现代化的声明式 UI 框架
- **SwiftData** - 数据持久化存储
- **iOS 17.0+** - 要求最低系统版本

## 项目结构

```
Teleprompter/
├── TeleprompterApp.swift              # 应用入口
├── ContentView.swift                  # 根视图
├── Info.plist                         # 应用配置
├── Models/
│   ├── Script.swift                   # 台词数据模型
│   └── TeleprompterSettings.swift     # 提词器设置模型
├── Views/
│   ├── LaunchScreenView.swift         # 启动页
│   ├── ScriptListView.swift           # 主页-台词列表
│   ├── ScriptEditorView.swift         # 台词编辑页
│   ├── TeleprompterSettingsView.swift # 悬浮提词设置页
│   └── FloatingTeleprompterView.swift # 悬浮窗提词器
└── Assets.xcassets/                   # 资源文件
```

## 使用指南

### 1. 创建台词
- 在主页点击"新建台词"卡片
- 输入您的演讲稿或台词内容
- 点击"保存"

### 2. 编辑台词
- 点击已保存的台词卡片
- 修改内容后保存

### 3. 使用悬浮提词器
- 点击台词卡片上的"悬浮提词"按钮
- 调整滚动速度、字号、颜色等参数
- 点击"开启悬浮窗"
- 悬浮窗会显示在屏幕上方，方便拍摄时查看

### 4. 控制滚动
- **单击屏幕** - 暂停或继续滚动
- **双击屏幕** - 从头开始重新滚动
- **点击 X** - 关闭悬浮窗

## 开发

### 环境要求
- Xcode 15.0+
- iOS 17.0+
- macOS 13.0+

### 运行项目
```bash
# 克隆项目
git clone https://github.com/chenyuanqi/teleprompter.git
cd teleprompter

# 用 Xcode 打开项目
open Teleprompter.xcodeproj

# 选择模拟器或真机运行
```

### 构建
在 Xcode 中选择 Product -> Build (⌘B) 或直接运行 (⌘R)

## 应用截图

- 主页 - 台词列表管理
- 编辑页 - 全屏文本编辑
- 设置页 - 自定义提词器参数
- 悬浮窗 - 画中画风格的提词显示

## 版本历史

### v1.0.0 (2025-01-22)
- ✨ 首次发布
- 📝 台词创建与编辑
- 🎬 悬浮窗提词器
- ⚙️ 自定义滚动速度、字号、颜色、旋转
- 👆 手势控制

## 贡献

欢迎提交 Issue 和 Pull Request！

## 许可证

MIT License

## 联系方式

- GitHub: [@chenyuanqi](https://github.com/chenyuanqi)
- 项目地址: [https://github.com/chenyuanqi/teleprompter](https://github.com/chenyuanqi/teleprompter)

---

让演讲更自信 💪
