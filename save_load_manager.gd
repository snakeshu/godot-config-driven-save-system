# SaveLoadManager.gd - 配置驱动的保存系统
extends CanvasLayer

var save_config: Dictionary = {}

func _ready():
	LoadSaveConfig()

# 加载保存配置
func LoadSaveConfig():
	var config_file = FileAccess.open("res://Scripts/save/save_config.json", FileAccess.READ)
	if config_file:
		var json_string = config_file.get_as_text()
		config_file.close()
		
		var json = JSON.new()
		var parse_result = json.parse(json_string)
		if parse_result == OK:
			save_config = json.data
			print("成功加载保存配置, 版本: ", save_config.get("save_version", "未知"))
		else:
			print("JSON解析失败: ", json.get_error_message())
	else:
		print("无法打开配置文件")

# 保存函数 - 基于配置
func Save() -> void:
	print("=== Save函数被调用 ===")
	
	if save_config.is_empty():
		print("配置未加载，无法保存")
		return
	
	var save_data = {}
	
	# 遍历配置中的对象类型
	for object_type in save_config.objects.keys():
		var object_config = save_config.objects[object_type]
		print("处理对象类型: ", object_type)
		
		# 根据配置获取节点
		var nodes = []
		if object_config.has("node_group"):
			nodes = get_tree().get_nodes_in_group(object_config.node_group)
			print("通过组 '", object_config.node_group, "' 找到节点: ", nodes)
			
			# 如果同时指定了node_name，进一步筛选
			if object_config.has("node_name"):
				var filtered_nodes = []
				for node in nodes:
					if node.name == object_config.node_name:
						filtered_nodes.append(node)
				nodes = filtered_nodes
				print("按名称筛选后的节点: ", nodes)
		elif object_config.has("node_name"):
			var node = get_tree().get_first_node_in_group("saveable")
			print("查找节点名为 '", object_config.node_name, "' 的节点，找到: ", node)
			if node and node.name == object_config.node_name:
				nodes = [node]
		
		print("找到 ", nodes.size(), " 个 ", object_type, " 节点")
		
		# 保存每个节点的数据
		for i in range(nodes.size()):
			var node = nodes[i]
			var node_data = {}
			
			# 根据配置提取属性
			for property_config in object_config.properties:
				var value = GetPropertyValue(node, property_config.path)
				node_data[property_config.name] = value
			
			# 存储数据
			var key = object_type
			if object_config.get("is_dynamic", false):
				key = object_type + "_" + str(i)
			
			save_data[key] = node_data
			save_data[key]["_object_type"] = object_type
			
			if object_config.has("scene_path"):
				save_data[key]["_scene_path"] = object_config.scene_path
	
	print("保存的数据: ", save_data)
	
	# 保存到文件
	var scene_data = SceneData.new()
	scene_data.all_objects_data = save_data
	
	# 为了兼容性，也设置旧字段
	if save_data.has("Player") and save_data.Player != null:
		scene_data.player_position = save_data.Player.get("position", Vector2.ZERO)
		scene_data.is_facing_left = save_data.Player.get("facing_left", false)
	else:
		# 如果没有Player数据，使用默认值
		scene_data.player_position = Vector2.ZERO
		scene_data.is_facing_left = false
	
	ResourceSaver.save(scene_data, "user://save_game.tres")
	print("Game Saved!")

# 加载函数 - 基于配置
func Load() -> void:
	print("=== Load函数被调用 ===")
	
	if save_config.is_empty():
		print("配置未加载，无法加载")
		return
		
	if not ResourceLoader.exists("user://save_game.tres"):
		print("保存文件不存在")
		return
		
	var scene_data = ResourceLoader.load("user://save_game.tres") as SceneData
	if not scene_data:
		print("加载SceneData失败")
		return
	
	var save_data = scene_data.all_objects_data
	print("加载的数据: ", save_data.keys())
	
	# 清理动态对象
	for object_type in save_config.objects.keys():
		var object_config = save_config.objects[object_type]
		if object_config.get("is_dynamic", false):
			var nodes = get_tree().get_nodes_in_group(object_config.node_group)
			for node in nodes:
				node.queue_free()
	
	await get_tree().process_frame
	
	# 恢复对象
	for data_key in save_data.keys():
		var object_data = save_data[data_key]
		var object_type = object_data.get("_object_type", "")
		
		if not save_config.objects.has(object_type):
			continue
			
		var object_config = save_config.objects[object_type]
		
		if object_config.get("is_dynamic", false):
			# 动态对象需要实例化
			RestoreDynamicObject(object_config, object_data)
		else:
			# 静态对象直接更新
			RestoreStaticObject(object_config, object_data)
	
	print("Game Loaded!")

# 获取节点属性值
func GetPropertyValue(node: Node, property_path: String):
	var parts = property_path.split(".")
	var current = node
	
	for part in parts:
		if part.contains("("):
			# 方法调用
			var method_name = part.split("(")[0]
			if part.contains(")"):
				var args_str = part.split("(")[1].split(")")[0]
				if args_str.is_empty():
					current = current.call(method_name)
				else:
					var args = [int(args_str)]
					current = current.call(method_name, args[0])
			else:
				current = current.call(method_name)
		else:
			# 属性访问
			current = current.get(part)
	
	return current

# 设置节点属性值
func SetPropertyValue(node: Node, property_path: String, value):
	var parts = property_path.split(".")
	var current = node
	
	# 导航到最后一个对象
	for i in range(parts.size() - 1):
		var part = parts[i]
		if part.contains("("):
			var method_name = part.split("(")[0]
			if part.contains(")"):
				var args_str = part.split("(")[1].split(")")[0]
				if args_str.is_empty():
					current = current.call(method_name)
				else:
					var args = [int(args_str)]
					current = current.call(method_name, args[0])
		else:
			current = current.get(part)
	
	# 设置最终属性
	var final_property = parts[-1]
	current.set(final_property, value)

# 恢复动态对象
func RestoreDynamicObject(object_config: Dictionary, object_data: Dictionary):
	var scene_path = object_data.get("_scene_path", "")
	if scene_path.is_empty():
		return
	
	var scene_resource = load(scene_path) as PackedScene
	if not scene_resource:
		print("无法加载场景: ", scene_path)
		return
	
	var new_object = scene_resource.instantiate()
	get_tree().current_scene.add_child(new_object)
	
	await get_tree().process_frame
	
	# 应用属性
	for property_config in object_config.properties:
		var property_name = property_config.name
		if object_data.has(property_name):
			SetPropertyValue(new_object, property_config.path, object_data[property_name])

# 恢复静态对象
func RestoreStaticObject(object_config: Dictionary, object_data: Dictionary):
	var nodes = []
	if object_config.has("node_group"):
		nodes = get_tree().get_nodes_in_group(object_config.node_group)
		
		# 如果同时指定了node_name，进一步筛选
		if object_config.has("node_name"):
			var filtered_nodes = []
			for node in nodes:
				if node.name == object_config.node_name:
					filtered_nodes.append(node)
			nodes = filtered_nodes
	elif object_config.has("node_name"):
		var node = get_tree().get_first_node_in_group("saveable")
		if node and node.name == object_config.node_name:
			nodes = [node]
	
	if nodes.is_empty():
		print("找不到要恢复的静态对象: ", object_config)
		return
	
	var target_node = nodes[0]
	
	# 应用属性
	for property_config in object_config.properties:
		var property_name = property_config.name
		if object_data.has(property_name):
			SetPropertyValue(target_node, property_config.path, object_data[property_name])