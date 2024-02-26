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
from libc.stdint cimport uint8_t, int8_t, int16_t
from libcpp cimport bool

from .unit cimport base_unit_t, UnitBuilder, CppUnit, Unit


#######################################################################
#
#                         Cython unit parsing.
#
#######################################################################

cdef void _parse_unit_single(str unit, int prefix, UnitBuilder& builder):
    """
    A single unit's representation to SI basis units.
    """
    #
    # Prefixes:
    #
    cdef bool has_prefix = False
    cdef size_t n = len(unit)
    cdef Py_UCS4 first
    if n == 0:
        raise RuntimeError("Empty unit string.")
    elif n > 1:
        # Parse prefies:
        first = unit[0]
        if first == u'T':
            # Tera.
            builder.add_decadal_exponent(12)
            has_prefix = True
        elif first == u'G':
            # Giga
            builder.add_decadal_exponent(9)
            has_prefix = True
        elif first == u'M':
            # Mega
            builder.add_decadal_exponent(6)
            has_prefix = True
        elif first == u'k':
            # kilo-prefix overlaps with kilogram.
            # Catch that overlap here:
            if n == 2 and unit == "kg":
                builder.add_base_unit_occurrence(SI_KILOGRAM, prefix * 1)
                return
            # kilo
            builder.add_decadal_exponent(3)
            has_prefix = True
        elif first == u'h':
            # hecto
            builder.add_decadal_exponent(2)
            has_prefix = True
        elif first == u'd':
            # dezi
            builder.add_decadal_exponent(-1)
            has_prefix = True
        elif first == u'c':
            # centi-prefix overlaps with Candela.
            # Catch that overlap here:
            if n == 2 and unit == "cd":
                builder.add_base_unit_occurrence(SI_CANDELA, prefix * 1)
                return
            # centi
            builder.add_decadal_exponent(-2)
            has_prefix = True
        elif first == u'm':
            # milli-prefix overlaps with mol.
            # Catch that overlap here:
            if n == 3 and unit == "mol":
                builder.add_base_unit_occurrence(SI_MOLE, prefix * 1)
                return
            # milli
            builder.add_decadal_exponent(-3)
            has_prefix = True
        elif first == u'µ':
            # micro
            builder.add_decadal_exponent(-6)
            has_prefix = True
        elif first == u'n':
            # nano
            builder.add_decadal_exponent(-9)
            has_prefix = True
        elif first == u'p':
            # pico
            builder.add_decadal_exponent(-12)
            has_prefix = True
        
        # Now need to cut the prefix:
        if has_prefix:
            unit = unit[1:]


    #
    # SI base units:
    #
    if unit == "s":
        builder.add_base_unit_occurrence(SI_SECOND, prefix * 1)
        return
    elif unit == "m":
        builder.add_base_unit_occurrence(SI_METER, prefix * 1)
        return
    elif unit == "kg":
        builder.add_base_unit_occurrence(SI_KILOGRAM, prefix * 1)
        return
    elif unit == "A":
        builder.add_base_unit_occurrence(SI_AMPERE, prefix * 1)
        return
    elif unit == "K":
        builder.add_base_unit_occurrence(SI_KELVIN, prefix * 1)
        return
    elif unit == "mol":
        builder.add_base_unit_occurrence(SI_MOLE, prefix * 1)
        return
    elif unit == "cd":
        builder.add_base_unit_occurrence(SI_CANDELA, prefix * 1)
        return
    elif unit == "rad":
        # Follow boost units in defining radians as a base unit.
        builder.add_base_unit_occurrence(OTHER_RADIANS, prefix * 1)
        return

    
    #
    # SI derived units:
    #
    if unit == "Pa":
        builder.add_base_unit_occurrence(SI_KILOGRAM, 1 * prefix)
        builder.add_base_unit_occurrence(SI_METER,   -1 * prefix)
        builder.add_base_unit_occurrence(SI_SECOND,  -2 * prefix)
        return
    elif unit == "J":
        builder.add_base_unit_occurrence(SI_KILOGRAM, 1 * prefix)
        builder.add_base_unit_occurrence(SI_METER,    2 * prefix)
        builder.add_base_unit_occurrence(SI_SECOND,  -2 * prefix)
        return
    elif unit == "W":
        # Watts
        builder.add_base_unit_occurrence(SI_KILOGRAM, 1 * prefix)
        builder.add_base_unit_occurrence(SI_METER,    2 * prefix)
        builder.add_base_unit_occurrence(SI_SECOND,  -3 * prefix)
        return
    elif unit == "erg":
        # 1 erg = 1e-7 J
        builder.add_decadal_exponent(-7)
        builder.add_base_unit_occurrence(SI_KILOGRAM, 1 * prefix)
        builder.add_base_unit_occurrence(SI_METER,    2 * prefix)
        builder.add_base_unit_occurrence(SI_SECOND,  -2 * prefix)
        return

    raise ValueError("Unknown unit '" + unit + "'")


cdef CppUnit parse_unit(str unit):
    """
    The central function that translates 
    """
    # Initialize the collected parsing results:
    cdef UnitBuilder builder

    # We allow the format like "kg*m/(s^2)"
    cdef list[str] nom_denom_split
    cdef str sub_unit
    cdef list nom_split
    cdef list denom_split
    if "/" in unit:
        # Fraction in the unit
        nom_denom_split = unit.split("/")
        if len(nom_denom_split) != 2:
            raise RuntimeError("Invalid format of unit '" + unit + "': "
                "only one division sign '/' allowed."
            )
        if nom_denom_split[1][0] != "(" or nom_denom_split[1][-1] != ")":
            raise RuntimeError("Invalid format of unit '" + unit + "': "
                "denominator needs to be enclosed in parantheses."
            )

        # Seems good to go.
        nom_split = nom_denom_split[0].split('*')
        denom_split = nom_denom_split[1][1:-1].split('*')

    else:
        # No fraction in the unit.
        nom_split = unit.split('*')
        denom_split = []

    # Now add nominator and denominator:
    cdef size_t i
    for sub_unit in nom_split:
        _parse_unit_single(sub_unit, 1, builder)
    for sub_unit in denom_split:
        _parse_unit_single(sub_unit, -1, builder)
    
    return CppUnit(builder)



####################################################################################
#                                                                                  #
#                           The cdef Python class                                  #
#                                                                                  #
####################################################################################

cdef Unit _multiply_units(Unit u0, Unit u1):
    cdef Unit res = Unit.__new__(Unit)
    res._unit = u0._unit * u1._unit
    return res


cdef Unit _divide_units(Unit u0, Unit u1):
    cdef Unit res = Unit.__new__(Unit)
    res._unit = u0._unit / u1._unit
    return res



cdef class Unit:
    """
    A physical unit.
    """
    def __init__(self, str unit):
        self._unit = parse_unit(unit)


    def __mul__(self, other):
        cdef Unit result
        if isinstance(other, Unit):
            # Unit multiplied by Unit is a unit:
            return _multiply_units(self, other)
        
        return NotImplemented


    def __truediv__(self, other):
        cdef Unit result
        if isinstance(other, Unit):
            # Unit divided by Unit is a unit:
            return _divide_units(self, other)

        return NotImplemented


    def __float__(self):
        # If dimensionless, we can convert to float:
        if self._unit.dimensionless():
            return self._unit.total_scale()
        
        # Attempting to lose dimension. Raise error!
        raise RuntimeError("Attempting to convert dimensional unit to float")


    def dimensionless(self):
        """
        Queries whether this unit is dimensionless.
        """
        return self._unit.dimensionless()