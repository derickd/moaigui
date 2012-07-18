----------------------------------------------------------------
--
-- Copyright (c) 2012, aaa - all about apps
--
-- Contributed to the moaigui project.
--
-- TECH DEMO: How to load and use multiple layouts in moaigui
--
-- The purpose of this project is to demonstrate a method of
-- loading and dealing with multiple layouts within an app,
-- including a means by which handlers can be set up and torn
-- down for each layout.

----------------------------------------------------------------
APP_NAME = "Multiple Layout Demo"
DEBUG = false

-- Classes for Lua
require "gui/support/class"

-- The MOAIGUI framework, which addes basic GUI features to MOAI
local gui = require "gui/gui"
local filesystem = require "gui/support/filesystem"
local inputconstants = require "gui/support/inputconstants"

-- These must be global for access from layout files
layer_manager = require "layermgr"
resources = require "gui/support/resources"

-- DEBUG MODE
if(DEBUG) then
  MOAIDebugLines.setStyle ( MOAIDebugLines.PARTITION_CELLS, 2, 0, 0, 1, 1 )
  MOAIDebugLines.setStyle ( MOAIDebugLines.PARTITION_PADDED_CELLS, 1, 0, 1, 0, 1 )
  MOAIDebugLines.setStyle ( MOAIDebugLines.PROP_WORLD_BOUNDS, 2, 1, 0, 0, 1 )
  MOAIDebugLines.setStyle ( MOAIDebugLines.PROP_MODEL_BOUNDS, 2, 1, 1, 0, 1 )
  MOAIDebugLines.setStyle ( MOAIDebugLines.TEXT_BOX, 2, 1, 0, 1, 1 )
  MOAIDebugLines.setStyle ( MOAIDebugLines.TEXT_BOX_BASELINES, 2, 1, 1, 0, 1 )
  MOAIDebugLines.setStyle ( MOAIDebugLines.TEXT_BOX_LAYOUT, 2, 1, 1, 0, 1 )
  MOAIDebugLines.setStyle ( MOAIDebugLines.TOTAL_STYLES, 2, 1, 1, 0, 1 )
end

-- we initialize these tables here, as they are used extensively in the app
roots, widgets, groups = {}
game_over = false

-- use this to go straight to a required screen by screen number
screen_requested = 1
screen_current = screen_requested or 1

last_text_entered = ""
screen_changing = true

screen_height = 480
screen_width = 320

--[[
    layout_handlers is a special table which layouts can use to add 
    handlers as needed.  The handlers available are:

          layout_entry_handler   = called when the layout is first entered
          layout_exit_handler    = called when the layout is exited
          window_handler         = handle window events
          button_handler         = handler for a button widget event
          touch_handler          = handler for any touch events 
          slider_handler         = handler for slider widget events
          radio_button_handler   = handler for radio button widget events
          editbox_handler        = handler for editbox widget events
          editbox_input_handler  = handler for whenever input is recieved in an editbox
          editbox_return_handler = handler for when RETURN is pressed in an editbox
]]

layout_handlers = {}
-- explicitly nil the handlers
layout_entry_handler = nil 
layout_exit_handler = nil 
window_handler = nil 
button_handler = nil 
touch_handler = nil  
slider_handler = nil 
radio_button_handler = nil 
editbox_handler = nil 
editbox_input_handler = nil 
editbox_return_handler = nil

-- start!
MOAISim.openWindow ( APP_NAME, screen_width, screen_height )

world_viewport = MOAIViewport.new ()

world_viewport:setSize ( screen_width, screen_height )
world_viewport:setScale ( screen_width / 10, screen_height / 10)

-- setup world_camera
world_camera = MOAICamera2D.new()
--world_layer:setCamera(world_camera)

world_layer = MOAILayer2D.new ()
world_layer:setViewport ( world_viewport )
world_layer:setCamera (world_camera )

layer_manager.addLayer("world_layer", 1, world_layer)

world_partition = MOAIPartition.new ()
world_layer:setPartition ( world_partition )

