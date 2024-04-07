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

#ifndef CYANTITIES_QUANTITYWRAP_HPP
#define CYANTITIES_QUANTITYWRAP_HPP

#include <cyantities/unit.hpp>
#include <cyantities/boost.hpp>

#include <iterator>

namespace cyantities {

class QuantityWrapper;

/*
 * Iterators over multidimensional quantities.
 * This class iterates all values (one or more) of the QuantityWrapper class
 * below. Dereferencing the iterator yields a Boost.Units quantity.
 */
template<typename boost_quantity, typename T>
class QuantityIterator
{
    friend QuantityWrapper;
public:
    /* Iterator traits: */
    typedef size_t difference_type;
    typedef boost_quantity value_type;
    typedef std::forward_iterator_tag iterator_category;
    typedef boost_quantity& reference;

    QuantityIterator() : data(nullptr), begin(nullptr), end(nullptr)
    {}


    QuantityIterator& operator++()
    {
        ++data;
        return *this;
    }

    QuantityIterator operator++(int)
    {
        QuantityIterator res(*this);
        this->operator++();
        return res;
    }

    QuantityIterator& operator--()
    {
        --data;
        return *this;
    }

    template<typename integer>
    QuantityIterator& operator-(integer off)
    {
        data -= off;
        return *this;
    }

    template<typename integer>
    QuantityIterator& operator+=(integer off)
    {
        data += off;
        return *this;
    }

    boost_quantity operator*() const
    {
        if (data == nullptr)
            throw std::runtime_error("Trying to dereference nullptr");
        if (data < begin){
            throw std::runtime_error(
                "Trying to dereference QuantityIterator before begin."
            );
        }
        if (data >= end)
            throw std::runtime_error(
                "Trying to dereference QuantityIterator past end."
            );
        return *data * unit;
    }

    bool operator==(const QuantityIterator& other) const
    {
        return data == other.data && unit == other.unit;
    }

private:
    T* data;
    const double* begin;
    const double* end;
    boost_quantity unit;

    QuantityIterator(T* data, size_t N, boost_quantity unit)
       : data(data), begin(data), end(data+N), unit(unit)
    {
        if (this->data < this->begin)
            throw std::runtime_error("Invalid initialization!");
    }
};


/*
 * This class wraps the info from the Cython/Python 'Quantity' class
 * (i.e. a scalar double or an array of doubles + a unit) into something
 * of the C++ world, and provides templates to obtain the quantity in
 * Boost.Unit units (based on the conversion in boost.hpp).
 **/
class QuantityWrapper {
public:
    QuantityWrapper();

    QuantityWrapper(double data, const Unit& unit);

    QuantityWrapper(double* data, size_t N, const Unit& unit);

    QuantityWrapper(const QuantityWrapper& other);

    QuantityWrapper& operator=(const QuantityWrapper& other);

    template<typename boost_quantity>
    boost_quantity get(size_t i = 0) const
    {
        if (i >= _N)
            throw std::out_of_range("Index out of range.");

        return data[i] * get_converter<boost_quantity>(_unit);
    }

    template<typename boost_quantity>
    void set_element(size_t i, boost_quantity bq)
    {
        if (i >= _N)
            throw std::out_of_range("Index out of range.");

        boost_quantity scale = get_converter<boost_quantity>(_unit);
        data[i] = bq / scale;
    }

    template<typename boost_quantity>
    QuantityIterator<boost_quantity,double> begin()
    {
        return QuantityIterator<boost_quantity, double>(
            data, _N, get_converter<boost_quantity>(_unit)
        );
    }

    template<typename boost_quantity>
    QuantityIterator<boost_quantity,const double> cbegin() const
    {
        return QuantityIterator<boost_quantity, const double>(
            data, _N, get_converter<boost_quantity>(_unit)
        );
    }

    template<typename boost_quantity>
    QuantityIterator<boost_quantity, const double> end() const
    {
        auto _end(cbegin<boost_quantity>());
        _end += _N;
        return _end;
    }


private:
    double scalar_data;

    /* Attributes: */
    double* data;
    size_t _N;
    Unit _unit;

public:
    size_t size() const;
    const Unit& unit() const;
};



} // end namespace

#endif