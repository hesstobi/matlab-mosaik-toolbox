import socket
import sys
import random
import time


def partition(alist, indices):
    return [alist[i:j] for i, j in zip([0]+indices, indices+[None])]

port = sys.argv[1]

if sys.argv[2].startswith('-'):
    messages = sys.argv[3:]
    option = sys.argv[2]
else:
    messages = sys.argv[2:]
    option = '-s'


messages = [elem.encode('ascii') for elem in messages]
headers = [bytearray([len(elem) >> i & 0xff for i in (24,16,8,0)]) for elem in messages]

messages = [b''.join([header, data]) for header, data in zip(headers,messages)]

if option == '-c':
    messages = [b''.join(messages)]
elif option == '-f' and len(messages)>1:
    numberOfSplits = random.randint(1, len(messages)-1)
    message = b''.join(messages)
    splits = list(set(random.sample(range(len(message)),numberOfSplits)))
    messages = partition(message,splits)
elif option == '-o' and len(messages)>1:
    order = random.sample(range(len(messages)),len(messages))
    messages = [ messages[i] for i in order]


HOST = ''
PORT = int(port)
sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
sock.bind((HOST, PORT))
sock.listen(1)
conn, addr = sock.accept()

for elem in messages:
    conn.send(elem)
    time.sleep(0.1)

time.sleep(0.5)
data = conn.recv(1024)