-- NOTE! We do not make g local, so that it can be used in any layout that needs it
--local g = gui.GUI(screen_width, screen_height)
g = gui.GUI(screen_width, screen_height)

function gui_setup()
  g:addToResourcePath(filesystem.pathJoin("resources", "fonts"))
  g:addToResourcePath(filesystem.pathJoin("resources", "gui"))
  g:addToResourcePath(filesystem.pathJoin("resources", "media"))
  g:addToResourcePath(filesystem.pathJoin("resources", "themes"))
  g:addToResourcePath(filesystem.pathJoin("resources", "layouts"))
  
  app_theme = "baseTheme.lua"
  g:setTheme(app_theme)
  g:setCurrTextStyle("default")  
end

gui_setup()


--[[
    app_layouts is the list of layouts that the app will use.  The layout
    is evaluated by the Lua VM *now*, and the data returned from the layout
    is stored here for future use.  Note that the layouts can also include
    code in the layout file that will be executed at this point - it could
    be used to initialize user data at this point, or other things needed
    by the app at this point in time.  data contains the raw layout data
    whereas layername sets the name to be used when switching layouts.
]]
app_layouts = {}
app_layouts = { 
  { data = dofile(resources.getPath("layout_1.lua")),    layername="layout1_" },
  { data = dofile(resources.getPath("layout_2.lua")),    layername="layout2_" },
}

-- This function changes to the screen specified.
function change_to_layout(layername)
  local screen_num = 1
  screen_changing = false
  for i,v in ipairs(app_layouts) do
    --print("i: ", i, " = v.layername:", v.layername, " screen number: ", screen_num)
    if v.layername == layername then
      screen_changing = true
      screen_requested= screen_num
    end
    if screen_changing == false then
      screen_num = screen_num + 1
    end
  end
end

-- global key-reading functions for the app
-- the purpose of these handlers are to gain a formatted text
-- string from the host soft keyboard.  the native edittext
-- field is used as appropriate for the platform, to benefit
-- from the platform-specific input mechanics - i.e. we only
-- care about the input as a done, formatted, edited string.
-- the last input string is always available as last_text_entered
-- if a layout requires string input, its edit_input_handler is
-- called after string input by the user, to process the 
-- string event.  in this handler, last_text_entered must be
-- the only means by which a layout gains access to the user
-- input text (i.e. no layouts should do key input directly)
function onSoftKeyInput ( start, length, text )
  print ( 'on softkeyinput start: ', start, 'length:', length, 'text:', text )
  
  if MOAIKeyboardIOS then
    last_text_entered = MOAIKeyboardIOS.getText ()
  end

  if MOAIKeyboardAndroid then
    if string.find(text, "\n") == nil then
      last_text_entered = MOAIKeyboardAndroid.getText ()
    else
      print("got return. Leaving onSoftKeyInput and continue at onSoftKeyReturn")
      onSoftKeyReturn()
      return      
    end 
  end

  print ( "text input from host keyboard callback is : [", last_text_entered, "]")

  -- call the handler as specified by the layout
  if (editbox_input_handler ~= nil) then
    editbox_input_handler(start, length, last_text_entered)
  end

end

-- the user has pressed return in a soft input field
function onSoftKeyReturn ()
  print ( 'on softkeyreturn' )
  if MOAIKeyboardIOS then
    last_text_entered = MOAIKeyboardIOS.getText ()
  elseif MOAIKeyboardAndroid then
    last_text_entered = MOAIKeyboardAndroid.getText ()
    MOAIKeyboardAndroid.setText("")
  end

  -- signal that keyboard has closed
  local ret = true
  if (editbox_return_handler ~= nil) then
    ret = editbox_return_handler()
  end

  last_text_entered = "" -- clear it for future use

  -- handler supports returning a bool value 
  -- which decideds if keyboard gets destroyed
  if ret == false then
    keyboardIsPopped = true
    --print("onSoftKeyRetrun returns false")
  else
    if MOAIKeyboardAndroid then
      MOAIKeyboardAndroid.hideKeyboard()
    end
    keyboardIsPopped = false
    --print("onSoftKeyRetrun returns true")
  end


  return ret
end


