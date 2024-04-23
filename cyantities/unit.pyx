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

from .unit cimport base_unit_t, UnitBuilder, CppUnit, Unit, base_unit_array_t,\
                   base_unit_index_t


#
# Some convenience functions:
#
cdef extern from * namespace "cyantities" nogil:
    """
    namespace cyantities {
    static base_unit_t _base_unit_from_index(base_unit_index_t i)
    {
        return static_cast<base_unit_t>(i);
    }
    }
    """
    base_unit_t _base_unit_from_index(base_unit_index_t i) nogil



#######################################################################
#
#                         Cython unit parsing.
#
#######################################################################

cdef void _parse_unit_single(str unit, int prefix, int exponent,
                             UnitBuilder& builder):
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
            builder.add_decadal_exponent(12 * prefix * exponent)
            has_prefix = True
        elif first == u'G':
            # Giga-prefix overlaps with Gray.
            # Catch that overlap here:
            if n == 2 and unit == 'Gy':
                builder.add_base_unit_occurrence(SI_METER,   2 * prefix * exponent)
                builder.add_base_unit_occurrence(SI_SECOND, -2 * prefix * exponent)
                return
            # Giga.
            builder.add_decadal_exponent(9 * prefix * exponent)
            has_prefix = True
        elif first == u'M':
            # Mega
            builder.add_decadal_exponent(6 * prefix * exponent)
            has_prefix = True
        elif first == u'k':
            # kilo-prefix overlaps with kilogram.
            # Catch that overlap here:
            if n == 2 and unit == "kg":
                builder.add_base_unit_occurrence(SI_KILOGRAM, prefix * exponent)
                return
            # kilo-prefix overlaps with katal:
            elif n == 3 and unit == "kat":
                builder.add_base_unit_occurrence(SI_MOLE,    1 * prefix * exponent)
                builder.add_base_unit_occurrence(SI_SECOND, -1 * prefix * exponent)
                return

            # kilo
            builder.add_decadal_exponent(3 * prefix * exponent)
            has_prefix = True
        elif first == u'h':
            # hecto
            builder.add_decadal_exponent(2 * prefix * exponent)
            has_prefix = True
        elif first == u'd':
            # dezi
            builder.add_decadal_exponent(-1 * prefix * exponent)
            has_prefix = True
        elif first == u'c':
            # centi-prefix overlaps with Candela.
            # Catch that overlap here:
            if n == 2 and unit == "cd":
                builder.add_base_unit_occurrence(SI_CANDELA, prefix * exponent)
                return
            # centi
            builder.add_decadal_exponent(-2 * prefix * exponent)
            has_prefix = True
        elif first == u'm':
            # milli-prefix overlaps with mol.
            # Catch that overlap here:
            if n == 3 and unit == "mol":
                builder.add_base_unit_occurrence(SI_MOLE, prefix * exponent)
                return
            # milli
            builder.add_decadal_exponent(-3 * prefix * exponent)
            has_prefix = True
        elif first == u'µ':
            # micro
            builder.add_decadal_exponent(-6 * prefix * exponent)
            has_prefix = True
        elif first == u'n':
            # nano
            builder.add_decadal_exponent(-9 * prefix * exponent)
            has_prefix = True
        elif first == u'p':
            # pico
            builder.add_decadal_exponent(-12 * prefix * exponent)
            has_prefix = True

        # Now need to cut the prefix:
        if has_prefix:
            unit = unit[1:]

    # A note for future performance optimization:
    # This function does a lot of string comparisons. Potentially, this process
    # might be sped up using a dict lookup for 'unit' (but that's also not clear
    # - measurement would be key).
    # Probably, units will not be parsed often enough in typical code to incur a
    # significant performance overhead, so that this function should be OK,
    # and simplicity in writing this function takes precendence.

    #
    # SI base units:
    #
    if unit == "m":
        builder.add_base_unit_occurrence(SI_METER, prefix * exponent)
        return
    elif unit == "kg":
        builder.add_base_unit_occurrence(SI_KILOGRAM, prefix * exponent)
        return
    elif unit == "s":
        builder.add_base_unit_occurrence(SI_SECOND, prefix * exponent)
        return
    elif unit == "A":
        builder.add_base_unit_occurrence(SI_AMPERE, prefix * exponent)
        return
    elif unit == "K":
        builder.add_base_unit_occurrence(SI_KELVIN, prefix * exponent)
        return
    elif unit == "mol":
        builder.add_base_unit_occurrence(SI_MOLE, prefix * exponent)
        return
    elif unit == "cd":
        builder.add_base_unit_occurrence(SI_CANDELA, prefix * exponent)
        return
    elif unit == "rad":
        # Follow boost units in defining radians as a base unit.
        builder.add_base_unit_occurrence(OTHER_RADIANS, prefix * exponent)
        return
    elif unit == "sr":
        # Follow boost units in defining steradian as a base unit.
        builder.add_base_unit_occurrence(OTHER_STERADIAN, prefix * exponent)
        return


    #
    # SI derived units:
    #
    if unit == "Pa":
        builder.add_base_unit_occurrence(SI_KILOGRAM, 1 * prefix * exponent)
        builder.add_base_unit_occurrence(SI_METER,   -1 * prefix * exponent)
        builder.add_base_unit_occurrence(SI_SECOND,  -2 * prefix * exponent)
        return
    elif unit == "J":
        builder.add_base_unit_occurrence(SI_KILOGRAM, 1 * prefix * exponent)
        builder.add_base_unit_occurrence(SI_METER,    2 * prefix * exponent)
        builder.add_base_unit_occurrence(SI_SECOND,  -2 * prefix * exponent)
        return
    elif unit == "W":
        # Watts
        builder.add_base_unit_occurrence(SI_KILOGRAM, 1 * prefix * exponent)
        builder.add_base_unit_occurrence(SI_METER,    2 * prefix * exponent)
        builder.add_base_unit_occurrence(SI_SECOND,  -3 * prefix * exponent)
        return
    elif unit == "erg":
        # 1 erg = 1e-7 J
        builder.add_decadal_exponent(-7 * prefix * exponent)
        builder.add_base_unit_occurrence(SI_KILOGRAM, 1 * prefix * exponent)
        builder.add_base_unit_occurrence(SI_METER,    2 * prefix * exponent)
        builder.add_base_unit_occurrence(SI_SECOND,  -2 * prefix * exponent)
        return
    elif unit == "g":
        builder.add_decadal_exponent(-3 * prefix * exponent)
        builder.add_base_unit_occurrence(SI_KILOGRAM, 1 * prefix * exponent)
        return
    elif unit == "h":
        builder.multiply_conversion_factor(pow(3600.0, prefix * exponent))
        builder.add_base_unit_occurrence(SI_SECOND, 1 * prefix * exponent)
        return
    elif unit == "Hz":
        # Hertz
        builder.add_base_unit_occurrence(SI_SECOND, -1 * prefix * exponent)
        return
    elif unit == "N":
        # Newton
        builder.add_base_unit_occurrence(SI_KILOGRAM,  1 * prefix * exponent)
        builder.add_base_unit_occurrence(SI_METER,     1 * prefix * exponent)
        builder.add_base_unit_occurrence(SI_SECOND,   -2 * prefix * exponent)
        return
    elif unit == "W":
        # Watt
        builder.add_base_unit_occurrence(SI_KILOGRAM,  1 * prefix * exponent)
        builder.add_base_unit_occurrence(SI_METER,     2 * prefix * exponent)
        builder.add_base_unit_occurrence(SI_SECOND,   -3 * prefix * exponent)
        return
    elif unit == "C":
        # Coulomb
        builder.add_base_unit_occurrence(SI_SECOND, 1 * prefix * exponent)
        builder.add_base_unit_occurrence(SI_AMPERE, 1 * prefix * exponent)
        return
    elif unit == "V":
        # Volt
        builder.add_base_unit_occurrence(SI_KILOGRAM,  1 * prefix * exponent)
        builder.add_base_unit_occurrence(SI_METER,     2 * prefix * exponent)
        builder.add_base_unit_occurrence(SI_SECOND,   -3 * prefix * exponent)
        builder.add_base_unit_occurrence(SI_AMPERE,   -1 * prefix * exponent)
        return
    elif unit == "F":
        # Farad
        builder.add_base_unit_occurrence(SI_KILOGRAM, -1 * prefix * exponent)
        builder.add_base_unit_occurrence(SI_METER,    -2 * prefix * exponent)
        builder.add_base_unit_occurrence(SI_SECOND,    4 * prefix * exponent)
        builder.add_base_unit_occurrence(SI_AMPERE,    2 * prefix * exponent)
        return
    elif unit == "Ω":
        # Ohm, electrical resistance
        builder.add_base_unit_occurrence(SI_KILOGRAM,  1 * prefix * exponent)
        builder.add_base_unit_occurrence(SI_METER,     2 * prefix * exponent)
        builder.add_base_unit_occurrence(SI_SECOND,   -3 * prefix * exponent)
        builder.add_base_unit_occurrence(SI_AMPERE,   -2 * prefix * exponent)
        return
    elif unit == "S":
        # Siemens, electrical conductance
        builder.add_base_unit_occurrence(SI_KILOGRAM, -1 * prefix * exponent)
        builder.add_base_unit_occurrence(SI_METER,    -2 * prefix * exponent)
        builder.add_base_unit_occurrence(SI_SECOND,    3 * prefix * exponent)
        builder.add_base_unit_occurrence(SI_AMPERE,    2 * prefix * exponent)
        return
    elif unit == "Wb":
        # Weber, magnetic flux
        builder.add_base_unit_occurrence(SI_KILOGRAM,  1 * prefix * exponent)
        builder.add_base_unit_occurrence(SI_METER,     2 * prefix * exponent)
        builder.add_base_unit_occurrence(SI_SECOND,   -2 * prefix * exponent)
        builder.add_base_unit_occurrence(SI_AMPERE,   -1 * prefix * exponent)
        return
    elif unit == "T":
        # Tesla, magnetic induction
        builder.add_base_unit_occurrence(SI_KILOGRAM,  1 * prefix * exponent)
        builder.add_base_unit_occurrence(SI_SECOND,   -2 * prefix * exponent)
        builder.add_base_unit_occurrence(SI_AMPERE,   -1 * prefix * exponent)
        return
    elif unit == "H":
        # Henry, electrical inductance
        builder.add_base_unit_occurrence(SI_KILOGRAM,  1 * prefix * exponent)
        builder.add_base_unit_occurrence(SI_METER,     2 * prefix * exponent)
        builder.add_base_unit_occurrence(SI_SECOND,   -2 * prefix * exponent)
        builder.add_base_unit_occurrence(SI_AMPERE,   -2 * prefix * exponent)
        return
    elif unit == "lm":
        # Lumen, luminous flux
        builder.add_base_unit_occurrence(SI_CANDELA,      1 * prefix * exponent)
        builder.add_base_unit_occurrence(OTHER_STERADIAN, 1 * prefix * exponent)
        return
    elif unit == "lx":
        # Lux, illuminance
        builder.add_base_unit_occurrence(SI_CANDELA,      1 * prefix * exponent)
        builder.add_base_unit_occurrence(OTHER_STERADIAN, 1 * prefix * exponent)
        builder.add_base_unit_occurrence(SI_METER,       -2 * prefix * exponent)
        return
    elif unit == "Bq":
        # Becquerel, radioactivity
        builder.add_base_unit_occurrence(SI_SECOND, -1 * prefix * exponent)
        return
    elif unit == "Gy" or unit == "Sv":
        # Gray, absorbed dose and
        # Sievert, equivalent dose
        builder.add_base_unit_occurrence(SI_METER,   2 * prefix * exponent)
        builder.add_base_unit_occurrence(SI_SECOND, -2 * prefix * exponent)
        return
    elif unit == "kat":
        # katal, catalyitic activity
        builder.add_base_unit_occurrence(SI_MOLE,    1 * prefix * exponent)
        builder.add_base_unit_occurrence(SI_SECOND, -1 * prefix * exponent)
        return
    elif unit == "bar":
        # bar, pressure
        builder.add_decadal_exponent(5 * prefix * exponent)
        builder.add_base_unit_occurrence(SI_KILOGRAM, 1 * prefix * exponent)
        builder.add_base_unit_occurrence(SI_METER,   -1 * prefix * exponent)
        builder.add_base_unit_occurrence(SI_SECOND,  -2 * prefix * exponent)
        return
    elif unit == "l":
        # litre, volume
        builder.add_decadal_exponent(-3 * prefix * exponent)
        builder.add_base_unit_occurrence(SI_METER, 3 * prefix * exponent)
        return
    elif unit == "t":
        # ton, mass
        builder.add_decadal_exponent(3 * prefix * exponent)
        builder.add_base_unit_occurrence(SI_KILOGRAM, 1 * prefix * exponent)
        return
    elif unit == "eV":
        # Electronvolt.
        # 1eV = 1.602176634e−19 J
        builder.multiply_conversion_factor(pow(1.602176634, prefix * exponent))
        builder.add_decadal_exponent(-19 * prefix * exponent)
        builder.add_base_unit_occurrence(SI_KILOGRAM, 1 * prefix * exponent)
        builder.add_base_unit_occurrence(SI_METER,    2 * prefix * exponent)
        builder.add_base_unit_occurrence(SI_SECOND,  -2 * prefix * exponent)
        return
    elif unit == "°C" or unit == "°F":
        raise ValueError("Cyantities does not support temperatures in Celsius "
            "or Fahrenheit since they are not proportional to the Kelvin scale. "
            "Please express your temperatures in Kelvin."
        )

    raise ValueError("Unknown unit '" + unit + "'")


