@testset "delete.jl                     " begin

#https://docs.influxdata.com/influxdb/v2.4/write-data/delete-data/

#=
curl --request POST http://localhost:8086/api/v2/delete?org=example-org&bucket=example-bucket \
  --header 'Authorization: Token YOUR_API_TOKEN' \
  --header 'Content-Type: application/json' \
  --data '{
    "start": "2020-03-01T00:00:00Z",
    "stop": "2020-11-14T00:00:00Z",
    "predicate": "_measurement=\"example-measurement\" AND exampleTag=\"exampleTagValue\""
  }'

=#

    reset_bucket(isettings,a_random_bucket_name);

    #buckets,_ = get_buckets(isettings;limit=100,offset=0)
    bucket = a_random_bucket_name
    @unpack INFLUXDB_HOST,INFLUXDB_TOKEN,INFLUXDB_ORG = isettings
    organization_names,jsonORG = get_organizations(isettings)
    ORG_ID = get_orgid(jsonORG,INFLUXDB_ORG)
    gzip_compression_is_enabled = false

    hdrs = Dict("Authorization" => "Token $(INFLUXDB_TOKEN)", "Content-Type"=>"application/json")
    url = """http://$(INFLUXDB_HOST)/api/v2/delete?org=$INFLUXDB_ORG&bucket=$bucket"""
    content = """{"name": "$bucket", "orgID": "$ORG_ID"}"""
    
    payload_to_write = """airSensors,sensor_id=TLM0201 temperature=73.97038159354763,humidity=35.23103248356096,co=0.48445310567793615 1630424257000000000
                airSensors,sensor_id=TLM0202 temperature=75.30007505999716,humidity=35.651929918691714,co=0.5141876544505826 1630424247000000000
                airSensors,sensor_id=TLM0202 temperature=70.30007505999716,humidity=45.651929918691714,co=0.7141876544505826 1630424258000000000
                airSensors,sensor_id=TLM0202 temperature=72.30007505999716,humidity=30.651929918691714,co=0.6141876544505826 1630424259000000000"""
    rs = write_data(isettings,a_random_bucket_name,payload_to_write,"ns",compress=gzip_compression_is_enabled)
    @test rs == 204

    datetime_str = string(DateTime(2000,9,30,15,59,33,0)-Hour(100),"+00:00")
    q="""from(bucket: "test_InfluxDBClient.jl_asdfeafdfasefsIyxdFDYfadsfasdfa____l")
        |> range(start: $(datetime_str))
        |> filter(fn: (r) => r["_measurement"] == "airSensors")
        |> aggregateWindow(every: 1s, fn: last, createEmpty: false)
        |> yield(name: "mean")"""
    bdy = query_flux(isettings,q)
    df = query_flux_postprocess_response(bdy,false,"ns",InfluxDBClient.utc_tz)
    @test size(df,1) == 12

    #specifying measurement and tag
    bdy = """{ "predicate": "_measurement = airSensors and sensor_id=TLM0201",
        "start": "2009-08-24T14:15:22Z",
        "stop": "2039-08-24T14:15:22Z" }"""
    r = HTTP.request("POST", url, hdrs, body = bdy)
    @test r.status == 204

    bdy = query_flux(isettings,q)
    df = query_flux_postprocess_response(bdy,false,"ns",InfluxDBClient.utc_tz)
    @test size(df,1) == 9

    #specifying only time range
    bdy = """{ "start": "2009-08-24T14:15:22Z",
        "stop": "2039-08-24T14:15:22Z" }"""
    JSON3.read(bdy)
    r = HTTP.request("POST", url, hdrs, body = bdy)
    @test r.status == 204
    bdy = query_flux(isettings,q)
    df = query_flux_postprocess_response(bdy,false,"ns",InfluxDBClient.utc_tz)
    @test size(df,1) == 0

    #specifying time range and measurement
    payload_to_write = """airSensors,sensor_id=TLM0201 temperature=73.97038159354763,humidity=35.23103248356096,co=0.48445310567793615 1000424257000000000
    airSensors,sensor_id=TLM0202 temperature=75.30007505999716,humidity=35.651929918691714,co=0.5141876544505826 1630424247000000000
    airSensors,sensor_id=TLM0202 temperature=70.30007505999716,humidity=45.651929918691714,co=0.7141876544505826 1630424258000000000
    airSensors,sensor_id=TLM0202 temperature=72.30007505999716,humidity=30.651929918691714,co=0.6141876544505826 1630424259000000000"""
    rs = write_data(isettings,a_random_bucket_name,payload_to_write,"ns",compress=gzip_compression_is_enabled)
    @test rs == 204

    bdy = """{ "predicate": "_measurement = airSensors",
        "start": "2009-08-24T14:15:22Z",
        "stop": "2039-08-24T14:15:22Z" }"""
    r = HTTP.request("POST", url, hdrs, body = bdy)
    @test r.status == 204

    bdy = query_flux(isettings,q)
    df = query_flux_postprocess_response(bdy,false,"ns",InfluxDBClient.utc_tz)
    @test size(df,1) == 3

    #delete measurement

    #delete responses show these min/max times which define the valid range
    influxb_time_minimum = "1677-09-21T00:12:44Z"
    influxb_time_maximum = "2262-04-11T23:47:16Z"
    
    bdy = """{ "predicate": "_measurement = airSensors",
    "start": "1677-09-21T00:12:44Z",
    "stop": "2262-04-11T23:47:16Z" }"""
    r = HTTP.request("POST", url, hdrs, body = bdy)
    @test r.status == 204

    rs = delete(isettings,a_random_bucket_name,measurement="")
    @test rs == 204

    tags = Dict("sensor_id"=>"TMLX1","color"=>"blue")
    rs = delete(isettings,a_random_bucket_name,tags=tags);
    @test rs == 204

    tags = Dict("sensor_id"=>"TMLX1","color"=>"blue")
    rs = delete(isettings,a_random_bucket_name,tags=tags,measurement="mihu");
    @test rs == 204

    tags = Dict("sensor_id"=>"TMLX1","color"=>"blue")
    rs = delete(isettings,a_random_bucket_name,measurement="mihu");
    @test rs == 204

    tags = Dict("sensor_id"=>"TMLX1","color"=>"blue")
    @test_throws HTTP.Exceptions.StatusError delete(isettings,a_random_bucket_name,measurement="mihu",start="asdf")

    tags = Dict("sensor_id"=>"TMLX1","color"=>"blue")
    @test 204 == delete(isettings,a_random_bucket_name,measurement="mihu",start="2262-04-11T23:47:16Z")
    @test 204 == delete(isettings,a_random_bucket_name,measurement="mihu",start="2262-04-11T23:47:16Z",stop="2262-04-11T23:47:16Z")

    @test 204 == delete(isettings,a_random_bucket_name,measurement="mihu",start="2222-04-11T23:47:16Z",stop="2222-03-11T23:47:16Z")

    @test 204 == delete(isettings,a_random_bucket_name,measurement="mihu",stop="2222-03-11T23:47:16Z")

    @test 204 == delete(isettings,a_random_bucket_name,measurement="mihu",stop="2222-03-11T23:47:16Z",start=now())
    @test 204 == delete(isettings,a_random_bucket_name,measurement="mihu",stop=now()+Hour(1),start=now())

    #end of these tests
    delete_bucket(isettings,a_random_bucket_name);
    
end