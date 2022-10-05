@testset "write.jl                      " begin

@test_throws ArgumentError write_data(isettings,a_random_bucket_name,"do_not_care","ns")

#tests
#delete_bucket(isettings,a_random_bucket_name);
create_bucket(isettings,a_random_bucket_name);

#call without compression keyword
payload = """myMeasurement,tag1=value1,tag2=value2 fieldKey="fieldValue" 1556813561098000000"""
rs = write_data(isettings,a_random_bucket_name,payload,"ns")
@test rs == 204

for gzip_compression_is_enabled in [false,true]
    if gzip_compression_is_enabled
        @info("Testing write_data WITH gzip compression...")
    else 
        @info("Testing write_data WITHOUT gzip compression...")
    end

    payload = """myMeasurement,tag1=value1,tag2=value2 fieldKey="fieldValue" 1556813561098000000"""
    rs = write_data(isettings,a_random_bucket_name,payload,"ns",compress=gzip_compression_is_enabled)
    @test rs == 204

    PRECISIONS

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
                airSensors,sensor_id=TLM0202 temperature=75.30007505999716,humidity=35.651929918691714,co=0.5141876544505826 1630424257000000000
                airSensors,sensor_id=TLM0202 temperature=70.30007505999716,humidity=45.651929918691714,co=0.7141876544505826 1630424258000000000
                airSensors,sensor_id=TLM0202 temperature=72.30007505999716,humidity=30.651929918691714,co=0.6141876544505826 1630424259000000000"""

    rs = write_data(isettings,a_random_bucket_name,payload,"ns",compress=gzip_compression_is_enabled)
    @test rs == 204

    #invalid payload type
    @test_throws MethodError write_data(isettings,a_random_bucket_name,Int[1,3,5],"ms",compress=gzip_compression_is_enabled)

end
    ###

delete_bucket(isettings,a_random_bucket_name);

end