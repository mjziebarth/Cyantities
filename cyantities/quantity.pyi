# Type information for Quantity.
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
from .unit import Unit
from typing import Any
from numpy.typing import NDArray


class Quantity:
    """
    A physical quantity: a single or array of real numbers with an associated
    physical unit.
    """

    def __init__(self, value, unit: Unit | str, copy: bool = True):
        pass


    def __float__(self) -> float:
        pass


    def __repr__(self) -> str:
        pass


    def __mul__(
            self,
            other: Quantity | Unit | NDArray[np.double] | float
        ) -> Quantity:
        pass


    def __rmul__(
            self,
            other: Quantity | Unit | NDArray[np.double] | float
        ) -> Quantity:
        pass


    def __truediv__(
            self,
            other: Quantity | Unit | NDArray[np.double] | float | int
        ) -> Quantity:
        pass


    def __rtruediv__(
            self,
            other: Quantity | Unit | NDArray[np.double] | float | int
        ) -> Quantity:
        pass


    def __add__(self, other: Quantity) -> Quantity:
        pass


    def __sub__(self, other: Quantity) -> Quantity:
        pass


    def __pow__(self, exponent: int) -> Quantity:
        pass


    def __neg__(self) -> Quantity:
        pass


    def __abs__(self) -> Quantity:
        pass


    def __eq__(self, other: Any) -> bool:
       pass


    def __getitem__(
            self,
            index: int | list[int]
                       | list[tuple[int | slice, ...]]
                       | tuple[int | slice,...]
                       | NDArray[np.bool] | NDArray[np.int64]
        ) -> Quantity:
        pass


    def shape(self) -> int | tuple[int,...]:
        pass


    def unit(self) -> Unit:
        pass