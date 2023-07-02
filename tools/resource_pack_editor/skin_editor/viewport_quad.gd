extends TextureRect

func _gui_input(event: InputEvent):
	if is_visible_in_tree():
		var scale_trf := Transform2D.IDENTITY
		var xform := get_global_transform()
		scale_trf = scale_trf.scaled(size / Vector2($SubViewport.size))
		xform *= scale_trf
		xform.origin -= global_position
		var ev := event.xformed_by(xform.affine_inverse())
		
		$SubViewport.push_input(ev)
		if $SubViewport is SkinEditorViewport:
			if ev is InputEventMouse:
				$SubViewport.mouse_position = ev.position
		$SubViewport.trf = xform
