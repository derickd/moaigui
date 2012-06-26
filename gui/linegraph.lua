----------------------------------------------------------------
-- Copyright (c) 2012, aaa - all about apps
-- All Rights Reserved. 
-- Line graph element for Derick Dong's GUI Framework for MOAI
----------------------------------------------------------------
--[[
The beginnings of a 'statgraph' gui control.  Given an array of values
and two labels (one for x axes and one for y axes), draw a line-graph 
that shows the values plotted over the x axes for y, in line-graph
form.
]]

local _M = {}

require "gui/support/class"

local awindow = require "gui/awindow"
local text = require "gui/text"

_M.LineGraph = class(awindow.AWindow)

--Useful functions
function findMax(a)
  if a ~= nil then
    -- local max_index = 1                        --index of max value
    -- while a[max_index] == nil and max_index <= table.maxn(a) do
    --   max_index= max_index + 1;
    -- end
    local current = 0                         --max value
    for i, max_val in pairs(a) do             --can use pairs() as well, ipairs() indicates an array-like table
      if max_val > current then
        max_index = i
        current = max_val
      end
    end
    return current, i        --neat feature of lua, can return multiple values
  end
end



--Drawing functions
function _M.LineGraph:_drawBaseLines()
  MOAIGfxDevice.setPenWidth(pendwidth_baseline)
  MOAIGfxDevice.setPenColor(baselinecolor[1], baselinecolor[2], baselinecolor[3], baselinecolor[4])

  MOAIDraw.drawLine(self._zeropos_x - 5 / 2, self._zeropos_y, self._maxpos_x, self._zeropos_y)
  MOAIDraw.drawLine(self._zeropos_x, self._zeropos_y - 5 / 2, self._zeropos_x, self._maxpos_y)
end

function _M.LineGraph:_drawBasePoints(table_graphdata)

  MOAIGfxDevice.setPenWidth(penwidth_basepoint)
  MOAIGfxDevice.setPenColor(basepointcolor[1], basepointcolor[2], basepointcolor[3], basepointcolor[4])
  
  local steps, stepsdummy =  self._gui:_calcAbsValue(0.6, 0)

  local fortarget = self._px_distance_x * round(table.maxn(table_graphdata) / axispointcount)

  if fortarget == 0 then
    fortarget = self._px_distance_x
  end

  for x = self._zeropos_x + self._px_distance_x, self._maxpos_x, fortarget do

    --print("in for x")
    MOAIDraw.fillCircle(x, self._zeropos_y, steps)

    --local l = self._gui:createLabel()
    --l:setText("abc")

    --textbox = MOAITextBox.new ()
    --textbox:setString (tostring((x + self._maxpos_x)/self._px_distance_x))
    --textbox:setFont(font)
    --textbox:setYFlip(true)
    --textbox:setRect(x - 10, -120, x + 10, -103)
    --textbox:setAlignment(MOAITextBox.CENTER_JUSTIFY)
    --textbox:setTextSize(11)

    --self._parent._gui:partition():insertProp(textbox)
    --main_layer:insertProp(textbox)
    --self:_addGraphText(x, self._zeropos_y - 5, tostring((x + self._maxpos_x)/self._px_distance_x))
  end

  fortarget = self._px_distance_y * round(self._maxvalue / axispointcount)

  if fortarget == 0 then
    fortarget = self._px_distance_y
  end

  for y = self._zeropos_y + self._px_distance_y, self._maxpos_y, fortarget  do
    MOAIDraw.fillCircle(self._zeropos_x, y, steps) 
  end

end

function _M.LineGraph:_drawValueCircles(table_graphdata)
  MOAIGfxDevice.setPenWidth(penwidth_circle)
  MOAIGfxDevice.setPenColor(linecolor[1], linecolor[2], linecolor[3], linecolor[4])
  for x, y in pairs(table_graphdata) do
    MOAIDraw.drawCircle(self._zeropos_x + x * self._px_distance_x, self._zeropos_y + y * self._px_distance_y, 4)
  end
end

function _M.LineGraph:_drawValuePoints(table_graphdata)
  MOAIGfxDevice.setPenWidth(penwidth_point)
  MOAIGfxDevice.setPenColor(pointcolor[1], pointcolor[2], pointcolor[3], pointcolor[4])
  for x, y in pairs(table_graphdata) do
    MOAIDraw.fillCircle(self._zeropos_x + x * self._px_distance_x, self._zeropos_y + y * self._px_distance_y, 3)
  end
end

function _M.LineGraph:_drawValueLines(table_graphdata)
  last_x = nil
  last_y = nil

