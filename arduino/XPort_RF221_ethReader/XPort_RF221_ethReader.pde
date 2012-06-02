/*
Program Name : XPort_RF221_ethReader
Designer     : Guo-Wei Su (nansenat16@gmail.com)
Licence      : GNU Public Licence v2
Test & Dev   : Arduino IDE 0015
               NewSoftSerial v9

XPort      Arduino     RF-221      Speaker
TXD -----> DIG 5
RXD <----- DIG 4
           DIG 7 -----> PIN 1
           DIG 8 <----- PIN 2
           GND   <----- PIN 4
           3V3   -----> PIN 5
           DIG 9 -----------------> Red
           GND   <----------------- Black
*/
#include <NewSoftSerial.h>
//�}��w�q
#define xport_tx 4
#define xport_rx 5
#define rfid_tx 7
#define rfid_rx 8
#define speaker_pin 9

//XPort�R�O�w�q
#define IP_PORT "C192.168.53.228/80\n"
#define HTTP_REQ "/rfid.php?id="
#define HOST_NAME "HOST: localhost\r\n"

//�w�q���A�r
static int rfid_status;
#define ready 0//�ǳƴN��
#define card_exist 1//�d���s�b
#define command_send 2//�w�e�XRFID�R�O
#define command_err 16//�d�����~

static int xport_status;
#define conn_err 3//�s�����ݥ���
#define send_http_req 4//�w�e�XHTTP�n�D
#define rec_timeout 5//�����O��,�PRFID�@��
#define http_response 6//HTTP��������
#define http_200 7//HTTP 200���^��
#define http_status_err 8//HTTP�^���D200
#define http_response_body 10//HTTP���Y����,����Ϭq�}�l
#define conn_close 11//XPort�����s�u
#define req_nothing 12//�S����L�n�D
#define req_err 13//�R�O�ѪR���~
#define req_rb 14//Ū��Block
#define req_wb 15//�g�JBlock

NewSoftSerial rfid=NewSoftSerial(rfid_rx,rfid_tx);
NewSoftSerial xport=NewSoftSerial(xport_rx,xport_tx);
void setup(){
  Serial.begin(9600);//Debug
  //Serial��l��
  pinMode(rfid_rx,INPUT);
  pinMode(rfid_tx,OUTPUT);
  rfid.begin(9600);
  pinMode(xport_rx,INPUT);
  pinMode(xport_tx,OUTPUT);
  xport.begin(9600);
  delay(5000);//XPort Init
  pinMode(speaker_pin,OUTPUT);
  //���A�r
  rfid_status=ready;
  xport_status=ready;
  /*
  //�]�w�w�]��KEY
  set_key();
  if(rfid_status==command_err){
    Serial.println("Set Key Err");
  }
  select_key();
  if(rfid_status==command_err){
    Serial.println("Select Key Err");
  }
  //*/
  Serial.println("Reader Start...");
}

