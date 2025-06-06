@doc raw"""
    change_representer(M::Hyperbolic, ::EuclideanMetric, p, X)

Change the Eucliden representer `X` of a cotangent vector at point `p`.
We only have to correct for the metric, which means that the sign of the last entry changes, since
for the result ``Y``  we are looking for a tangent vector such that

```math
    g_p(Y,Z) = -y_{n+1}z_{n+1} + \sum_{i=1}^n y_iz_i = \sum_{i=1}^{n+1} z_ix_i
```

holds, which directly yields ``y_i=x_i`` for ``i=1,\ldots,n`` and ``y_{n+1}=-x_{n+1}``.
"""
change_representer(::Hyperbolic, ::EuclideanMetric, ::Any, ::Any)

function change_representer!(M::Hyperbolic, Y, ::EuclideanMetric, p, X)
    copyto!(M, Y, p, X)
    Y[end] *= -1
    return Y
end

function change_metric!(::Hyperbolic, ::Any, ::EuclideanMetric, ::Any, ::Any)
    return error(
        "Changing metric from Euclidean to Hyperbolic is not possible (see Sylvester's law of inertia).",
    )
end

function check_point(M::Hyperbolic, p; kwargs...)
    if !isapprox(minkowski_metric(p, p), -1.0; kwargs...)
        return DomainError(
            minkowski_metric(p, p),
            "The point $(p) does not lie on $(M) since its Minkowski inner product is not -1.",
        )
    end
    return nothing
end

function check_vector(
    M::Hyperbolic,
    p,
    X::T;
    atol::Real=sqrt(prod(representation_size(M))) * eps(real(float(number_eltype(T)))),
    kwargs...,
) where {T}
    if !isapprox(minkowski_metric(p, X), 0; atol=atol, kwargs...)
        return DomainError(
            abs(minkowski_metric(p, X)),
            "The vector $(X) is not a tangent vector to $(p) on $(M), since it is not orthogonal (with respect to the Minkowski inner product) in the embedding.",
        )
    end
    return nothing
end

function convert(::Type{HyperboloidTangentVector}, X::T) where {T<:AbstractVector}
    return HyperboloidTangentVector(X)
end
function convert(
    ::Type{HyperboloidTangentVector},
    p::P,
    X::T,
) where {P<:AbstractVector,T<:AbstractVector}
    return HyperboloidTangentVector(X)
end
convert(::Type{AbstractVector}, X::HyperboloidTangentVector) = X.value
function convert(
    ::Type{T},
    p::HyperboloidPoint,
    X::HyperboloidTangentVector,
) where {T<:AbstractVector}
    return X.value
end

function convert(::Type{HyperboloidPoint}, p::T) where {T<:AbstractVector}
    return HyperboloidPoint(p)
end
convert(::Type{AbstractVector}, p::HyperboloidPoint) = p.value

@doc raw"""
    convert(::Type{HyperboloidPoint}, p::PoincareBallPoint)
    convert(::Type{AbstractVector}, p::PoincareBallPoint)

convert a point [`PoincareBallPoint`](@ref) `x` (from ``ℝ^n``) from the
Poincaré ball model of the [`Hyperbolic`](@ref) manifold ``\mathcal H^n`` to a [`HyperboloidPoint`](@ref) ``π(p) ∈ ℝ^{n+1}``.
The isometry is defined by

````math
π(p) = \frac{1}{1-\lVert p \rVert^2}
\begin{pmatrix}2p_1\\⋮\\2p_n\\1+\lVert p \rVert^2\end{pmatrix}
````

Note that this is also used, when the type to convert to is a vector.
"""
function convert(::Type{HyperboloidPoint}, p::PoincareBallPoint)
    return HyperboloidPoint(convert(AbstractVector, p))
end
function convert(::Type{AbstractVector}, p::PoincareBallPoint)
    return 1 / (1 - norm(p.value)^2) .* vcat(2 .* p.value, 1 + norm(p.value)^2)
end

@doc raw"""
    convert(::Type{HyperboloidPoint}, p::PoincareHalfSpacePoint)
    convert(::Type{AbstractVector}, p::PoincareHalfSpacePoint)

convert a point [`PoincareHalfSpacePoint`](@ref) `p` (from ``ℝ^n``) from the
Poincaré half plane model of the [`Hyperbolic`](@ref) manifold ``\mathcal H^n`` to a [`HyperboloidPoint`](@ref) ``π(p) ∈ ℝ^{n+1}``.

This is done in two steps, namely transforming it to a Poincare ball point and from there further on to a Hyperboloid point.
"""
function convert(t::Type{HyperboloidPoint}, p::PoincareHalfSpacePoint)
    return convert(t, convert(PoincareBallPoint, p))
