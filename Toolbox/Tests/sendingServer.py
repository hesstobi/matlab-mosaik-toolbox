import socket
import sys

data = sys.argv[1].encode('ascii')

header = bytearray([len(data) >> i & 0xff for i in (24,16,8,0)])
data = b''.join([header,data])

HOST = ''
PORT = 8000
sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
sock.bind((HOST, PORT))
sock.listen(1)
conn, addr = sock.accept()
conn.send(data)
data = conn.recv(1024)
