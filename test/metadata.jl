@testset "Metadata.jl                   " begin

   #tests
    #delete_bucket(isettings,a_random_bucket_name);
    reset_bucket(isettings,a_random_bucket_name);
    
    ######################################################################
    #write some data to the bucket
    ######################################################################
            some_dt = DateTime(2022,9,30,15,59,33,33)
            df = DataFrame(sensor_id = ["TLM0900","TLM0901","TLM0901"],other_tag=["m","m","x"] ,temperature = [73.9,55.1,22.9], humidity=[14.9,55.2,3], datetime = [some_dt,some_dt-Second(51),some_dt-Second(500)])
            
            lp = lineprotocol("my_meas",df[1:1,:],["temperature","humidity"], :datetime)
            lp_want = "my_meas temperature=73.9,humidity=14.9 1664553573033000000"
            @test lp == lp_want
            @test 204 == write_data(isettings,a_random_bucket_name,lp,"ns")

    ######################################################################
    #Test functions
    ######################################################################

    measurements = query_measurements(isettings, a_random_bucket_name)
    @test measurements == ["my_meas"]

    lp = lineprotocol("my_meas2",df[1:1,:],["temperature","humidity"], :datetime)
    @test 204 == write_data(isettings,a_random_bucket_name,lp,"ns")

    measurements = query_measurements(isettings, a_random_bucket_name)
    @test sort(measurements) == sort(["my_meas","my_meas2"])

    #String(query_flux(isettings, """import "influxdata/influxdb/schema" schema.measurements(bucket: "$bucket")"""))

    for measurement in measurements
        fields = query_measurement_field_keys(isettings, a_random_bucket_name, measurement)
        #on my local machine this vector is empty, not sure why
        @warn("may need to improve this test")
        @show fields
        println("$measurement : $(join(fields, ", "))")
    end

    delete_bucket(isettings,a_random_bucket_name);
end


