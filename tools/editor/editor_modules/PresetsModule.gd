extends HBEditorModule

func _ready():
	transforms = [
		HBEditorTransforms.VerticalMultiPreset.new(-1),
		HBEditorTransforms.VerticalMultiPreset.new(1),
		HBEditorTransforms.HorizontalMultiPreset.new(1),
		HBEditorTransforms.HorizontalMultiPreset.new(-1),
		HBEditorTransforms.QuadPreset.new(),
		HBEditorTransforms.QuadPreset.new(true),
		HBEditorTransforms.SidewaysQuadPreset.new(),
		HBEditorTransforms.TrianglePreset.new(false),
		HBEditorTransforms.TrianglePreset.new(true),
	]
