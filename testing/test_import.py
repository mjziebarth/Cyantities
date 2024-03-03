# Test imports.
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

def test_SI_units():
    """
    Test whether we can generate the SI units.
    """
    metre = Unit("m")
    kilogram = Unit("kg")
    second = Unit("s")
    ampere = Unit("A")
    kelvin = Unit("K")
    mole = Unit("mol")
    candela = Unit("cd")
    radians = Unit("rad")
