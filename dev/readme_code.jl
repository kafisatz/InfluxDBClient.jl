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

#querying 
#note that the agg keyword is optional
#consider calls in runtests.jl for more exmaples (i.e. search this repository for "query_flux(")
agg = """   aggregateWindow(every: 20m, fn: mean, createEmpty: false)
                |> yield(name: "mean") """    
datetime_str = string(minimum(df.datetime),"+02:00")
df_result = query_flux(isettings,a_random_bucket_name,"xxmeasurment";tzstr = "Europe/Berlin",range=Dict("start"=>"$datetime_str"),fields=["temperature","humidity"],tags=Dict("sensor_id"=>"TLM0900"),aggregate=agg);

delete_bucket(isettings,a_random_bucket_name)