end
function convert(t::Type{AbstractVector}, p::PoincareHalfSpacePoint)
    return convert(t, convert(PoincareBallPoint, p))
end

@doc raw"""
    convert(::Type{HyperboloidTangentVector}, p::PoincareBallPoint, X::PoincareBallTangentVector)
    convert(::Type{AbstractVector}, p::PoincareBallPoint, X::PoincareBallTangentVector)

Convert the [`PoincareBallTangentVector`](@ref) `X` from the tangent space at `p` to a
[`HyperboloidTangentVector`](@ref) by computing the push forward of the isometric map, cf.
[`convert(::Type{HyperboloidPoint}, p::PoincareBallPoint)`](@ref).

The push forward ``π_*(p)`` maps from ``ℝ^n`` to a subspace of ``ℝ^{n+1}``, the formula reads

````math
π_*(p)[X] = \begin{pmatrix}
    \frac{2X_1}{1-\lVert p \rVert^2} + \frac{4}{(1-\lVert p \rVert^2)^2}⟨X,p⟩p_1\\
    ⋮\\
    \frac{2X_n}{1-\lVert p \rVert^2} + \frac{4}{(1-\lVert p \rVert^2)^2}⟨X,p⟩p_n\\
    \frac{4}{(1-\lVert p \rVert^2)^2}⟨X,p⟩
\end{pmatrix}.
````
"""
function convert(
    ::Type{HyperboloidTangentVector},
    p::PoincareBallPoint,
    X::PoincareBallTangentVector,
)
    return HyperboloidTangentVector(convert(AbstractVector, p, X))
end
function convert(
    ::Type{T},
    p::PoincareBallPoint,
    X::PoincareBallTangentVector,
) where {T<:AbstractVector}
    t = (1 - norm(p.value)^2)
    den = 4 * dot(p.value, X.value) / (t^2)
    c1 = (2 / t) .* X.value + den .* p.value
    return vcat(c1, den)
end

@doc raw"""
    convert(
        ::Type{Tuple{HyperboloidPoint,HyperboloidTangentVector}}.
        (p,X)::Tuple{PoincareBallPoint,PoincareBallTangentVector}
    )
    convert(
        ::Type{Tuple{P,T}},
        (p, X)::Tuple{PoincareBallPoint,PoincareBallTangentVector},
    ) where {P<:AbstractVector, T <: AbstractVector}

Convert a [`PoincareBallPoint`](@ref) `p` and a [`PoincareBallTangentVector`](@ref) `X`
to a [`HyperboloidPoint`](@ref) and a [`HyperboloidTangentVector`](@ref) simultaneously,
see [`convert(::Type{HyperboloidPoint}, ::PoincareBallPoint)`](@ref) and
[`convert(::Type{HyperboloidTangentVector}, ::PoincareBallPoint, ::PoincareBallTangentVector)`](@ref)
for the formulae.
"""
function convert(
    ::Type{Tuple{HyperboloidPoint,HyperboloidTangentVector}},
    (p, X)::Tuple{PoincareBallPoint,PoincareBallTangentVector},
)
    return (convert(HyperboloidPoint, p), convert(HyperboloidTangentVector, p, X))
end

@doc raw"""
    convert(::Type{HyperboloidTangentVector}, p::PoincareHalfSpacePoint, X::PoincareHalfSpaceTangentVector)
    convert(::Type{AbstractVector}, p::PoincareHalfSpacePoint, X::PoincareHalfSpaceTangentVector)

convert a point [`PoincareHalfSpaceTangentVector`](@ref) `X` (from ``ℝ^n``) at `p` from the
Poincaré half plane model of the [`Hyperbolic`](@ref) manifold ``\mathcal H^n`` to a
[`HyperboloidTangentVector`](@ref) ``π(p) ∈ ℝ^{n+1}``.

This is done in two steps, namely transforming it to a Poincare ball point and from there further on to a Hyperboloid point.
"""
function convert(
    t::Type{HyperboloidTangentVector},
    p::PoincareHalfSpacePoint,
    X::PoincareHalfSpaceTangentVector,
)
    return convert(
        t,
        convert(Tuple{PoincareBallPoint,PoincareBallTangentVector}, (p, X))...,
    )
