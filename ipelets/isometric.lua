----------------------------------------------------------------------
-- isometric ipelet
----------------------------------------------------------------------
--[[

    This ipelet is based on the included "Goodies" ipelet.

    2023 Tomáš Drobil
    2024 Alexander Greyling

    Version 2

--]]

label = "Isometric projection"

revertOriginal = _G.revertOriginal

about = [[
Isometric projection.
]]

V = ipe.Vector

local function bounding_box(p)
  local box = ipe.Rect()
  for i,obj,sel,layer in p:objects() do
    if sel then box:add(p:bbox(i)) end
  end
  return box
end

function isometricRotation(tx, ty, tz, plane)
   local sin = math.sin
   local cos = math.cos
   local alpha = math.asin(math.tan(math.pi/6))
   local beta = -math.pi/4
   local result_matrix
   -- proj_matrix format: ix, iy, jx, jy, kx, ky
   local proj_matrix = {(cos(beta)*sin(tz)+sin(beta)*cos(tz))*cos(ty),
      -cos(alpha)*sin(ty)+sin(alpha)*(sin(beta)*sin(tz)-cos(beta)*cos(tz))*cos(ty),
      (cos(beta)*cos(tz)-sin(beta)*sin(tz))*cos(tx)+(cos(beta)*sin(tz)+sin(beta)*cos(tz))*sin(ty)*sin(tx),
      sin(alpha)*(sin(beta)*cos(tz)+cos(beta)*sin(tz))*cos(tx)+(cos(alpha)*cos(ty)+sin(alpha)*(sin(beta)*sin(tz)-cos(beta)*cos(tz))*sin(ty))*sin(tx),
	-(cos(beta)*cos(tz)-sin(beta)*sin(tz))*sin(tx)+(cos(beta)*sin(tz)+sin(beta)*cos(tz))*sin(ty)*cos(tx),
	-sin(alpha)*(sin(beta)*cos(tz)+cos(beta)*sin(tz))*sin(tx)+(cos(alpha)*cos(ty)+sin(alpha)*(sin(beta)*sin(tz)-cos(beta)*cos(tz))*sin(ty))*cos(tx)}

   if plane == 1 then 
      -- xy plane
      result_matrix = {proj_matrix[1], proj_matrix[2],proj_matrix[3],proj_matrix[4], 0, 0}
   elseif plane == 2 then 
      -- xz plane
      result_matrix = {proj_matrix[1], proj_matrix[2],proj_matrix[5],proj_matrix[6], 0, 0}
   elseif plane == 3 then 
      -- yz plane
      result_matrix = {proj_matrix[3], proj_matrix[4],proj_matrix[5],proj_matrix[6], 0, 0}
   end
   return result_matrix
   end

