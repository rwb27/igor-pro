Igor Pro Procedures
===================

Hardware
--------

### VISA Communications
>#### Current Information
>**Status**: working
>
- [x] tested
- [ ] upgraded to data folder referencing

#### Notes
- Required to use certain VISA based equipment.
- Must install either NIVISA or TekVISA including loading the VISA.xop into Igor Pro.

#### Functions list
- [x] **open_comms(hardware_id)**: opens communications to instrument

----------

### Agilent 33220a signal generator
>#### Current Information
>**Status**: working

#### Notes
- Requires VISA

#### Functions list
- [ ]

----------

### Agilent DSOX2000 Series DSO
>#### Current Information
>**Status**: working
>
>**Changes**: fix set channel label, add set_acquire to panel

#### Notes
- Requires VISA

#### Functions list
- [ ]

----------

### Coherent CUBE laser
>#### Current Information
>

#### Notes
- Requires VDT2

#### Functions list
- [ ]

----------

### Horiba Yvon Jobin Triax 320
>#### Current Information
>

#### Notes
- Requires VISA

#### Functions list
- [ ]

----------

### HP HP33120a signal generator
>#### Current Information
>**Status**: working

#### Notes
- Requires VISA

#### Functions list
- [ ]

----------

### Keithley 2635A SMU
>#### Current Information
>**Status**: working

#### Notes
- Requires VISA
- Connect using GPIB

#### Features list
- [ ] Includes panel

#### Functions list
- [x] **initialise()**: creates required global variables, resets the hardware to default settings and sets the current range to 10 nA
- [x] **empty_buffer()**
- [x] **output(o)**: turn SMU output on (1) or off (2)
- [ ] **get_error()**: returns a string containing the error message
- [x] **set_current_range(i_range)**: sets the current range
- [x] **get_current_range()**: returns the current range
- [x] **set_voltage(v)**
- [x] **measure_voltage()**
- [x] **measure_current()**
- [x] **measure_iv()**: returns a complex number containing the voltage (real) and the current (imaginary)
- [x] **measure_resistance()**
- [ ] **check_current_range()**

----------

### Newport LTA-HA and NanoPZ actuators ###
>#### Current Information ####
>**Status**: working with some bugs. Left/right motion keeps crashing. Needs a fix. Manual control working until then. Problem is with GetPos.

#### Notes ####
- Requires VISA

#### Functions list ####
- [ ]

----------

### PI PI733.3CD nanopositioner
>#### Current Information
>**Status**: working

#### Notes
- Requires VISA

#### Functions list
- [ ]

----------

### SRS SR830 lock-in amplifier
>#### Current Information
>**Status**: working

#### Notes
- Requires VISA

#### Functions list
- [ ]

----------

### Tektronix TDS1001B DSO ###
>#### Current Information ####
>**Status**: working - problems with VISAreadbinarywave resolved
>
>Issue seemed to be with the number of points in the binary storage wave. 4 extra points required.
>
>- [ ] tested
#### Notes
- Requires VISA
#### Functions list

----------

Custom Hardware
------------------

### HD Shutter
- Requires Arduino

### Relay Controller
- Requires Arduino

----------

Experiment
----------
