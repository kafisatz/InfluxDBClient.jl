
@testset "special chars in meas name.jl  " begin

    reset_bucket(isettings,a_random_bucket_name);

    #https://vscode.dev/github/kafisatz/InfluxDBClient.jl/pull/3 

    measurment_name = """my_meas"""
    some_dt = DateTime(2022,9,30,15,59,33,33)
    df = DataFrame(temperature = [73.9,55.1,22.9], humidity=[14.9,55.2,3], datetime = [some_dt,some_dt-Second(51),some_dt-Second(500)])    
    lp = lineprotocol(measurment_name,df[1:end,:],["temperature","humidity"], :datetime)
    lp_want = """$(measurment_name) temperature=73.9,humidity=14.9 1664553573033000000\n$(measurment_name) temperature=55.1,humidity=55.2 1664553522033000000\n$(measurment_name) temperature=22.9,humidity=3.0 1664553073033000000"""
    @test lp == lp_want
    @test 204 == write_data(isettings,a_random_bucket_name,lp,"ns")

    df2 = query_flux(isettings,a_random_bucket_name,measurment_name;range=Dict("start"=>minimum(df.datetime)-Day(2)),fields=["temperature"])
    @test size(df2,1) == 3
   
    #delete entries 
    delete(isettings, a_random_bucket_name, measurement=measurment_name)
    df2 = query_flux(isettings,a_random_bucket_name,measurment_name;range=Dict("start"=>minimum(df.datetime)-Day(2)),fields=["temperature"])
    @test size(df2,1) == 0

    measurment_name = """RANDOM~A_B.C_D"""
    lp = lineprotocol(measurment_name,df[1:end,:],["temperature","humidity"], :datetime)
    @test 204 == write_data(isettings,a_random_bucket_name,lp,"ns")
    df2 = query_flux(isettings,a_random_bucket_name,"my_meas";range=Dict("start"=>minimum(df.datetime)-Day(2)),fields=["temperature"])
    @test size(df2,1) == 0
    
    df2 = query_flux(isettings,a_random_bucket_name,measurment_name;range=Dict("start"=>minimum(df.datetime)-Day(2)),fields=["temperature"])
    @test size(df2,1) == 3
    
    delete(isettings, a_random_bucket_name, measurement=measurment_name)
    df2 = query_flux(isettings,a_random_bucket_name,measurment_name;range=Dict("start"=>minimum(df.datetime)-Day(2)),fields=["temperature"])
    @test size(df2,1) == 0
    
    delete_bucket(isettings,a_random_bucket_name);

end