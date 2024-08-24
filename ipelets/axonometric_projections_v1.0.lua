----------------------------------------------------------------------
-- axonometric ipelet
----------------------------------------------------------------------
--[[

    This ipelet is based on the included "Goodies" ipelet.

    Axonometric projection is defined by three (but usually two)
    angles, which define the normal vector of the plane in which is
    the 3D space projected.

    2023, 2024 Tomáš Drobil
    2024 Alexander Greyling (idea for extra rotaion feature)

    Version 1

    Version 2
    Added extra rotation before projection rotations
    (only rotation along one axis at a time).

    Version 3
    Whole ipelet reworked, dialog windows for settings added,
    extra rotation can be done around multiple axis at once.
    Now one ipelet for both general axonometric projection and
    isometric projection (special case).

--]]

label = "Axonometric projections"

revertOriginal = _G.revertOriginal

about = [[
Axonometric projections.
]]

V = ipe.Vector

-- Define parameters for projections
local phi = 30.0
local theta = 30.0
local psi = 0.0

-- Variables for storing settings
local rot_axes = {
  xy = {ax1 = 1, ax2 = 2, ax3 = 3},
  xz = {ax1 = 1, ax2 = 2, ax3 = 3},
  yz = {ax1 = 1, ax2 = 2, ax3 = 3}
}

local rot_angles = {
  xy = {ang1 = 0.0, ang2 = 0.0, ang3 = 0.0},
  xz = {ang1 = 0.0, ang2 = 0.0, ang3 = 0.0},
  yz = {ang1 = 0.0, ang2 = 0.0, ang3 = 0.0}
}

local run_settings1_always = true
local run_settings2_always = true

local inverse_plane_no = 1
local inverse_extra_rot = false


local function bounding_box(p)
  local box = ipe.Rect()
  for i,obj,sel,layer in p:objects() do
    if sel then box:add(p:bbox(i)) end
  end
  return box
end

local function get_dialog_parent(model)
  local ui = model.ui
  if(ui.win == nil) then
     return ui
  end
  return ui:win()
end

local function plane_no2str(plane_no)
  local plane_str

  if plane_no == 1 then
    plane_str = "xy"
  elseif plane_no == 2 then
    plane_str = "xz"
  elseif plane_no == 3 then
    plane_str = "yz"
  end

  return plane_str
end

-- Function to multiply two 3x3 matrices
local function matrix_mult(matrix1, matrix2)
  local result = {}

  -- Initialize the result matrix with zeros
  for i = 1, 3 do
    result[i] = {}
    for j = 1, 3 do
      result[i][j] = 0
    end
  end

  -- Perform matrix multiplication
  for i = 1, 3 do
    for j = 1, 3 do
      for k = 1, 3 do
        result[i][j] = result[i][j] + matrix1[i][k] * matrix2[k][j]
      end
    end
  end

  return result
end

-- Perform matrix multiplication of 2+ matrices
local function matrix_mult_multiple(...)
  local matrices = {...}
  local result = matrices[1]

  for i = 2, #matrices do
    result = matrix_mult(result, matrices[i])
  end

  return result
end

-- Function generating a rotation matrix
local function matrix_rot3d(angle, axis)
  -- axis is an integer: 1=x, 2=y, 3=z
  local sin = math.sin
  local cos = math.cos
  local matrix

  if axis == 1 then
    -- Rotation around x-axis
    matrix = {
      {1, 0, 0},
      {0, cos(angle), -sin(angle)},
      {0, sin(angle), cos(angle)}
    }
  elseif axis == 2 then
    -- Rotation around y-axis
    matrix = {
      {cos(angle), 0, sin(angle)},
      {0, 1, 0},
      {-sin(angle), 0, cos(angle)}
    }
  elseif axis == 3 then
    -- Rotation around z-axis
    matrix = {
      {cos(angle), -sin(angle), 0},
      {sin(angle), cos(angle), 0},
      {0, 0, 1}
    }
  end

  return matrix
