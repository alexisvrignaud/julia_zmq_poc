#!/usr/bin/env julia

# Hello World server in Julia
# Binds REP socket to tcp://*:5555
# Expects "Hello" from client, replies "World"

using ZMQ

context = Context()
socket = Socket(context, REP)
ZMQ.bind(socket, "tcp://*:5555")

function ReceiveArray(_socket::Socket)
    #Receive first message containing the number of dimensions
    _message = ZMQ.recv(socket)

    # read first 2 bytes for int16 ndims
    ndims_buf = _message[1:2]
    ndims = reinterpret(Int16, ndims_buf)[1]

    _shape = []
    #Receive messages containing array size for each dimensions
    for _ in 1:ndims
        _message = ZMQ.recv(socket)
        # read first 2 bytes for int16 ndims
        axis_size_buf  = _message[1:2]
        axis_size = reinterpret(Int16, axis_size_buf)[1]

        #add to a list, to be used later in the reshape function.
        push!(_shape, axis_size)
    end

    #Receive the bulk of the array data
    _message = ZMQ.recv(socket)
    vec = reinterpret(Float32, _message) #will change to a Int8 vector
    arr = reshape(vec, tuple(_shape...))

    #Receive params
    _message = String(ZMQ.recv(socket))
    #println(_message)
end

while true
    println("New loop:")

    # Wait for next request from client
    @time "receive" ReceiveArray(socket)

    # Do some 'work'
    #sleep(2.5)

    # Send reply back to client
    ZMQ.send(socket, "Array received")
end

# classy hit men always clean up when finish the job.
ZMQ.close(socket)
ZMQ.close(context)
