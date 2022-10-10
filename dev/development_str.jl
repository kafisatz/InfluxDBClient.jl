using DataFrames 
using CSV 

xxx = DataFrame(x=rand(9),y=rand(9))

@edit CSV.write(raw"C:\temp\mo.csv",xxx)

Parsers.writeshortest

#return Parsers.writeshortest(buf, pos, x, false, false, true, -1, UInt8('e'), false, opts.decimal)

len = 2^22
buf = Vector{UInt8}(undef, len)
x = 15.1531536156581681616816881612122111232
using Parsers
using BenchmarkTools

#may want to ensure that exp_form is false!
    exp_form = true
    pt = nexp + olength
    if -4 < pt <= (precision == -1 ? (T == Float16 ? 3 : 6) : precision)
        exp_form = false
    end

function test0(x) 
    nd = Parsers.writeshortest(buf, 1, x, false, false, true, -1, UInt8('e'), false,'.')
    return String(buf[1:nd])
end

function test1(x) 
    return string(x)
end

test0(x)
@btime test0(x)
@btime test1(x)
buf