boolean bool_tmp;
char card_id[16];//�s��d��ID
char char16_tmp[17];//�s��HTTP���Y�Ĥ@��
char char32_tmp[33];
char char44_tmp[45];//�s��HTTP����
void loop(){
  //read_card(card_id);
  if(rfid_status==card_exist){//�p�GŪ����d��
    //Serial.println(card_id);
    if(xport_status==ready||xport_status==req_rb||xport_status==req_wb){//�p�GXPort�N���~�i��s��
      //Serial.println("xport_conn");//Debug
      bool_tmp=xport_conn();
      if(bool_tmp==false){//XPort�s�����ݦ��A������
        speaker(200,250);//�@���G�u
        delay(100);
        speaker(100,250);
        delay(50);
        speaker(100,250);
        //Serial.println("xport_conn_err");
        xport_status=conn_err;
        rfid_status=ready;
      }else{//�����s�����\
        //Serial.println("xport_conn_successful");
        if(xport_status==req_rb){
          xport_http_response_rb(char32_tmp,card_id);
          xport_status=send_http_req;
        }else if(xport_status==req_wb){
          xport_http_response_wb(char16_tmp,char32_tmp,card_id);
          xport_status=send_http_req;
        }else{
          xport_http_req(card_id);//�e�XHTTP�n�D
          xport_status=send_http_req;
        }
      }
    }
  }else{
    read_card(card_id);
  }
  if(xport_status==send_http_req){//���ݱ������A���^��
    xport_http_rec(char16_tmp,char44_tmp);
    switch(xport_status){
      case http_status_err://HTTP���A�D200
      case rec_timeout://Server
        rfid_status=ready;
        break;
      case conn_close://�����s�u
        //Serial.println(char44_tmp);//Debug
        paser_http_response(char44_tmp,char16_tmp,char32_tmp);
        switch(xport_status){
          case req_rb:
            read_block(char16_tmp,char32_tmp);
            if(rfid_status==rec_timeout||rfid_status==command_err){//Ū��Block����
              speaker(100,250);//�T���n
              delay(50);
              speaker(100,250);
              xport_status=ready;//���]���A���sŪ�d
              rfid_status=ready;
              delay(2000);//���𵥫ݤU���ʧ@
            }
            break;
          case req_wb:
            write_block(char16_tmp,char32_tmp);
            if(rfid_status==rec_timeout||rfid_status==command_err){//�g�JBlock����
              speaker(100,250);//�T���n
              delay(50);
              speaker(100,250);
              xport_status=ready;//���]���A���sŪ�d
              rfid_status=ready;
              delay(2000);//���𵥫ݤU���ʧ@
            }
            break;
          case req_nothing:
            rfid_status=ready;
            xport_status=ready;
            speaker(100,300);//���ܧ���,�T�@�n
            delay(2000);//�����קKŪ�����ƪ��d��
            break;
          case req_err:
            //Serial.println("REQ_Err");//Debug
            break;
        }//Server request block
        break;
    }//Server response block
    //Serial.println(xport_status);//Debug
    //Serial.println(rfid_status);//Debug
  }
}

void read_card(char *cardid){
  char command[10];
  int count=-2;
  char tmp;
  while(true){
    if(rfid_status==ready){
      count=-2;
      const_rfcomd(command,"A1","\0");
      rfid.print(command);
      rfid_status=command_send;
      delay(100);//Delay 100ms,HW Need delay more then 60ms
    }
    if(rfid_status==command_send){
      if(rfid.available()>0){//�p�G�����
        tmp=rfid.read();
        //Serial.print(tmp,BYTE);//Debug
        if(tmp==2){//�P�_�O�_��F��ưϬq�}�Y
          count=-1;
        }
        if(count>-2){//�p�G��ưϬq�}�l
          count++;
          if(count==1&&tmp=='N'){//��ưϬq�Ĥ@��byte��N
            //Serial.print("F");//Debug
            if(xport_status==conn_err){//���}�d���h���]���A
              //Serial.println("Reset xport_status");//Debug
              xport_status=ready;
            }
            delay(100);//�C�j100ms�ˬd�@���O�_��Tag
            rfid_status=ready;
          }
        }
        if(count>1&&count<=17){//16 char
          //Serial.print(tmp,BYTE);//Debug
          cardid[count-2]=tmp;
        }
        if(count>17){
          if(xport_status==conn_err){
            rfid_status=ready;
          }else{
            rfid_status=card_exist;
            break;
          }
        }
      }//available block
    }//command send block
  }//while loop
}

void read_block(char *block,char *data){
  char command[13];//13
  char argv[4]="M";
  int count=0;//�r�ƭp�ƾ�
  int count2=0;//����p�ƾ�
  char tmp;
  if(rfid_status!=command_send){
    argv[1]=block[0];
    argv[2]=block[1];
    argv[3]='\0';
    const_rfcomd(command,"K0",argv);
    //Serial.println(command);//Debug
    rfid.print(command);
    rfid_status=command_send;
    delay(100);
  }
  while(true){
    if(rfid.available()>0){
      count++;
      tmp=rfid.read();
      //Serial.print(tmp);//Debug
      if(tmp==3){
        rfid_status=card_exist;
        break;
      }
      if(count==8&&tmp=='N'){
        rfid_status=command_err;
        break;
      }
      if(count>9){//�qData���ĤG��byte�}�l�x�s
        data[count-10]=tmp;
        //Serial.print(tmp,BYTE);//Debug
      }
    }else{
      if(count2>10){
        rfid_status=rec_timeout;
        //Serial.println("Timeout");
        break;
      }
      delay(10);
      count2++;
    }
  }
}

