module InfluxDBClient

import JSON3
import CodecZlib
import TimeZones
using UnPack
using DataFrames
using Dates
import HTTP

export PRECISIONS
export PRECISION_DICT

#PRECISION_DICT = Dict("s"=>1_000_000_000,"ms"=>1_000_000,"us"=>1000,"ns"=>1)
PRECISIONS = ["s","ms","us", "ns"]
#PRECISIONS = collect(keys(PRECISION_DICT))

global const utc_tz = TimeZones.TimeZone("UTC")

    include("settings.jl")
    include("buckets.jl")
    include("lineprotocol.jl")
    include("write.jl")

    #in the works.
    include("query.jl")

end
