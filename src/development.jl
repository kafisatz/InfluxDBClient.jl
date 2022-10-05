using CodecZlib
using TranscodingStreams

strings = ["foo", "bar", "baz","asdfasdfdasfasdfasdfasdfdasfasdfasdfasdfdasfasdfasdfasdfdasfasdfasdfasdfdasfasdfasdfasdfdasfasdfasdfasdfdasfasdfasdfasdfdasfasdfasdfasdfasdfasdfasd8949318asdfa8s9df81asdf","asdfasdfdasfasdfasdfasdfdasfasdfasdfasdfdasfasdfasdfasdfdasfasdfasdfasdfdasfasdfasdfasdfdasfasdfasdfasdfdasfasdfasdfasdfdasfasdfasdfasdfasdfasdfasd8949318asdfa8s9df81asdf","asdfasdfdasfasdfasdfasdfdasfasdfasdfasdfdasfasdfasdfasdfdasfasdfasdfasdfdasfasdfasdfasdfdasfasdfasdfasdfdasfasdfasdfasdfdasfasdfasdfasdfasdfasdfasd8949318asdfa8s9df81asdf"]
length.(strings)
codec = CodecZlib.GzipCompressor()
TranscodingStreams.initialize(codec)  # allocate resources
try
    for s in strings
        data = transcode(codec, s)
        @show length(data)
        # do something...
    end
catch
    rethrow()
finally
    TranscodingStreams.finalize(codec)  # free resources
end


using CodecZlib
decompressed = transcode(ZlibDecompressor, b"x\x9cKL*JLNLI\x04R\x00\x19\xf2\x04U")
String(decompressed)