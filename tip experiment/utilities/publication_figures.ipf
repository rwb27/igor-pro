#pragma rtGlobals=3		// Use modern global access method and strict wave access.

function publication_figure(wx, wy, fig_width, aspect_ratio, span_columns)
	wave wx, wy
	variable fig_width, aspect_ratio, span_columns
	display wy vs wx
	modifygraph minor=1, fSize=10, btLen=5, stLen=2, font="SansSerif", mirror=1
	setaxis/a=2 left
	if (span_columns)
		fig_width *= 2
	endif
	modifygraph width=fig_width, height = {aspect, aspect_ratio}
	modifygraph axoffset(left)=0.1, lblposmode(left)=3, lblpos(left)=40
	textbox/c/n=lbl/f=0/m/a=LT/X=-20.50/Y=-11.50 "\\Z10\\F'SansSerif'(b)"
end

function update_figure(fig_width, aspect_ratio, span_columns)
	variable fig_width, aspect_ratio, span_columns
	modifygraph minor=1, fSize=10, btLen=5, stLen=2, font="SansSerif", mirror=1
	setaxis/a=2 left
	if (span_columns)
		fig_width *= 2
	endif
	modifygraph width=fig_width, height = {aspect, aspect_ratio}
	modifygraph axoffset(left)=1.5, lblposmode(left)=3, lblpos(left)=40
	textbox/c/n=lbl/f=0/m/a=LT/X=-20.50/Y=-11.50 "\\Z10\\F'SansSerif'(b)"
end