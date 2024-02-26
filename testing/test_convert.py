# Test unit conversions.
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

from cyantities import Unit, Quantity

def test_unit_prefixes():
    """
    Test whether we can generate the SI units.
    """
    meter = Unit("m")
    second = Unit("s")
    kilogram = Unit("kg")
    kelvin = Unit("K")
    ampere = Unit("A")
    candela = Unit("cd")
    mole = Unit("mol")
    radians = Unit("rad")

    # Once explicitly inspect all steps of the unit division
    # procedure:
    km = Unit("km")
    tmp = km / meter
    assert isinstance(tmp, Unit)
    assert tmp.dimensionless()
    assert float(tmp) == 1e3

    # Now check all prefixes:
    assert float(Unit('dm')/meter) == 1e-1
    assert float(Unit('cm')/meter) == 1e-2
    assert float(Unit('mA')/ampere) == 1e-3
    assert float(Unit('µcd')/candela) == 1e-6
    assert float(Unit('ns')/second) == 1e-9
    assert float(Unit('pmol')/mole) == 1e-12
    assert float(Unit('MK')/kelvin) == 1e6
    assert float(Unit('Gs')/second) == 1e9
    assert float(Unit('Trad')/radians) == 1e12