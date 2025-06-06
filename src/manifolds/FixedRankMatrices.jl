@doc raw"""
    FixedRankMatrices{T,𝔽} <: AbstractDecoratorManifold{𝔽}

The manifold of ``m×n`` real-valued or complex-valued matrices of fixed rank ``k``, i.e.
````math
\bigl\{ p ∈ 𝔽^{m×n}\ \big|\ \operatorname{rank}(p) = k\bigr\},
````
where ``𝔽 ∈ \{ℝ,ℂ\}`` and the rank is the number of linearly independent columns of a matrix.

# Representation with 3 matrix factors

A point ``p ∈ \mathcal M`` can be stored using unitary matrices ``U ∈ 𝔽^{m×k}``, ``V ∈ 𝔽^{n×k}`` as well as the ``k``
singular values of ``p = U_p S V_p^\mathrm{H}``, where ``⋅^{\mathrm{H}}`` denotes the complex conjugate transpose or
Hermitian. In other words, ``U`` and ``V`` are from the manifolds [`Stiefel`](@ref)`(m,k,𝔽)` and [`Stiefel`](@ref)`(n,k,𝔽)`,
respectively; see [`SVDMPoint`](@ref) for details.

The tangent space ``T_p \mathcal M`` at a point ``p ∈ \mathcal M`` with ``p=U_p S V_p^\mathrm{H}``
is given by
````math
T_p\mathcal M = \bigl\{ U_p M V_p^\mathrm{H} + U_X V_p^\mathrm{H} + U_p V_X^\mathrm{H} :
    M  ∈ 𝔽^{k×k},
    U_X  ∈ 𝔽^{m×k},
    V_X  ∈ 𝔽^{n×k}
    \text{ s.t. }
    U_p^\mathrm{H}U_X = 0_k,
    V_p^\mathrm{H}V_X = 0_k
\bigr\},
````
where ``0_k`` is the ``k×k`` zero matrix. See [`UMVTangentVector`](@ref) for details.

The (default) metric of this manifold is obtained by restricting the metric
on ``ℝ^{m×n}`` to the tangent bundle [Vandereycken:2013](@cite).

# Constructor
    FixedRankMatrices(m, n, k[, field=ℝ])

Generate the manifold of `m`-by-`n` (`field`-valued) matrices of rank `k`.
"""
struct FixedRankMatrices{T,𝔽} <: AbstractDecoratorManifold{𝔽}
    size::T
end

function FixedRankMatrices(
    m::Int,
    n::Int,
    k::Int,
    field::AbstractNumbers=ℝ;
    parameter::Symbol=:type,
)
    size = wrap_type_parameter(parameter, (m, n, k))
    return FixedRankMatrices{typeof(size),field}(size)
end

function active_traits(f, ::FixedRankMatrices, args...)
    return merge_traits(IsEmbeddedManifold(), IsDefaultMetric(EuclideanMetric()))
end

@doc raw"""
    SVDMPoint <: AbstractManifoldPoint

A point on a certain manifold, where the data is stored in a svd like fashion,
i.e. in the form ``USV^\mathrm{H}``, where this structure stores ``U``, ``S`` and
``V^\mathrm{H}``. The storage might also be shortened to just ``k`` singular values
and accordingly shortened ``U`` (columns) and ``V^\mathrm{H}`` (rows).

# Constructors
* `SVDMPoint(A)` for a matrix `A`, stores its svd factors (i.e. implicitly ``k=\min\{m,n\}``)
* `SVDMPoint(S)` for an `SVD` object, stores its svd factors (i.e. implicitly ``k=\min\{m,n\}``)
* `SVDMPoint(U,S,Vt)` for the svd factors to initialize the `SVDMPoint`` (i.e. implicitly ``k=\min\{m,n\}``)
* `SVDMPoint(A,k)` for a matrix `A`, stores its svd factors shortened to the
  best rank ``k`` approximation
* `SVDMPoint(S,k)` for an `SVD` object, stores its svd factors shortened to the
  best rank ``k`` approximation
* `SVDMPoint(U,S,Vt,k)` for the svd factors to initialize the `SVDMPoint`,
  stores its svd factors shortened to the best rank ``k`` approximation
"""
struct SVDMPoint{TU<:AbstractMatrix,TS<:AbstractVector,TVt<:AbstractMatrix} <:
       AbstractManifoldPoint
    U::TU
    S::TS
    Vt::TVt
