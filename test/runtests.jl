using InfluxDBClient
using Test,UnPack
using DataFrames
using Dates
import JSON3, HTTP, CodecZlib
import TimeZones
using BenchmarkTools
using StatsBase

#bucket name for testing puroses 
#Note: this bucket will be created and deleted several times. Hopefully you don't have this bucket name with real data :) 
a_random_bucket_name = "test_InfluxDBClient.jl_asdfeafdfasefsIyxdFDYfadsfasdfa____l"

isettings = get_settings()
#ENV["INFLUXDB_USER"] is this needed?

@test isa(a_random_bucket_name,String)
@test length(a_random_bucket_name) > 0

#smoketest 1 to see if DB is up
#a get request to """http://$(INFLUXDB_HOST)/metrics""" is another possibility to check if the server is up
#"""http://$(INFLUXDB_HOST)/metrics"""
r = HTTP.request("GET", """http://$(isettings.INFLUXDB_HOST)/metrics""",status_exception = false)
@test r.status == 403

#Post onboarding request
#this should work if the DB was 'newly set up' (e.g. by docker in github action / CI )
#curl -i -X POST http://localhost:8086/api/v2/setup -H 'accept: application/json' -d '{"username": "my-user", "password": "my-password", "org": "my-org", "bucket": "my-bucket", "token": "my-token"}'
@warn("implement this")

#smoketest 2 to see if DB is up
#https://docs.influxdata.com/influxdb/v2.4/write-data/developer-tools/api/
bucket_names,json = try
    try 
        get_buckets(isettings); #1.7 ms btime, (influxdb host is on a different machine)
    catch er 
        @show er 
        
    end
catch 
    "","";
end;
@test length(bucket_names) > 0

if !(length(bucket_names) > 0 )
    @warn("InfluxDB is not reachable. No tests will be performed.")
else
    @info("InfluxDB seems to be reachable. Running tests...")
    prefix = ifelse(isinteractive() , "test/", "")
    include(string(prefix,"influxdb_tests.jl"))
end