end

-- Dialog windows for settings angles phi, theta, psi
local function settings1(model)
  local id = get_dialog_parent(model)
  local d = ipeui.Dialog(id, "Settings")

  -- Create dialog window
  d:add("label_phi", "label", {label="Phi"}, 1, 1, 1, 1)
  d:add("phi", "input", {}, 1, 2, 1, 1)
  d:add("label_theta", "label", {label="Theta"}, 2, 1, 1, 1)
  d:add("theta", "input", {}, 2, 2, 1, 1)
  d:add("label_psi", "label", {label="Psi"}, 3, 1, 1, 1)
  d:add("psi", "input", {}, 3, 2, 1, 1)

  local function set_isometric_angles1()
    if d:get("box1") then
      phi = -45.0
      theta = math.atan(math.sqrt(2)/2) * 180/math.pi
      psi = 0.0
      d:set("phi", phi)
      d:set("theta", theta)
      d:set("psi", psi)
    end
  end
  local function set_isometric_angles2()
    if d:get("box2") then
      phi = 45.0
      theta = math.atan(math.sqrt(2)/2) * 180/math.pi
      psi = 0.0
      d:set("phi", phi)
      d:set("theta", theta)
      d:set("psi", psi)
    end
  end

  d:add("box1", "checkbox", {label="Set isometric projection (option 1)", action=set_isometric_angles1}, 4, 1, 1, 2)
  d:add("box2", "checkbox", {label="Set isometric projection (option 2)", action=set_isometric_angles2}, 5, 1, 1, 2)

  local function set_dialog1_appearance()
    run_settings1_always = d:get("checkbox1")
  end
  d:add("checkbox1", "checkbox", {label="Run dialog before each simple projection.", action=set_dialog1_appearance}, 6, 1, 1, 2)
  d:set("checkbox1", run_settings1_always)

  d:addButton("ok", "&Ok", "accept")
  d:addButton("cancel", "&Cancel", "reject")

  -- Set input values to values by user or default if the first input is done
  d:set("phi", phi)
  d:set("theta", theta)
  d:set("psi", psi)

  ::rerun::
  if not d:execute() then return false end
  -- Return false if dialog is aborted (i.e. "cancel" is pressed)
  -- Code bellow done if okay is pressed and no error is detected

  -- Store values of angles in temporary local variables
  local phi_store = tonumber(d:get("phi"))
  local theta_store = tonumber(d:get("theta"))
  local psi_store = tonumber(d:get("psi"))

  -- Check user input for angles
  if not phi_store or
  not theta_store or
  not psi_store then
    model:warning("Please enter valid values.")
    goto rerun
  end

  -- overwrite global values
  phi = phi_store
  theta = theta_store
  psi = psi_store
end

