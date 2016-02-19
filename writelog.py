import time
# decorator wrap around the coroutine
def coroutine(func):
	def wrap(*arg, **args):
		result = func(*arg, **args)
		result.next()
		return result
	return wrap

# simple coroutine
def printer():
	while True:
		line = yield
		print line
pr = printer() 
pr.next()
pr.send("hello")
pr.send("happy")

# simple coroutine with decorator
@coroutine
def printer():
	while True:
		line = yield
		print line

pr = printer()
pr.send("decorator hello")
import time
# tail
def tail(file, target):
	file.seek(0,2)
	while True:
		line = file.readline()
		if not line:
			time.sleep(0.1)
			continue
		target.send(line)	

# sink--filter
@coroutine
def filter(pattern, target):
	while True:
		line = yield
		if pattern in line:
			target.send(line)


file = open("/home/siyaochen/snippets/simullog/tmp.log","r")
tail(file, filter("",printer()))
