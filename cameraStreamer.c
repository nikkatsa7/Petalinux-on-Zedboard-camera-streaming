/*****************************************************************************/
/*                         I N C L U D E   F I L E S                         */
/*****************************************************************************/
#include <sys/socket.h>
#include <netinet/in.h>
#include <arpa/inet.h>
#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <errno.h>
#include <string.h>
#include <sys/types.h>
#include <sys/mman.h>
#include <fcntl.h>
#include <time.h>

/*****************************************************************************/
/*                            D E F I N E S                                  */
/*****************************************************************************/


#define CAMERA_BASE_ADDR		0x43C00000
#define CAMERA_HIGH_ADDR		0x43C0FFFF
/*****************************************************************************/
/*                                M A I N                                    */
/*****************************************************************************/

int main(void)
{
    int listenfd = 0, connfd = 0;
	int i,j,x;
	int 		fd;
	unsigned int 		*pic;
	void 		*ptr_camera;
	unsigned 	page_addr_camera;
	unsigned	page_offset_camera;
	unsigned 	page_size = sysconf(_SC_PAGESIZE);
    struct sockaddr_in serv_addr; 
    char *recvBuff;
	clock_t t;

	fd = open("/dev/mem",O_RDWR);

	page_addr_camera	= (CAMERA_BASE_ADDR & ~(page_size-1));
	page_offset_camera	= CAMERA_BASE_ADDR - page_addr_camera;
	
	ptr_camera = mmap(NULL,page_size,PROT_READ|PROT_WRITE,MAP_SHARED,fd,(CAMERA_BASE_ADDR & ~(page_size-1)));
	
	//Allocate memory for a 24-bit 640x480 rgb image
	pic = (int*)malloc(230400*sizeof(int));
	recvBuff = (char*)malloc(1*sizeof(char));

	for(i = 0; i < 230400 ; i++){
		pic[i] = 0;	
	}

	fprintf(stdout,"End Init\n");	

	//Create the TCP socket
    listenfd = socket(AF_INET, SOCK_STREAM, 0);
    memset(&serv_addr, '0', sizeof(serv_addr));
    memset(pic, '0', sizeof(pic)); 

    serv_addr.sin_family = AF_INET;
    serv_addr.sin_addr.s_addr = htonl(INADDR_ANY);
    serv_addr.sin_port = htons(5002); 

    bind(listenfd, (struct sockaddr*)&serv_addr, sizeof(serv_addr)); 

    listen(listenfd, 10); 
    connfd = accept(listenfd, (struct sockaddr*)NULL, NULL); 
    while(1)
    {
		recv(connfd,recvBuff, sizeof(char),MSG_WAITALL);
		//Wait for client request 
		if(strcmp(recvBuff,"A")){
			printf("Error in input\n");
		}else{
			printf("BUFF: %s\n",recvBuff);	
			//Freeze the camera
			*((unsigned *)(ptr_camera+page_offset_camera)) = 1; 		
			fprintf(stdout,"Sent 1\n");
			//Use clock just to measure the reading speed
			t = clock();
			//Read the image from the slv_reg1,slv_reg2,slv_reg3
			for(i = 0; i < 230400 ; i=i+3){
				pic[i] = *((unsigned *)(ptr_camera+page_offset_camera+4));	
				pic[i+1] = *((unsigned *)(ptr_camera+page_offset_camera+8));	
				pic[i+2] = *((unsigned *)(ptr_camera+page_offset_camera+12));	
			}
			t = clock() - t;
			//Send the 24-bit image through the socket
			write(connfd, pic, 921600); 
			fprintf(stdout,"Sent\n");
			printf("Elapsed time:%f\n",((float)t)/CLOCKS_PER_SEC);
			//Unfreeze the camera
			*((unsigned *)(ptr_camera+page_offset_camera)) = 0; 		
			fprintf(stdout,"Sent zero\n");
			strcpy(recvBuff,"b");
		}
	}
    close(connfd);
}