-- Dialog windows for settings angles of extra rotation before projection
local function settings2(model)
  -- Store 3 angles separated for each rotated plane projection
  local id = get_dialog_parent(model)
  local d = ipeui.Dialog(id, "Settings for extra rotation")

  -- Create dialog window
  d:add("label_xy", "label", {label="xy"}, 1, 1, 1, 2)
  d:add("combo_ang11", "combo", {"x rotation", "y rotation", "z rotation"}, 2, 1, 1, 1)
  d:add("ang11", "input", {}, 2, 2, 1, 1)
  d:add("combo_ang12", "combo", {"x rotation", "y rotation", "z rotation"}, 3, 1, 1, 1)
  d:add("ang12", "input", {}, 3, 2, 1, 1)
  d:add("combo_ang13", "combo", {"x rotation", "y rotation", "z rotation"}, 4, 1, 1, 1)
  d:add("ang13", "input", {}, 4, 2, 1, 1)

  d:add("label_xz", "label", {label="xz"}, 5, 1, 1, 2)
  d:add("combo_ang21", "combo", {"x rotation", "y rotation", "z rotation"}, 6, 1, 1, 1)
  d:add("ang21", "input", {}, 6, 2, 1, 1)
  d:add("combo_ang22", "combo", {"x rotation", "y rotation", "z rotation"}, 7, 1, 1, 1)
  d:add("ang22", "input", {}, 7, 2, 1, 1)
  d:add("combo_ang23", "combo", {"x rotation", "y rotation", "z rotation"}, 8, 1, 1, 1)
  d:add("ang23", "input", {}, 8, 2, 1, 1)

  d:add("label_yz", "label", {label="yz"}, 9, 1, 1, 2)
  d:add("combo_ang31", "combo", {"x rotation", "y rotation", "z rotation"}, 10, 1, 1, 1)
  d:add("ang31", "input", {}, 10, 2, 1, 1)
  d:add("combo_ang32", "combo", {"x rotation", "y rotation", "z rotation"}, 11, 1, 1, 1)
  d:add("ang32", "input", {}, 11, 2, 1, 1)
  d:add("combo_ang33", "combo", {"x rotation", "y rotation", "z rotation"}, 12, 1, 1, 1)
  d:add("ang33", "input", {}, 12, 2, 1, 1)

  d:add("label_explain", "label", {label="Note: Order from top to bottom determines the order of rotations."}, 13, 1, 1, 2)

  local function set_dialog2_appearance()
    run_settings2_always = d:get("checkbox1")
  end

  d:add("checkbox1", "checkbox", {label="Run dialog before each projection.", action=set_dialog2_appearance}, 14, 1, 1, 2)
  d:set("checkbox1", run_settings2_always)

  d:addButton("ok", "&Ok", "accept")
  d:addButton("cancel", "&Cancel", "reject")


  -- Set combos to previous values set by user
  d:set("combo_ang11", rot_axes.xy.ax1)
  d:set("combo_ang12", rot_axes.xy.ax2)
  d:set("combo_ang13", rot_axes.xy.ax3)

  d:set("combo_ang21", rot_axes.xz.ax1)
  d:set("combo_ang22", rot_axes.xz.ax2)
  d:set("combo_ang23", rot_axes.xz.ax3)

  d:set("combo_ang31", rot_axes.yz.ax1)
  d:set("combo_ang32", rot_axes.yz.ax2)
  d:set("combo_ang33", rot_axes.yz.ax3)

  -- Set input values to values by user or default (0.0) if the first input is done
  d:set("ang11", rot_angles.xy.ang1)
  d:set("ang12", rot_angles.xy.ang2)
  d:set("ang13", rot_angles.xy.ang3)

  d:set("ang21", rot_angles.xz.ang1)
  d:set("ang22", rot_angles.xz.ang2)
  d:set("ang23", rot_angles.xz.ang3)

  d:set("ang31", rot_angles.yz.ang1)
  d:set("ang32", rot_angles.yz.ang2)
  d:set("ang33", rot_angles.yz.ang3)


  ::rerun::
  if not d:execute() then return false end
  -- Return false if dialog is aborted (i.e. "cancel" is pressed)
  -- Code bellow done if okay is pressed and no error is detected


  -- Store chosen values (around which axis rotation is done)
  local combo_ang11_store = d:get("combo_ang11")
  local combo_ang12_store = d:get("combo_ang12")
  local combo_ang13_store = d:get("combo_ang13")

  local combo_ang21_store = d:get("combo_ang21")
  local combo_ang22_store = d:get("combo_ang22")
  local combo_ang23_store = d:get("combo_ang23")

  local combo_ang31_store = d:get("combo_ang31")
  local combo_ang32_store = d:get("combo_ang32")
  local combo_ang33_store = d:get("combo_ang33")

  -- Store values of angles
  local ang11_store = tonumber(d:get("ang11"))
  local ang12_store = tonumber(d:get("ang12"))
  local ang13_store = tonumber(d:get("ang13"))

  local ang21_store = tonumber(d:get("ang21"))
  local ang22_store = tonumber(d:get("ang22"))
  local ang23_store = tonumber(d:get("ang23"))

  local ang31_store = tonumber(d:get("ang31"))
  local ang32_store = tonumber(d:get("ang32"))
  local ang33_store = tonumber(d:get("ang33"))

  -- Check user input
  if not ang11_store or not ang12_store or not ang13_store or
  not ang21_store or not ang22_store or not ang23_store or
  not ang31_store or not ang32_store or not ang33_store then
    model:warning("Please enter valid values.")
    goto rerun
  end

  -- Overwrite values
  rot_axes.xy.ax1 = combo_ang11_store
  rot_axes.xy.ax2 = combo_ang12_store
  rot_axes.xy.ax3 = combo_ang13_store

  rot_axes.xz.ax1 = combo_ang21_store
  rot_axes.xz.ax2 = combo_ang22_store
  rot_axes.xz.ax3 = combo_ang23_store

  rot_axes.yz.ax1 = combo_ang31_store
  rot_axes.yz.ax2 = combo_ang32_store
  rot_axes.yz.ax3 = combo_ang33_store


  rot_angles.xy.ang1 = ang11_store
  rot_angles.xy.ang2 = ang12_store
  rot_angles.xy.ang3 = ang13_store

  rot_angles.xz.ang1 = ang21_store
  rot_angles.xz.ang2 = ang22_store
  rot_angles.xz.ang3 = ang23_store

  rot_angles.yz.ang1 = ang31_store
  rot_angles.yz.ang2 = ang32_store
  rot_angles.yz.ang3 = ang33_store
