# A benchmark of different C++ array iteration techniques based on the
# gravity code.
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
from datetime import datetime
from cyantities import Quantity, Unit
from gravity import gravitational_force

rng = np.random.default_rng(989182)
benchmark_m_np = rng.uniform(0.0, 100, 500000000)
benchmark_m = Quantity(benchmark_m_np, 'kg')
g = Quantity(9.81, 'm s^-2')


t0 = datetime.now()
gravitational_force(benchmark_m, g, method='rac')
t1 = datetime.now()
gravitational_force(benchmark_m, g, method='iter')
t2 = datetime.now()
gravitational_force(benchmark_m, g, method='index')
t3 = datetime.now()
benchmark_m_np * 9.81
t4 = datetime.now()
benchmark_m * g
t5 = datetime.now()

print('Pure numpy:     ',t4-t3)
print('Quantities:     ',t5-t4)
print('C++ RAC (pipes):',t1-t0)
print('C++ iterators:  ',t2-t1)
print('C++ indexing:   ',t3-t2)