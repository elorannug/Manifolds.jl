@doc raw"""
    CholeskySpace{T} <: AbstractManifold{ℝ}

The manifold of lower triangular matrices with positive diagonal and
a metric based on the Cholesky decomposition. The formulae for this manifold
are for example summarized in Table 1 of [Lin:2019](@cite).

# Constructor

    CholeskySpace(n; parameter::Symbol=:type)

Generate the manifold of ``n×n`` lower triangular matrices with positive diagonal.
"""
struct CholeskySpace{T} <: AbstractManifold{ℝ}
    size::T
end

function CholeskySpace(n::Int; parameter::Symbol=:type)
    size = wrap_type_parameter(parameter, (n,))
    return CholeskySpace{typeof(size)}(size)
end

@doc raw"""
    check_point(M::CholeskySpace, p; kwargs...)

Check whether the matrix `p` lies on the [`CholeskySpace`](@ref) `M`, i.e.
it's size fits the manifold, it is a lower triangular matrix and has positive
entries on the diagonal.
The tolerance for the tests can be set using the `kwargs...`.
"""
function check_point(
    M::CholeskySpace,
    p::T;
    atol::Real=sqrt(prod(representation_size(M))) * eps(real(float(number_eltype(T)))),
    kwargs...,
) where {T}
    cks = check_size(M, p)
    cks === nothing || return cks
    if !isapprox(norm(strictlyUpperTriangular(p)), 0.0; atol=atol, kwargs...)
        return DomainError(
            norm(UpperTriangular(p) - Diagonal(p)),
            "The point $(p) does not lie on $(M), since it strictly upper triangular nonzero entries",
        )
    end
    if any(diag(p) .<= 0)
        return DomainError(
            min(diag(p)...),
            "The point $(p) does not lie on $(M), since it hast nonpositive entries on the diagonal",
        )
    end
    return nothing
end

"""
    check_vector(M::CholeskySpace, p, X; kwargs... )

Check whether `v` is a tangent vector to `p` on the [`CholeskySpace`](@ref) `M`, i.e.
after [`check_point`](@ref)`(M,p)`, `X` has to have the same dimension as `p`
and a symmetric matrix.
The tolerance for the tests can be set using the `kwargs...`.
"""
function check_vector(
    M::CholeskySpace,
    p,
    X;
    atol::Real=sqrt(prod(representation_size(M)) * eps(float(eltype(p)))),
    kwargs...,
)
    if !isapprox(norm(strictlyUpperTriangular(X)), 0.0; atol=atol, kwargs...)
        return DomainError(
            norm(UpperTriangular(X) - Diagonal(X)),
            "The matrix $(X) is not a tangent vector at $(p) (represented as an element of the Lie algebra) since it is not lower triangular.",
        )
    end
    return nothing
end

@doc raw"""
    distance(M::CholeskySpace, p, q)

Compute the Riemannian distance on the [`CholeskySpace`](@ref) `M` between two
matrices `p`, `q` that are lower triangular with positive diagonal. The formula
reads

````math
d_{\mathcal M}(p,q) = \sqrt{\sum_{i>j} (p_{ij}-q_{ij})^2 +
\sum_{j=1}^m (\log p_{jj} - \log q_{jj})^2
}
````
"""
function distance(::CholeskySpace, p, q)
    return sqrt(
        sum((strictlyLowerTriangular(p) - strictlyLowerTriangular(q)) .^ 2) +
        sum((log.(diag(p)) - log.(diag(q))) .^ 2),
    )
end

@doc raw"""
    exp(M::CholeskySpace, p, X)

Compute the exponential map on the [`CholeskySpace`](@ref) `M` emanating from the lower
triangular matrix with positive diagonal `p` towards the lower triangular matrix `X`
The formula reads

````math
\exp_p X = ⌊ p ⌋ + ⌊ X ⌋ + \operatorname{diag}(p)
\operatorname{diag}(p)\exp\bigl( \operatorname{diag}(X)\operatorname{diag}(p)^{-1}\bigr),
````

where ``⌊⋅⌋`` denotes the strictly lower triangular matrix,
and ``\operatorname{diag}`` extracts the diagonal matrix.
"""
exp(::CholeskySpace, ::Any...)

function exp!(::CholeskySpace, q, p, X)
    q .= (
        strictlyLowerTriangular(p) +
        strictlyLowerTriangular(X) +
        Diagonal(diag(p)) * Diagonal(exp.(diag(X) ./ diag(p)))
    )
    return q
end

function get_coordinates_orthonormal!(M::CholeskySpace, Xⁱ, p, X, ::RealNumbers)
    n = get_parameter(M.size)[1]
    view(Xⁱ, 1:n) .= diag(X)
    xi_ind = n + 1
    for i in 1:n
        for j in (i + 1):n
            Xⁱ[xi_ind] = X[j, i]
            xi_ind += 1
        end
    end
    return Xⁱ
end

function get_vector_orthonormal!(M::CholeskySpace, X, p, Xⁱ, ::RealNumbers)
    n = get_parameter(M.size)[1]
    fill!(X, 0)
    view(X, diagind(X)) .= view(Xⁱ, 1:n) .* diag(p)
    xi_ind = n + 1
    for i in 1:n
        for j in (i + 1):n
            X[j, i] = Xⁱ[xi_ind]
            xi_ind += 1
        end
    end
    return X
