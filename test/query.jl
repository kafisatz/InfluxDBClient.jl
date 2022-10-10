@testset "query.jl                      " begin

    @info("query tests are still rudimentary...")
        
    create_bucket(isettings,a_random_bucket_name);

    #call without compression keyword
    payload = """myMeasurement,tag1=value1,tag2=value2 fieldKey="fieldValue" 1556813561098000000"""
    rs = write_data(isettings,a_random_bucket_name,payload,"ns")
    @test rs == 204

    #########################################################################################################
    #testing query function
    #########################################################################################################
    
    resp = query_flux(isettings,a_random_bucket_name,"my_meas",range=Dict("start"=>"-100d"))
    @test typeof(resp) == Vector{UInt8}
    #next call should not throw an error 
    str = String(resp)
    @test typeof(str) == String
    @test length(str) > 0


    delete_bucket(isettings,a_random_bucket_name);

end