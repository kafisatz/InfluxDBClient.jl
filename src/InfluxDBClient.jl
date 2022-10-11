module InfluxDBClient

import JSON3
import CodecZlib
import TimeZones
using UnPack
using DataFrames
using Dates
import HTTP
import Random
import CSV
import NanoDates

export PRECISIONS
export PRECISION_DICT
export PRECISION_DATETIME_LENGTH
export DATETIME_LENGTHS

PRECISION_DICT = Dict("s"=>1_000_000_000,"ms"=>1_000_000,"us"=>1000,"ns"=>1)
PRECISIONS = ["s","ms","us", "ns"]
#PRECISIONS = collect(keys(PRECISION_DICT))

#this is the length of the datetime string returned by Influxdb, we can infer the datetime precision based on this
#length 29 (tests) is somewhat surprising though
PRECISION_DATETIME_LENGTH = Dict(20=>"s",24=>"ms",27=>"us",30=>"ns")
DATETIME_LENGTHS = sort(collect(keys(PRECISION_DATETIME_LENGTH)))
# 20=>"s",24=>"ms",27=>"us",30=>"ns"
#df._time[1] = "2022-09-30T15:59:32.039Z"
#df._time[1] = "2022-09-30T15:59:32Z"



global const utc_tz = TimeZones.TimeZone("UTC")

    include("settings.jl")
    include("buckets.jl")
    include("lineprotocol.jl")
    include("write.jl")

    #in the works.
    include("query.jl")

end
