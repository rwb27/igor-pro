#pragma rtGlobals=3		// Use modern global access method and strict wave access.

#include "Infinity v3.0"

// take an image every 2 minutes and monitor the tip positions //
function drift_monitor()
	dfref data_folder
	variable t, dt
	do
		infinity_image()
		duplicate/o root:InfImg, data_folder:image_t
		t += dt
	while (1)
end