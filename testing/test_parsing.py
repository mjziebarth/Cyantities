# Test unit parsing.
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


import pytest
from cyantities import Unit, Quantity


def test_composed_unit_parsing():
    """
    Test whether we can parse the string syntax.
    """
    # First check of parsing capabilities:
    accel = Unit('m/(s^2)')
    accel2 = Unit('m/(ms^2)')
    
    # The second acceleration unit divides by milliseconds squared.
    # By convention of this library, a quantity of the first unit should be a
    # factor of 1e-6 smaller than a quantity of same 'value' in the second unit.
    assert float(accel / accel2) == 1e-6

    # Two different ways to specify SI unit for energy:
    # - Joules
    # - in base units
    # They must be equal:
    energy0 = Unit('J')
    energy1 = Unit('kg*m^2/(s^2)')
    assert energy0 == energy1

    # Invalid pattern: missing parantheses!
    with pytest.raises(RuntimeError):
        Unit('kg*m^2/s^2')

    # Invalid pattern: currently disallow negative and zero exponents:
    with pytest.raises(RuntimeError):
        Unit('kg*m^-2/(s^2)')
    with pytest.raises(RuntimeError):
        Unit('kg*m^-2/(s^0)')