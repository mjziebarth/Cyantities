# SI Units in Python, accelerated by Cython.
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

from libcpp.vector cimport vector
from libcpp.pair cimport pair
from libc.stdint cimport uint8_t, int8_t, int16_t
from libcpp cimport bool


#######################################################################
#
#                         C++ Unit backend.
#
#######################################################################

cdef extern from "cyantities/unit.hpp" namespace "cyantities":

    ctypedef uint8_t base_unit_index_t

    enum base_unit_t:
        SI_METER
        SI_KILOGRAM
        SI_SECOND
        SI_AMPERE
        SI_KELVIN
        SI_MOLE
        SI_CANDELA
        OTHER_RADIANS
        OTHER_STERADIAN

    const uint8_t BASE_UNIT_COUNT

    cdef cppclass base_unit_array_t:
        int8_t operator[](int) nogil

    struct UnitBuilder:
        int add_base_unit_occurrence(base_unit_t unit, int8_t exponent) nogil
        void add_decadal_exponent(int16_t exp) nogil
        void multiply_conversion_factor(double f) nogil


    cppclass CppUnit "cyantities::Unit":
        CppUnit() nogil
        CppUnit(int16_t dec_exp) nogil
        CppUnit(int16_t dec_exp, double conversion_factor) nogil
        CppUnit(const UnitBuilder&) nogil

        bool operator==(const CppUnit& other) nogil

        bool same_dimension(const CppUnit& other) nogil

        bool dimensionless() nogil

        CppUnit  operator*(CppUnit other) nogil

        CppUnit  operator/(CppUnit other) nogil

        CppUnit invert() nogil

        int16_t decadal_exponent() nogil
        double conversion_factor() nogil
        double total_scale() nogil
        const base_unit_array_t& base_units() nogil



#######################################################################
#
#                              Cython.
#
#######################################################################

cdef CppUnit parse_unit(str unit)

cdef str format_unit(const CppUnit& unit, str rule)

cdef class Unit:
    cdef CppUnit _unit

cdef Unit generate_from_cpp(const CppUnit& unit)