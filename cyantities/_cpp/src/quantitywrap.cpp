/*
 * A wrapper around the Cython Quantity class.
 *
 * Author: Malte J. Ziebarth (mjz.science@fmvkb.de)
 *
 * Copyright (C) 2024 Malte J. Ziebarth
 *
 * Licensed under the EUPL, Version 1.2 or – as soon they will be approved by
 * the European Commission - subsequent versions of the EUPL (the "Licence");
 * You may not use this work except in compliance with the Licence.
 * You may obtain a copy of the Licence at:
 *
 * https://joinup.ec.europa.eu/collection/eupl/eupl-text-eupl-12
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the Licence is distributed on an "AS IS" basis,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the Licence for the specific language governing permissions and
 * limitations under the Licence.
 */

#include <limits>
#include <cyantities/quantitywrap.hpp>

namespace cyantities {

QuantityWrapper::QuantityWrapper()
   : scalar_data(std::numeric_limits<double>::quiet_NaN()),
     data(&scalar_data), _N(0)
{}

QuantityWrapper::QuantityWrapper(double data, const Unit& unit)
   : scalar_data(data), data(&scalar_data), _N(1), _unit(unit)
{}

QuantityWrapper::QuantityWrapper(double* data, size_t N, const Unit& unit)
   : scalar_data(0.0), data(data), _N(N), _unit(unit)
{
    if (N == 0)
        throw std::runtime_error("Zero-dimensional quantity not allowed.");
}

QuantityWrapper::QuantityWrapper(const QuantityWrapper& other)
   : scalar_data(other.scalar_data),
     data((other.data == &other.scalar_data) ? &scalar_data : other.data),
     _N(other._N), _unit(other._unit)
{}

QuantityWrapper& QuantityWrapper::operator=(const QuantityWrapper& other)
{
   scalar_data = other.scalar_data;
   /* If the 'data' points to the scalar_data member of the other,
    * replace it by a pointer to this object's scalar_data: */
   if (other.data == &other.scalar_data)
      data = &scalar_data;
   else
      data = other.data;
   _N = other._N;
   _unit = other._unit;
   return *this;
}

const Unit& QuantityWrapper::unit() const
{
   return _unit;
}

size_t QuantityWrapper::size() const
{
   return _N;
}

}