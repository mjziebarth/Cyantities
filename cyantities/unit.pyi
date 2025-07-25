# Type information for Unit.
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


from typing import Literal, Any

class Unit:
    """
    A physical unit.
    """
    def __init__(self, unit: str):
        pass


    def __repr__(self) -> str:
        pass


    def format(self, rule: Literal['coherent','casual'] = 'coherent') -> str:
        pass


    def __str__(self) -> str:
        pass


    def __mul__(self, other: Unit) -> Unit:
        pass


    def __truediv__(self, other: Unit) -> Unit:
        pass


    def __pow__(self, exp: int) -> Unit:
        pass


    def __float__(self) -> float:
        pass


    def __eq__(self, other: Any) -> bool:
        pass


    def same_dimension(self, other: Unit) -> bool:
        pass


    def dimensionless(self) -> bool:
        pass