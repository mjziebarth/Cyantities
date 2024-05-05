# Run the gravity code.
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

# The compiled model code:
from gravity import gravitational_force

# Quantities to work with:
from cyantities import Quantity, Unit

#
# Model definition
# ================
#
g = Quantity(9.81, 'm s^-2')
rng = np.random.default_rng(989182)
m_np = rng.uniform(0.0, 100, 20)
m = Quantity(m_np, 'kg')
m2 = Quantity(m_np, 'g')

#
# Model run
# =========
#
F  = gravitational_force(m, g)
F2 = gravitational_force(m2, g)
F3 = gravitational_force(m, g, method='iter')
F4 = gravitational_force(m, g, method='index')


#
# Print and validate the results:
# ===============================
#
print(F / Unit('kg m s^-2'))
print(m_np * 9.81)
assert np.all(m_np * 9.81 == F / Unit('kg m s^-2'))
assert np.allclose(np.array(F / F2), np.full_like(m_np, 1e3))
assert np.all(F == F3)
assert np.all(F == F4)