end

-- Dialog windows for settings angles of extra rotation before projection (lite version for one plane)
local function settings2_lite(model, plane)
  -- Run for each projection to plane + rotation (if checkbox to run it every time is checked)
  -- Store 3 angles for one plane projection with extra rotation
  local id = get_dialog_parent(model)
  local d = ipeui.Dialog(id, "Settings for extra rotation")

  -- Create dialog window
  d:add("label_xy", "label", {label=plane}, 1, 1, 1, 2)
  d:add("combo_ang11", "combo", {"x rotation", "y rotation", "z rotation"}, 2, 1, 1, 1)
  d:add("ang11", "input", {}, 2, 2, 1, 1)
  d:add("combo_ang12", "combo", {"x rotation", "y rotation", "z rotation"}, 3, 1, 1, 1)
  d:add("ang12", "input", {}, 3, 2, 1, 1)
  d:add("combo_ang13", "combo", {"x rotation", "y rotation", "z rotation"}, 4, 1, 1, 1)
  d:add("ang13", "input", {}, 4, 2, 1, 1)

  d:add("label_explain", "label", {label="Note: Order from top to bottom determines the order of rotations."}, 5, 1, 1, 2)

  local function set_dialog2_appearance()
    run_settings2_always = d:get("checkbox1")
  end

  d:add("checkbox1", "checkbox", {label="Run dialog before each projection with rotation.", action=set_dialog2_appearance}, 6, 1, 1, 2)
  d:set("checkbox1", run_settings2_always)

  d:addButton("ok", "&Ok", "accept")
  d:addButton("cancel", "&Cancel", "reject")

  -- Set combos to previous values set by user
  d:set("combo_ang11", rot_axes[plane].ax1)
  d:set("combo_ang12", rot_axes[plane].ax2)
  d:set("combo_ang13", rot_axes[plane].ax3)

  -- Set input values to values by user or defaults if the first input is done
  d:set("ang11", rot_angles[plane].ang1)
  d:set("ang12", rot_angles[plane].ang2)
  d:set("ang13", rot_angles[plane].ang3)

  ::rerun::
  if not d:execute() then return false end
  -- Return false if dialog is aborted (i.e. "cancel" is pressed)
  -- Code bellow done if okay is pressed and no error is detected

  -- Store chosen values (around which axis rotation is done)
  local combo_ang11_store = d:get("combo_ang11")
  local combo_ang12_store = d:get("combo_ang12")
  local combo_ang13_store = d:get("combo_ang13")

  -- Store values of angles
  local ang11_store = tonumber(d:get("ang11"))
  local ang12_store = tonumber(d:get("ang12"))
  local ang13_store = tonumber(d:get("ang13"))

  -- Check user input
  if not ang11_store or not ang12_store or not ang13_store then
    model:warning("Please enter valid values.")
    goto rerun
  end

  -- Overwrite values
  rot_axes[plane].ax1 = combo_ang11_store
  rot_axes[plane].ax2 = combo_ang12_store
  rot_axes[plane].ax3 = combo_ang13_store

  rot_angles[plane].ang1 = ang11_store
  rot_angles[plane].ang2 = ang12_store
  rot_angles[plane].ang3 = ang13_store
