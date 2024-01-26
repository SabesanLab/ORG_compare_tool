# Tool to allow browsing ORG signals. Requires:
1) enface image to be displayed
2) MAT file with ORG traces for each pixel.

# Quickstart:
Modify the variables at the top of "org_compare.m" with the correct directory name and filenames and run org_compare.m.

# When run, 3 windows appear: (*need to move big window to see others*)
1) Main window: Shows the enface, with a square indicating the current ROI. The ROI can be moved by click-dragging the square.
2) Zoomed-in magnifier window: Shows a magnified version of the ROI
3) ORG trace window: Show the average trace for current ROI. Dynamic, as the ROI is moved around.

# ontrol is currently through keyboard commands only:
'm': cycles through the different ROI square sizes (10x10 to 200x200)

# Special ORG-trace phse step-through mode:
Press 'p.' Now the magnifier displays shows the unwrapped phase at each pixel for a given time-point. Press ',' and '.' to move left and right through timepoints.
Current timepoint is indicated by a line on the ORG window.

# TBD:
- Before, could also show cone-based ORGs (restore this ability)
- Save different ROIs for comparison
- Compare two pixel-based ROIs