-- Local MOAI Event Handlers
function onKeyboardEvent(key, down)
  --print("Key received: ", key, " down: ", down)
  if (down == true) then
    g:injectKeyDown(key)
  else
    g:injectKeyUp(key)
    if (shouldDoKeyHack) then
      screen_requested = screen_requested + 1    
      screen_changing = true
    end
  end
end

function onPointerEvent(x, y)
  g:injectMouseMove(x, y)

end

function onMouseLeftEvent(down)
  if (down) then
    g:injectMouseButtonDown(inputconstants.LEFT_MOUSE_BUTTON)
  else
    g:injectMouseButtonUp(inputconstants.LEFT_MOUSE_BUTTON)
  end
end

function onMouseMiddleEvent(down)
  if (down) then
    g:injectMouseButtonDown(inputconstants.MIDDLE_MOUSE_BUTTON)
  else
    g:injectMouseButtonUp(inputconstants.MIDDLE_MOUSE_BUTTON)
  end
end

function onMouseRightEvent(down)
  if (down) then
    g:injectMouseButtonDown(inputconstants.RIGHT_MOUSE_BUTTON)
  else
    g:injectMouseButtonUp(inputconstants.RIGHT_MOUSE_BUTTON)
  end
end


-- multiple platforms have different mechanics
-- i.e. single-touch keypad, keyboard-only,
-- multi-touch, mouse+keyboard, etc.
-- this function is to adapt each platform mechanic 
-- for the needs of the layouts
function setupUserInputs()
  -- Register the callbacks for input
  --MOAIInputMgr.device.pointer:setCallback(onPointerEvent)
  --MOAIInputMgr.device.mouseLeft:setCallback(onMouseLeftEvent)
  --MOAIInputMgr.device.mouseMiddle:setCallback(onMouseMiddleEvent)
  --MOAIInputMgr.device.mouseRight:setCallback(onMouseRightEvent)

  if MOAIKeyboardIOS then
    MOAIKeyboardIOS.setListener ( MOAIKeyboardIOS.EVENT_INPUT, onSoftKeyInput )
    MOAIKeyboardIOS.setListener ( MOAIKeyboardIOS.EVENT_RETURN, onSoftKeyReturn )
  end
  
  if MOAIKeyboardAndroid then
    --MOAIKeyboardAndroid.setListener ( MOAIKeyboardAndroid.ACTION_DOWN, onSoftKeyInput )
    MOAIKeyboardAndroid.setListener ( MOAIKeyboardAndroid.EVENT_INPUT, onSoftKeyInput )
    MOAIKeyboardAndroid.setListener ( MOAIKeyboardAndroid.EVENT_RETURN, onSoftKeyReturn )
  end

  if MOAIInputMgr.device.keyboard then
    MOAIInputMgr.device.keyboard:setCallback(onKeyboardEvent)
  end

  if MOAIInputMgr.device.pointer then
    -- mouse input
    MOAIInputMgr.device.pointer:setCallback (onPointerEvent)
    MOAIInputMgr.device.mouseLeft:setCallback (onMouseLeftEvent)
  else
    -- touch input
    MOAIInputMgr.device.touch:setCallback ( 

      function ( eventType, idx, x, y, tapCount )

        onPointerEvent( x, y )

        if (touch_handler~=nil) then
          touch_handler(eventType, x, y)
        end

        if eventType == MOAITouchSensor.TOUCH_DOWN then
          onMouseLeftEvent ( true )
        elseif eventType == MOAITouchSensor.TOUCH_UP then
          onMouseLeftEvent ( false )
        end
      end
      )
  end
end

setupUserInputs()