cdef CppUnit parse_unit(str unit):
    """
    The central function that translates
    """
    # Early exit: Dimensionless, unit-unit:
    if unit == "1":
        return CppUnit()

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
        if '*' in unit:
            nom_split = unit.split('*')
        else:
            nom_split = unit.split(' ')
        denom_split = []

    # Now add nominator and denominator:
    cdef size_t i
    cdef int exponent
    for sub_unit in nom_split:
        if sub_unit == "1":
            continue
        if "^" in sub_unit:
            sub_unit, exp = sub_unit.split("^")
            exponent = int(exp)
            if exponent == 0:
                continue
        else:
            exponent = 1
        _parse_unit_single(sub_unit, 1, exponent, builder)
    for sub_unit in denom_split:
        if "^" in sub_unit:
            sub_unit, exp = sub_unit.split("^")
            exponent = int(exp)
            if exponent <= 0:
                raise RuntimeError("Only positive exponents allowed if "
                                   "denominator is expressed through "
                                   "parantheses.")
        else:
            exponent = 1
        _parse_unit_single(sub_unit, -1, exponent, builder)

    return CppUnit(builder)


################################################################################
#                                                                              #
#                          Cython unit formatting                              #
#                                                                              #
################################################################################

cdef str _unit_id_to_string(base_unit_t uid):
    """
    Convert the 'base_unit_t' enum to the string representation
    of the unit.
    """
    if uid == SI_METER:
        return "m"
    elif uid == SI_KILOGRAM:
        return "kg"
    if uid == SI_SECOND:
        return "s"
    elif uid == SI_AMPERE:
        return "A"
    elif uid == SI_KELVIN:
        return "K"
    elif uid == SI_MOLE:
        return "mol"
    elif uid == SI_CANDELA:
        return "cd"
    elif uid == OTHER_RADIANS:
        return "rad"
    elif uid == OTHER_STERADIAN:
        return "sr"
    else:
        raise ValueError("Unknown base unit id")


