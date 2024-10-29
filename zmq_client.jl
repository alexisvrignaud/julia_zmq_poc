#!/usr/bin/env julia


using ProtoBuf
using ZMQ

"""
    SendArray(_arr::Array, _socket::Socket)

TBW
"""
function SendArray(_arr::Array, _socket::Socket)
    n_dims = Int16(ndims(_arr))
    ZMQ.send(_socket, n_dims, more=true)

    params = "type=" * string(typeof(_arr[1])) * "; n_dims=" * string(n_dims) * "; dims=["

    for dim in size(_arr)
        println("dim: ", dim)
        ZMQ.send(_socket, dim, more=true)
        params = params * string(dim) * ","
    end
    params = params[1:end-1] * "]"

    println("arr msg sent:")
    arr_msg = ZMQ.Message(_arr)
    ZMQ.send(_socket, arr_msg, more=true)

    ZMQ.send(_socket, params, more=false)
end

context = Context()

# Socket to talk to server
println("Connecting to hello world server...")
socket = Socket(context, REQ)
ZMQ.connect(socket, "tcp://localhost:5555")

data = Float32.([i*j-k for i=1:600, j=1:400, k=1:400])
println(typeof(data))

for request in 1:3
    println("Sending request $request ...")

    @time "send" SendArray(data,socket)

    # Get the reply.
    println("Waiting for response...")
    message = String(ZMQ.recv(socket))
    println("Received reply $request [ $message ]")
    #sleep(1.5)
    println("---------------")
end

# Making a clean exit.
ZMQ.close(socket)
ZMQ.close(context)