end

local function inverse_operation_dialog(model, num)
  local id = get_dialog_parent(model)
  local d = ipeui.Dialog(id, "Inverse operation")

  d:add("combo_plane", "combo", {"xy plane", "xz plane", "yz plane"}, 1, 1, 1, 1)
  d:add("box_rotation", "checkbox", {label="Extra rotation"}, 1, 2, 1, 1)

  d:set("combo_plane", inverse_plane_no)
  d:set("box_rotation", inverse_extra_rot)

  local function show_set1()
    settings1(model)
  end

  local function show_set2()
    settings2(model)
  end

  -- Buttons for settings
  d:addButton("set1_button", "Settings", show_set1)
  d:addButton("set2_button", "Settings 2", show_set2)

  d:addButton("ok", "&Ok", "accept")
  d:addButton("cancel", "&Cancel", "reject")

  if not d:execute() then return false end
  -- Return false if dialog is aborted (i.e. "cancel" is pressed)

  -- Overwrite
  inverse_plane_no = d:get("combo_plane")
  inverse_extra_rot = d:get("box_rotation")
end

-- Function returning the ipe matrix for projection
-- (for a given plane and with boolean representing if extra rotation is done/not done)
local function get_ipe_matrix(plane_no, extra_rot)
  -- Plane_no: integer (1=xy, 2=xz, 3=yz)
  -- Extra_rot: true/false
  local matrix3d
  local matrix
  local plane_str = plane_no2str(plane_no)
  local m1, m2, m3, m4, m5, m6

  m4 = matrix_rot3d(phi * math.pi / 180.0, 3)
  m5 = matrix_rot3d(theta * math.pi / 180.0, 2)
  m6 = matrix_rot3d(psi * math.pi / 180.0, 1)

  -- Projection without extra rotation before projection rotations
  if not extra_rot then
    matrix3d = matrix_mult_multiple(m6, m5, m4)
  end

  -- Projection with extra rotation before projection rotations
  if extra_rot then
    m1 = matrix_rot3d(rot_angles[plane_str].ang1 * math.pi / 180.0, rot_axes[plane_str].ax1)
    m2 = matrix_rot3d(rot_angles[plane_str].ang2 * math.pi / 180.0, rot_axes[plane_str].ax2)
    m3 = matrix_rot3d(rot_angles[plane_str].ang3 * math.pi / 180.0, rot_axes[plane_str].ax3)
    matrix3d = matrix_mult_multiple(m6, m5, m4, m3, m2, m1)
  end

  -- Calculate 2D vectors that are projection of
  -- Base vectors (i,j,k) in the original 3D space
  local ix = matrix3d[2][1]
  local iy = matrix3d[3][1]
  local jx = matrix3d[2][2]
  local jy = matrix3d[3][2]
  local kx = matrix3d[2][3]
  local ky = matrix3d[3][3]

  if plane_no == 1 then  -- xy plane
    matrix = ipe.Matrix(ix, iy, jx, jy, 0, 0)
  elseif plane_no == 2 then  -- xz plane
    matrix = ipe.Matrix(ix, iy, kx, ky, 0, 0)
  elseif plane_no == 3 then  -- yz plane
    matrix = ipe.Matrix(jx, jy, kx, ky, 0, 0)
  end

  return matrix
