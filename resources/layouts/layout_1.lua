-- This is layout 1
local data = {
	label_info = {
		widget = "label",
		pos = {5, 3},
		dim = {50, 5},
		text = "This is layout 1"
	},
	button_navigate = {
		widget = "button",
		pos = {5, 10},
		dim = {30, 10},
		text = "go to layout 2",
	},
}


-- set up the handlers for this layout
layout_handlers["layout1_"] = layout_handlers["layout1_"] or {
    button_handler = function(event, data) 
        print ("A button was pressed, and its name is: " .. event.widget._name)

        if event.widget._name == "layout1_button_navigate" then
            change_to_layout("layout2_")
        end
    end

}

return data
