#=
using Pkg;
Pkg.activate(".")
using TestEnv
TestEnv.activate()
=#

using InfluxDBClient
using Test, UnPack, DataFrames, Dates, Aqua
import JSON3, HTTP, CodecZlib, TimeZones, Random, CSV
using StatsBase
#using BenchmarkTools

#bucket name for testing purposes
#Note: this bucket will be created and deleted several times. Hopefully you don't have this bucket name with real data :) 
a_random_bucket_name = "test_InfluxDBClient.jl_asdfeafdfasefsIyxdFDYfadsfasdfa____l"

isettings = get_settings()
if iszero(length(isettings))
    isettings = get_settings_from_file()
end
#ENV["INFLUXDB_USER"] is this needed?

@test isa(a_random_bucket_name,String)
@test length(a_random_bucket_name) > 0

#smoketest 1 to see if DB is up
#a get request to """$(INFLUXDB_URL)/metrics""" is another possibility to check if the server is up
try 
    metrics_url = """$(isettings["INFLUXDB_URL"])/metrics"""
    @info("Trying to query $(metrics_url)...")
    r = HTTP.request("GET", metrics_url,status_exception = false)
    #maybe status is 200 when metrics are ENABLED and status is 403 when metrics are DISABLED
    @test in(r.status,[200,403])
    @info("Status is $(r.status)")
    @info("Body is $(String(r.body))")
catch er
    @warn("failed to query: $(isettings["INFLUXDB_URL"])/metrics")
    @show er
end

#smoketest 2 to see if DB is up
#https://docs.influxdata.com/influxdb/v2.4/write-data/developer-tools/api/
bucket_names,json = try
    try
        get_buckets(isettings); #1.7 ms btime, (influxdb host is on a different machine)
    catch er
        @show er
        "","";
    end
catch
    "","";
end;
@test length(bucket_names) > 0
@show bucket_names
prefix = ifelse(isinteractive() , "test/", "")
include(string(prefix,"functions.jl"))

nmax_repeat_selected_query_tests = 2 #(haskey(ENV,"USERPROFILE")&&endswith(ENV["USERPROFILE"],"konig")) ? 2 : 20
#see NOTE99831 for motivation of nmax
#preliminary testing showed that influxdb does not always return the very same values

if !(length(bucket_names) > 0 )
    @warn("InfluxDB is not reachable. No tests will be performed.")
else
    @info("InfluxDB seems to be reachable. Running tests...")    

    testfld = normpath(joinpath(pathof(InfluxDBClient),"..","..","test"))
    testfis = sort(setdiff(filter(x->endswith(x,".jl"),readdir(testfld)),["functions.jl","runtests.jl"]))
    #testfis = sort(["settings.jl","buckets.jl","write.jl","lineprotocol.jl","timezones.jl","query.jl","special_chars_in_meas_name.jl","large_data.jl","delete.jl","metadata.jl"])
    for tf in testfis
        isfile(tf) && include(tf)
        tf2 = joinpath("test",tf)
        isfile(tf2) && include(tf2)
    end
    #=
        include(joinpath("test","settings.jl"))
        include(joinpath("test","buckets.jl"))
        include(joinpath("test","write.jl"))
        include(joinpath("test","lineprotocol.jl"))
        include(joinpath("test","timezones.jl"))
        include(joinpath("test","query.jl"))
        include(joinpath("test","large_data.jl"))
        include(joinpath("test","delete.jl"))
    =#
end

#Aqua tests
Aqua.test_all(InfluxDBClient,ambiguities=false,deps_compat=false)