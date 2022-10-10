InfluxDBClient.jl
=================

[![CI Testing](https://github.com/kafisatz/InfluxDBClient.jl/workflows/CI/badge.svg)](https://github.com/kafisatz/InfluxDBClient.jl/actions?query=workflow%3ACI+branch%3Amain)
[![Coverage Status](http://codecov.io/github/kafisatz/InfluxDBClient.jl/coverage.svg?branch=main)](http://codecov.io/github/kafisatz/InfluxDBClient.jl?branch=main)

**WORK IN PROGRESS**

## Scope and Purpose

* This was developed for InfluxDB v2 OSS. In my case the InfluxDB is running on a machine in the local area network (docker container)
* I wanted a Julia solution to write data (e.g. from a DataFrame) to InfluxDB v2

## Usage
* Below is an example snippet how to use the functions in this package. 
* Consider `names(InfluxDBClient)` for a list of methods of this package
* You may want to consider the functions in runtests.jl to get an idea of the other functions and their arguments.

## Configuration
Ideally you define several envirnoment variables to configure the settings, see function `get_settings` 
* ENV["INFLUXDB_ORG"] the organization
* ENV["INFLUXDB_TOKEN"] the token to access the InfluxDB
* ENV["INFLUXDB_HOST"] should include the port, e.g. "10.14.15.10:8086"

## Limitations
* The functions are quite slow for large DataFrames. I am open for suggestions to improve my string handling in Julia.
* Backslashes and special characters in strings may not (yet) be parsed correctly. https://docs.influxdata.com/influxdb/v2.4/reference/syntax/line-protocol/#integer 
* Some bucket management functions (`get_buckets` etc) assume that you have fewer than 100 buckets. Functions may fail otherwise. See keywords limit and offset. 
* When data is provided integer valued, InfluxDB will display the result as float, when an aggregation function (such as mean) is selected. Select 'last' or similar to show the data as is.

## Ideas / Aspects not yet implemented
* A query function (`query_flux`) has been drafted. But it is rudimentary and output is not parsed yet, see https://docs.influxdata.com/influxdb/cloud/api/#operation/PostQuery for API details
* Precision is currently stored as string 'ns', 's', 'us', 'ms'. Possibly performance is increased if we use another type for this
* May want to consider performance tips from here: https://docs.influxdata.com/influxdb/cloud/write-data/best-practices/optimize-writes/
* The optimal batch size is 5000 lines of line protocol. -> account for this? 
* By default, InfluxDB writes data in nanosecond precision. However if your data isn’t collected in nanoseconds, there is no need to write at that precision. For better performance, use the coarsest precision possible for timestamps.

## References 
See https://docs.influxdata.com/influxdb/v2.4/reference/syntax/line-protocol/ for details of the line protocol.
See also https://docs.influxdata.com/influxdb/cloud/api/.

## Example 

```
using InfluxDBClient
using Dates
using DataFrames

a_random_bucket_name = "test_InfluxDBClient.jl_asdfeafdfasefsIyxdFDYfadsfasdfa____l"

#isettings should return a NamedTuple similar to 
#(INFLUXDB_HOST = "10.14.15.10:8086", INFLUXDB_ORG = "bk", INFLUXDB_TOKEN = "5Ixxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx==")
isettings = get_settings()

#check if the InfluxDB is reachable
bucket_names, json = get_buckets(isettings);

#bucket_names is a Vector{String} of the buckets in the database

#create or delete a bucket
create_bucket(isettings,a_random_bucket_name)
delete_bucket(isettings,a_random_bucket_name)
create_bucket(isettings,a_random_bucket_name)

#given a DataFrame, we can then write the data to the database
some_dt = DateTime(2022,9,30,15,59,33,0)
df = DataFrame(sensor_id = ["TLM0900","TLM0901","TLM0901"],other_tag=["m","m","x"] ,temperature = [70.1,11.2,99.3], humidity=[14.9,55.2,3], datetime = [some_dt,some_dt-Second(51),some_dt-Second(500)])

#get the line protocol string
lp = lineprotocol("my_meas",df,Symbol.(["temperature","humidity"]),tags=["sensor_id"], "datetime")
#here lp is a string (and thus readable by a human)
rs = write_data(isettings,a_random_bucket_name,lp,"ns")
#the value of RS must be 204 (HTTP return code after successful write)
@show rs

#Please note that by default the lineprotocol function assumes that your timestamps are in UTC
#if your timestamps are in a different TimeZone, consider the tzstr keyword as follows:
lp = lineprotocol("my_meas",df,Symbol.(["temperature","humidity"]),tags=["sensor_id"], "datetime", tzstr="Europe/Berlin")

#for lager dataframes you will want to use compression for the line protocol, using the keyword compress
lp_gzip_compressed = lineprotocol("my_meas",df,Symbol.(["temperature","humidity"]),tags=["sensor_id"], "datetime",compress = true)
#lp_gzip_compressed is now a Unit8 Vector
rs = write_data(isettings,a_random_bucket_name,lp_gzip_compressed,"ns")
@assert rs == 204

#we also provide a wrapper function to directly write a DataFrame to the database
rs,lp = write_dataframe(settings=isettings,bucket=a_random_bucket_name,measurement="xxmeasurment",data=df,fields=["humidity","temperature"],timestamp=:datetime,tags=String["sensor_id"],tzstr = "Europe/Berlin",compress=true);

delete_bucket(isettings,a_random_bucket_name)

```