end
function convert(
    t::Type{T},
    p::PoincareHalfSpacePoint,
    X::PoincareHalfSpaceTangentVector,
) where {T<:AbstractVector}
    return convert(
        t,
        convert(Tuple{PoincareBallPoint,PoincareBallTangentVector}, (p, X))...,
    )
end

@doc raw"""
    convert(
        ::Type{Tuple{HyperboloidPoint,HyperboloidTangentVector},
        (p,X)::Tuple{PoincareHalfSpacePoint, PoincareHalfSpaceTangentVector}
    )
    convert(
        ::Type{Tuple{T,T},
        (p,X)::Tuple{PoincareHalfSpacePoint, PoincareHalfSpaceTangentVector}
    ) where {T<:AbstractVector}

convert a point [`PoincareHalfSpaceTangentVector`](@ref) `X` (from ``ℝ^n``) at `p` from the
Poincaré half plane model of the [`Hyperbolic`](@ref) manifold ``\mathcal H^n``
to a tuple of a [`HyperboloidPoint`](@ref) and a [`HyperboloidTangentVector`](@ref) ``π(p) ∈ ℝ^{n+1}``
simultaneously.

This is done in two steps, namely transforming it to the Poincare ball model and from there
further on to a Hyperboloid.
"""
function convert(
    t::Type{Tuple{HyperboloidPoint,HyperboloidTangentVector}},
    (p, X)::Tuple{PoincareHalfSpacePoint,PoincareHalfSpaceTangentVector},
)
    return convert(t, convert(Tuple{PoincareBallPoint,PoincareBallTangentVector}, (p, X)))
end

@doc raw"""
    distance(M::Hyperbolic, p, q)
    distance(M::Hyperbolic, p::HyperboloidPoint, q::HyperboloidPoint)

Compute the distance on the [`Hyperbolic`](@ref) `M`, which reads

````math
d_{\mathcal H^n}(p,q) = \operatorname{acosh}( - ⟨p, q⟩_{\mathrm{M}}),
````

where ``⟨⋅,⋅⟩_{\mathrm{M}}`` denotes the [`MinkowskiMetric`](@ref) on the embedding, the [`Lorentz`](@ref)ian manifold,
see for example the extended version [BergmannPerschSteidl:2015:1](@cite) of the paper [BergmannPerschSteidl:2016:1](@cite).
"""
function distance(::Hyperbolic, p, q)
    w = q - p
    m = sqrt(max(0.0, minkowski_metric(w, w)))
    return 2 * asinh(m / 2)
end

embed(M::Hyperbolic, p::HyperboloidPoint) = embed(M, p.value)
embed!(M::Hyperbolic, q, p::HyperboloidPoint) = embed!(M, q, p.value)
function embed(M::Hyperbolic, p::HyperboloidPoint, X::HyperboloidTangentVector)
    return embed(M, p.value, X.value)
end
function embed!(M::Hyperbolic, Y, p::HyperboloidPoint, X::HyperboloidTangentVector)
    return embed!(M, Y, p.value, X.value)
end

function exp_fused!(M::Hyperbolic, q, p, X, t::Number)
    return exp!(M, q, p, t * X)
end
function exp!(M::Hyperbolic, q, p, X)
    vn = sqrt(max(inner(M, p, X, X), 0.0))
    sn = vn == 0 ? one(vn) : sinh(vn) / vn
    q .= cosh(vn) .* p .+ sn .* X
    return q
end

# overwrite the default construction on level 2 (dispatching on basis)
# since this function should not call get_vector (that relies on get_basis itself on H2)
function _get_basis(
    M::Hyperbolic,
    p,
    B::DefaultOrthonormalBasis{ℝ,TangentSpaceType};
    kwargs...,
)
    return get_basis_orthonormal(M, p, ℝ)
end

function get_basis_orthonormal(M::Hyperbolic, p, r::RealNumbers)
    n = get_parameter(M.size)[1]
    V = [
        _hyperbolize(M, p, [i == k ? one(eltype(p)) : zero(eltype(p)) for k in 1:n]) for
        i in 1:n
    ]
    return CachedBasis(DefaultOrthonormalBasis(r), gram_schmidt(M, p, V))
end