void write_block(char *block,char *data){
  char command[13];//13
  char argv[36]="M";
  int count=0;//�r�ƭp�ƾ�
  int count2=0;//����p�ƾ�
  char tmp;
  if(rfid_status!=command_send){
    argv[1]=block[0];
    argv[2]=block[1];
    for(int n=0;n<32;n++){
      argv[n+3]=data[n];
    }
    argv[35]='\0';
    const_rfcomd(command,"K1",argv);
    //Serial.println(command);//Debug
    rfid.print(command);
    rfid_status=command_send;
    delay(100);
  }
  while(true){
    if(rfid.available()>0){
      count++;
      tmp=rfid.read();
      //Serial.print(tmp);//Debug
      if(tmp==3){
        rfid_status=card_exist;
        break;
      }
      if(count==8&&tmp=='N'){
        rfid_status=command_err;
        break;
      }else if(count==8&&tmp=='Y'){
        data[0]='Y';
      }
    }else{
      if(count2>10){
        rfid_status=rec_timeout;
        //Serial.println("Timeout");
        break;
      }
      delay(10);
      count2++;
    }
  }
}

boolean xport_conn(){
  int count=0;
  int tmp;
  if(xport_status==ready||xport_status==req_rb||xport_status==req_wb){
    xport.print(IP_PORT);
  }
  while(true){
    if(xport.available()>0){
      tmp=xport.read();
      //Serial.println(tmp,HEX);//Debug
      if(tmp==67){//char 'C'
        //Serial.println("XPort conn OK");//Debug
        return true;
      }else{
        //Serial.println("XPort conn Err");//Debug
        return false;
      }
    }else{
      count++;
      if(count>10){//Timeout
        //Serial.println("XPort response Timeout");//Debug
        return false;
      }
      delay(10);
    }
  }
}

void xport_http_req(char *cardid){
  xport.print("GET ");
  xport.print(HTTP_REQ);
  xport.print(cardid);
  xport.print(" HTTP/1.0\r\n");
  xport.print(HOST_NAME);
  xport.print("Connection: close\r\n\r\n");
  xport_status=send_http_req;
}

void xport_http_rec(char *http_status,char *http_body){
  //Serial.println("http_rec");
  int int_count1=0;//�r�Ʋέp
  int int_count2=0;//����έp
  int int_tmp=0;//�ƭȼȦs��
  char char4_tmp[5]="0000";//3byte�r���Ȧs��
  while(true){
    if(xport.available()>0){
      int_tmp=xport.read();
      //Serial.print(int_tmp,BYTE);//Debug
      int_count1++;
      if(int_count1<16){
        char16_tmp[int_count1-1]=int_tmp;
      }else if(int_count1==16&&xport_status==send_http_req){
        xport_status=http_response;
      }
      //HTTP header Paser
      if(xport_status==http_response){
        substr(char16_tmp,http_status,9,11);
        //Serial.println(http_status);//Debug
        if(strcmp(http_status,"200",3)){
          xport_status=http_200;
        }else{
          xport_status=http_status_err;
          break;
        }
      }
      if(xport_status==http_200){
        char4_tmp[3]=int_tmp;
        //Serial.println(char4_tmp);//Debug
        if(strcmp(char4_tmp,"\r\n\r\n",4)==true){
          xport_status=http_response_body;
          int_count1=-1;
        }
        char4_tmp[0]=char4_tmp[1];
        char4_tmp[1]=char4_tmp[2];
        char4_tmp[2]=char4_tmp[3];
        char4_tmp[3]=int_tmp;
      }
      if(xport_status==http_response_body){//����HTTP����
        //Serial.print(int_tmp,BYTE);
        if(int_count1<44){
          http_body[int_count1]=int_tmp;
        }
      }
    }else{
      if(int_count2>20){//���`���_
        if(int_tmp=='D'){
          xport_status=conn_close;
        }else{//XPort�����O��
          xport_status=rec_timeout;
        }
        break;
      }
      int_count2++;
      delay(10);
    }
  }//while loop
}

