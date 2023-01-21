----------------------------------------------------------------------
-- axonometric ipelet
----------------------------------------------------------------------
--[[

    This ipelet is based on the included "Goodies" ipelet.

    Axonometric projection is defined by two angles, which define the 
    normal vector of the plane in which is the 3D space projected.

    2023 Tomáš Drobil

    Version 1

--]]

label = "Axonometric projection"

revertOriginal = _G.revertOriginal

about = [[
Axonometric projection defined by two angles.
]]

V = ipe.Vector

local function bounding_box(p)
  local box = ipe.Rect()
  for i,obj,sel,layer in p:objects() do
    if sel then box:add(p:bbox(i)) end
  end
  return box
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
  local str = model:getString("Enter two angles in degrees")
  if not str or str:match("^%s*$") then return end
  local ssx, ssy = str:match("^([%+%-%d%.]+)%s+([%+%-%d%.]+)$")
  if not ssx then
    model:warning("Please enter selfwidth and height in deg",
      "Separate the two numbers by a space.")
    return
  end
  local sx, sy = tonumber(ssx) * math.pi / 180.0, tonumber(ssy) * math.pi / 180.0
  local ix = -math.sin(sx)
  local iy = -math.cos(sx) * math.sin(sy)
  local jx = math.cos(sx)
  local jy = -math.sin(sx) * math.sin(sy)
  local kx = 0.0
  local ky = math.cos(sy)
  if num == 1 then  -- xy plane
    matrix = ipe.Matrix(ix, iy, jx, jy, 0, 0)
    label = "Axonometric projection using angles: " .. sx .. ", " .. sy .. " degrees to xy plane"
  elseif num == 2 then  -- xz plane
    matrix = ipe.Matrix(ix, iy, kx, ky, 0, 0)
    label = "Axonometric projection using angles: " .. sx .. ", " .. sy .. " degrees to xz plane"
  elseif num == 3 then  -- yz plane
    matrix = ipe.Matrix(jx, jy, kx, ky, 0, 0)
    label = "Axonometric projection using angles: " .. sx .. ", " .. sy .. " degrees to yz plane"
  elseif num == 4 then  -- xy plane inversion
    matrix = ipe.Matrix(ix, iy, jx, jy, 0, 0)
    matrix = matrix:inverse()
    label = "Axonometric projection using angles: " .. sx .. ", " .. sy .. " degrees to xy plane"
  elseif num == 5 then  -- xz plane inversion
    matrix = ipe.Matrix(ix, iy, kx, ky, 0, 0)
    matrix = matrix:inverse()
    label = "Axonometric projection using angles: " .. sx .. ", " .. sy .. " degrees to xz plane"
  elseif num == 6 then  -- yz plane inversion
    matrix = ipe.Matrix(jx, jy, kx, ky, 0, 0)
    matrix = matrix:inverse()
    label = "Axonometric projection using angles: " .. sx .. ", " .. sy .. " degrees to yz plane"
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
  { label = "revert from xy plane", run=preciseTransform },
  { label = "revert from xz plane", run=preciseTransform },
  { label = "revert from yz plane", run=preciseTransform },
}

----------------------------------------------------------------------
