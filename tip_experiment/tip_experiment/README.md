# Tip Experiment #
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