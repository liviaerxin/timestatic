import time
logfile = "tmp.log"

def readlog():
	with open("./hls_ssl_request.log","r") as f:
		while True:
			line = f.readline()
			if line:
				yield line
			else:
				return

with open(logfile,"wr") as f:
	for line in readlog():
		f.write(line)
		f.flush()
		#control time to write into the log
		print line
		time.sleep(3)
			