end
SVDMPoint(A::AbstractMatrix) = SVDMPoint(svd(A))
SVDMPoint(S::SVD) = SVDMPoint(S.U, S.S, S.Vt)
SVDMPoint(A::Matrix, k::Int) = SVDMPoint(svd(A), k)
SVDMPoint(S::SVD, k::Int) = SVDMPoint(S.U, S.S, S.Vt, k)
SVDMPoint(U, S, Vt, k::Int) = SVDMPoint(U[:, 1:k], S[1:k], Vt[1:k, :])
Base.:(==)(x::SVDMPoint, y::SVDMPoint) = (x.U == y.U) && (x.S == y.S) && (x.Vt == y.Vt)
Base.eltype(p::SVDMPoint) = Base.eltype(p.S)

@doc raw"""
    UMVTangentVector <: AbstractTangentVector

A tangent vector that can be described as a product ``U_p M V_p^\mathrm{H} + U_X V_p^\mathrm{H} + U_p V_X^\mathrm{H}``,
where ``X = U_X S V_X^\mathrm{H}`` is its base point, see for example [`FixedRankMatrices`](@ref).

The base point ``p`` is required for example embedding this point, but it is not stored.
The fields of thie tangent vector are `U` for ``U_X``, `M` and `Vt` to store ``V_X^\mathrm{H}``

# Constructors
* `UMVTangentVector(U,M,Vt)` store umv factors to initialize the `UMVTangentVector`
* `UMVTangentVector(U,M,Vt,k)` store the umv factors after shortening them down to
  inner dimensions `k`.
"""
struct UMVTangentVector{TU<:AbstractMatrix,TM<:AbstractMatrix,TVt<:AbstractMatrix} <:
       AbstractTangentVector
    U::TU
    M::TM
    Vt::TVt
end

UMVTangentVector(U, M, Vt, k::Int) = UMVTangentVector(U[:, 1:k], M[1:k, 1:k], Vt[1:k, :])

# here the division in M corrects for the first factor in UMV + x.U*Vt + U*x.Vt, where x is the base point to v.
Base.:*(v::UMVTangentVector, s::Number) = UMVTangentVector(v.U * s, v.M * s, v.Vt * s)
Base.:*(s::Number, v::UMVTangentVector) = UMVTangentVector(s * v.U, s * v.M, s * v.Vt)
Base.:/(v::UMVTangentVector, s::Number) = UMVTangentVector(v.U / s, v.M / s, v.Vt / s)
Base.:\(s::Number, v::UMVTangentVector) = UMVTangentVector(s \ v.U, s \ v.M, s \ v.Vt)
function Base.:+(v::UMVTangentVector, w::UMVTangentVector)
    return UMVTangentVector(v.U + w.U, v.M + w.M, v.Vt + w.Vt)
end
function Base.:-(v::UMVTangentVector, w::UMVTangentVector)
    return UMVTangentVector(v.U - w.U, v.M - w.M, v.Vt - w.Vt)
end
Base.:-(v::UMVTangentVector) = UMVTangentVector(-v.U, -v.M, -v.Vt)
Base.:+(v::UMVTangentVector) = UMVTangentVector(v.U, v.M, v.Vt)
function Base.:(==)(v::UMVTangentVector, w::UMVTangentVector)
    return (v.U == w.U) && (v.M == w.M) && (v.Vt == w.Vt)
end

# Move to Base when name is established – i.e. used in more than one manifold
# |/---
"""
    OrthographicRetraction <: AbstractRetractionMethod

Retractions that are related to orthographic projections, which was first
used in [AbsilMalick:2012](@cite).
"""
struct OrthographicRetraction <: AbstractRetractionMethod end

"""
    OrthographicInverseRetraction <: AbstractInverseRetractionMethod

Retractions that are related to orthographic projections, which was first
used in [AbsilMalick:2012](@cite).
"""
struct OrthographicInverseRetraction <: AbstractInverseRetractionMethod end

# Layer II
function _inverse_retract!(
    M::AbstractManifold,
    X,
    p,
    q,
    ::OrthographicInverseRetraction;
    kwargs...,
)
    return inverse_retract_orthographic!(M, X, p, q; kwargs...)
end

# Layer III
"""
    inverse_retract_orthographic!(M::AbstractManifold, X, p, q)

Compute the in-place variant of the [`OrthographicInverseRetraction`](@ref).
"""
inverse_retract_orthographic!(M::AbstractManifold, X, p, q)

## Layer II
function ManifoldsBase._retract_fused!(
    M::AbstractManifold,
    q,
    p,
    X,
    t::Number,
    ::OrthographicRetraction;
    kwargs...,
)
    return retract_orthographic_fused!(M, q, p, X, t; kwargs...)
end
function ManifoldsBase._retract!(
    M::AbstractManifold,
    q,
    p,
    X,
    ::OrthographicRetraction;
    kwargs...,
)
    return retract_orthographic!(M, q, p, X; kwargs...)
end
## Layer III

