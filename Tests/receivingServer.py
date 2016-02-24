import socket
import sys
import json
import random
import time

def partition(alist, indices):
    return [alist[i:j] for i, j in zip([0]+indices, indices+[None])]


if len(sys.argv) > 1:

    if sys.argv[1].startswith('-'):
        messages = [sys.argv[2]]
        option = sys.argv[1]
    else:
        messages = [sys.argv[1]]
        option = '-s'

    nessages = messages + ['[\"other_mesage\", [1,2,3,4,5,6,7,8], {}]','[\"other_mesage1\", [1,2,3,4,5,6,7,8], {}]','[\"other_mesage3\", [1,2,3,4,5,6,7,8], {}]']
else:
    option = '-s'
    messages = ['[\"stop\", [], {}]']


HOST = ''
PORT = 8000
sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
sock.bind((HOST, PORT))
sock.listen(1)
conn, addr = sock.accept()
data = conn.recv(1024)
print(list(data))

jsondata = json.loads("".join(map(chr, data[4:])))
ids = [elem+jsondata[1] for elem in range(len(messages))]
messages = [('[1, '+ str(idnum) +  ', ' + elem + ']') for idnum, elem in zip(ids, messages)]
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

for elem in messages:
    conn.send(elem)
    time.sleep(0.1)
