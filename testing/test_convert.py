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
import pytest

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
    steradian = Unit("sr")

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

    # SI composed units:
    assert float(Unit('Hz') * second) == 1.0
    newton = Unit('N')
    assert float(newton / (kilogram * meter) * second * second) == 1.0
    pascals = Unit('Pa')
    assert float(pascals / newton * meter * meter) == 1.0
    joule = Unit('J')
    assert float(joule / (kilogram * meter * meter)
                 * second * second) == 1.0
    assert float(Unit('W') / joule * second) == 1.0
    coulomb = Unit('C')
    assert float(coulomb / (ampere * second)) == 1.0
    volt = Unit('V')
    assert float(volt / joule * coulomb) == 1.0
    assert float(Unit('F') * volt / coulomb) == 1.0
    assert float(Unit('Ω') * ampere / volt) == 1.0
    assert float(Unit('S') * volt / ampere) == 1.0
    weber = Unit('Wb')
    assert float(weber * ampere / joule) == 1.0
    assert float(Unit('T') * ampere * meter / newton) == 1.0
    assert float(Unit('H') * ampere / weber) == 1.0
    lumen = Unit('lm')
    assert float(lumen / (candela * steradian)) == 1.0
    assert float(Unit('lx') / lumen * meter * meter) == 1.0
    assert float(Unit('Bq') * second) == 1.0
    assert float(Unit('Gy') * kilogram / joule) == 1.0
    assert float(Unit('Sv') * kilogram / joule) == 1.0
    assert float(Unit('kat') * second / mole) == 1.0


    # Some other conventional units:
    assert float(Unit('g') / kilogram) == 1e-3
    assert float(Unit('h') / second) == 3600.0
    assert float(Unit('h^2') / (second*second)) == 3600.0 ** 2
    assert float(Unit('h^-2') * (second*second)) == 3600.0 ** (-2)
    assert float(Unit('bar') / pascals) == 1e5
    assert float(Unit('l') / (meter * meter * meter)) == 1e-3
    assert float(Unit('t') / kilogram) == 1e3

    # Cyantities does not directly support °C and °F since they
    # are not proportional to Kelvin:
    with pytest.raises(ValueError):
        Unit('°C')
    with pytest.raises(ValueError):
        Unit('°F')