cdef str format_unit(const CppUnit& unit, str rule):
    """
    Output a unit to a string using a specific formating
    rule.
    """
    # First get the scale:
    cdef double scale = unit.total_scale()
    cdef str s
    if scale != 1.0:
        s = str(scale) + " * "
    else:
        s = ""

    # Get the list of all units and exponents:
    cdef list olist = list()
    cdef base_unit_index_t i
    cdef int8_t occ
    for i in range(BASE_UNIT_COUNT):
        occ = unit.base_units()[i]
        olist.append((
            int(occ),
            _unit_id_to_string(_base_unit_from_index(i)),
            i
        ))

    # Now perform the different rules:
    if rule == 'coherent':
        s += " ".join(
            o[1] if o[0] == 1 else o[1] + "^" + str(o[0]) for o in olist
            if o[0] != 0
        )

    elif rule == 'casual':
        olist.sort(key = lambda o : (-o[0], o[2]))
        s += " ".join(
            o[1] if o[0] == 1 else o[1] + "^" + str(o[0]) for o in olist
            if o[0] != 0
        )

    else:
        raise RuntimeError("Rule '" + rule + "' not implemented.")

    return s


####################################################################################
#                                                                                  #
#                           The cdef Python class                                  #
#                                                                                  #
####################################################################################

