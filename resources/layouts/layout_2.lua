-- This is layout 1
local data = {
	label_info = {
		widget = "label",
		pos = {5, 3},
		dim = {50, 5},
		text = "This is layout 2"
	},

    linegraph_demo = {
        widget = "line graph",
        pos = {50.5, 33.2},
        --axislength = {200, 400},
    },

	button_navigate = {
		widget = "button",
		pos = {5, 10},
		dim = {30, 10},
		text = "go to layout 1",
	},
}


-- set up the handlers for this layout
layout_handlers["layout2_"] = layout_handlers["layout2_"] or {

    layout_entry_handler = function()
        local linegraph_data = {1,2,4,8,4,2,1}
        --Sending data to the graph
        graph = widgets.layout2_linegraph_demo.window
        local width, height = graph._gui:_calcAbsValue(75, 26.6)
        graph:setAxisLength(width, height)
        graph:setData(linegraph_data)

    end,

    button_handler = function(event, data) 
        print ("A button was pressed, and its name is: " .. event.widget._name)

        if event.widget._name == "layout2_button_navigate" then
            change_to_layout("layout1_")
        end
    end
}

return data