-- Now we register the events that the moaigui Widgets can produce.
-- 
-- Widget Events available to be wired up - you can create the list like this:
--
--          cd moaigui/gui && grep "self.EVENT" * | grep  "= \""  | sort
--
-- awindow.lua:  self.EVENT_DISABLE = "EventDisable"
-- awindow.lua:  self.EVENT_DRAG_END = "EventDragEnd"
-- awindow.lua:  self.EVENT_DRAG_ITEM_DROPPED = "EventDragItemDropped"
-- awindow.lua:  self.EVENT_DRAG_ITEM_ENTERS = "EventDragItemEnters"
-- awindow.lua:  self.EVENT_DRAG_ITEM_LEAVES = "EventDragItemLeaves"
-- awindow.lua:  self.EVENT_DRAG_START = "EventDragStart"
-- awindow.lua:  self.EVENT_ENABLE = "EventEnable"
-- awindow.lua:  self.EVENT_GAIN_FOCUS = "EventGainFocus"
-- awindow.lua:  self.EVENT_HIDE = "EventHide"
-- awindow.lua:  self.EVENT_KEY_DOWN = "EventKeyDown"
-- awindow.lua:  self.EVENT_KEY_UP = "EventKeyUp"
-- awindow.lua:  self.EVENT_LOSE_FOCUS = "EventLoseFocus"
-- awindow.lua:  self.EVENT_MOUSE_CLICK = "EventMouseClick"
-- awindow.lua:  self.EVENT_MOUSE_DOWN = "EventMouseDown"
-- awindow.lua:  self.EVENT_MOUSE_ENTERS = "EventMouseEnters"
-- awindow.lua:  self.EVENT_MOUSE_LEAVES = "EventMouseLeaves"
-- awindow.lua:  self.EVENT_MOUSE_MOVE = "EventMouseMove"
-- awindow.lua:  self.EVENT_MOUSE_MOVES = "EventMouseMoves"
-- awindow.lua:  self.EVENT_MOUSE_UP = "EventMouseUp"
-- awindow.lua:  self.EVENT_MOVE = "EventMove"
-- awindow.lua:  self.EVENT_SHOW = "EventShow"
-- awindow.lua:  self.EVENT_SIZE = "EventSize"
-- awindow.lua:  self.EVENT_TOUCH_DOWN = "EventTouchDown"
-- awindow.lua:  self.EVENT_TOUCH_ENTERS = "EventTouchEnters"
-- awindow.lua:  self.EVENT_TOUCH_LEAVES = "EventTouchLeaves"
-- awindow.lua:  self.EVENT_TOUCH_TAP = "EventTouchTap"
-- awindow.lua:  self.EVENT_TOUCH_UP = "EventTouchUp"
-- button.lua: self.EVENT_BUTTON_CLICK = "EventButtonClick"
-- checkbox.lua: self.EVENT_CHECK_BOX_STATE_CHANGE = "EventCheckBoxStateChange"
-- editbox.lua:  self.EVENT_EDIT_BOX_TEXT_ACCEPTED = "EventEditBoxTextAccepted"
-- progressbar.lua:  self.EVENT_PROGRESS_BAR_CHANGED = "EventProgressBarChanged"
-- progressbar.lua:  self.EVENT_PROGRESS_BAR_DONE = "EventProgressBarDone"
-- radiobutton.lua:  self.EVENT_RADIO_BUTTON_STATE_CHANGE = "EventRadioButtonStateChange"
-- scrollbar.lua:  self.EVENT_SCROLL_BAR_POS_CHANGED = "EventScrollBarPosChanged"
-- slider.lua: self.EVENT_SLIDER_VALUE_CHANGED = "EventSliderValueChanged"
-- textbox.lua:  self.EVENT_TEXT_BOX_ADD_TEXT = "EventTextBoxAddText"
-- textbox.lua:  self.EVENT_TEXT_BOX_CLEAR_TEXT = "EventTextBoxClearText"
-- thumb.lua:  self.EVENT_THUMB_DECREASE = "EventThumbDecrease"
-- thumb.lua:  self.EVENT_THUMB_INCREASE = "EventThumbIncrease"
-- thumb.lua:  self.EVENT_THUMB_MOVE_END = "EventThumbMoveEnd"
-- thumb.lua:  self.EVENT_THUMB_MOVE_START = "EventThumbMoveStart"
-- thumb.lua:  self.EVENT_THUMB_POS_CHANGED = "EventThumbPosChanged"
-- widgetlist.lua: self.EVENT_WIDGET_LIST_ADD_ROW = "EventWidgetListAddRow"
-- widgetlist.lua: self.EVENT_WIDGET_LIST_REMOVE_ROW = "EventWidgetListRemoveRow"
-- widgetlist.lua: self.EVENT_WIDGET_LIST_SELECT = "EventWidgetListSelect"
-- widgetlist.lua: self.EVENT_WIDGET_LIST_UNSELECT = "EventWidgetListUnselect"