function get_basis_diagonalizing(M::Hyperbolic, p, B::DiagonalizingOrthonormalBasis)
    n = manifold_dimension(M)
    X = B.frame_direction
    V = [
        _hyperbolize(M, p, [i == k ? one(eltype(p)) : zero(eltype(p)) for k in 1:n]) for
        i in 1:n
    ]
    κ = -ones(n)
    if norm(M, p, X) != 0
        placed = false
        for i in 1:n
            if abs(inner(M, p, X, V[i])) ≈ norm(M, p, X) # is X a multiple of V[i]?
                V[i] .= V[1]
                V[1] .= X
                placed = true
                break
            end
        end
        if !placed
            V[1] .= X
        end
        κ[1] = 0.0
    end
    V = gram_schmidt(M, p, V; atol=4 * eps(eltype(V[1])))
    return CachedBasis(B, DiagonalizingBasisData(B.frame_direction, κ, V))
end

@doc raw"""
    get_coordinates(M::Hyperbolic, p, X, ::DefaultOrthonormalBasis)

Compute the coordinates of the vector `X` with respect to the orthogonalized version of
the unit vectors from ``ℝ^n``, where ``n`` is the manifold dimension of the [`Hyperbolic`](@ref)
 `M`, putting them into the tangent space at `p` and orthonormalizing them.
"""
get_coordinates(M::Hyperbolic, p, X, ::DefaultOrthonormalBasis)

function get_coordinates_orthonormal(M::Hyperbolic, p, X, r::RealNumbers)
    return get_coordinates(M, p, X, get_basis_orthonormal(M, p, r))
end
function get_coordinates_orthonormal!(M::Hyperbolic, c, p, X, r::RealNumbers)
    c = get_coordinates!(M, c, p, X, get_basis_orthonormal(M, p, r))
    return c
end
function get_coordinates_diagonalizing!(
    M::Hyperbolic,
    c,
    p,
    X,
    B::DiagonalizingOrthonormalBasis,
)
    c = get_coordinates!(M, c, p, X, get_basis_diagonalizing(M, p, B))
    return c
end

@doc raw"""
    get_vector(M::Hyperbolic, p, c, ::DefaultOrthonormalBasis)

Compute the vector from the coordinates with respect to the orthogonalized version of
the unit vectors from ``ℝ^n``, where ``n`` is the manifold dimension of the [`Hyperbolic`](@ref)
 `M`, putting them into the tangent space at `p` and orthonormalizing them.
"""
get_vector(M::Hyperbolic, p, c, ::DefaultOrthonormalBasis)

function get_vector_orthonormal!(M::Hyperbolic, X, p, c, r::RealNumbers)
    X = get_vector!(M, X, p, c, get_basis(M, p, DefaultOrthonormalBasis(r)))
    return X
end
function get_vector!(M::Hyperbolic, X, p, c, B::DiagonalizingOrthonormalBasis)
    X = get_vector!(M, X, p, c, get_basis(M, p, B))
    return X
end

@doc raw"""
    _hyperbolize(M, q)

Given the [`Hyperbolic`](@ref)`(n)` manifold using the hyperboloid model, a point from the
``q\in ℝ^n`` can be set onto the manifold by computing its last component such that for the
resulting `p` we have that its [`minkowski_metric`](@ref) is ``⟨p,p⟩_{\mathrm{M}} = - 1``,
i.e. ``p_{n+1} = \sqrt{\lVert q \rVert^2 - 1}``
"""
_hyperbolize(::Hyperbolic, q) = vcat(q, sqrt(norm(q)^2 + 1))

@doc raw"""
    _hyperbolize(M, p, Y)

Given the [`Hyperbolic`](@ref)`(n)` manifold using the hyperboloid model and a point `p`
thereon, we can put a vector ``Y\in ℝ^n``  into the tangent space by computing its last
component such that for the
resulting `p` we have that its [`minkowski_metric`](@ref) is ``⟨p,X⟩_{\mathrm{M}} = 0``,
i.e. ``X_{n+1} = \frac{⟨\tilde p, Y⟩}{p_{n+1}}``, where ``\tilde p = (p_1,\ldots,p_n)``.
"""
_hyperbolize(::Hyperbolic, p, Y) = vcat(Y, dot(p[1:(end - 1)], Y) / p[end])

@doc raw"""
    inner(M::Hyperbolic, p, X, Y)
    inner(M::Hyperbolic, p::HyperboloidPoint, X::HyperboloidTangentVector, Y::HyperboloidTangentVector)

Cmpute the inner product in the Hyperboloid model, i.e. the [`minkowski_metric`](@ref) in
the embedding. The formula reads

````math
g_p(X,Y) = ⟨X,Y⟩_{\mathrm{M}} = -X_{n}Y_{n} + \displaystyle\sum_{k=1}^{n-1} X_kY_k.
````
This employs the metric of the embedding, see [`Lorentz`](@ref) space,
see for example the extended version [BergmannPerschSteidl:2015:1](@cite) of the paper [BergmannPerschSteidl:2016:1](@cite).
"""
inner(M::Hyperbolic, p, X, Y)