end

@doc raw"""
    inner(M::CholeskySpace, p, X, Y)

Compute the inner product on the [`CholeskySpace`](@ref) `M` at the
lower triangular matrix with positive diagonal `p` and the two tangent vectors
`X`,`Y`, i.e they are both lower triangular matrices with arbitrary diagonal.
The formula reads

````math
g_p(X,Y) = \sum_{i>j} X_{ij}Y_{ij} + \sum_{j=1}^m X_{ii}Y_{ii}p_{ii}^{-2}
````
"""
function inner(::CholeskySpace, p, X, Y)
    return (
        sum(strictlyLowerTriangular(X) .* strictlyLowerTriangular(Y)) +
        sum(diag(X) .* diag(Y) ./ (diag(p) .^ 2))
    )
end

"""
    is_flat(::CholeskySpace)

Return true. [`CholeskySpace`](@ref) is a flat manifold. See Proposition 8 of [Lin:2019](@cite).
"""
is_flat(M::CholeskySpace) = true

@doc raw"""
    log(M::CholeskySpace, X, p, q)

Compute the logarithmic map on the [`CholeskySpace`](@ref) `M` for the geodesic emanating
from the lower triangular matrix with positive diagonal `p` towards `q`.
The formula reads

````math
\log_p q = ⌊ p ⌋ - ⌊ q ⌋ + \operatorname{diag}(p)\log\bigl(\operatorname{diag}(q)\operatorname{diag}(p)^{-1}\bigr),
````

where ``⌊⋅⌋`` denotes the strictly lower triangular matrix,
and ``\operatorname{diag}`` extracts the diagonal matrix.
"""
log(::Cholesky, ::Any...)

function log!(::CholeskySpace, X, p, q)
    return copyto!(
        X,
        strictlyLowerTriangular(q) - strictlyLowerTriangular(p) +
        Diagonal(diag(p) .* log.(diag(q) ./ diag(p))),
    )
end

@doc raw"""
    manifold_dimension(M::CholeskySpace)

Return the manifold dimension for the [`CholeskySpace`](@ref) `M`, i.e.

````math
    \dim(\mathcal M) = \frac{N(N+1)}{2}.
````
"""
function manifold_dimension(M::CholeskySpace)
    N = get_parameter(M.size)[1]
    return div(N * (N + 1), 2)
end

@doc raw"""
    representation_size(M::CholeskySpace)

Return the representation size for the [`CholeskySpace`](@ref)`{N}` `M`, i.e. `(N,N)`.
"""
function representation_size(M::CholeskySpace)
    N = get_parameter(M.size)[1]
    return (N, N)
end

function Base.show(io::IO, ::CholeskySpace{TypeParameter{Tuple{n}}}) where {n}
    return print(io, "CholeskySpace($(n))")
end
function Base.show(io::IO, M::CholeskySpace{Tuple{Int}})
    n = get_parameter(M.size)[1]
    return print(io, "CholeskySpace($(n); parameter=:field)")
end

# two small helpers for strictly lower and upper triangulars
strictlyLowerTriangular(p) = LowerTriangular(p) - Diagonal(diag(p))

strictlyUpperTriangular(p) = UpperTriangular(p) - Diagonal(diag(p))

@doc raw"""
    parallel_transport_to(M::CholeskySpace, p, X, q)

Parallely transport the tangent vector `X` at `p` along the geodesic to `q`
on the [`CholeskySpace`](@ref) manifold `M`. The formula reads

````math
\mathcal P_{q←p}(X) = ⌊ X ⌋
+ \operatorname{diag}(q)\operatorname{diag}(p)^{-1}\operatorname{diag}(X),
````

where ``⌊⋅⌋`` denotes the strictly lower triangular matrix,
and ``\operatorname{diag}`` extracts the diagonal matrix.
"""
parallel_transport_to(::CholeskySpace, ::Any, ::Any, ::Any)

function parallel_transport_to!(::CholeskySpace, Y, p, X, q)
    return copyto!(Y, strictlyLowerTriangular(p) + Diagonal(diag(q) .* diag(X) ./ diag(p)))
end

function Random.rand!(
    rng::AbstractRNG,
    M::CholeskySpace,
    pX;
    vector_at=nothing,
    σ::Real=one(eltype(pX)) /
            (vector_at === nothing ? 1 : norm(convert(AbstractMatrix, vector_at))),
    tangent_distr=:Gaussian,
)
    N = get_parameter(M.size)[1]
    if vector_at === nothing
        p_spd = rand(
            rng,
            SymmetricPositiveDefinite(N; parameter=:field);
            σ=σ,
            tangent_distr=tangent_distr,
        )
        pX .= cholesky(p_spd).L
    else
        p_spd = vector_at * vector_at'
        X_spd = rand(
            rng,
            SymmetricPositiveDefinite(N; parameter=:field);
            vector_at=p_spd,
            σ=σ,
            tangent_distr=tangent_distr,
        )
        pX .= spd_to_cholesky(p_spd, X_spd)[2]
    end
    return pX
end

@doc raw"""
    zero_vector(M::CholeskySpace, p)

Return the zero tangent vector on the [`CholeskySpace`](@ref) `M` at `p`.
"""
zero_vector(::CholeskySpace, ::Any...)

zero_vector!(M::CholeskySpace, X, p) = fill!(X, 0)
