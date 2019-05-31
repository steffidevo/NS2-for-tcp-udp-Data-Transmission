# Create a simulation object
set ns [new Simulator]

# Define different colors for data flows
$ns color 1 Blue
$ns color 2 Red

# Open NAM trace file
set nf [ open out.nam w ]
$ns namtrace-all $nf

# Open the Trace file
set tf1 [open out2.tr w]
set tf2 [open out3.tr w]
set trace-all $tf1
set trace-all $tf2
puts $tf1 "color = blue"
puts $tf2 "color = pink"

# Define a "finish" procedure
proc finish {} {
    global ns nf tf1 tf2
    close $tf1
    close $tf2
    exec /home/steffan/Documents/XGraph4.38_linux64/bin/xgraph out2.tr out3.tr -geometry 800x400 &
    exec nam out2.nam &
    exit 0
}


proc record {} {
        global sink1 sink2 tf1 tf2
    #Get an instance of the simulator
        set ns [Simulator instance]
    #Set the time after which the procedure should be called again
        set time 0.5
    #How many bytes have been received by the traffic sinks?
        set bw0 [$sink1 set bytes_]
        set bw1 [$sink2 set bytes_]
    #Get the current time
        set now [$ns now]
    #Calculate the bandwidth (in MBit/s) and write it to the files
        puts $tf1 "$now [expr $bw0/$time*8/1000000]"
        puts $tf2 "$now [expr $bw1/$time*8/1000000]"
    #Reset the bytes_ values on the traffic sinks
        $sink1 set bytes_ 0
        $sink2 set bytes_ 0
    #Re-schedule the procedures
        $ns at [expr $now+$time] "record"
}


# Create nodes
set n0 [$ns node]
set n1 [$ns node]
set n2 [$ns node]
set n3 [$ns node]
set n4 [$ns node]
set n5 [$ns node]

# Create links between the nodes
$ns duplex-link $n0 $n2 5Mb 10ms DropTail
$ns duplex-link $n1 $n2 5Mb 10ms DropTail
$ns duplex-link $n2 $n3 5Mb 10ms DropTail
$ns duplex-link $n3 $n4 5Mb 10ms DropTail
$ns duplex-link $n3 $n5 5Mb 10ms DropTail

# Set queue size for link
$ns queue-limit $n2 $n3 10

# Give node positions
$ns duplex-link-op $n0 $n2 orient right-down
$ns duplex-link-op $n1 $n2 orient right-up
$ns duplex-link-op $n2 $n3 orient rights
$ns duplex-link-op $n3 $n4 orient right-up
$ns duplex-link-op $n3 $n5 orient right-down

# Monitor the queue for link
$ns duplex-link-op $n2 $n3 queuePos 0.5

# Setup a TCP connection_1
set tcp1 [new Agent/TCP]
$tcp1 set class_ 2
$ns attach-agent $n0 $tcp1
set sink1 [ new Agent/TCPSink]
$ns attach-agent $n4 $sink1
$ns connect $tcp1 $sink1
$tcp1 set fid_ 1

# Setup a FTP over TCP connection
set ftp1 [new Application/FTP]
$ftp1 attach-agent $tcp1
$ftp1 set type_ FTP

# Setup a TCP connection_2
set tcp2 [new Agent/TCP]
$tcp2 set class_ 2
$ns attach-agent $n1 $tcp2
set sink2 [ new Agent/TCPSink]
$ns attach-agent $n5 $sink2
$ns connect $tcp2 $sink2
$tcp2 set fid_ 2

# Setup a FTP over TCP connection
set ftp2 [new Application/FTP]
$ftp2 attach-agent $tcp2
$ftp2 set type_ FTP



# Schedule event for FTP agent
$ns at 0.0 "$ftp1 start"
$ns at 0.0 "$ftp2 start"
$ns at 0.0 "record"
$ns at 4.0 "$ftp1 stop"
$ns at 4.0 "$ftp2 stop"
$ns at 5.0 "finish"
$ns run