"""
    retract_orthographic!(M::AbstractManifold, q, p, X)

Compute the in-place variant of the [`OrthographicRetraction`](@ref).
"""
retract_orthographic!(M::AbstractManifold, q, p, X)

# \|---

allocate(p::SVDMPoint) = SVDMPoint(allocate(p.U), allocate(p.S), allocate(p.Vt))
function allocate(p::SVDMPoint, ::Type{T}) where {T}
    return SVDMPoint(allocate(p.U, T), allocate(p.S, T), allocate(p.Vt, T))
end
function allocate(X::UMVTangentVector)
    return UMVTangentVector(allocate(X.U), allocate(X.M), allocate(X.Vt))
end
function allocate(X::UMVTangentVector, ::Type{T}) where {T}
    return UMVTangentVector(allocate(X.U, T), allocate(X.M, T), allocate(X.Vt, T))
end

function allocate_result(M::FixedRankMatrices, ::typeof(inverse_retract), p, q)
    return zero_vector(M, p)
end
function allocate_result(M::FixedRankMatrices, ::typeof(project), X, p, vals...)
    m, n, k = get_parameter(M.size)
    # vals are p and X, so we can use their fields to set up those of the UMVTangentVector
    return UMVTangentVector(allocate(p.U, m, k), allocate(p.S, k, k), allocate(p.Vt, k, n))
end

Base.copy(v::UMVTangentVector) = UMVTangentVector(copy(v.U), copy(v.M), copy(v.Vt))

# Tuple-like broadcasting of UMVTangentVector

function Broadcast.BroadcastStyle(::Type{<:UMVTangentVector})
    return Broadcast.Style{UMVTangentVector}()
end
function Broadcast.BroadcastStyle(
    ::Broadcast.AbstractArrayStyle{0},
    b::Broadcast.Style{UMVTangentVector},
)
    return b
end

function Broadcast.instantiate(
    bc::Broadcast.Broadcasted{Broadcast.Style{UMVTangentVector},Nothing},
)
    return bc
end
function Broadcast.instantiate(bc::Broadcast.Broadcasted{Broadcast.Style{UMVTangentVector}})
    Broadcast.check_broadcast_axes(bc.axes, bc.args...)
    return bc
end

Broadcast.broadcastable(v::UMVTangentVector) = v

@inline function Base.copy(bc::Broadcast.Broadcasted{Broadcast.Style{UMVTangentVector}})
    return UMVTangentVector(
        @inbounds(Broadcast._broadcast_getindex(bc, Val(:U))),
        @inbounds(Broadcast._broadcast_getindex(bc, Val(:M))),
        @inbounds(Broadcast._broadcast_getindex(bc, Val(:Vt))),
    )
end

Base.@propagate_inbounds function Broadcast._broadcast_getindex(
    v::UMVTangentVector,
    ::Val{I},
) where {I}
    return getfield(v, I)
end

Base.axes(::UMVTangentVector) = ()

@inline function Base.copyto!(
    dest::UMVTangentVector,
    bc::Broadcast.Broadcasted{Broadcast.Style{UMVTangentVector}},
)
    # Performance optimization: broadcast!(identity, dest, A) is equivalent to copyto!(dest, A) if indices match
    if bc.f === identity && bc.args isa Tuple{UMVTangentVector} # only a single input argument to broadcast!
        A = bc.args[1]
        return copyto!(dest, A)
    end
    bc′ = Broadcast.preprocess(dest, bc)
    copyto!(dest.U, Broadcast._broadcast_getindex(bc′, Val(:U)))
    copyto!(dest.M, Broadcast._broadcast_getindex(bc′, Val(:M)))
    copyto!(dest.Vt, Broadcast._broadcast_getindex(bc′, Val(:Vt)))
    return dest
end

@doc raw"""
    check_point(M::FixedRankMatrices, p; kwargs...)

Check whether the matrix or [`SVDMPoint`](@ref) `x` ids a valid point on the
[`FixedRankMatrices`](@ref) `M`, i.e. is an `m`-by`n` matrix of
rank `k`. For the [`SVDMPoint`](@ref) the internal representation also has to have the right
shape, i.e. `p.U` and `p.Vt` have to be unitary. The keyword arguments are passed to the
`rank` function that verifies the rank of `p`.
"""
function check_point(M::FixedRankMatrices, p; kwargs...)
    m, n, k = get_parameter(M.size)
    r = rank(p; kwargs...)
    s = "The point $(p) does not lie on $(M), "
    if r > k
        return DomainError(r, string(s, "since its rank is too large ($(r))."))
    end
    return nothing
