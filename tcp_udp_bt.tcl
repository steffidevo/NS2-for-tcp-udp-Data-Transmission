# Create a simulation object
set ns [new Simulator]

# Define different colors for data flows
$ns color 1 Blue
$ns color 2 Red

# Open NAM trace file
set nf [ open out.nam w ]
$ns namtrace-all $nf

#Recording data in OutputFiles
set f0 [open out2.tr w]
set f1 [open out3.tr w]
set trace-all $f0
set trace-all $f1
puts $f0 "color = blue"
puts $f1 "color = pink"

# Open the Trace file
set tf [open out.tr w]
set trace-all $tf

# Define a "finish" procedure
proc finish {} {
    global ns nf tf f0 f1
    #$ns flush-trace
    close $nf
    close $tf
    close $f0
    close $f1
    exec /home/steffan/Documents/XGraph4.38_linux64/bin/xgraph out2.tr out3.tr -geometry 800x400
    exec nam out.nam &
    exit 0
}

proc record {} {
        global sink null f0 f1
    #Get an instance of the simulator
        set ns [Simulator instance]
    #Set the time after which the procedure should be called again
        set time 0.5
    #How many bytes have been received by the traffic sinks?
        set bw0 [$sink set bytes_]
        set bw1 [$null set bytes_]
    #Get the current time
        set now [$ns now]
    #Calculate the bandwidth (in MBit/s) and write it to the files
        puts $f0 "$now [expr $bw0/$time*8/1000000]"
        puts $f1 "$now [expr $bw1/$time*8/1000000]"
    #Reset the bytes_ values on the traffic sinks
        $sink set bytes_ 0
        $null set bytes_ 0
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

# Setup a TCP connection
set tcp [new Agent/TCP]
$tcp set class_ 2
$ns attach-agent $n0 $tcp
set sink [ new Agent/TCPSink]
$ns attach-agent $n4 $sink
$ns connect $tcp $sink
$tcp set fid_ 1

# Setup a UDP connection
set udp [new Agent/UDP]
$ns attach-agent $n1 $udp
set null [ new Agent/LossMonitor]
$ns attach-agent $n5 $null
$ns connect $udp $null
$udp set fid_ 2

# Setup a FTP over TCP connection
set ftp [new Application/FTP]
$ftp attach-agent $tcp
$ftp set type_ FTP

#Setup a CBR over UDP connection
set cbr [new Application/Traffic/CBR]
$cbr attach-agent $udp
$cbr set type_ CBR
$cbr set packet_size_ 1000
$cbr set random_ false


# Schedule event for FTP agent
$ns at 0.0 "record"
$ns at 0.0 "$ftp start"
$ns at 0.0 "$cbr start"
$ns at 4.0 "$ftp stop"
$ns at 4.0 "$cbr stop"
$ns at 5.0 "finish"
$ns run
