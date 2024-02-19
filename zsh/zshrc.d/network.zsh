# Reduce default TIME_WAIT timeout (twice the Maximum Segment Lifetime) from 30 to 10 seconds.
# Suggested by Siege.
#sudo sysctl -w net.inet.tcp.msl=5000
