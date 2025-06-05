# Godot 配置驱动存档系统 (Config-Driven Save System)

一个基于JSON配置的Godot 4通用存档系统，支持静态对象和动态对象的保存与加载。

## 🌟 特性

- **配置驱动** - 通过JSON文件轻松配置需要保存的对象和属性
- **混合模式** - 支持静态对象(如玩家)和动态对象(如敌人、物品)
- **灵活的属性访问** - 支持复杂的节点属性路径
- **零代码侵入** - 无需修改现有游戏对象代码
- **兼容性好** - 保持与传统保存方式的兼容性

## 📁 文件结构

```
Scripts/save/
├── save_load_manager.gd      # 核心存档管理器
├── ISaveable.gd             # 可保存对象接口（可选）
├── save_config.json         # 配置文件（需根据项目调整）
└── scene_data_template.gd   # SceneData类模板

项目根目录/
└── scene_data.gd           # 存档数据资源类（从模板复制）
```

## 🚀 快速开始

### 1. 下载文件
从GitHub下载或克隆整个仓库

### 2. 文件复制
将所有`.gd`文件和`.json`文件复制到你的Godot项目的`Scripts/save/`目录中

### 3. 添加SceneData类
将`scene_data_template.gd`复制到项目根目录并重命名为`scene_data.gd`

### 4. 配置对象
编辑`save_config.json`根据你的游戏对象调整配置

### 5. 使用系统
将`save_load_manager.gd`附加到场景中的CanvasLayer节点，然后调用Save()和Load()方法

## 🎮 使用示例

```gdscript
# 保存游戏
save_manager.Save()

# 加载游戏  
save_manager.Load()
```

## 📝 配置示例

```json
{
  "save_version": "1.0",
  "objects": {
    "Player": {
      "node_group": "saveable",
      "node_name": "Player",
      "is_dynamic": false,
      "properties": [
        {
          "name": "position",
          "path": "global_position"
        },
        {
          "name": "facing_left",
          "path": "get_child(0).flip_h"
        }
      ]
    },
    "Box": {
      "node_group": "Box",
      "scene_path": "res://box.tscn",
      "is_dynamic": true,
      "properties": [
        {
          "name": "position",
          "path": "global_position"
        },
        {
          "name": "rotation",
          "path": "rotation"
        }
      ]
    }
  }
}
```

## 📄 许可证

MIT License - 可自由使用、修改和分发

## 📞 支持

如果使用过程中遇到问题，请查看详细文档或提交Issue。

---

**让Godot存档变得简单！** 🎯