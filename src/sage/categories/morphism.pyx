"""
Morphisms

AUTHORS:

- William Stein: initial version

- David Joyner (12-17-2005): added examples

- Robert Bradshaw (2007-06-25) Pyrexification
"""

#*****************************************************************************
#       Copyright (C) 2005 William Stein <wstein@gmail.com>
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 2 of the License, or
# (at your option) any later version.
#                  http://www.gnu.org/licenses/
#*****************************************************************************

from cpython.object cimport *
from sage.misc.constant_function import ConstantFunction

import operator



from sage.structure.element cimport Element, ModuleElement
from sage.structure.richcmp cimport richcmp_not_equal, rich_to_bool
from sage.structure.parent cimport Parent


def is_Morphism(x):
    return isinstance(x, Morphism)

cdef class Morphism(Map):

    def _repr_(self):
        """
        Return the string representation of ``self``.

        .. NOTE::

            It uses :meth:`_repr_type` and :meth:`_repr_defn`.

            A morphism that has been subject to
            :meth:`~sage.categories.map.Map._make_weak_references` has probably
            been used internally in the coercion system. Hence, it may become
            defunct by garbage collection of the domain. In this case, a warning
            is printed accordingly.

        EXAMPLES::

            sage: R.<t> = ZZ[]
            sage: f = R.hom([t+1])
            sage: f     # indirect doctest
            Ring endomorphism of Univariate Polynomial Ring in t over Integer Ring
              Defn: t |--> t + 1

        TESTS::

            sage: K = CyclotomicField(12)
            sage: L = CyclotomicField(132)
            sage: phi = L._internal_coerce_map_from(K); phi
            (map internal to coercion system -- copy before use)
            Generic morphism:
              From: Cyclotomic Field of order 12 and degree 4
              To:   Cyclotomic Field of order 132 and degree 40

            sage: del K
            sage: import gc
            sage: _ = gc.collect()
            sage: phi
            Defunct morphism
        """
        D = self.domain()
        if D is None:
            return "Defunct morphism"
        if self.is_endomorphism():
            s = "{} endomorphism of {}".format(self._repr_type(), self.domain())
        else:
            s = "{} morphism:".format(self._repr_type())
            s += "\n  From: {}".format(self.domain())
            s += "\n  To:   {}".format(self._codomain)
        if isinstance(self.domain, ConstantFunction):
            d = self._repr_defn()
            if d != '':
                s += "\n  Defn: " + '\n        '.join(d.split('\n'))
        else:
            d = "(map internal to coercion system -- copy before use)"
            s = d + "\n" + s
        return s

    def _default_repr_(self):
        """
        Return a string representation of this morphism.

        EXAMPLES::

            sage: R.<t> = ZZ[]
            sage: f = R.hom([t+1])
            sage: f._default_repr_()
            'Ring endomorphism of Univariate Polynomial Ring in t over Integer Ring\n  Defn: t |--> t + 1'
        """
        D = self.domain()
        if D is None:
            return "Defunct morphism"
        if self.is_endomorphism():
            s = "{} endomorphism of {}".format(self._repr_type(), self.domain())
        else:
            s = "{} morphism:".format(self._repr_type())
            s += "\n  From: {}".format(self.domain())
            s += "\n  To:   {}".format(self._codomain)
        d = self._repr_defn()
        if d != '':
            s += "\n  Defn: " + '\n        '.join(d.split('\n'))
        return s

    def _repr_short(self):
        """
        Return a short string representation of this morphism.

        EXAMPLES::

            sage: R.<t> = ZZ[]
            sage: f = R.hom([t+1])
            sage: f
            Ring endomorphism of Univariate Polynomial Ring in t over Integer Ring
              Defn: t |--> t + 1
            sage: f._repr_short()
            't |--> t + 1'
            sage: print(f._repr_short())
            t |--> t + 1

            sage: R.<u,v> = ZZ[]
            sage: f = R.hom([v,u+v])
            sage: f
            Ring endomorphism of Multivariate Polynomial Ring in u, v over Integer Ring
              Defn: u |--> v
                    v |--> u + v
            sage: print(f._repr_short())
            u |--> v, v |--> u + v

        AUTHOR:

        - Xavier Caruso (2012-06-29)
        """
        d = self._repr_defn()
        if d == "":
            return self._repr_()
        else:
            return ", ".join(d.split("\n"))

    def category(self):
        """
        Return the category of the parent of this morphism.

        EXAMPLES::

            sage: R.<t> = ZZ[]
            sage: f = R.hom([t**2])
            sage: f.category()
            Category of endsets of unital magmas and right modules over
             (euclidean domains and infinite enumerated sets and metric spaces)
             and left modules over (euclidean domains
             and infinite enumerated sets and metric spaces)

            sage: K = CyclotomicField(12)
            sage: L = CyclotomicField(132)
            sage: phi = L._internal_coerce_map_from(K)
            sage: phi.category()
            Category of homsets of number fields
        """
        # Should it be Category of elements of ...?
        return self.parent().category()

    def is_endomorphism(self):
        """
        Return ``True`` if this morphism is an endomorphism.

        EXAMPLES::

            sage: R.<t> = ZZ[]
            sage: f = R.hom([t])
            sage: f.is_endomorphism()
            True

            sage: K = CyclotomicField(12)
            sage: L = CyclotomicField(132)
            sage: phi = L._internal_coerce_map_from(K)
            sage: phi.is_endomorphism()
            False
        """
        return self.parent().is_endomorphism_set()

    def is_identity(self):
        """
        Return ``True`` if this morphism is the identity morphism.

        .. NOTE::

            Implemented only when the domain has a method gens()

        EXAMPLES::

            sage: R.<t> = ZZ[]
            sage: f = R.hom([t])
            sage: f.is_identity()
            True
            sage: g = R.hom([t+1])
            sage: g.is_identity()
            False

        A morphism between two different spaces cannot be the identity::

            sage: R2.<t2> = QQ[]
            sage: h = R.hom([t2])
            sage: h.is_identity()
            False
        """
        try:
            i = self._parent.identity()
        except TypeError:
            # If there is no identity morphism,
            # then self cannot be equal to it.
            return False
        return self._richcmp_(i, Py_EQ)

    def pushforward(self, I):
        raise NotImplementedError

    def register_as_coercion(self):
        r"""
        Register this morphism as a coercion to Sage's coercion model
        (see :mod:`sage.structure.coerce`).

        EXAMPLES:

        By default, adding polynomials over different variables triggers an error::

            sage: X.<x> = ZZ[]
            sage: Y.<y> = ZZ[]
            sage: x^2 + y
            Traceback (most recent call last):
            ...
            TypeError: unsupported operand parent(s) for +: 'Univariate Polynomial Ring in x over Integer Ring' and 'Univariate Polynomial Ring in y over Integer Ring'

        Let us declare a coercion from `\ZZ[x]` to `\ZZ[z]`::

            sage: Z.<z> = ZZ[]
            sage: phi = Hom(X, Z)(z)
            sage: phi(x^2+1)
            z^2 + 1
            sage: phi.register_as_coercion()

        Now we can add elements from `\ZZ[x]` and `\ZZ[z]`, because
        the elements of the former are allowed to be implicitly
        coerced into the later::

            sage: x^2 + z
            z^2 + z

        Caveat: the registration of the coercion must be done before any
        other coercion is registered or discovered::

            sage: phi = Hom(X, Y)(y)
            sage: phi.register_as_coercion()
            Traceback (most recent call last):
            ...
            AssertionError: coercion from Univariate Polynomial Ring in x over Integer Ring to Univariate Polynomial Ring in y over Integer Ring already registered or discovered

        """
        self._codomain.register_coercion(self)

    def register_as_conversion(self):
        r"""
        Register this morphism as a conversion to Sage's coercion model

        (see :mod:`sage.structure.coerce`).

        EXAMPLES:

        Let us declare a conversion from the symmetric group to `\ZZ`
        through the sign map::

            sage: S = SymmetricGroup(4)
            sage: phi = Hom(S, ZZ)(lambda x: ZZ(x.sign()))
            sage: x = S.an_element(); x
            (2,3,4)
            sage: phi(x)
            1
            sage: phi.register_as_conversion()
            sage: ZZ(x)
            1
        """
        self._codomain.register_conversion(self)

    def __hash__(self):
        """
        Return a hash of this morphism.

        It is the hash of the triple (domain, codomain, definition)
        where ``definition`` is:

        - a tuple consisting of the images of the generators
          of the domain if domain has generators

        - the string representation of this morphism otherwise

        AUTHOR:

        - Xavier Caruso (2012-07-09)
        """
        domain = self.domain()
        codomain = self.codomain()
        try:
            gens = domain.gens()
            definition = tuple([self(x) for x in gens])
        except (AttributeError, NotImplementedError):
            definition = repr(self)
        return hash((domain, codomain, definition))

    cpdef _richcmp_(self, other, int op):
        """
        Generic comparison function for morphisms.

        We check the images of the generators of the domain under both
        maps. We then iteratively check the base.

        TESTS::

            sage: from sage.categories.morphism import SetMorphism
            sage: E = End(Partitions(5))
            sage: f = E.identity()
            sage: g = SetMorphism(E, lambda x:x)
            sage: f == g
            Traceback (most recent call last):
            ...
            NotImplementedError: unable to compare morphisms of type <... 'sage.categories.morphism.IdentityMorphism'> and <... 'sage.categories.morphism.SetMorphism'> with domain Partitions of the integer 5
        """
        if self is other:
            return rich_to_bool(op, 0)

        # Important note: because of the coercion model, we know that
        # self and other have identical parents. This means that self
        # and other have the same domain and codomain.

        cdef Parent domain = <Parent?>self.domain()
        e = None
        while True:
            try:
                m = domain.gens
            except AttributeError:
                raise NotImplementedError(f"unable to compare morphisms of type {type(self)} and {type(other)} with domain {domain}")
            gens = m()
            # If e is a ModuleElement, then this is not the first
            # iteration and we are really in the base structure.
            #
            # If so, we see the base as a ring of scalars and create new
            # gens by picking an element of the initial domain (e) and
            # multiplying it with the gens of the scalar ring.
            if e is not None and isinstance(e, ModuleElement):
                gens = [(<ModuleElement>e)._lmul_(x) for x in gens]
            for e in gens:
                x = self(e)
                y = other(e)
                if x != y:
                    return richcmp_not_equal(x, y, op)
            # Check base
            base = domain._base
            if base is None or base is domain:
                break
            domain = <Parent?>base
        return rich_to_bool(op, 0)

    def __nonzero__(self):
        r"""
        Return whether this morphism is not a zero morphism.

        .. NOTE::

            Be careful when overriding this method. Often morphisms are used
            (incorrectly) in constructs such as ``if f: # do something`` where
            the author meant to write ``if f is not None: # do something``.
            Having morphisms return ``False`` here can therefore lead to subtle
            bugs.

        EXAMPLES::

            sage: f = Hom(ZZ,Zmod(1)).an_element()
            sage: bool(f) # indirect doctest
            False

        """
        try:
            return self._is_nonzero()
        except Exception:
            if PY_MAJOR_VERSION < 3:
                return super(Morphism, self).__nonzero__()
            else:
                return super().__bool__()


