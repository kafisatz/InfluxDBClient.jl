
@testset "Create and Delete Buckets.jl  " begin

    #get buckets
    #@time bucket_names,json = get_buckets_curl(isettings); #11ms btime, (influxdb host is on a different machine)
    @time bucket_names,json = get_buckets(isettings); #1.7 ms btime, (influxdb host is on a different machine)
    bucket_names
    @test length(bucket_names) > 0  #not sure if is possible to have ZERO buckets...? (_tasks, _monitoring) 

    #cleanup (if bucket exists from developping / testing)
    @show in(a_random_bucket_name,bucket_names)
    if in(a_random_bucket_name,bucket_names)
        @test 204 == delete_bucket(isettings,a_random_bucket_name)
    end

    #create bucket
    json = create_bucket(isettings,a_random_bucket_name)
    @test json.name == a_random_bucket_name
    @test_throws ArgumentError create_bucket(isettings,a_random_bucket_name)
    
    bucket_names,json = get_buckets(isettings);
    @test in(a_random_bucket_name,bucket_names)

    reset_bucket(isettings,a_random_bucket_name)
    #delete bucket
    @test 204 == delete_bucket(isettings,a_random_bucket_name)

    @test_throws ArgumentError delete_bucket(isettings,a_random_bucket_name)

    #errors
    organization_names,jsonORG = get_organizations(isettings)
    @unpack INFLUXDB_ORG = isettings
    ORG_ID = get_orgid(jsonORG,INFLUXDB_ORG)
    @test_throws ArgumentError get_orgid(jsonORG,"mi___ha")

    buckets,json = get_buckets(isettings;limit=100,offset=0);
    @test_throws ArgumentError BUCKET_ID = get_bucketid(json,a_random_bucket_name)
    @test_throws ArgumentError BUCKET_ID = get_bucketid(json,"mi____ha")


    #test delete_bucket return value
    reset_bucket(isettings,a_random_bucket_name);    
        rs = delete_bucket(isettings,a_random_bucket_name);
        @test rs == 204

end