function registerScreenWidgets(widgets)
  for i,v in pairs(widgets) do
    ----print("widget : ", i .. " = ", v)
    if string.find(i, "_slider_") then
      ----print("reg slider widget : ", i .. " = ", v)
      local_slider = v.window
      local_slider:registerEventHandler(local_slider.EVENT_SLIDER_VALUE_CHANGED, nil, slider_handler)
    end
    -- progressbar takes button handler
    if string.find(i, "_progressbar_") then
      local_button = v.window
      local_button:registerEventHandler(local_button.EVENT_MOUSE_CLICK, nil, button_handler)
    end
    if string.find(i, "_button_") then
      ----print("reg button widget : ", i .. " = ", v)
      local_button = v.window
      local_button:registerEventHandler(local_button.EVENT_BUTTON_CLICK, nil, button_handler)
      local_button:registerEventHandler(local_button.EVENT_DISABLE, nil, button_disable_handler)
    end
    if string.find(i, "_window") then
      ----print("reg window widget : ", i .. " = ", v)
      local_window = v.window
      local_window:registerEventHandler(local_window.EVENT_SHOW, nil, window_handler)
      local_window:registerEventHandler(local_window.EVENT_HIDE, nil, window_handler)
      local_window:registerEventHandler(local_window.EVENT_MOUSE_CLICK, nil, window_handler)
--[[
      local_window:registerEventHandler(local_window.EVENT_TOUCH_DOWN, nil, touch_handler)
      local_window:registerEventHandler(local_window.EVENT_TOUCH_UP, nil, touch_handler)
      local_window:registerEventHandler(local_window.EVENT_TOUCH_TAP, nil, touch_handler)
      local_window:registerEventHandler(local_window.EVENT_MOUSE_UP, nil, touch_handler)
      local_window:registerEventHandler(local_window.EVENT_MOUSE_DOWN, nil, touch_handler)
      local_window:registerEventHandler(local_window.EVENT_MOUSE_MOVE, nil, touch_handler)
]]
    end

    if string.find(i, "_radiobutton_") then
      ----print("reg _radiobutton_ widget : ", i .. " = ", v)
      local_radiobutton = v.window
      local_radiobutton:registerEventHandler(local_radiobutton.EVENT_RADIO_BUTTON_STATE_CHANGE, nil, radio_button_handler)
    end
    if string.find(i, "_editbox_") then
      ----print("reg _editbox_ widget : ", i .. " = ", v)
      local_editbox = v.window
      if (editbox_handler ~= nil) then
        local_editbox:registerEventHandler(local_editbox.EVENT_GAIN_FOCUS, nil, editbox_handler)
        local_editbox:registerEventHandler(local_editbox.EVENT_EDIT_BOX_TEXT_ACCEPTED, nil, editbox_handler)
        --local_editbox:registerEventHandler(local_editbox.EVENT_LOSE_FOCUS, nil, editbox_handler)
        --local_editbox:registerEventHandler(local_editbox.EVENT_KEY_DOWN, nil, editbox_handler)
        --local_editbox:registerEventHandler(local_editbox.EVENT_KEY_UP, nil, editbox_handler)
      end
    end
  end
end