void paser_http_response(char *response,char *comm_arg1,char *comm_arg2){
  char header[5];
  char int_tmp=0;
  substr(response,header,0,4);
  if(strcmp(header,"RF221",5)==false){
    xport_status=req_err;
  }else{
    substr(response,header,6,7);
    //Serial.print("Header methed : ");
    //Serial.println(header);
    if(strcmp(header,"RB",2)==true){
      xport_status=req_rb;
      substr(response,header,9,10);
      comm_arg1[0]=header[0];
      comm_arg1[1]=header[1];
      comm_arg1[2]='\0';
      //Serial.println(comm_arg1);//Debug
    }else if(strcmp(header,"WB",2)==true){
      xport_status=req_wb;
      substr(response,header,9,10);
      comm_arg1[0]=header[0];
      comm_arg1[1]=header[1];
      comm_arg1[2]='\0';
      comm_arg2[32]='\0';
      //Serial.println(comm_arg1);//Debug
      for(int_tmp=0;int_tmp<32;int_tmp++){
        substr(response,header,(12+int_tmp),(13+int_tmp));
        comm_arg2[int_tmp]=header[0];
        //Serial.print(header[0]);//Debug
      }
    }else if(strcmp(header,"NO",2)==true){
      xport_status=req_nothing;
    }else{
      xport_status=req_err;
    }
  }
}

void xport_http_response_rb(char *data,char *cardid){
  xport.print("GET ");
  xport.print(HTTP_REQ);
  xport.print(cardid);
  xport.print("&rb=");
  for(int n=0;n<34;n++){
    xport.print(data[n]);
  }
  xport.print(" HTTP/1.0\r\n");
  xport.print(HOST_NAME);
  xport.print("Connection: close\r\n\r\n");
  xport_status=send_http_req;
}

void xport_http_response_wb(char *block,char *msg,char *cardid){
  xport.print("GET ");
  xport.print(HTTP_REQ);
  xport.print(cardid);
  xport.print("&wb=");
  xport.print(block[0]);
  xport.print(block[1]);
  xport.print(msg[0]);
  xport.print(" HTTP/1.0\r\n");
  xport.print(HOST_NAME);
  xport.print("Connection: close\r\n\r\n");
  xport_status=send_http_req;
}

void const_rfcomd(char *msg,char *myfc,char *mydata) {//RF-221 header
  msg[0]=1;//SOH
  msg[1]='S';//PT
  msg[2]='0';//ID1
  msg[3]='1';//ID2
  msg[4]=myfc[0];
  msg[5]=myfc[1];
  msg[6]=2;//STX
  int i=0;
  int m=7;
  while(mydata[i]!='\0'){
    //Serial.println(mydata[i]);//debug
    msg[m]=mydata[i];
    i++;
    m++;
  }
  msg[m]=3;
  byte bcc=msg[0];
  for(i=1;i<=m;i++){
    bcc=bcc^byte(msg[i]);
  }
  i=20;
  bcc=bcc|B100000;
  msg[m+1]=bcc;
  msg[m+2]='\0';
}

//String Function
int index(char* str,char* key){
  return (int(strstr(str,key))-int(str));
}

void substr(char* s_str,char* d_str,int s_start,int s_end){
  int m=0;
  while(m<=(s_end-s_start)){
    d_str[m]=s_str[(s_start+m)];
    m++;
  }
  d_str[m]='\0';
}

boolean strcmp(char *src,char *dst,int size){
  int n=0;
  for(n;n<size;n++){
    if(src[n]!=dst[n]){
      return false;
    }
  }
  return true;
}

void speaker(int n,int hz){
  if(n==0){
    return;
  }
  digitalWrite(speaker_pin, HIGH);
  delayMicroseconds(hz);
  digitalWrite(speaker_pin, LOW);
  delayMicroseconds(hz);
  n--;
  speaker(n,hz);
}