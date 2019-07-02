module ECDSA

using BitConverter
using secp256k1: Point, KeyPair, Signature, N, G
export KeyPair

KeyPair{:ECDSA}(𝑑) = 𝑑 ∉ 1:N-1 ? throw(NotInField()) : KeyPair{:ECDSA}(𝑑, 𝑑 * G)

"""
    ECDSA.sign(kp::KeyPair{:ECDSA}, 𝑧::Integer) -> Signature{:ECDSA}

Returns a Signature{:ECDSA} for a given `KeyPair` and data `𝑧`
"""
function sign(kp::KeyPair{:ECDSA}, 𝑧::Integer)
    𝑘 = rand(big.(0:N))
    𝑟 = (𝑘 * G).𝑥.𝑛
    𝑘⁻¹ = powermod(𝑘, N - 2, N)
    𝑠 = mod((𝑧 + 𝑟 * kp.𝑑) * 𝑘⁻¹, N)
    if 𝑠 > N / 2
        𝑠 = N - 𝑠
    end
    return Signature{:ECDSA}(𝑟, 𝑠)
end

"""
    verify(𝑄::Point, 𝑧::Integer, sig::Signature{:ECDSA}) -> Bool

Returns true if Signature{:ECDSA} is valid for 𝑧 given 𝑄, false if not
"""
function verify(𝑄::Point, 𝑧::Integer, sig::Signature{:ECDSA})
    𝑠⁻¹ = powermod(sig.𝑠, N - 2, N)
    𝑢 = mod(𝑧 * 𝑠⁻¹, N)
    𝑣 = mod(sig.𝑟 * 𝑠⁻¹, N)
    𝑅 = 𝑢 * G + 𝑣 * 𝑄
    return 𝑅.𝑥.𝑛 == sig.𝑟
end


"""
    serialize(x::Signature{:ECDSA}) -> Vector{UInt8}

Serialize a Signature{:ECDSA} to DER format
"""
function serialize(x::Signature{:ECDSA})
    rbin = bytes(x.𝑟)
    # if rbin has a high bit, add a 00
    if rbin[1] >= 128
        rbin = pushfirst!(rbin, 0x00)
    end
    prepend!(rbin, bytes(length(rbin)))
    pushfirst!(rbin, 0x02)

    sbin = bytes(x.𝑠)
    # if sbin has a high bit, add a 00
    if sbin[1] >= 128
        sbin = pushfirst!(sbin, 0x00)
    end
    prepend!(sbin, bytes(length(sbin)))
    pushfirst!(sbin, 0x02)

    result = sbin
    prepend!(result, rbin)
    prepend!(result, bytes(length(result)))
    return pushfirst!(result, 0x30)
end

"""
    parse(x::Vector{UInt8}) -> Signature{:ECDSA}

Parse a DER binary to a Signature{:ECDSA}
"""
function parse(x::Vector{UInt8})
    io = IOBuffer(x)
    prefix = read(io, 1)[1]
    if prefix != 0x30
        throw(PrefixError())
    end
    len = read(io, 1)[1]
    if len + 2 != length(x)
        throw(LengthError())
    end
    prefix = read(io, 1)[1]
    if prefix != 0x02
        throw(PrefixError())
    end
    rlength = Int(read(io, 1)[1])
    r = Int(read(io, rlength))
    prefix = read(io, 1)[1]
    if prefix != 0x02
        throw(PrefixError())
    end
    slength = Int(read(io, 1)[1])
    s = Int(read(io, slength))
    if length(x) != 6 + rlength + slength
        throw(LengthError())
    end
    return Signature{:ECDSA}(r, s)
end

end  # module ECDSA