-- .. and of course, un-register them too when needed
function unregisterScreenWidgets(widgets)
  for i,v in pairs(widgets) do

    if string.find(i, "_slider_") then
      ----print("unreg widget : ", i .. " = ", v)
      local_slider = v.window
      local_slider:unregisterEventHandler(local_slider.EVENT_SLIDER_VALUE_CHANGED)
    end
    if string.find(i, "_button_") then
      ----print("unreg widget : ", i .. " = ", v)
      local_button = v.window
      local_button:unregisterEventHandler(local_button.EVENT_BUTTON_CLICK)
      local_button:unregisterEventHandler(local_button.EVENT_DISABLE)
    end
    if string.find(i, "_window") then
      ----print("unreg widget : ", i .. " = ", v)
      local_window = v.window
      local_window:unregisterEventHandler(local_window.EVENT_SHOW)
      local_window:unregisterEventHandler(local_window.EVENT_HIDE)
      
      local_window:unregisterEventHandler(local_window.EVENT_TOUCH_DOWN)
      local_window:unregisterEventHandler(local_window.EVENT_TOUCH_UP)
      local_window:unregisterEventHandler(local_window.EVENT_TOUCH_TAP)
      local_window:unregisterEventHandler(local_window.EVENT_MOUSE_UP)
      local_window:unregisterEventHandler(local_window.EVENT_MOUSE_DOWN)
      local_window:unregisterEventHandler(local_window.EVENT_MOUSE_MOVE)
    end
    if string.find(i, "_radiobutton_") then
      local_radiobutton = v.window
      local_radiobutton:unregisterEventHandler(local_radiobutton.EVENT_RADIO_BUTTON_STATE_CHANGE)
    end
    if string.find(i, "_editbox_") then
      local_editbox = v.window
      local_editbox:unregisterEventHandler(local_editbox.EVENT_GAIN_FOCUS)
      local_editbox:unregisterEventHandler(local_editbox.EVENT_EDIT_BOX_TEXT_ACCEPTED)
    end
  end
end


-- here is the main thread for the app, which is responsible for switching
-- layouts:

mainThread = MOAIThread.new()

mainThread:run(
  function()

    while not game_over do
      coroutine.yield()

      -- if a layout handler has requested a screen_change
      if (screen_changing == true) then

        -- range-check the requested screen_requested
        if (screen_requested > #app_layouts) then
          screen_requested  = 1
        end

        -- hide/prepare the existing GUI for release
        if (nil ~= g) then

          if layout_exit_handler then
            layout_exit_handler()
          end

          if (nil ~= widgets) then
            unregisterScreenWidgets(widgets)
          end

          layer_manager.hideLayer("gui")
          -- CleanlinessGodliness
          --g:shutdown()
          --g = nil
          --g = gui.GUI(screen_width, screen_height)
          --gui_setup()

          roots = nil
          widgets = nil
          groups = nil

          -- explicitly nil the handlers
          layout_entry_handler = nil 
          layout_exit_handler = nil 
          window_handler = nil 
          button_handler = nil 
          button_disable_handler = nil
          touch_handler = nil  
          slider_handler = nil 
          radio_button_handler = nil 
          editbox_handler = nil 
          editbox_input_handler = nil 
          editbox_return_handler = nil

        end

        -- we do this here to be sure there aren't leaky props, but its not strictly necessary
        --world_layer:clear()
        g:layer():clear()

        roots, widgets, groups = g:loadLayoutfromData(app_layouts[screen_requested].data, app_layouts[screen_requested].layername)
        screen_current = screen_requested

        layer_manager.addLayer("gui", 99999, g:layer())
        layer_manager.showLayer("gui")

        --layer_manager.hideLayer("gui")

        -- get the handlers as declared
        local t = layout_handlers[app_layouts[screen_requested].layername]
        ----print(table.show(t))
        if t then
          layout_entry_handler   = nil or t.layout_entry_handler
          layout_exit_handler    = nil or t.layout_exit_handler
          window_handler         = nil or t.window_handler
          button_handler         = nil or t.button_handler
          button_disable_handler = nil or t.button_disable_handler
          touch_handler          = nil or t.touch_handler
          slider_handler         = nil or t.slider_handler
          radio_button_handler   = nil or t.radio_button_handler
          editbox_handler        = nil or t.editbox_handler
          editbox_input_handler  = nil or t.editbox_input_handler
          editbox_return_handler = nil or t.editbox_return_handler
        end

        registerScreenWidgets(widgets)

        screen_changing = false

        if layout_entry_handler then
          layout_entry_handler()
        end

      end

    end

    os.exit()    
  end 
  )

