extends TextureRect

func _gui_input(event: InputEvent):
	if is_visible_in_tree():
		var scale_trf := Transform2D.IDENTITY
		var xform := get_global_transform()
		scale_trf = scale_trf.scaled(rect_size / $Viewport.size)
		xform *= scale_trf
		xform.origin -= rect_global_position
		var ev := event.xformed_by(xform.affine_inverse())
		
		$Viewport.input(ev)
		if $Viewport is SkinEditorViewport:
			if ev is InputEventMouse:
				$Viewport.mouse_position = ev.position
		$Viewport.trf = xform
