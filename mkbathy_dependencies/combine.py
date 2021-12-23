#!/usr/bin/env python
import numpy as np
import sys
XYZ = np.loadtxt(sys.argv[1])
ASC = np.loadtxt(sys.argv[2])
ASC_F = np.zeros((len(XYZ), 3))
for i in range(len(XYZ)):
    ASC_F[i] = np.array([ASC[i][0], ASC[i][1], XYZ[i][2]])
np.savetxt(sys.argv[3], ASC_F, fmt='%10.5f', delimiter=' ')

