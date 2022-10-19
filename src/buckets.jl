#https://docs.influxdata.com/influxdb/cloud/api/
#https://docs.influxdata.com/influxdb/cloud/organizations/buckets/create-bucket/ 

export bucket_exists
function bucket_exists(isettings,bucket)
    buckets,_ = get_buckets(isettings;limit=100,offset=0)
    return in(bucket,buckets)
end

export create_bucket
function create_bucket(isettings,bucket,content::String="")
    #https://docs.influxdata.com/influxdb/cloud/api/#operation/PostBuckets
    @unpack INFLUXDB_HOST,INFLUXDB_TOKEN,INFLUXDB_ORG = isettings
    
    buckets,_ = get_buckets(isettings;limit=100,offset=0)
    if in(bucket,buckets)
        throw(ArgumentError("Bucket $bucket already exists"))
    end

    organization_names,jsonORG = get_organizations(isettings)
    ORG_ID = get_orgid(jsonORG,INFLUXDB_ORG)

    if length(content) == 0
        content = """{"name": "$bucket", "orgID": "$ORG_ID"}"""
    end

    r = HTTP.request("POST", """http://$(INFLUXDB_HOST)/api/v2/buckets""", ["Authorization" => "Token $(INFLUXDB_TOKEN)", "Accept"=>"application/json","Content-Type"=>"application/json"],body=content)
    if !in(r.status,[201])
        @warn "Unexpected status" r.status
    end

    json = JSON3.read(String(r.body))

    return json
end 

export delete_bucket
function delete_bucket(isettings,bucket)
    @unpack INFLUXDB_HOST,INFLUXDB_TOKEN = isettings
    buckets,json = get_buckets(isettings;limit=100,offset=0);
    if !in(bucket,buckets)
        msg = "Unable to delete bucket $bucket as it does not exist."
        throw(ArgumentError(msg))
    end

    BUCKET_ID = get_bucketid(json,bucket)

    r = HTTP.request("DELETE", """http://$(INFLUXDB_HOST)/api/v2/buckets/$BUCKET_ID""", ["Authorization" => "Token $(INFLUXDB_TOKEN)", "Accept"=>"application/json"])
    #if !in(r.status,[200,204])
    if !in(r.status,[204]) #api shows that 204 should be returned
        @warn "Unexpected status" r.status
    end
    #"Content-Type"=>"text/plain; charset=utf-8"

    return r.status
end

export get_bucketid
function get_bucketid(json,bucket)
    bucket_names = map(x->x.name,json.buckets)

    #get id from bucket name 
    idx = bucket_names.==bucket
    if sum(idx) != 1
        throw(ArgumentError("Bucket $bucket not found in json"))
    end
    BUCKET_ID = json.buckets[idx][1].id
    return BUCKET_ID
end 

export get_buckets
function get_buckets(isettings;limit=100,offset=0)
    @unpack INFLUXDB_HOST,INFLUXDB_TOKEN = isettings

    r = HTTP.request("GET", """http://$(INFLUXDB_HOST)/api/v2/buckets?limit=$limit&offset=$offset""", ["Authorization" => "Token $(INFLUXDB_TOKEN)", "Content-Type"=>"text/plain; charset=utf-8","Accept"=>"application/json"] )
    if r.status != 200 
        @warn "Unexpected status" r.status
    end

    json = JSON3.read(String(r.body))

    bucket_names = map(x->x.name,json.buckets)
    return bucket_names,json
end

export get_organizations
function get_organizations(isettings;limit=100,offset=0)
    @unpack INFLUXDB_HOST,INFLUXDB_TOKEN = isettings

    r = HTTP.request("GET", """http://$(INFLUXDB_HOST)/api/v2/orgs?limit=$limit&offset=$offset""", ["Authorization" => "Token $(INFLUXDB_TOKEN)", "Content-Type"=>"text/plain; charset=utf-8","Accept"=>"application/json"] )
    if r.status != 200
        @warn "Unexpected status" r.status
    end

    json = JSON3.read(String(r.body))

    organization_names = map(x->x.name,json.orgs)
    return organization_names,json
end

export get_orgid
function get_orgid(json,org)
    org_names = map(x->x.name,json.orgs)

    #get id from org name 
    idx = org_names.==org
    if sum(idx) != 1
        throw(ArgumentError("org $org not found in json"))
    end
    org_ID = json.orgs[idx][1].id
    return org_ID
end 

#=
export get_buckets_curl
function get_buckets_curl(isettings;limit=100,offset=0)
    @unpack INFLUXDB_HOST,INFLUXDB_TOKEN = isettings
    cmd = `curl -s --request GET "http://$(INFLUXDB_HOST)/api/v2/buckets?limit=$limit&offset=$offset" --header "Authorization: Token $(INFLUXDB_TOKEN)" --header "Content-Type: text/plain; charset=utf-8" --header "Accept: application/json"`
    rs = read(cmd, String)
    json = JSON3.read(rs)
    bucket_names = map(x->x.name,json.buckets)
    return bucket_names,json
  end
=#

  #=
  https://docs.influxdata.com/influxdb/cloud/organizations/buckets/create-bucket/
  https://docs.influxdata.com/influxdb/cloud/organizations/buckets/create-bucket/

  curl --request GET "http://localhost:8086/api/v2/buckets?name=_monitoring" \
  --header "Authorization: Token INFLUX_TOKEN" \
  --header "Accept: application/json" \
  --header "Content-Type: application/json"

  =#