end

-- Main function to perform operation
local function preciseTransform(model, num)
  local p = model:page()
  -- Check if an object is selected, if not, cancel the operation
  if not p:hasSelection() then
    model.ui:explain("No selection")
    return
  end

  -- Check pinned
  for i, obj, sel, layer in p:objects() do
    if sel and obj:get("pinned") ~= "none" then
      model:warning("Cannot transform objects",
        "At least one of the objects is pinned")
      return
    end
  end

  local label = methods[num].label
  local matrix
  local plane_no
  local extra_rot

  if num == 9 then
    -- Call special dialog
    -- To solve bug: when "cancel" is pressed, operation is still proceed
    if inverse_operation_dialog(model, num) == false then return end
    plane_no = inverse_plane_no
    extra_rot = inverse_extra_rot

  elseif num == 2 or num == 6 then
    plane_no = 1
  elseif num == 3 or num == 7 then
    plane_no = 2
  elseif num == 4 or num == 8 then
    plane_no = 3
  end

  local plane_str = plane_no2str(plane_no)

  if num == 2 or num == 3 or num == 4 then
    extra_rot = false
    if run_settings1_always then
      -- To solve bug: when "cancel" is pressed, operation is still proceed
      if settings1(model) == false then return end
    end
  elseif num == 6 or num == 7 or num == 8 then
    extra_rot = true
    if run_settings2_always then
      -- To solve bug: when "cancel" is pressed, operation is still proceed
      if settings2_lite(model, plane_str) == false then return end
    end
  end

  -- GET THE IPE MATRIX
  matrix = get_ipe_matrix(plane_no, extra_rot)
  --

  if num == 9 then
    matrix = matrix:inverse()
  end

  -- Transformation operation
  local origin
  if model.snap.with_axes then
    origin = model.snap.origin
  else
    local box = bounding_box(p)
    origin = 0.5 * (box:bottomLeft() + box:topRight())
  end

  matrix = ipe.Translation(origin) * matrix * ipe.Translation(-origin)

  local t = { label = label,
        pno = model.pno,
        vno = model.vno,
        selection = model:selection(),
        original = model:page():clone(),
        matrix = matrix,
        undo = revertOriginal,
      }
  t.redo = function (t, doc)
       local p = doc[t.pno]
       for _,i in ipairs(t.selection) do p:transform(i, t.matrix) end
     end
  model:register(t)
end


methods = {
  { label = "Settings", run=settings1 },
  { label = "xy plane", run=preciseTransform },
  { label = "xz plane", run=preciseTransform },
  { label = "yz plane", run=preciseTransform },
  { label = "Settings for additional rotation", run=settings2 },
  { label = "xy plane + rotation", run=preciseTransform },
  { label = "xz plane + rotation", run=preciseTransform },
  { label = "yz plane + rotation", run=preciseTransform },
  { label = "Inverse operation", run=preciseTransform }
}

shortcuts.ipelet_2_axonometric_projections_v2 = "Ctrl+Shift+1"
shortcuts.ipelet_3_axonometric_projections_v2 = "Ctrl+Shift+2"
shortcuts.ipelet_4_axonometric_projections_v2 = "Ctrl+Shift+3"
shortcuts.ipelet_6_axonometric_projections_v2 = "Ctrl+Shift+4"
shortcuts.ipelet_7_axonometric_projections_v2 = "Ctrl+Shift+5"
shortcuts.ipelet_8_axonometric_projections_v2 = "Ctrl+Shift+6"
shortcuts.ipelet_9_axonometric_projections_v2 = "Ctrl+Shift+Z"

----------------------------------------------------------------------
