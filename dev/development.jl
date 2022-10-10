using CodecZlib
using TranscodingStreams

x=rand()
strings = ["foo", "$x", x,"asdfasdfdasfasdfasdfasdfdasfasdfasdfasdfdasfasdfasdfasdfdasfasdfasdfasdfdasfasdfasdfasdfdasfasdfasdfasdfdasfasdfasdfasdfdasfasdfasdfasdfasdfasdfasd8949318asdfa8s9df81asdf","asdfasdfdasfasdfasdfasdfdasfasdfasdfasdfdasfasdfasdfasdfdasfasdfasdfasdfdasfasdfasdfasdfdasfasdfasdfasdfdasfasdfasdfasdfdasfasdfasdfasdfasdfasdfasd8949318asdfa8s9df81asdf","asdfasdfdasfasdfasdfasdfdasfasdfasdfasdfdasfasdfasdfasdfdasfasdfasdfasdfdasfasdfasdfasdfdasfasdfasdfasdfdasfasdfasdfasdfdasfasdfasdfasdfasdfasdfasd8949318asdfa8s9df81asdf"]
length.(strings)
codec = CodecZlib.GzipCompressor()
TranscodingStreams.initialize(codec)  # allocate resources
data = UInt8[]
for s in strings
    d = transcode(codec, s)
    #@show length(d)
    append!(data,d)
    # do something...
end

TranscodingStreams.finalize(codec)  # free resources

data

decompressed = transcode(GzipDecompressor,data)
String(decompressed)

#=
using CodecZlib
decompressed = transcode(ZlibDecompressor, b"x\x9cKL*JLNLI\x04R\x00\x19\xf2\x04U")
String(decompressed)
=#

x
io = IOBuffer();

 write(io, "JuliaLang is a GitHub organization.", " It has many members.")
write(io,x)

 String(take!(io))