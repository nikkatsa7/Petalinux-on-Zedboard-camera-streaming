import socket
import struct
import pygame
import time
import timeit
msg = ''
string = ''
old_msg = ''

port = 5002
screen = pygame.display.set_mode((640,480))

s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
#The zedboard IP address
s.connect(('192.168.1.10',port))

while(1):
	#Send Request to the server
	s.send('A')
	string = ''
	msg = ''
	#To measure download time
	start1 = time.time()
	
	#Receive the image
	for y in range(921600/8):
		msg += s.recv(8)

	end1 = time.time()
	print '----Downloaded---- with time \n', (end1-start1)

	#In case of a packet loss use the previous downloaded image
	if(len(msg) != 921600):
		print "Receive wrong image size:%d\n" %len(msg)
		msg = old_msg
	
	old_msg = msg
	start2 = time.time()
	#Create the image from the received from socket string 
	image = pygame.image.fromstring(msg,(640,480),"RGB")
	screen.blit(image,(0,0))
	pygame.display.update()
	end2 = time.time() 
	
#close the socket
s.close

