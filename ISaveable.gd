# ISaveable.gd - 可保存对象接口
class_name ISaveable
extends RefCounted

# 获取保存数据
func GetSaveData() -> Dictionary:
	return {}

# 加载数据
func LoadSaveData(data: Dictionary) -> void:
	pass