@tool
extends EditorPlugin

func _enter_tree():
	var icon = preload("res://addons/character_control/icon-plugin.png")
	add_custom_type("CharacterControl", "CharacterBody3D", preload("res://addons/character_control/main.gd"), icon)

func _exit_tree():
	remove_custom_type("CharacterControl")
