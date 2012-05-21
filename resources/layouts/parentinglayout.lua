
local data = {
	window = {
		widget = "window",
		pos = {5, 5},
		dim = {90, 90},

		children = {
			label1 = {
				widget = "label",
				pos = {5, 3},
				dim = {50, 5},
				text = "Just some simple text",
			},
			image1 = {
				widget = "image",
				pos = {20, 20},
				dim = {50, 35},
				text = "Image",
				textHorzAlign = "center",
				textVertAlign = "bottom",
				images = {
					{
						fileName = "cathead.png",
					},
				},

				children = {
					button1 = {
						widget = "button",
						pos = {5, 10},
						dim = {40, 10},
						text = "button 1",
					},
				},
			},
		},
	},
}

return data
