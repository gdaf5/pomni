@tool
extends SkeletonPlayerModel
class_name GojoPlayerModel

var GOJO_PATH = "res://рыцарь/gojo.glb"

# Map Gojo metarig bone names -> Mixamo bone names so existing FBX animations apply directly
var BONE_RENAME_MAP = {
	"spine": "mixamorig_Hips",
	"spine.001": "mixamorig_Spine",
	"spine.002": "mixamorig_Spine1",
	"spine.003": "mixamorig_Spine2",
	"spine.004": "mixamorig_Neck",
	"spine.005": "mixamorig_Head",
	"shoulder.L": "mixamorig_LeftShoulder",
	"upper_arm.L": "mixamorig_LeftArm",
	"forearm.L": "mixamorig_LeftForeArm",
	"hand.L": "mixamorig_LeftHand",
	"shoulder.R": "mixamorig_RightShoulder",
	"upper_arm.R": "mixamorig_RightArm",
	"forearm.R": "mixamorig_RightForeArm",
	"hand.R": "mixamorig_RightHand",
	"f_index.01.L": "mixamorig_LeftHandIndex1",
	"f_index.02.L": "mixamorig_LeftHandIndex2",
	"f_index.03.L": "mixamorig_LeftHandIndex3",
	"thumb.01.L": "mixamorig_LeftHandThumb1",
	"thumb.02.L": "mixamorig_LeftHandThumb2",
	"thumb.03.L": "mixamorig_LeftHandThumb3",
	"f_middle.01.L": "mixamorig_LeftHandMiddle1",
	"f_middle.02.L": "mixamorig_LeftHandMiddle2",
	"f_middle.03.L": "mixamorig_LeftHandMiddle3",
	"f_ring.01.L": "mixamorig_LeftHandRing1",
	"f_ring.02.L": "mixamorig_LeftHandRing2",
	"f_ring.03.L": "mixamorig_LeftHandRing3",
	"f_pinky.01.L": "mixamorig_LeftHandPinky1",
	"f_pinky.02.L": "mixamorig_LeftHandPinky2",
	"f_pinky.03.L": "mixamorig_LeftHandPinky3",
	"f_index.01.R": "mixamorig_RightHandIndex1",
	"f_index.02.R": "mixamorig_RightHandIndex2",
	"f_index.03.R": "mixamorig_RightHandIndex3",
	"thumb.01.R": "mixamorig_RightHandThumb1",
	"thumb.02.R": "mixamorig_RightHandThumb2",
	"thumb.03.R": "mixamorig_RightHandThumb3",
	"f_middle.01.R": "mixamorig_RightHandMiddle1",
	"f_middle.02.R": "mixamorig_RightHandMiddle2",
	"f_middle.03.R": "mixamorig_RightHandMiddle3",
	"f_ring.01.R": "mixamorig_RightHandRing1",
	"f_ring.02.R": "mixamorig_RightHandRing2",
	"f_ring.03.R": "mixamorig_RightHandRing3",
	"f_pinky.01.R": "mixamorig_RightHandPinky1",
	"f_pinky.02.R": "mixamorig_RightHandPinky2",
	"f_pinky.03.R": "mixamorig_RightHandPinky3",
	"thigh.L": "mixamorig_LeftUpLeg",
	"shin.L": "mixamorig_LeftLeg",
	"foot.L": "mixamorig_LeftFoot",
	"toe.L": "mixamorig_LeftToeBase",
	"thigh.R": "mixamorig_RightUpLeg",
	"shin.R": "mixamorig_RightLeg",
	"foot.R": "mixamorig_RightFoot",
	"toe.R": "mixamorig_RightToeBase",
}

func _ready() -> void:
	if Engine.is_editor_hint():
		return
	PALADIN_PATH = GOJO_PATH
	super._ready()
	_reparent_skeleton_to_root()
	_rename_bones_to_mixamo()

# GLB imports skeleton under an intermediate node (gojo/metarig/Skeleton3D),
# but animation tracks reference "Skeleton3D:mixamorig_*" relative to the model root.
# Reparent so the paths resolve exactly like the Paladin FBX.
func _reparent_skeleton_to_root() -> void:
	if not skeleton or not fbx_model:
		push_warning("[Gojo] Skeleton or model missing, reparent skipped")
		return
	if skeleton.get_parent() == fbx_model:
		return
	if skeleton.get_parent() == null:
		return
	print("[Gojo] Reparenting skeleton from ", skeleton.get_parent().name, " to ", fbx_model.name)
	skeleton.reparent(fbx_model, true)

func _rename_bones_to_mixamo() -> void:
	if not skeleton:
		push_warning("[Gojo] Skeleton not found, bone rename skipped")
		return
	var renamed := 0
	for i in range(skeleton.get_bone_count()):
		var bone_name = skeleton.get_bone_name(i)
		if BONE_RENAME_MAP.has(bone_name):
			skeleton.set_bone_name(i, BONE_RENAME_MAP[bone_name])
			renamed += 1
	_update_skin_binds()
	print("[Gojo] Renamed ", renamed, " bones to Mixamo convention")

# GLB skins bind bones by name; after renaming skeleton bones the mesh Skin
# references must be updated so the model keeps its deformation.
func _update_skin_binds() -> void:
	if not skeleton:
		return
	for mesh_node in _collect_mesh_instances(skeleton):
		var skin = mesh_node.skin
		if skin == null:
			continue
		for i in range(skin.get_bind_count()):
			var bind_name = skin.get_bind_name(i)
			if BONE_RENAME_MAP.has(bind_name):
				skin.set_bind_name(i, BONE_RENAME_MAP[bind_name])

func _collect_mesh_instances(node: Node) -> Array:
	var result: Array = []
	if node is MeshInstance3D:
		result.append(node)
	for child in node.get_children():
		result.append_array(_collect_mesh_instances(child))
	return result