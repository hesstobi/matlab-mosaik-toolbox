import socket
import sys



HOST = ''
PORT = 8000
sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
sock.bind((HOST, PORT))
sock.listen(1)
conn, addr = sock.accept()
data = conn.recv(1024)
print(list(data))
answer = '[0, 0, ["stop\", [], {}]]'.encode('ascii')
header = bytearray([len(answer) >> i & 0xff for i in (24,16,8,0)])
answer = b''.join([header,answer])
conn.send(answer)
