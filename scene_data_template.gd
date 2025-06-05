# scene_data_template.gd - SceneData类模板
# 将此文件复制到项目根目录并重命名为scene_data.gd

extends Resource
class_name SceneData

@export var player_position : Vector2
@export var is_facing_left : bool
@export var box_array : Array[PackedScene]

# 新增：存储所有对象的数据
@export var all_objects_data : Dictionary = {}