@testset "write.jl                      " begin

@test_throws ArgumentError write_data(isettings,a_random_bucket_name,"do_not_care","ns")

#tests
#delete_bucket(isettings,a_random_bucket_name);
reset_bucket(isettings,a_random_bucket_name);

#call without compression keyword
payload = """myMeasurement,tag1=value1,tag2=value2 fieldKey="fieldValue" 1556813561098000000"""
rs = write_data(isettings,a_random_bucket_name,payload,"ns")
@test rs == 204

#nsx, it's a car, not a precision :) 
@test_throws ArgumentError write_data(isettings,a_random_bucket_name,payload,"nsx")

for gzip_compression_is_enabled in [false,true]
    if gzip_compression_is_enabled
        @info("Testing write_data WITH gzip compression...")
    else 
        @info("Testing write_data WITHOUT gzip compression...")
    end

    payload = """myMeasurement,tag1=value1,tag2=value2 fieldKey="fieldValue" 1556813561098000000"""
    rs = write_data(isettings,a_random_bucket_name,payload,"ns",compress=gzip_compression_is_enabled)
    @test rs == 204

    ############################################################################################################
    #test with tags which contain a space
    ############################################################################################################
    payload = """myMeasurement,tag1=val ue1,tag2=value2 fieldKey="fieldValue" 1556813561098000000"""
    #here we forgot to quote the tag1
    #-> we expect HTTP error code 400
    @test_throws HTTP.Exceptions.StatusError write_data(isettings,a_random_bucket_name,payload,"ns",compress=gzip_compression_is_enabled)

    payload = """myMeasurement,tag1="value1",tag2="value2" fieldKey="fieldValue" 1556813561098000000"""
    rs = write_data(isettings,a_random_bucket_name,payload,"ns",compress=gzip_compression_is_enabled)
    @test rs == 204
    
    #from the docs
    #If a tag key, tag value, or field key contains a space , comma ,, or an equals sign = it must be escaped using the backslash character \. Backslash characters do not need to be escaped. Commas , and spaces will also need to be escaped for measurements, though equals signs = do not.

    #whitespace
    payload = """myMeasurement,tag1="valu\\ e1",tag2="value2" fieldKey="fieldValue" 1556813561098000000"""
    rs = write_data(isettings,a_random_bucket_name,payload,"ns",compress=gzip_compression_is_enabled)
    @test rs == 204

    #comma
    payload = """myMeasurement,tag1="val\\,ue1",tag2="value2" fieldKey="fieldValue" 1556813561098000000"""
    rs = write_data(isettings,a_random_bucket_name,payload,"ns",compress=gzip_compression_is_enabled)
    @test rs == 204

    #equal sign =
    payload = """myMeasurement,tag1="val\\=ue1",tag2="value2" fieldKey="fieldValue" 1556813561098000000"""
    rs = write_data(isettings,a_random_bucket_name,payload,"ns",compress=gzip_compression_is_enabled)
    @test rs == 204

    ############################################################################################################
    #passing wrong influx_precision (second, us, ms) as influx_precision will fail
    payload = """myMeasurement,tag1=value1,tag2=value2 fieldKey="fieldValue" 1556813561098000000"""
    @test_throws HTTP.Exceptions.StatusError write_data(isettings,a_random_bucket_name,payload,"s",compress=gzip_compression_is_enabled)

    payload = """myMeasurement,tag1=value1,tag2=value2 fieldKey="fieldValue" 1556813561098000000"""
    @test_throws HTTP.Exceptions.StatusError write_data(isettings,a_random_bucket_name,payload,"ms",compress=gzip_compression_is_enabled)

    payload = """myMeasurement,tag1=value1,tag2=value2 fieldKey="fieldValue" 1556813561098000000"""
    @test_throws HTTP.Exceptions.StatusError write_data(isettings,a_random_bucket_name,payload,"us",compress=gzip_compression_is_enabled)

    #us
    payload = """myMeasurement,tag1=value1,tag2=value2 fieldKey="fieldValue" 1556813561098000"""
    rs = write_data(isettings,a_random_bucket_name,payload,"us",compress=gzip_compression_is_enabled)
    @test rs == 204

    #ms
    payload = """myMeasurement,tag1=value1,tag2=value2 fieldKey="fieldValue" 1556813561098"""
    rs = write_data(isettings,a_random_bucket_name,payload,"ms",compress=gzip_compression_is_enabled)
    @test rs == 204

    #s
    payload = """myMeasurement,tag1=value1,tag2=value2 fieldKey="fieldValue" 1556813561"""
    rs = write_data(isettings,a_random_bucket_name,payload,"s",compress=gzip_compression_is_enabled)
    @test rs == 204


    ########################################################################################
    #multiline payload
    ########################################################################################
    payload = """airSensors,sensor_id=TLM0201 temperature=73.97038159354763,humidity=35.23103248356096,co=0.48445310567793615 1630424257000000000
                airSensors,sensor_id=TLM0202 temperature=75.30007505999716,humidity=35.651929918691714,co=0.5141876544505826 1630424247000000000
                airSensors,sensor_id=TLM0202 temperature=70.30007505999716,humidity=45.651929918691714,co=0.7141876544505826 1630424258000000000
                airSensors,sensor_id=TLM0202 temperature=72.30007505999716,humidity=30.651929918691714,co=0.6141876544505826 1630424259000000000"""

    rs = write_data(isettings,a_random_bucket_name,payload,"ns",compress=gzip_compression_is_enabled)
    @test rs == 204

    ########################################################################################
    #multiline payload with "missing" value for certain "columns"
    ########################################################################################
    reset_bucket(isettings,a_random_bucket_name);
    #4 values for temp, 3 value for humidity, 2 values for co2
    payload = """airSensors,sensor_id=TLM0201 temperature=73.97038159354763,humidity=35.23103248356096,co=0.48445310567793615 1630524257000000000
                airSensors,sensor_id=TLM0202 temperature=75.30007505999716,humidity=35.651929918691714 1630524247000000000
                airSensors,sensor_id=TLM0202 temperature=70.30007505999716,humidity=45.651929918691714,co=0.7141876544505826 1630524258000000000
                airSensors,sensor_id=TLM0202 temperature=72.30007505999716 1630524259000000000"""

    rs = write_data(isettings,a_random_bucket_name,payload,"ns",compress=gzip_compression_is_enabled)
    @test rs == 204

    datetime_str = string(DateTime(2000,9,30,15,59,33,0)-Hour(100),"+00:00")
        q="""from(bucket: "test_InfluxDBClient.jl_asdfeafdfasefsIyxdFDYfadsfasdfa____l")
        |> range(start: $(datetime_str))
        |> filter(fn: (r) => r["_measurement"] == "airSensors")
        |> filter(fn: (r) => r["_field"] == "co")
        |> aggregateWindow(every: 1s, fn: last, createEmpty: false)
        |> yield(name: "mean")"""
    bdy = query_flux(isettings,q)
    df = query_flux_postprocess_response(bdy,false,"ns",InfluxDBClient.utc_tz)
    @test size(df,1) == 2 

        q="""from(bucket: "test_InfluxDBClient.jl_asdfeafdfasefsIyxdFDYfadsfasdfa____l")
            |> range(start: $(datetime_str))
            |> filter(fn: (r) => r["_measurement"] == "airSensors")
            |> filter(fn: (r) => r["_field"] == "temperature")
            |> aggregateWindow(every: 1s, fn: last, createEmpty: false)
            |> yield(name: "mean")"""
        bdy = query_flux(isettings,q)
    df = query_flux_postprocess_response(bdy,false,"ns",InfluxDBClient.utc_tz)
    @test size(df,1) == 4

    q="""from(bucket: "test_InfluxDBClient.jl_asdfeafdfasefsIyxdFDYfadsfasdfa____l")
        |> range(start: $(datetime_str))
        |> filter(fn: (r) => r["_measurement"] == "airSensors")
        |> filter(fn: (r) => r["_field"] == "humidity")
        |> aggregateWindow(every: 1s, fn: last, createEmpty: false)
        |> yield(name: "mean")"""
    bdy = query_flux(isettings,q)
    df = query_flux_postprocess_response(bdy,false,"ns",InfluxDBClient.utc_tz)
    @test size(df,1) == 3

    #df2 = query_flux(isettings,a_random_bucket_name,"airSensors";range=Dict("start"=>"$datetime_str"),fields=["temperature","humidity"],tags=Dict("color"=>"blue"),aggregate=agg);
   

    #invalid payload type
    @test_throws MethodError write_data(isettings,a_random_bucket_name,Int[1,3,5],"ms",compress=gzip_compression_is_enabled)

end
    ###

delete_bucket(isettings,a_random_bucket_name);

end