cdef Unit generate_from_cpp(const CppUnit& unit):
    cdef Unit u = Unit.__new__(Unit)
    u._unit = unit
    return u

cdef Unit _multiply_units(Unit u0, Unit u1):
    return generate_from_cpp(u0._unit * u1._unit)


cdef Unit _divide_units(Unit u0, Unit u1):
    return generate_from_cpp(u0._unit / u1._unit)



cdef class Unit:
    """
    A physical unit.
    """
    def __init__(self, str unit):
        self._unit = parse_unit(unit)


    def __repr__(self) -> str:
        """
        String representation.
        """
        return "Unit(" + str(self) + ")"


    def format(self, rule='coherent') -> str:
        """
        Output this unit to a string using a specific formating
        rule.

        Parameters
        ----------
        rule : 'coherent' | 'casual'
        """
        if not isinstance(rule, str):
            raise TypeError("`rule` has to be a string!")
        return format_unit(self._unit, rule)


    def __str__(self) -> str:
        return self.format('coherent')


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


    def __eq__(self, other):
        if not isinstance(other, Unit):
            return False

        cdef Unit ou = other
        return self._unit == ou._unit


    def same_dimension(self, Unit other):
        return self._unit.same_dimension(other._unit)


    def dimensionless(self):
        """
        Queries whether this unit is dimensionless.
        """
        return self._unit.dimensionless()