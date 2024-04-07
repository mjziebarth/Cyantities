# Run the parasolve code.
#
# Author: Malte J. Ziebarth (mjz.science@fmvkb.de)
#
# Copyright (C) 2024 Malte J. Ziebarth
#
# Licensed under the EUPL, Version 1.2 or – as soon they will be approved by
# the European Commission - subsequent versions of the EUPL (the "Licence");
# You may not use this work except in compliance with the Licence.
# You may obtain a copy of the Licence at:
#
# https://joinup.ec.europa.eu/collection/eupl/eupl-text-eupl-12
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the Licence is distributed on an "AS IS" basis,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the Licence for the specific language governing permissions and
# limitations under the Licence.

import numpy as np
import matplotlib.pyplot as plt

# The compiled model code:
from parasolve import ball_throw_with_friction

# Quantities to work with:
from cyantities import Quantity, Unit

#
# Model definition
# ================
#

t = Quantity(np.linspace(0.0, 6.0), 's')
x0 = Quantity(0.0, 'm')
y0 = Quantity(2.1, 'm')
v = Quantity(145.0, 'km h^-1')
vx0 = np.sin(np.pi/4) * v
vy0 = np.cos(np.pi/4) * v
r = Quantity(75.0, 'mm') / 2.0
cw = Quantity(0.45, '1')
rho = Quantity(0.875, 'g*cm^-3') # baseball
rho_air = Quantity(1.2, 'kg*m^-3')

#
# Model run
# =========
#
x,y = ball_throw_with_friction(t, x0, y0, vx0, vy0, r, cw, rho, rho_air)


#
# Plot the results
# ================
#
print(x / Unit('m'))
print(y / Unit('m'))
fig = plt.figure()
ax = fig.add_subplot(111)
ax.plot(np.array(x / Unit('m')), np.array(y / Unit('m')), marker='.')
ax.set_ylim(0, ax.get_ylim()[1])
ax.set_aspect('equal')
fig.savefig('result.pdf')