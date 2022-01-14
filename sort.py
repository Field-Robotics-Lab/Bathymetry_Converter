#!/usr/bin/env python
import numpy as np
import sys

# https://gdal.org/drivers/raster/xyz.html
# Cells with same Y coordinates must be placed on consecutive lines.
# For a same Y coordinate value, the lines in the dataset must be
# organized by increasing X values. The value of the Y coordinate
# can increase or decrease however.

ASC = np.loadtxt(sys.argv[1])
index = np.lexsort((ASC[:,0],ASC[:,1]))
np.savetxt(sys.argv[2], ASC[index], fmt='%10.5f', delimiter=' ')