--  for cheap_aliasing=3, 9, 3 do
    cheap_aliasing = 3
    MOAIGfxDevice.setPenWidth(penwidth_line * cheap_aliasing)
    MOAIGfxDevice.setPenColor(linecolor[1], linecolor[2], linecolor[3], linecolor[4])
    --We can't use pairs here, because it would skip the nil values
    for x = 1, table.maxn(table_graphdata)  do
      y = table_graphdata[x]
      if y ~= nil and last_y ~= nil then
        MOAIDraw.drawLine(self._zeropos_x + last_x * self._px_distance_x, 
                          self._zeropos_y + last_y * self._px_distance_y, 
                          self._zeropos_x + x * self._px_distance_x, 
                          self._zeropos_y + y * self._px_distance_y)
      end
      last_x = x
      last_y = y
    end
-- end

end

--Label function
function _M.LineGraph:_addGraphText(x, y, text)
    stext = self:_addText()
    stext:setRect(40)
    stext:setPos(50, 50)
    --stext:setString(text)
    stext:setString("ASDFFFFFFF")
    return stext
  end

function _M.LineGraph:draw(table_graphdata)

  -- copied from lua-users.org
  function round(val, decimal)
    if (decimal) then
      return math.floor( (val * 10^decimal) + 0.5) / (10^decimal)
    else
      return math.floor(val+0.5)
    end
  end

	--table_graphdata = table_graphdata
	local function drawGraph()
	  --Drawing baselines
	  self:_drawBaseLines()

	  --Getting biggest value of array. If it is null, the table doesn't contain valid values
	  self._maxvalue = findMax(self._table_graphdata)

	  if self._maxvalue ~= nil then

	    --Calculating data needed for the data to pixel conversion
      local amount_x_values = table.maxn(self._table_graphdata)
      local amount_y_values = self._maxvalue

      if (amount_x_values < 5) then
        amount_x_values = 5
      end

     if (amount_y_values < 5) then
        amount_y_values = 5
      end

	    self._px_distance_x = round(self._graph_width / amount_x_values )
	    self._px_distance_y = round(self._graph_height / amount_y_values)

	    --Drawing points on X and Y lines
	    self:_drawBasePoints(self._table_graphdata)

      --self:_drawValueCircles(self._table_graphdata)
      self:_drawValueLines(self._table_graphdata)
      self:_drawValuePoints(self._table_graphdata)

      self._rootProp:setPriority(999999)
    end
  end

	scriptDeck = MOAIScriptDeck.new()
	scriptDeck:setRect(-64, -64, 64, 64)
	scriptDeck:setDrawCallback(drawGraph)

	self._rootProp:setDeck(scriptDeck)

end

function _M.LineGraph:setData(table_graphdata)
  self._table_graphdata = table_graphdata
end

function _M.LineGraph:setAxisLength(xlength, ylength)
  
  self._maxpos_x = xlength/2
  self._maxpos_y = ylength/2
  self._zeropos_x = self._maxpos_x * -1
  self._zeropos_y = self._maxpos_y * -1

  self._graph_width = self._maxpos_x - self._zeropos_x
  self._graph_height = self._maxpos_y - self._zeropos_y
end

function _M.LineGraph:init(gui)
	awindow.AWindow.init(self, gui)

	self._type = "LineGraph"


	--Default Variables
	self._zeropos_x = -100
	self._zeropos_y = -100
	self._maxpos_x = 100
	self._maxpos_y = 100

  --self._zeropos_x, self._zeropos_y = self._gui:_calcAbsValue(self._zeropos_x, self._zeropos_y)
  --self._maxpos_x, self._maxpos_y = self._gui:_calcAbsValue(self._maxpos_x, self._maxpos_y)

	self._graph_width = self._maxpos_x - self._zeropos_x
	self._graph_height = self._maxpos_y - self._zeropos_y

  --print("Before: " .. self._zeropos_x .. " " .. self._zeropos_y)
  --local a, b = self._gui:_testCalc(self._zeropos_x, self._zeropos_y)
  local a, b = self._gui:_calcRelValue(self._zeropos_x, self._zeropos_y)
  --print("After: " .. a .. " " .. b)

	last_x = nil
	last_y = nil
	label_size = 12
	circle_size = 4
	max_range = 30
	--penwidth = 5

	--Graph colors
	baselinecolor = {0, 0, 0, 0}  
	basepointcolor = {0, 0, 0, 1}
	linecolor = {1, 0, 0, 0.5}
	pointcolor = {1, 0, 0, 0.9}

  --Pen widths
  pendwidth_baseline = 5.5
  
  penwidth_basepoint = 0.1
  penwidth_line = 1.5
  penwidth_circle = 2
  penwidth_point = 1

	--How many points should be displayed on the axis
	axispointcount = 4

  self:draw()
end

return _M





