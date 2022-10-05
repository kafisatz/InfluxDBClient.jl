using Profile 
using InfluxDBClient
using Test,UnPack
using DataFrames
using Dates
import JSON3, HTTP, CodecZlib
using BenchmarkTools
using StatsBase

#bucket name for testing puroses 
#Note: this bucket will be created and deleted several times. Hopefully you don't have this bucket name with real data :) 
a_random_bucket_name = "test_InfluxDBClient.jl_asdfeafdfasefsIyxdFDYfadsfasdfa____l"
@test isa(a_random_bucket_name,String)
@test length(a_random_bucket_name) > 0

isettings = get_settings()

#smoketest to see if DB is up
#https://docs.influxdata.com/influxdb/v2.4/write-data/developer-tools/api/
bucket_names,json = try 
    get_buckets(isettings); #1.7 ms btime, (influxdb host is on a different machine)
catch 
    "","";
end;
@test length(bucket_names) > 0

#define random data
nn = 20_000
some_dt = DateTime(2022,9,30,15,59,33,0)
sensor_id = ["TLM0900","TLM0901","TLM0901"]
color = ["green","blue"]

df = DataFrame(sensor_id =sample(sensor_id,nn),
            color = sample(color,nn),
            temperature = map(i->mod(1 + i,100)+0.3,1:nn),
            an_int_value = map(i->mod(1 + i,100),1:nn),
            abool = map(x->ifelse(x==1,true,false),rand(1:2,nn)),
            humidity = rand(nn).^2 .*50,
            co2 = map(i->mod(1 + i,100)*2,1:nn),
            datetime = some_dt .- Second.(rand(1:nn,nn)));

use_compression = true
@show use_compression
@show nn

lp = lineprotocol("my_meas",df,["temperature","an_int_value","abool","humidity"],tags=["color","sensor_id"], :datetime,compress = use_compression);

Profile.clear_malloc_data()
#https://github.com/JuliaCI/Coverage.jl
@time lp = lineprotocol("my_meas",df,["temperature","an_int_value","abool","humidity"],tags=["color","sensor_id"], :datetime,compress = use_compression);

#@time write_data(isettings,a_random_bucket_name,lp,"ns")
#@test 204 == write_data(isettings,a_random_bucket_name,lp,"ns")