function preciseTransform(model, num)
  local p = model:page()
  if not p:hasSelection() then
    model.ui:explain("no selection")
    return
  end

  -- check pinned
  for i, obj, sel, layer in p:objects() do
    if sel and obj:get("pinned") ~= "none" then
      model:warning("Cannot transform objects",
        "At least one of the objects is pinned")
      return
    end
  end

  local matrix
  local label = methods[num].label
  local ix = -math.sqrt(2) / 2
  local iy = -math.sqrt(6) / 6
  local jx = math.sqrt(2) / 2
  local jy = -math.sqrt(6) / 6
  local kx = 0.0
  local ky = math.sqrt(6) / 3

  if num == 1 then  -- xy plane
     matrix = ipe.Matrix(isometricRotation(0,0,0,1))
     label = "Isometric projection to xy plane *"

  elseif num == 2 then  -- xz plane
     matrix = ipe.Matrix(isometricRotation(0,0,0,2))
     label = "Isometric projection to xz plane"

  elseif num == 3 then  -- yz plane
     matrix = ipe.Matrix(isometricRotation(0,0,0,3))
    label = "Isometric projection to yz plane"

  elseif num == 4 then  
    local str = model:getString("Enter angle in degrees")
    if not str or str:match("^%s*$") then return end
    local degrees = tonumber(str)
    if not degrees then
      model:warning("Please enter angle in degrees")
      return
    end
    local angle = math.pi * degrees / 180.0
    matrix = ipe.Matrix(isometricRotation(0,0,angle,1))
    label = "Isometric projection to xy plane + z rotation"

  elseif num == 5 then  
    local str = model:getString("Enter angle in degrees")
    if not str or str:match("^%s*$") then return end
    local degrees = tonumber(str)
    if not degrees then
      model:warning("Please enter angle in degrees")
      return
    end
    local angle = math.pi * degrees / 180.0
    matrix = ipe.Matrix(isometricRotation(0,0,angle,2))
    label = "Isometric projection to xz plane + z rotation"

  elseif num == 6 then  
    local str = model:getString("Enter angle in degrees")
    if not str or str:match("^%s*$") then return end
    local degrees = tonumber(str)
    if not degrees then
      model:warning("Please enter angle in degrees")
      return
    end
    local angle = math.pi * degrees / 180.0
    matrix = ipe.Matrix(isometricRotation(0,0,angle,3))
    label = "Isometric projection to yz plane + z rotation"

  elseif num == 7 then  
    local str = model:getString("Enter angle in degrees")
    if not str or str:match("^%s*$") then return end
    local degrees = tonumber(str)
    if not degrees then
      model:warning("Please enter angle in degrees")
      return
    end
    local angle = math.pi * degrees / 180.0
    matrix = ipe.Matrix(isometricRotation(0,angle,0,1))
    label = "Isometric projection to xy plane + y rotation"

  elseif num == 8 then  
    local str = model:getString("Enter angle in degrees")
    if not str or str:match("^%s*$") then return end
    local degrees = tonumber(str)
    if not degrees then
      model:warning("Please enter angle in degrees")
      return
    end
    local angle = math.pi * degrees / 180.0
    matrix = ipe.Matrix(isometricRotation(0,angle,0,2))
    label = "Isometric projection to xz plane + y rotation"

  elseif num == 9 then  
    local str = model:getString("Enter angle in degrees")
    if not str or str:match("^%s*$") then return end
    local degrees = tonumber(str)
    if not degrees then
      model:warning("Please enter angle in degrees")
      return
    end
    local angle = math.pi * degrees / 180.0
    matrix = ipe.Matrix(isometricRotation(0,angle,0,3))
    label = "Isometric projection to yz plane + y rotation"

  elseif num == 10 then  
    local str = model:getString("Enter angle in degrees")
    if not str or str:match("^%s*$") then return end
    local degrees = tonumber(str)
    if not degrees then
      model:warning("Please enter angle in degrees")
      return
    end
    local angle = math.pi * degrees / 180.0
    matrix = ipe.Matrix(isometricRotation(angle,0,0,1))
    label = "Isometric projection to xy plane + x rotation"

  elseif num == 11 then  
    local str = model:getString("Enter angle in degrees")
    if not str or str:match("^%s*$") then return end
    local degrees = tonumber(str)
    if not degrees then
      model:warning("Please enter angle in degrees")
      return
    end
    local angle = math.pi * degrees / 180.0
    matrix = ipe.Matrix(isometricRotation(angle,0,0,2))
    label = "Isometric projection to xz plane + x rotation"

  elseif num == 12 then  
    local str = model:getString("Enter angle in degrees")
    if not str or str:match("^%s*$") then return end
    local degrees = tonumber(str)
    if not degrees then
      model:warning("Please enter angle in degrees")
      return
    end
    local angle = math.pi * degrees / 180.0
    matrix = ipe.Matrix(isometricRotation(angle,0,0,3))
    label = "Isometric projection to yz plane + x rotation"

  elseif num == 13 then  -- xy plane inversion
    matrix = ipe.Matrix(ix, iy, jx, jy, 0, 0)
    matrix = matrix:inverse()
    label = "Isometric projection to xy plane"

  elseif num == 14 then  -- xz plane inversion
    matrix = ipe.Matrix(ix, iy, kx, ky, 0, 0)
    matrix = matrix:inverse()
    label = "Isometric projection to xz plane"

  elseif num == 15 then  -- yz plane inversion
    matrix = ipe.Matrix(jx, jy, kx, ky, 0, 0)
    matrix = matrix:inverse()
    label = "Isometric projection to yz plane"
  end

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
  { label = "xy plane", run=preciseTransform },
  { label = "xz plane", run=preciseTransform },
  { label = "yz plane", run=preciseTransform },
  { label = "xy plane + z rotation", run=preciseTransform },
  { label = "xz plane + z rotation", run=preciseTransform },
  { label = "yz plane + z rotation", run=preciseTransform },
  { label = "xy plane + y rotation", run=preciseTransform },
  { label = "xz plane + y rotation", run=preciseTransform },
  { label = "yz plane + y rotation", run=preciseTransform },
  { label = "xy plane + x rotation", run=preciseTransform },
  { label = "xz plane + x rotation", run=preciseTransform },
  { label = "yz plane + x rotation", run=preciseTransform },
  { label = "revert from xy plane", run=preciseTransform },
  { label = "revert from xz plane", run=preciseTransform },
  { label = "revert from yz plane", run=preciseTransform }
}

----------------------------------------------------------------------
