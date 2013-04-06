# Tip Experiment #

>#### Current Information ####
>**Status**: tested - some unknown VISA errors periodically appear in setup.

#### Controls ####
Controls which can be activated during tip scans are listed below:

- **ESC** - aborts the current experimental run.
- **CTRL** - enables set_point_reached, halting the scan and holding the separation fixed.
- **SHIFT** - disables set_point_reached, allowing the scan to progress.
- **ALT** - engages a previously defined measurement function to be used when the separation is fixed.

#### Information ####
The spectral images are stored with fixed row numbers for wavelength and variable column numbers for steps. When displaying the images the wavelength axis becomes the row-axis and the step becomes the column-axis. In Igor images this corresponds to the row being the x-axis and the column being the y-axis i.e. the spectral progression is viewed vertically.

## Tip Experiment Modules ##

### Tip Experiment Init ###
Module required by the main tip experiment code to initialise each scan and initialise the tip experiment folder structure the first time it is run.
The module should have three separate features:

- Initialise the experiment structure the first time it is used.
- Initialise the tip experiment scan each time the ***tip_scan*** function is called.
- Restore the equipment settings to default values when called.
>#### Current Information ###
>**Status**: untested
#### Functions ####

- **init_experiment()**: initialises the experiment then calls ***restore_default_values()***.

	#####Dependencies:#####
	- **init_equipment**: initialises the required equipment to defaults.

- **init_scan()**: initialises the scan.

	#####Dependencies:#####
	- **check_prereqs()**
	- **init_scan_folder()**
	- **init_waves()**
- **restore_default_values()**: Note that this can not be called until after the experiment has been initialised.

----------

### Tip Experiment Setup ###
Module required to set each of the pieces of equipment into its experimental configuration.
>#### Current Information ###
>**Status**: untested
#### Functions ####

- **setup(rst)**: sets the equipment to experiment configurations. Pass ***rst = 1*** to restore default values to parameters or ***rst = 0*** to use the previously set parameters.

----------

### Tip Experiment Logging ###

----------

### Tip Experiment Display ###
Standalone module required by the main tip experiment code to display the data in Igor during and after data acquisition.
>#### Current Information ###
>**Status**: working
#### Functions ####

- **make_axis_wave(w, wname)**: creates axis waves given an initial axis data wave for use with Igor Pro images.
- **display_scan(scan_folder)**: displays the contents of the current scan folder in the required format.

#### Information ####
Part of the code

    appendimage spec2d vs {wavelength, *}
assumes that the image has spectra as rows with each column being a new step. This would display the spectra transposed with respect to the other measurements. The other traces are therefore plotted using the /vert command.

----------

### Tip Experiment Time-Resolved Measurements
Module containing the function to measure time-resolved data in the tip experiment.
>#### Current Information ###
>**Status**: untested
#### Functions ####

- **measure_time_resolved(scan_folder, i)**: measures time-resolved data in the tip experiment and stores it in the designated scan folder.

----------

### Tip Experiment Panel ###
Contains the necessary code to produce the tip experiment GUI from which all variables can be set and viewed and relevent functions called.
>#### Current Information ###
>**Status**: not started