end
function check_point(M::FixedRankMatrices, p::SVDMPoint; kwargs...)
    m, n, k = get_parameter(M.size)
    s = "The point $(p) does not lie on $(M), "
    if !isapprox(p.U' * p.U, one(zeros(k, k)); kwargs...)
        return DomainError(
            norm(p.U' * p.U - one(zeros(k, k))),
            string(s, " since U is not orthonormal/unitary."),
        )
    end
    if !isapprox(p.Vt * p.Vt', one(zeros(k, k)); kwargs...)
        return DomainError(
            norm(p.Vt * p.Vt' - one(zeros(k, k))),
            string(s, " since V is not orthonormal/unitary."),
        )
    end
    return nothing
end

function check_size(M::FixedRankMatrices, p::SVDMPoint)
    m, n, k = get_parameter(M.size)
    if (size(p.U) != (m, k)) || (length(p.S) != k) || (size(p.Vt) != (k, n))
        return DomainError(
            [size(p.U)..., length(p.S), size(p.Vt)...],
            "The point $(p) does not lie on $(M) since the dimensions do not fit (expected $(n)x$(m) rank $(k) got $(size(p.U,1))x$(size(p.Vt,2)) rank $(size(p.S,1)).",
        )
    end
end
function check_size(M::FixedRankMatrices, p)
    m, n, k = get_parameter(M.size)
    pS = svd(p)
    if (size(pS.U) != (m, k)) || (length(pS.S) != k) || (size(pS.Vt) != (k, n))
        return DomainError(
            [size(pS.U)..., length(pS.S), size(pS.Vt)...],
            "The point $(p) does not lie on $(M) since the dimensions do not fit (expected $(n)x$(m) rank $(k) got $(size(pS.U,1))x$(size(pS.Vt,2)) rank $(size(pS.S,1)).",
        )
    end
end
function check_size(M::FixedRankMatrices, p, X::UMVTangentVector)
    m, n, k = get_parameter(M.size)
    if (size(X.U) != (m, k)) || (size(X.Vt) != (k, n)) || (size(X.M) != (k, k))
        return DomainError(
            cat(size(X.U), size(X.M), size(X.Vt), dims=1),
            "The tangent vector $(X) is not a tangent vector to $(p) on $(M), since matrix dimensions do not agree (expected $(m)x$(k), $(k)x$(k), $(k)x$(n)).",
        )
    end
end

@doc raw"""
    check_vector(M:FixedRankMatrices, p, X; kwargs...)

Check whether the tangent [`UMVTangentVector`](@ref) `X` is from the tangent space of the [`SVDMPoint`](@ref) `p` on the
[`FixedRankMatrices`](@ref) `M`, i.e. that `v.U` and `v.Vt` are (columnwise) orthogonal to `x.U` and `x.Vt`,
respectively, and its dimensions are consistent with `p` and `X.M`, i.e. correspond to `m`-by-`n` matrices of rank `k`.
"""
function check_vector(
    M::FixedRankMatrices,
    p::SVDMPoint,
    X::UMVTangentVector;
    atol::Real=sqrt(prod(representation_size(M)) * eps(float(eltype(p.U)))),
    kwargs...,
)
    m, n, k = get_parameter(M.size)
    if !isapprox(X.U' * p.U, zeros(k, k); atol=atol, kwargs...)
        return DomainError(
            norm(X.U' * p.U - zeros(k, k)),
            "The tangent vector $(X) is not a tangent vector to $(p) on $(M) since v.U'x.U is not zero. ",
        )
    end
    if !isapprox(X.Vt * p.Vt', zeros(k, k); atol=atol, kwargs...)
        return DomainError(
            norm(X.Vt * p.Vt - zeros(k, k)),
            "The tangent vector $(X) is not a tangent vector to $(p) on $(M) since v.V'x.V is not zero.",
        )
    end
    return nothing
end

function Base.copyto!(p::SVDMPoint, q::SVDMPoint)
    copyto!(p.U, q.U)
    copyto!(p.S, q.S)
    copyto!(p.Vt, q.Vt)
    return p
end
function Base.copyto!(X::UMVTangentVector, Y::UMVTangentVector)
    copyto!(X.U, Y.U)
    copyto!(X.M, Y.M)
    copyto!(X.Vt, Y.Vt)
    return X
end

"""
    default_inverse_retraction_method(M::FixedRankMatrices)

Return [`PolarInverseRetraction`](@extref `ManifoldsBase.PolarInverseRetraction`)
as the default inverse retraction for the [`FixedRankMatrices`](@ref) manifold.
"""
default_inverse_retraction_method(::FixedRankMatrices) = PolarInverseRetraction()

"""
    default_retraction_method(M::FixedRankMatrices)

Return [`PolarRetraction`](@extref `ManifoldsBase.PolarRetraction`)
as the default retraction for the [`FixedRankMatrices`](@ref) manifold.
"""
default_retraction_method(::FixedRankMatrices) = PolarRetraction()

"""
    default_vector_transport_method(M::FixedRankMatrices)

Return the [`ProjectionTransport`](@extref `ManifoldsBase.ProjectionTransport`)
as the default vector transport method for the [`FixedRankMatrices`](@ref) manifold.
"""
default_vector_transport_method(::FixedRankMatrices) = ProjectionTransport()

@doc raw"""
    embed(::FixedRankMatrices, p::SVDMPoint)

Embed the point `p` from its `SVDMPoint` representation into the set of ``m×n`` matrices
by computing ``USV^{\mathrm{H}}``.
"""
function embed(::FixedRankMatrices, p::SVDMPoint)
    return p.U * Diagonal(p.S) * p.Vt
end

function embed!(::FixedRankMatrices, q, p::SVDMPoint)
    return mul!(q, p.U * Diagonal(p.S), p.Vt)
end

@doc raw"""
    embed(M::FixedRankMatrices, p, X)

Embed the tangent vector `X` at point `p` in `M` from
its [`UMVTangentVector`](@ref) representation  into the set of ``m×n`` matrices.

The formula reads
```math
U_pMV_p^{\mathrm{H}} + U_XV_p^{\mathrm{H}} + U_pV_X^{\mathrm{H}}
```
"""
function embed(::FixedRankMatrices, p::SVDMPoint, X::UMVTangentVector)
    return (p.U * X.M .+ X.U) * p.Vt + p.U * X.Vt
end

function embed!(::FixedRankMatrices, Y, p::SVDMPoint, X::UMVTangentVector)
    tmp = p.U * X.M
    tmp .+= X.U
    mul!(Y, tmp, p.Vt)
    return mul!(Y, p.U, X.Vt, true, true)
end

function get_embedding(::FixedRankMatrices{TypeParameter{Tuple{m,n,k}},𝔽}) where {m,n,k,𝔽}
    return Euclidean(m, n; field=𝔽)
end
function get_embedding(M::FixedRankMatrices{Tuple{Int,Int,Int},𝔽}) where {𝔽}
    m, n, k = get_parameter(M.size)
    return Euclidean(m, n; field=𝔽, parameter=:field)
end

"""
    injectivity_radius(::FixedRankMatrices)

Return the incjectivity radius of the manifold of [`FixedRankMatrices`](@ref), i.e. 0.
See [HosseiniUschmajew:2017](@cite).
"""
function injectivity_radius(::FixedRankMatrices)
    return 0.0
end

@doc raw"""
    inner(M::FixedRankMatrices, p::SVDMPoint, X::UMVTangentVector, Y::UMVTangentVector)

Compute the inner product of `X` and `Y` in the tangent space of `p` on the [`FixedRankMatrices`](@ref) `M`,
which is inherited from the embedding, i.e. can be computed using `dot` on the elements (`U`, `Vt`, `M`) of `X` and `Y`.
"""
function inner(::FixedRankMatrices, x::SVDMPoint, v::UMVTangentVector, w::UMVTangentVector)
    return dot(v.U, w.U) + dot(v.M, w.M) + dot(v.Vt, w.Vt)
end

@doc raw"""
    inverse_retract(M, p, q, ::OrthographicInverseRetraction)

Compute the orthographic inverse retraction [`FixedRankMatrices`](@ref) `M` by computing

```math
    X = P_{T_{p}M}(q - p) = qVV^\mathrm{T} + UU^{\mathrm{T}}q - UU^{\mathrm{T}}qVV^{\mathrm{T}} - p,
```
where ``p`` is a [`SVDMPoint`](@ref)`(U,S,Vt)` and ``P_{T_{p}M}`` is the [`project`](@ref)ion
onto the tangent space at ``p``.

For more details, see [AbsilOseledets:2014](@cite).
"""
inverse_retract(::FixedRankMatrices, ::Any, ::Any, ::OrthographicInverseRetraction)

function inverse_retract_orthographic!(
    M::FixedRankMatrices,
    X::UMVTangentVector,
    p::SVDMPoint,
    q::SVDMPoint,
)
    project!(M, X, p, embed(M, q) - embed(M, p))
    return X
end

function _isapprox(::FixedRankMatrices, p::SVDMPoint, q::SVDMPoint; kwargs...)
    return isapprox(p.U * Diagonal(p.S) * p.Vt, q.U * Diagonal(q.S) * q.Vt; kwargs...)
end
function _isapprox(
    ::FixedRankMatrices,
    p::SVDMPoint,
    X::UMVTangentVector,
    Y::UMVTangentVector;
    kwargs...,
)
    return isapprox(
        p.U * X.M * p.Vt + X.U * p.Vt + p.U * X.Vt,
        p.U * Y.M * p.Vt + Y.U * p.Vt + p.U * Y.Vt;
        kwargs...,
    )
end

"""
    is_flat(::FixedRankMatrices)

Return false. [`FixedRankMatrices`](@ref) is not a flat manifold.
"""
is_flat(M::FixedRankMatrices) = false

function number_eltype(p::SVDMPoint)
    return typeof(one(eltype(p.U)) + one(eltype(p.S)) + one(eltype(p.Vt)))
end
function number_eltype(X::UMVTangentVector)
    return typeof(one(eltype(X.U)) + one(eltype(X.M)) + one(eltype(X.Vt)))
end

@doc raw"""
    manifold_dimension(M::FixedRankMatrices)

Return the manifold dimension for the `𝔽`-valued [`FixedRankMatrices`](@ref) `M`
of dimension `m`x`n` of rank `k`, namely

````math
\dim(\mathcal M) = k(m + n - k) \dim_ℝ 𝔽,
````

where ``\dim_ℝ 𝔽`` is the [`real_dimension`](@extref `ManifoldsBase.real_dimension-Tuple{ManifoldsBase.AbstractNumbers}`) of `𝔽`.
"""
function manifold_dimension(M::FixedRankMatrices{<:Any,𝔽}) where {𝔽}
    m, n, k = get_parameter(M.size)
    return (m + n - k) * k * real_dimension(𝔽)
end

function Base.one(p::SVDMPoint)
    m = size(p.U, 1)
    n = size(p.Vt, 2)
    k = length(p.S)
    return SVDMPoint(one(zeros(m, m))[:, 1:k], one.(p.S), one(zeros(n, n))[1:k, :], k)
end

@doc raw"""
    project(M, p, A)

Project the matrix ``A ∈ ℝ^{m,n}`` or from the embedding the tangent space at ``p`` on the [`FixedRankMatrices`](@ref) `M`,
further decomposing the result into ``X=UMV^\mathrm{H}``, i.e. a [`UMVTangentVector`](@ref).
"""
project(::FixedRankMatrices, ::Any, ::Any)

function project!(::FixedRankMatrices, Y::UMVTangentVector, p::SVDMPoint, A::AbstractMatrix)
    av = A * (p.Vt')
    uTav = p.U' * av
    aTu = A' * p.U
    Y.M .= uTav
    Y.U .= A * p.Vt' - p.U * uTav
    Y.Vt .= (aTu - p.Vt' * uTav')'
    return Y
end

@doc raw"""
    Random.rand(M::FixedRankMatrices; vector_at=nothing, kwargs...)

If `vector_at` is `nothing`, return a random point on the [`FixedRankMatrices`](@ref)
manifold. The orthogonal matrices are sampled from the [`Stiefel`](@ref) manifold
and the singular values are sampled uniformly at random.

If `vector_at` is not `nothing`, generate a random tangent vector in the tangent space of
the point `vector_at` on the `FixedRankMatrices` manifold `M`.
"""
function Random.rand(M::FixedRankMatrices; vector_at=nothing, kwargs...)
    return rand(Random.default_rng(), M; vector_at=vector_at, kwargs...)
end
function Random.rand(rng::AbstractRNG, M::FixedRankMatrices; vector_at=nothing, kwargs...)
    m, n, k = get_parameter(M.size)
    if vector_at === nothing
        p = SVDMPoint(
            Matrix{Float64}(undef, m, k),
            Vector{Float64}(undef, k),
            Matrix{Float64}(undef, k, n),
        )
        return rand!(rng, M, p; kwargs...)
    else
        X = UMVTangentVector(
            Matrix{Float64}(undef, m, k),
            Matrix{Float64}(undef, k, k),
            Matrix{Float64}(undef, k, n),
        )
        return rand!(rng, M, X; vector_at, kwargs...)
    end
end

function Random.rand!(
    rng::AbstractRNG,
    M::FixedRankMatrices,
    pX;
    vector_at=nothing,
    kwargs...,
)
    m, n, k = get_parameter(M.size)
    if vector_at === nothing
        U = rand(rng, Stiefel(m, k); kwargs...)
        S = sort(rand(rng, k); rev=true)
        V = rand(rng, Stiefel(n, k); kwargs...)
        copyto!(pX, SVDMPoint(U, S, V'))
    else
        Up = randn(rng, m, k)
        Vp = randn(rng, n, k)
        A = randn(rng, k, k)
        copyto!(
            pX,
            UMVTangentVector(
                Up - vector_at.U * vector_at.U' * Up,
                A,
                Vp' - Vp' * vector_at.Vt' * vector_at.Vt,
            ),
        )
    end
    return pX
end

@doc raw"""
    representation_size(M::FixedRankMatrices)

Return the element size of a point on the [`FixedRankMatrices`](@ref) `M`, i.e.
the size of matrices on this manifold ``(m,n)``.
"""
function representation_size(M::FixedRankMatrices)
    m, n, k = get_parameter(M.size)
    return (m, n)
end

@doc raw"""
    retract(M::FixedRankMatrices, p, X, ::OrthographicRetraction)

Compute the OrthographicRetraction on the [`FixedRankMatrices`](@ref) `M` by finding
the nearest point to ``p + X`` in

```math
    p + X + N_{p}\mathcal M \cap \mathcal M
```

where ``N_{p}\mathcal M `` is the Normal Space of ``T_{p}\mathcal M ``.

If ``X`` is sufficiently small, then the nearest such point is unique and can be expressed by

```math
    q = (U(S + M) + U_{p})(S + M)^{-1}((S + M)V^{\mathrm{T}} + V^{\mathrm{T}}_{p}),
```

where ``p`` is a [`SVDMPoint`](@ref)`(U,S,Vt)` and ``X`` is an [`UMVTangentVector`](@ref)`(Up,M,Vtp)`.

For more details, see [AbsilOseledets:2014](@cite).
"""
retract(::FixedRankMatrices, ::Any, ::Any, ::OrthographicRetraction)

function retract_orthographic!(
    M::FixedRankMatrices,
    q::SVDMPoint,
    p::SVDMPoint,
    X::UMVTangentVector,
)
    return retract_orthographic_fused!(M, q, p, X, one(eltype(p)))
end

function retract_orthographic_fused!(
    M::FixedRankMatrices,
    q::SVDMPoint,
    p::SVDMPoint,
    X::UMVTangentVector,
    t::Number,
)
    m, n, k = get_parameter(M.size)
    tX = t * X
    QU, RU = qr(p.U * (diagm(p.S) + tX.M) + tX.U)
    QV, RV = qr(p.Vt' * (diagm(p.S) + tX.M') + tX.Vt')

    Uk, Sk, Vtk = svd(RU * inv(diagm(p.S) + tX.M) * RV')

    mul!(q.U, QU[:, 1:k], Uk)
    q.S .= Sk[1:k]
    mul!(q.Vt, Vtk, QV[:, 1:k]')

    return q
end

@doc raw"""
    retract(M, p, X, ::PolarRetraction)

Compute an SVD-based retraction on the [`FixedRankMatrices`](@ref) `M` by computing
````math
    q = U_kS_kV_k^\mathrm{H},
````
where ``U_k S_k V_k^\mathrm{H}`` is the shortened singular value decomposition ``USV^\mathrm{H}=p+X``,
in the sense that ``S_k`` is the diagonal matrix of size ``k×k`` with the ``k`` largest
singular values and ``U`` and ``V`` are shortened accordingly.
"""
retract(::FixedRankMatrices, ::Any, ::Any, ::PolarRetraction)

function retract_polar!(
    M::FixedRankMatrices,
    q::SVDMPoint,
    p::SVDMPoint,
    X::UMVTangentVector,
)
    return ManifoldsBase.retract_polar_fused!(M, q, p, X, one(eltype(p.S)))
end

function ManifoldsBase.retract_polar_fused!(
    M::FixedRankMatrices,
    q::SVDMPoint,
    p::SVDMPoint,
    X::UMVTangentVector,
    t::Number,
)
    m, n, k = get_parameter(M.size)
    tX = t * X
    QU, RU = qr([p.U tX.U])
    QV, RV = qr([p.Vt' tX.Vt'])

    # Compute T = svd(RU * [diagm(p.S) + X.M I; I zeros(k, k)] * RV')
    @views begin # COV_EXCL_LINE
        RU11 = RU[:, 1:k]
        RU12 = RU[:, (k + 1):(2 * k)]
        RV11 = RV[:, 1:k]
        RV12 = RV[:, (k + 1):(2 * k)]
    end
    tmp = RU11 .* p.S' .+ RU12
    mul!(tmp, RU11, tX.M, true, true)
    tmp2 = tmp * RV11'
    mul!(tmp2, RU11, RV12', true, true)
    T = svd(tmp2)

    mul!(q.U, QU, @view(T.U[:, 1:k]))
    q.S .= @view(T.S[1:k])
    copyto!(q.Vt, @view(T.Vt[1:k, :]) * QV')

    return q
end

@doc raw"""
    Y = riemannian_Hessian(M::FixedRankMatrices, p, G, H, X)
    riemannian_Hessian!(M::FixedRankMatrices, Y, p, G, H, X)

Compute the Riemannian Hessian ``\operatorname{Hess} f(p)[X]`` given the
Euclidean gradient ``∇ f(\tilde p)`` in `G` and the Euclidean Hessian ``∇^2 f(\tilde p)[\tilde X]`` in `H`,
where ``\tilde p, \tilde X`` are the representations of ``p,X`` in the embedding,.

The Riemannian Hessian can be computed as stated in Remark 4.1 [Nguyen:2023](@cite)
or Section 2.3 [Vandereycken:2013](@cite), that B. Vandereycken adopted for [Manopt (Matlab)](https://www.manopt.org/reference/manopt/manifolds/fixedrank/fixedrankembeddedfactory.html).
"""
riemannian_Hessian(M::FixedRankMatrices, p, G, H, X)

function riemannian_Hessian!(M::FixedRankMatrices, Y, p, G, H, X)
    project!(M, Y, p, H)
    T1 = (G * X.Vt) / Diagonal(p.S)
    Y.U .+= T1 .- p.U * (p.U' * T1)
    T2 = (G' * X.U) / Diagonal(p.S)
    Y.Vt .+= T2 .- p.Vt' * (p.Vt * T2)
    return Y
end

function Base.show(
    io::IO,
    ::FixedRankMatrices{TypeParameter{Tuple{m,n,k}},𝔽},
) where {m,n,k,𝔽}
    return print(io, "FixedRankMatrices($(m), $(n), $(k), $(𝔽))")
end
function Base.show(io::IO, M::FixedRankMatrices{Tuple{Int,Int,Int},𝔽}) where {𝔽}
    m, n, k = get_parameter(M.size)
    return print(io, "FixedRankMatrices($(m), $(n), $(k), $(𝔽); parameter=:field)")
end
function Base.show(io::IO, ::MIME"text/plain", p::SVDMPoint)
    pre = " "
    summary(io, p)
    println(io, "\nU factor:")
    su = sprint(show, "text/plain", p.U; context=io, sizehint=0)
    su = replace(su, '\n' => "\n$(pre)")
    println(io, pre, su)
    println(io, "singular values:")
    ss = sprint(show, "text/plain", p.S; context=io, sizehint=0)
    ss = replace(ss, '\n' => "\n$(pre)")
    println(io, pre, ss)
    println(io, "Vt factor:")
    sv = sprint(show, "text/plain", p.Vt; context=io, sizehint=0)
    sv = replace(sv, '\n' => "\n$(pre)")
    return print(io, pre, sv)
end
function Base.show(io::IO, ::MIME"text/plain", X::UMVTangentVector)
    pre = " "
    summary(io, X)
    println(io, "\nU factor:")
    su = sprint(show, "text/plain", X.U; context=io, sizehint=0)
    su = replace(su, '\n' => "\n$(pre)")
    println(io, pre, su)
    println(io, "M factor:")
    sm = sprint(show, "text/plain", X.M; context=io, sizehint=0)
    sm = replace(sm, '\n' => "\n$(pre)")
    println(io, pre, sm)
    println(io, "Vt factor:")
    sv = sprint(show, "text/plain", X.Vt; context=io, sizehint=0)
    sv = replace(sv, '\n' => "\n$(pre)")
    return print(io, pre, sv)
end

@doc raw"""
    vector_transport_to(M::FixedRankMatrices, p, X, q, ::ProjectionTransport)

Compute the vector transport of the tangent vector `X` at `p` to `q`,
using the [`project`](@ref project(::FixedRankMatrices, ::Any...))
of `X` to `q`.
"""
vector_transport_to!(::FixedRankMatrices, ::Any, ::Any, ::Any, ::ProjectionTransport)

function vector_transport_to_project!(M::FixedRankMatrices, Y, p, X, q)
    return project!(M, Y, q, embed(M, p, X))
end

@doc raw"""
    zero_vector(M::FixedRankMatrices, p::SVDMPoint)

Return a [`UMVTangentVector`](@ref) representing the zero tangent vector in the tangent space of
`p` on the [`FixedRankMatrices`](@ref) `M`, for example all three elements of the resulting
structure are zero matrices.
"""
function zero_vector(M::FixedRankMatrices, p::SVDMPoint)
    m, n, k = get_parameter(M.size)
    v = UMVTangentVector(
        zeros(eltype(p.U), m, k),
        zeros(eltype(p.S), k, k),
        zeros(eltype(p.Vt), k, n),
    )
    return v
end

function zero_vector!(::FixedRankMatrices, X::UMVTangentVector, p::SVDMPoint)
    X.U .= zero(eltype(X.U))
    X.M .= zero(eltype(X.M))
    X.Vt .= zero(eltype(X.Vt))
    return X
end
