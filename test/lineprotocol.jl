@testset "Lineprotocol.jl               " begin

   @test true 

   #tests
    #delete_bucket(isettings,a_random_bucket_name);
    reset_bucket(isettings,a_random_bucket_name);

   #= 
   payload = """airSensors,sensor_id=TLM0201 temperature=73.97038159354763,humidity=35.23103248356096,co=0.48445310567793615 1630424257000000000
                airSensors,sensor_id=TLM0202 temperature=75.30007505999716,humidity=35.651929918691714,co=0.5141876544505826 1630424257000000000
                airSensors,sensor_id=TLM0202 temperature=70.30007505999716,humidity=45.651929918691714,co=0.7141876544505826 1630424258000000000
                airSensors,sensor_id=TLM0202 temperature=72.30007505999716,humidity=30.651929918691714,co=0.6141876544505826 1630424259000000000"""
    =#

    some_dt = DateTime(2022,9,30,15,59,33,33)
    df = DataFrame(sensor_id = ["TLM0900","TLM0901","TLM0901"],other_tag=["m","m","x"] ,temperature = [73.9,55.1,22.9], humidity=[14.9,55.2,3], datetime = [some_dt,some_dt-Second(51),some_dt-Second(500)])
    
    lp = lineprotocol("my_meas",df[1:1,:],["temperature","humidity"], :datetime)
    lp_want = "my_meas temperature=73.9,humidity=14.9 1664553573033000000"
    @test lp == lp_want
    @test 204 == write_data(isettings,a_random_bucket_name,lp,"ns")

    lp = lineprotocol("my_meas",df,["temperature","humidity"], :datetime)
    lp_want = "my_meas temperature=73.9,humidity=14.9 1664553573033000000\nmy_meas temperature=55.1,humidity=55.2 1664553522033000000\nmy_meas temperature=22.9,humidity=3.0 1664553073033000000"
    @test lp == lp_want
    @test 204 == write_data(isettings,a_random_bucket_name,lp,"ns")

    #view of df
    lp2lines = lineprotocol("my_meas",view(df,1:2,:),["temperature","humidity"], :datetime)
    @test lp2lines == "my_meas temperature=73.9,humidity=14.9 1664553573033000000\nmy_meas temperature=55.1,humidity=55.2 1664553522033000000"
    @test 204 == write_data(isettings,a_random_bucket_name,lp,"ns")
   
    #with Symbol
    @test lp == lineprotocol("my_meas",df,Symbol.(["temperature","humidity"]), :datetime)
    @test 204 == write_data(isettings,a_random_bucket_name,lp,"ns")

    #datetime col as string
    @test lp == lineprotocol("my_meas",df,Symbol.(["temperature","humidity"]), "datetime")
    @test 204 == write_data(isettings,a_random_bucket_name,lp,"ns")
    
    #with tags
    lp = lineprotocol("my_meas",df,Symbol.(["temperature","humidity"]),tags=["sensor_id"], "datetime")
    @test lp == "my_meas,sensor_id=TLM0900 temperature=73.9,humidity=14.9 1664553573033000000\nmy_meas,sensor_id=TLM0901 temperature=55.1,humidity=55.2 1664553522033000000\nmy_meas,sensor_id=TLM0901 temperature=22.9,humidity=3.0 1664553073033000000"
    @test 204 == write_data(isettings,a_random_bucket_name,lp,"ns")

    lp = lineprotocol("my_meas",df,Symbol.(["temperature","humidity"]),tags=["sensor_id","other_tag"], "datetime")
    @test lp == "my_meas,sensor_id=TLM0900,other_tag=m temperature=73.9,humidity=14.9 1664553573033000000\nmy_meas,sensor_id=TLM0901,other_tag=m temperature=55.1,humidity=55.2 1664553522033000000\nmy_meas,sensor_id=TLM0901,other_tag=x temperature=22.9,humidity=3.0 1664553073033000000"
    @test 204 == write_data(isettings,a_random_bucket_name,lp,"ns")

    ######################################################################
    #Integer valued data
    ######################################################################
    df = DataFrame(sensor_id = ["TLM0900","TLM0901","TLM0901"],other_tag=["m","m","x"] ,temperatureINT = [73,55,22], humidity=[14.9,55.2,3], datetime = [some_dt,some_dt-Second(51),some_dt-Second(500)])
    lp = lineprotocol("my_meas",df,["temperatureINT","humidity"], :datetime)
    @test 204 == write_data(isettings,a_random_bucket_name,lp,"ns")

    ######################################################################
    #Unsigned Integer valued data
    ######################################################################
    df = DataFrame(sensor_id = ["TLM0900","TLM0901","TLM0901"],other_tag=["m","m","x"] ,temperatureUINT = UInt[73,55,22], humidity=[14.9,55.2,3], datetime = [some_dt,some_dt-Second(51),some_dt-Second(500)])
    lp = lineprotocol("my_meas",df,["temperatureUINT","humidity"], :datetime)
    @test 204 == write_data(isettings,a_random_bucket_name,lp,"ns")

    ######################################################################
    #Boolean data
    ######################################################################
    df = DataFrame(sensor_id = ["TLM0900","TLM0901","TLM0901"],other_tag=["m","m","x"] ,temperatureBool = [false,true,true], humidity=[14.9,55.2,3], datetime = [some_dt,some_dt-Second(51),some_dt-Second(500)])
    lp = lineprotocol("my_meas",df,["temperatureBool","humidity"], :datetime)
    @test 204 == write_data(isettings,a_random_bucket_name,lp,"ns")


    ######################################################################
    #String valued data
    ######################################################################
    df = DataFrame(sensor_id = ["TLM0900","TLM0901","TLM0901"],other_tag=["m","m","x"] ,temperatureSTRING = string.([73,55,22]), humidity=[14.9,55.2,3], datetime = [some_dt,some_dt-Second(51),some_dt-Second(500)])
    lp = lineprotocol("my_meas",df,["temperatureSTRING","humidity"], :datetime)
    @test 204 == write_data(isettings,a_random_bucket_name,lp,"ns")


    #invalid measurment name
    @test_throws ArgumentError lineprotocol("_my_meas",df,["temperatureSTRING","humidity"], :datetime)
    #invalid field name
    df = DataFrame(sensor_id = ["TLM0900","TLM0901","TLM0901"],other_tag=["m","m","x"] ,_temperatureSTRING = string.([73,55,22]), humidity=[14.9,55.2,3], datetime = [some_dt,some_dt-Second(51),some_dt-Second(500)])
    @test_throws ArgumentError lineprotocol("my_meas",df,["_temperatureSTRING","humidity"], :datetime)
    #invalid tag name
    df = DataFrame(_sensor_id = ["TLM0900","TLM0901","TLM0901"],other_tag=["m","m","x"] ,temperatureSTRING = string.([73,55,22]), humidity=[14.9,55.2,3], datetime = [some_dt,some_dt-Second(51),some_dt-Second(500)])
    @test_throws ArgumentError lineprotocol("my_meas",df,["temperatureSTRING","humidity"], tags=["_sensor_id"],:datetime)
    
    

    ######################################################################
    #Compression
    ######################################################################
    for gzip_compression_is_enabled in [false,true]
        if gzip_compression_is_enabled
            @info("Testing lineprotocol WITH gzip compression...")
        else 
            @info("Testing lineprotocol WITHOUT gzip compression...")
        end
        
        df = DataFrame(_sensor_id = ["TLM0900","TLM0901","TLM0901"],other_tag=["m","m","x"] ,temperature = [73.1,55,22.0], humidity=[14.9,55.2,3], datetime = [some_dt,some_dt-Second(51),some_dt-Second(500)])
        lp = lineprotocol("my_meas",df,["temperature","humidity"], :datetime,compress = gzip_compression_is_enabled)

        #NOTE: we are explicitly passing compress = false here 
        #the payload (lp) is already compressed, thus the write_data function does not need to compress the payload (again)
        @test 204 == write_data(isettings,a_random_bucket_name,lp,"ns",compress = false)

        lp = lineprotocol("my_meas",df,["temperature","humidity"], :datetime,compress = true)
        write_data(isettings,a_random_bucket_name,lp,"ns",compress = false)
       
        #= 
            @btime lp = lineprotocol("my_meas",df,["temperature","humidity"], :datetime,compress = true);

            lp = lineprotocol("my_meas",df,["temperature","humidity"], :datetime,compress = true)
            write_data(isettings,a_random_bucket_name,lp,"ns",compress = false)
                                                  "my_meas temperature=73.1,humidity=14.9 1664553573033000000\nmy_meas temperature=55.0,humidity=55.2 1664553522033000000\nmy_meas temperature=22.0,humidity=3.0 1664553073033000000"
            #{"code":"invalid","message":"unable to parse 'my_meas temperature=73.1,humidity=14.9 1664553573033000000my_meas temperature=55.0,humidity=55.2 1664553522033000000my_meas temperature=22.0,humidity=3.0 1664553073033000000': bad timestamp"}""")     
        =#


    end

    ######################################################################
    #wrapper for write data
    ######################################################################
    #write_data(settings=settings,bucket="bucketname",measurement="measurment",df=df,fields=fields,timestamp=timestamp;tags=String[],influx_precision="ns",tzstr = "UTC",compress::Bool=false)

    some_dt = now() 
    df = DataFrame(sensor_id = ["TLM0900","TLM0901","TLM0901"],other_tag=["m","m","x"] ,temperature = [73.1,55,22.0], humidity=[14.9,55.2,3], datetime = [some_dt,some_dt-Second(51),some_dt-Second(500)])
    rs,lp = write_dataframe(settings=isettings,bucket=a_random_bucket_name,measurement="xxmeasurment",data=df,fields=["humidity","temperature"],timestamp=:datetime,tags=String["sensor_id"],influx_precision="ns",tzstr = "UTC",compress=false)
    @test rs == 204

    rs,lp = write_dataframe(settings=isettings,bucket=a_random_bucket_name,measurement="xxmeasurment",data=df,fields=["humidity","temperature"],timestamp=:datetime,influx_precision="ns",tzstr = "UTC",compress=false)
    @test rs == 204

    rs,lp = write_dataframe(settings=isettings,bucket=a_random_bucket_name,measurement="xxmeasurment",data=df,fields=["humidity","temperature"],timestamp=:datetime,tzstr = "UTC",compress=false)
    @test rs == 204

    rs,lp = write_dataframe(settings=isettings,bucket=a_random_bucket_name,measurement="xxmeasurment",data=df,fields=["humidity","temperature"],timestamp=:datetime,tzstr = "UTC",compress=true)
    @test rs == 204

    rs,lp = write_dataframe(settings=isettings,bucket=a_random_bucket_name,measurement="xxmeasurment",data=df,fields=["humidity","temperature"],timestamp=:datetime,tzstr = "Europe/Berlin",compress=false)
    @test rs == 204

    rs,lp = write_dataframe(settings=isettings,bucket=a_random_bucket_name,measurement="xxmeasurment",data=df,fields=["humidity","temperature"],timestamp=:datetime,compress=false)
    @test rs == 204

    @test_throws UndefKeywordError write_dataframe(settings=isettings,measurement="xxmeasurment",data=df,fields=["humidity","temperature"],timestamp=:datetime,compress=false)



    ################################################################################################################################################
    #skipmissingvalues      
    #note: this was originally a keyword. However, 'not skipping missing values' is not meaningful, thus skipping them is the default
    ################################################################################################################################################
    # write_dataframe(;settings,bucket,measurement,data,fields,timestamp,tags=String[],batchsize::Int = 0,influx_precision::String = "ns",tzstr::String = "UTC",compress::Bool=false,printinfo::Bool=true)
    reset_bucket(isettings,a_random_bucket_name);

    some_dt = DateTime(2022,9,30,15,59,33,33)
    df = DataFrame(sensor_id = ["TLM0800","TLM0801","TLM0801"],other_tag=["m","m","x"] ,co2=[missing,missing,99.3],temperature = [73.1,missing,22.0], humidity=[14.9,55.2,3], datetime = [some_dt,some_dt-Second(51),some_dt-Second(500)])
    datetime_str = string(minimum(df.datetime) - Day(100),"+02:00")
    rw = df[1,:]
    measurement = "miha"
    timestamp = :datetime
    fields=["humidity","temperature","co2"]
    tagsSymbols=String[]
    influx_precision="ns"
    shift_datetime_to_utc(x) = DateTime(TimeZones.astimezone(TimeZones.ZonedDateTime(x, InfluxDBClient.utc_tz), InfluxDBClient.utc_tz))
    # function create_lp(rw::DataFrameRow,measurement,timestamp,fields,tagsSymbols,influx_precision,shift_datetime_to_utc)
    for i=1:size(df,1)
        rw = df[i,:]
        lp = create_lp(rw,measurement,timestamp,fields,tagsSymbols,influx_precision,shift_datetime_to_utc)
        for f in fields 
            oci = occursin(f,lp)
            if ismissing(rw[f])
                @test !oci
            else 
                @test oci            
            end
        end
    end
    
    #write df
    rs,lp = write_dataframe(settings=isettings,bucket=a_random_bucket_name,measurement=measurement,data=df,fields=fields,timestamp=:datetime,compress=false)
    @test rs == 204
    
    
        q="""from(bucket: "test_InfluxDBClient.jl_asdfeafdfasefsIyxdFDYfadsfasdfa____l")
                |> range(start: $(datetime_str))
                |> filter(fn: (r) => r["_measurement"] == "$(measurement)")
                |> filter(fn: (r) => r["_field"] == "co2" or r["_field"] == "humidity" or r["_field"] == "temperature")
                |> aggregateWindow(every: 1s, fn: mean, createEmpty: false)
                |> yield(name: "mean")"""
        bdy = query_flux(isettings,q)
        dfres = query_flux_postprocess_response(bdy,false,"ns",InfluxDBClient.utc_tz)
        
    f = fields[1]
    for f in fields
        expected_rows = sum(.!ismissing.(df[!,f]))
        size_of_df_query_result = size(filter(x->x._field == f,dfres),1)
        @test size_of_df_query_result == expected_rows
    end

   #"Todo - We may want to add a test for each note in the 'Manual', e.g. Line protocol does not support the newline character \n in tag or field values.")
   #e.g. 
   "https://github.com/influxdata/influxdb2-sample-data/blob/master/air-sensor-data/sample-sensor-info.csv"

   #(Required) The measurement name. InfluxDB accepts one measurement per point. Measurement names are case-sensitive and subject to naming restrictions.

   #(Required) All field key-value pairs for the point. Points must have at least one field. Field keys and string values are case-sensitive. Field keys are subject to naming restrictions.

   #Always double quote string field values. More on quotes below.

   #To ensure a data point includes the time a metric is observed (not received by InfluxDB), include the timestamp.

   #If your timestamps are not in nanoseconds, specify the influx_precision of your timestamps when writing the data to InfluxDB.

   #Whitespace
   #Whitespace in line protocol determines how InfluxDB interprets the data point. The first unescaped space delimits the measurement and the tag set from the field set. The second unescaped space delimits the field set from the timestamp.

    delete_bucket(isettings,a_random_bucket_name);

    reset_bucket(isettings,a_random_bucket_name);

    
    df = DataFrame(sensor_id = ["TLM0900","TLM0901","TLM0901"],other_tag=["m","m","x"] ,temperature = [73.9,55.1,22.9], humidity=[14.9,55.2,3], datetime = [some_dt,some_dt-Second(51),some_dt-Second(500)])

    ########################################
    #microseconds
    ########################################
    lp = lineprotocol("my_meas",df,["temperature","humidity"], :datetime,influx_precision = "us")
    @test 204 == write_data(isettings,a_random_bucket_name,lp,"us")

    #we cannot 'check' the timestamp precision, as everything is stored as nanoseconds
    #(but data is smaller when sent as seconds (string encoded/compressed))
    #https://docs.influxdata.com/influxdb/v1.8/troubleshooting/frequently-asked-questions/#can-i-identify-write-precision-from-returned-timestamps
    #InfluxDB stores all timestamps as nanosecond values, regardless of the write precision supplied. It is important to note that when returning query results, the database silently drops trailing zeros from timestamps which obscures the initial write precision.
    #In the example below, the tags precision_supplied and timestamp_supplied show the time precision and timestamp that the user provided at the write. Because InfluxDB silently drops trailing zeros on returned timestamps, the write precision is not recognizable in the returned timestamps.

    ########################################
    #seconds
    ########################################
    @test_throws ArgumentError lp = lineprotocol("my_meas",df,["temperature","humidity"], :datetime,influx_precision = "ss")
    
    lp = lineprotocol("my_meas",df,["temperature","humidity"], :datetime,influx_precision = "s")
    @test 204 == write_data(isettings,a_random_bucket_name,lp,"s")

    #Int32 and UInt32 etc types 
    for tt in [UInt128,UInt64,UInt32,UInt16,UInt8,Int128,Int64,Int32,Int16,Int8]
        df = DataFrame(sensor_id = ["TLM0900","TLM0901","TLM0901"],other_tag=["m","m","x"] ,temperature = [73.9,55.1,22.9], humidity=convert(Vector{tt},[14,52,3]), datetime = [some_dt,some_dt-Second(51),some_dt-Second(500)])    
        @test eltype(df.humidity) == tt
        lp = lineprotocol("my_meas",df[1:1,:],["temperature","humidity"], :datetime)
    end

    delete_bucket(isettings,a_random_bucket_name);
end


