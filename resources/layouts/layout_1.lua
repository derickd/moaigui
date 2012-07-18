-- This is layout 1
local data = {
	label_info = {
		widget = "label",
		pos = {5, 3},
		dim = {50, 5},
		text = "This is layout 1"
	},
 	button_disable= {
		widget = "button",
		pos = {15, 20},
		dim = {80, 10},
		text = "disable button 1",
	},
    button_navigate = {
		widget = "button",
		pos = {5, 10},
		dim = {30, 10},
		text = "go to layout 2",
	},
    button_navigate = {
		widget = "button",
		pos = {5, 10},
		dim = {30, 10},
		text = "go to layout 2",
		images = {
			normal = {
				{
					fileName = "cathead.png",
					color = {1, 1, 1, 1},
				},
			},
			hover = {
				{
					fileName = "cathead.png",
					color = {1, 0, 0, 1},
				},
			},
			pushed = {
				{
					fileName = "cathead.png",
					color = {0, 1, 0, 1},
				},
			},
			disabled = {
				{
					fileName = "button_hidden.png",
					color = {0, 0, 1, 1},
				},
			},
		},
	},
 



}


-- set up the handlers for this layout
layout_handlers["layout1_"] = layout_handlers["layout1_"] or {
    button_disable_handler = function(event, data)
        print("Button disabled.")
    end,

    button_handler = function(event, data) 
        print ("A button was pressed, and its name is: " .. event.widget._name)

        if event.widget._name == "layout1_button_navigate" then
            change_to_layout("layout2_")
        end

        if event.widget._name == "layout1_button_disable" then
            if widgets.layout1_button_navigate.window:getEnabled() then
                widgets.layout1_button_navigate.window:setEnabled(false)
            else
                widgets.layout1_button_navigate.window:setEnabled(true)
            end
        end

 
    end

}

return data
