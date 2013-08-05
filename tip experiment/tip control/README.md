# Tip Control #
## Features ##
The tip control procedures are required for positioning of tips, both coarse and fine alignment using the built-in AFM. The directory also contains the procedure necessary for recreating the tip experiment in a new Igor experiment file.

## Tip Alignment ##

### Alignment Procedure ###
To take out the read functions of the piezo stage and the offset caused by using it a set point is defined at the start of each scan. At the start of a scan the tip goes to the set position. The scan then creates a grid based around the set position and moves to each of the grid coordinates. This can then be used to align to a centroid based only upon set positions.

### Alignment Details ###
- Align with piezo stage DCO on (1) or off (0) to prevent movement? Off means movement is smooth despite the position reporting being inaccurate. On means movement is not smooth but position may be accurate.
- Using an oscilloscope measurement for alignment is no longer needed as the lock-in can be used to better effect. This should speed up the alignment procedure considerably.

#### Old Approaches to Alignment ####
- Using 500 points to measure from oscilloscope is supposedly fastest. 2500 points also proves fast and allows a greater number of periods to be acquired for analysis with greater number of points for accuracy.
- Tried using Tektronix immediate measurement of frequency and pk2pk however the measurement was too slow. Approximately 3 s per point of acquisition.
- Attempting to fit to wave to test alignment not tried since at low voltages it does not appear to be a pure sine wave.