cdef class FormalCoercionMorphism(Morphism):
    def __init__(self, parent):
        Morphism.__init__(self, parent)
        if not self._codomain.has_coerce_map_from(self.domain()):
            raise TypeError("Natural coercion morphism from {} to {} not defined.".format(self.domain(), self._codomain))

    def _repr_type(self):
        return "Coercion"

    cpdef Element _call_(self, x):
        return self._codomain.coerce(x)

cdef class CallMorphism(Morphism):

    def _repr_type(self):
        return "Call"

    cpdef Element _call_(self, x):
        return self._codomain(x)

cdef class IdentityMorphism(Morphism):

    def __init__(self, parent):
        from .homset import Homset, Hom
        if not isinstance(parent, Homset):
            parent = Hom(parent, parent)
        Morphism.__init__(self, parent)

    def _repr_type(self):
        return "Identity"

    cpdef Element _call_(self, x):
        return x

    cpdef Element _call_with_args(self, x, args=(), kwds={}): 
        if len(args) == 0 and len(kwds) == 0:
            return x
        cdef Parent C = self._codomain
        if C._element_init_pass_parent:
            from sage.misc.superseded import deprecation
            deprecation(26879, "_element_init_pass_parent=True is deprecated. This probably means that _element_constructor_ should be a method and not some other kind of callable")
            return C._element_constructor(C, x, *args, **kwds)
        else:
            return C._element_constructor(x, *args, **kwds)

    def __mul__(left, right):
        if not isinstance(right, Map):
            raise TypeError("right (=%s) must be a map to multiply it by %s"%(right, left))
        if not isinstance(left, Map):
            raise TypeError("left (=%s) must be a map to multiply it by %s"%(left, right))
        if right.codomain() != left.domain():
            raise TypeError("self (=%s) domain must equal right (=%s) codomain"%(left, right))
        if isinstance(left, IdentityMorphism):
            return right
        else:
            return left

    cpdef _pow_int(self, n):
        return self

    def __invert__(self):
        return self

    def is_identity(self):
        """
        Return ``True`` if this morphism is the identity morphism.

        EXAMPLES::

            sage: E = End(Partitions(5))
            sage: E.identity().is_identity()
            True

        Check that :trac:`15478` is fixed::

            sage: K.<z> = GF(4)
            sage: phi = End(K)([z^2])
            sage: R.<t> = K[]
            sage: psi = End(R)(phi)
            sage: psi.is_identity()
            False
        """
        return True

    def section(self):
        """
        Return a section of this morphism.

        EXAMPLES::

            sage: T = Hom(ZZ, ZZ).identity()
            sage: T.section() is T
            True
        """
        return self

    def is_surjective(self):
        r"""
        Return whether this morphism is surjective.

        EXAMPLES::

            sage: Hom(ZZ, ZZ).identity().is_surjective()
            True
        """
        return True

    def is_injective(self):
        r"""
        Return whether this morphism is injective.

        EXAMPLES::

            sage: Hom(ZZ, ZZ).identity().is_injective()
            True
        """
        return True


