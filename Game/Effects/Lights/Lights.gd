extends Node2D

var torch:=false

func torchOn():
	torch=true
	update_torch()
	
func torchOff():
	torch=false
	update_torch()

func has_torch():
	return torch

func update_torch():
	$TorchOn.visible=torch
	$TorchOff.visible=!torch