function log!(M::Hyperbolic, X, p, q)
    d = distance(M, p, q)
    s = sinh(d)
    w = s == 0 ? one(s) : d / s
    project!(M, X, p, w .* q)
    return X
end

function minkowski_metric(a::HyperboloidPoint, b::HyperboloidPoint)
    return minkowski_metric(a.value, b.value)
end
function minkowski_metric(a::HyperboloidTangentVector, b::HyperboloidPoint)
    return minkowski_metric(a.value, b.value)
end
function minkowski_metric(a::HyperboloidPoint, b::HyperboloidTangentVector)
    return minkowski_metric(a.value, b.value)
end
function minkowski_metric(a::HyperboloidTangentVector, b::HyperboloidTangentVector)
    return minkowski_metric(a.value, b.value)
end

function project(::Hyperbolic, p::HyperboloidPoint, X)
    return HyperboloidTangentVector(X .+ minkowski_metric(p.value, X) .* p.value)
end

project!(::Hyperbolic, Y, p, X) = (Y .= X .+ minkowski_metric(p, X) .* p)
function project!(::Hyperbolic, Y::HyperboloidTangentVector, p::HyperboloidPoint, X)
    return (Y.value .= X .+ minkowski_metric(p.value, X) .* p.value)
end

function Random.rand!(
    rng::AbstractRNG,
    M::Hyperbolic,
    pX;
    vector_at=nothing,
    σ::Real=one(eltype(pX)),
)
    N = get_parameter(M.size)[1]
    if vector_at === nothing
        a = randn(rng, N)
        f = 1 + σ * abs(randn(rng))
        pX[firstindex(pX):(end - 1)] .= a .* sqrt(f^2 - 1) / norm(a)
        pX[end] = f
    else
        Y = σ * randn(rng, eltype(vector_at), size(vector_at))
        project!(M, pX, vector_at, Y)
    end
    return pX
end

function parallel_transport_to!(::Hyperbolic, Y, p, X, q)
    return copyto!(
        Y,
        X .+ minkowski_metric(q, X) ./ (1 - minkowski_metric(p, q)) .* (p + q),
    )
end

@doc raw"""
    Y = riemannian_Hessian(M::Hyperbolic, p, G, H, X)
    riemannian_Hessian!(M::Hyperbolic, Y, p, G, H, X)

Compute the Riemannian Hessian ``\operatorname{Hess} f(p)[X]`` given the
Euclidean gradient ``∇ f(\tilde p)`` in `G` and the Euclidean Hessian ``∇^2 f(\tilde p)[\tilde X]`` in `H`,
where ``\tilde p, \tilde X`` are the representations of ``p,X`` in the embedding,.

Let ``\mathbf{g} = \mathbf{g}^{-1} = \operatorname{diag}(1,...,1,-1)``.
Then using Remark 4.1 [Nguyen:2023](@cite) the formula reads

```math
\operatorname{Hess}f(p)[X]
=
\operatorname{proj}_{T_p\mathcal M}\bigl(
    \mathbf{g}^{-1}\nabla^2f(p)[X] + X⟨p,\mathbf{g}^{-1}∇f(p)⟩_p
\bigr).
```
"""
riemannian_Hessian(M::Hyperbolic, p, G, H, X)

function riemannian_Hessian!(M::Hyperbolic, Y, p, G, H, X)
    g = copy(G)
    g[end] *= -1 # = g^{-1}G
    h = copy(H)
    H[end] *= -1 # = g^{-1}H
    project!(M, Y, p, h .+ dot(p, g) .* X)
    return Y
end
@doc raw"""
    volume_density(M::Hyperbolic, p, X)

Compute volume density function of the hyperbolic manifold. The formula reads
``(\sinh(\lVert X\rVert)/\lVert X\rVert)^(n-1)`` where `n` is the dimension of `M`.
It is derived from Eq. (4.1) in[ChevallierLiLuDunson:2022](@cite).
"""
function volume_density(M::Hyperbolic, p, X)
    Xnorm = norm(X)
    if Xnorm == 0
        return one(eltype(X))
    else
        n = manifold_dimension(M) - 1
        return (sinh(Xnorm) / Xnorm)^n
    end
end