cdef class SetMorphism(Morphism):
    def __init__(self, parent, function):
        """
        INPUT:

        - ``parent`` -- a Homset
        - ``function`` -- a Python function that takes elements
          of the domain as input and returns elements of the domain.

        EXAMPLES::

            sage: from sage.categories.morphism import SetMorphism
            sage: f = SetMorphism(Hom(QQ, ZZ, Sets()), numerator)
            sage: f.parent()
            Set of Morphisms from Rational Field to Integer Ring in Category of sets
            sage: f.domain()
            Rational Field
            sage: f.codomain()
            Integer Ring
            sage: TestSuite(f).run()
        """
        Morphism.__init__(self, parent)
        self._function = function

    cpdef Element _call_(self, x):
        """
        INPUT:

        - ``x`` -- an element of ``self.domain()``

        Returns the result of ``self`` applied on ``x``.

        EXAMPLES::

            sage: from sage.categories.morphism import SetMorphism
            sage: f = SetMorphism(Hom(QQ, ZZ, Sets()), numerator)  # could use Monoids() once the categories will be in
            sage: f(2/3)
            2
            sage: f(5/4)
            5
            sage: f(3) # todo: this should complain that 3 is not in QQ
            3
        """
        return self._function(x)

    cpdef Element _call_with_args(self, x, args=(), kwds={}):
        """
        Extra arguments are passed to the defining function.

        TESTS::

            sage: from sage.categories.morphism import SetMorphism
            sage: R.<x> = QQ[]
            sage: def foo(x,*args,**kwds):
            ....:     print('foo called with {} {}'.format(args, kwds))
            ....:     return x
            sage: f = SetMorphism(Hom(R,R,Rings()), foo)
            sage: f(2,'hello world',test=1)     # indirect doctest
            foo called with ('hello world',) {'test': 1}
            2

        """
        try:
            return self._function(x, *args, **kwds)
        except Exception:
            raise TypeError("Underlying map %s does not accept additional arguments" % type(self._function))

    cdef dict _extra_slots(self):
        """
        INPUT:

        - ``_slots`` -- a dictionary

        Extends the dictionary with extra slots for this class.

        EXAMPLES::

            sage: f = sage.categories.morphism.SetMorphism(Hom(ZZ,ZZ, Sets()), operator.__abs__)
            sage: f._extra_slots_test()
            {'_codomain': Integer Ring,
             '_domain': Integer Ring,
             '_function': <built-in function ...abs...>,
             '_is_coercion': False,
             '_repr_type_str': None}
        """
        slots = Map._extra_slots(self)
        slots['_function'] = self._function
        return slots

    cdef _update_slots(self, dict _slots):
        """
        INPUT:

        - ``_slots`` -- a dictionary

        Updates the slots of ``self`` from the data in the dictionary

        EXAMPLES::

            sage: f = sage.categories.morphism.SetMorphism(Hom(ZZ,ZZ, Sets()), operator.__abs__)
            sage: f(3)
            3
            sage: f._update_slots_test({'_function' : operator.__neg__,
            ....:                       '_domain' : QQ,
            ....:                       '_codomain' : QQ,
            ....:                       '_repr_type_str' : 'bla'})
            sage: f(3)
            -3
            sage: f._repr_type()
            'bla'
            sage: f.domain()
            Rational Field
            sage: f.codomain()
            Rational Field
        """
        self._function = _slots['_function']
        Map._update_slots(self, _slots)

    cpdef bint _eq_c_impl(self, Element other):
        """
        Equality test

        EXAMPLES::

            sage: f = sage.categories.morphism.SetMorphism(Hom(ZZ,ZZ, Sets()),    operator.__abs__)
            sage: g = sage.categories.morphism.SetMorphism(Hom(ZZ,ZZ, Sets()),    operator.__abs__)
            sage: h = sage.categories.morphism.SetMorphism(Hom(ZZ,ZZ, Rings()),   operator.__abs__) # todo: replace by the more correct Monoids
            sage: i = sage.categories.morphism.SetMorphism(Hom(ZZ,ZZ, Sets()),    operator.__neg__)
            sage: f._eq_c_impl(g)
            True
            sage: f._eq_c_impl(h)
            False
            sage: f._eq_c_impl(i)
            False
            sage: f._eq_c_impl(1)
            False

        """
        return isinstance(other, SetMorphism) and self.parent() == other.parent() and self._function == (<SetMorphism>other)._function

    def __richcmp__(self, right, int op):
        """
        INPUT:

        - ``self``  -- SetMorphism
        - ``right`` -- any object
        - ``op``    -- integer

        EXAMPLES::

            sage: f = sage.categories.morphism.SetMorphism(Hom(ZZ,ZZ, Sets()),    operator.__abs__)
            sage: g = sage.categories.morphism.SetMorphism(Hom(ZZ,ZZ, Sets()),    operator.__abs__)
            sage: h = sage.categories.morphism.SetMorphism(Hom(ZZ,ZZ, Rings()),   operator.__abs__) # todo: replace by the more correct Monoids
            sage: i = sage.categories.morphism.SetMorphism(Hom(ZZ,ZZ, Sets()),    operator.__neg__)
            sage: f == f, f != f, f < f, f > f, f <= f, f >= f
            (True, False, False, False, True, True)
            sage: f == g, f != g, f < g, f > g, f <= g, f >= g
            (True, False, False, False, True, True)
            sage: f == h, f != h, f < h, f > h, f <= h, f >= h
            (False, True, False, False, False, False)
            sage: f == i, f != i, f < i, f > i, f <= i, f >= i
            (False, True, False, False, False, False)
            sage: f == 0, f == int(0), f is None
            (False, False, False)
            sage: f != 0, f != int(0), f is not None
            (True, True, True)
        """
        if op == Py_EQ or op == Py_LE or op == Py_GE:
            return isinstance(right, Element) and self._eq_c_impl(right)
        elif op == Py_NE:
            return not (isinstance(right, Element) and self._eq_c_impl(right))
        else:
            return False
