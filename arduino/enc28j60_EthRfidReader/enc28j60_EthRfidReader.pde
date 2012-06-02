#include "etherShield.h"
#include <SoftwareSerial.h>

static uint8_t mymac[6] = {0x00,0xb9,0x41,0x10,0x06,0x84}; 
static uint8_t myip[4] = {192,168,0,1};
static uint8_t mymask[4] = {255,255,255,0};
static uint8_t mygtwy[4] = {192,168,0,253};

static uint8_t dest_ip[4]={192,168,1,1};
static uint8_t dest_mac[6];
static long local_port;
static int tmp_fg=0;

static int speaker_pin=7;

enum ETH_STATE{IDLE,ARP_SENT,ARP_REPLY,ARP_OK,ARP_END,ARP_OUT};
enum NET_STATE{INSUB,OUTSUB,UNKNOWN};
enum TCP_STATE{TCP_IDLE,SYN_SENT,TCP_ESTD,CLOSE_WAIT,CLOSEING,LAST_ACK};

static ETH_STATE arp_state;
static NET_STATE net_type=UNKNOWN;
static TCP_STATE tcp_state;
static int last_ack=0;
static boolean response_http=false;

#define BUFFER_SIZE 500
static uint8_t buf[BUFFER_SIZE+1];
static uint16_t plen;
EtherShield es=EtherShield();
#define TEMP_PIN  3


//RFID
int  val = 0; 
char code[10]; 
int bytesread = 0; 
int enable=10;
#define rxPin 8
#define txPin 9

int stopfg=0; 

void setup(){
  Serial.begin(9600);

  /*initialize enc28j60*/
  es.ES_enc28j60Init(mymac);
  es.ES_enc28j60clkout(2); // change clkout from 6.25MHz to 12.5MHz
  delay(10);
  /* Magjack leds configuration, see enc28j60 datasheet, page 11 */
  // LEDA=greed LEDB=yellow
  //
  // 0x880 is PHLCON LEDB=on, LEDA=on
  // enc28j60PhyWrite(PHLCON,0b0000 1000 1000 00 00);
  es.ES_enc28j60PhyWrite(PHLCON,0x880);
  delay(500);
  //
  // 0x990 is PHLCON LEDB=off, LEDA=off
  // enc28j60PhyWrite(PHLCON,0b0000 1001 1001 00 00);
  es.ES_enc28j60PhyWrite(PHLCON,0x990);
  delay(500);
  //
  // 0x880 is PHLCON LEDB=on, LEDA=on
  // enc28j60PhyWrite(PHLCON,0b0000 1000 1000 00 00);
  es.ES_enc28j60PhyWrite(PHLCON,0x880);
  delay(500);
  //
  // 0x990 is PHLCON LEDB=off, LEDA=off
  // enc28j60PhyWrite(PHLCON,0b0000 1001 1001 00 00);
  es.ES_enc28j60PhyWrite(PHLCON,0x990);
  delay(500);
  //
  // 0x476 is PHLCON LEDA=links status, LEDB=receive/transmit
  // enc28j60PhyWrite(PHLCON,0b0000 0100 0111 01 10);
  es.ES_enc28j60PhyWrite(PHLCON,0x476);
  delay(100);
  //init the ethernet/ip layer:
  es.ES_init_ip_arp_udp_tcp(mymac,myip,80);
  // intialize varible;
  arp_state = IDLE;
  // initialize DS18B20 datapin
  digitalWrite(TEMP_PIN, LOW);
  pinMode(TEMP_PIN, INPUT);      // sets the digital pin as input (logic 1)
  
  //RFID
  pinMode(enable,OUTPUT);       // Set digital pin 10 as OUTPUT to connect it to the RFID /ENABLE pin

  //Random
  randomSeed(analogRead(6));
  
  //speaker
  pinMode(speaker_pin, OUTPUT);
}

void loop(){
  //Parallax RFID Reader Module
  //use 125kHz
  digitalWrite(enable,LOW);
  SoftwareSerial RFID = SoftwareSerial(rxPin,txPin);
  RFID.begin(2400);
  if((val = RFID.read()) == 10){   // check for header 
    bytesread = 0; 
    while(bytesread<10){  // read 10 digit code 
      val = RFID.read(); 
      if((val == 10)||(val == 13)){  // if header or stop bytes before the 10 digit reading 
        break;                       // stop reading 
      }
      code[bytesread] = val;         // add the digit           
      bytesread++;                   // ready to read next digit  
    }

    if(bytesread == 10){  // if 10 digit read is complete 
      //Serial.print("TAG code is: ");   // possibly a good TAG 
      //Serial.println(code);            // print the TAG code
      //SEND RDIF
      set_arp();
      //Serial.print("SEND..");
      local_port=random(1024,65535);
      //Serial.println(local_port);
      send_rfid();
    }
    bytesread = 0; 
    digitalWrite(enable,HIGH);
    delay(500);                       // wait for a second
  }
}

void set_arp(){
  if(arp_state!=ARP_OK&&arp_state!=ARP_END&&arp_state!=ARP_OUT){
  //判斷網內外
    if(net_type==UNKNOWN){
      int n;
      for(n=0;n<4;n++){
        int tmp=myip[n]&mymask[n];
        int tmp2=dest_ip[n]&mymask[n];
        if(tmp!=tmp2){
          net_type=OUTSUB;
          break;
        }
      }
      if(net_type==UNKNOWN){
        net_type=INSUB;
      }
    }
    //取得mac
    int time;
    time=get_arp(50);
    if(time==0){
      arp_state=ARP_OUT;
    }
  }
}

int get_arp(int fg){
  uint16_t plen;
  if(fg==0){
    return 0;
  }
  if(arp_state==IDLE){
    if(net_type==INSUB){
      es.ES_make_arp_request(buf, dest_ip);
    }else{
      es.ES_make_arp_request(buf, mygtwy);
    }
    arp_state=ARP_SENT;
  }
  if(arp_state==ARP_SENT){
    plen = es.ES_enc28j60PacketReceive(BUFFER_SIZE, buf);
    if(plen!=0){
      if(es.ES_arp_packet_is_myreply_arp(buf)){
        arp_state = ARP_REPLY;
      }
    }
    delay(10);
    fg--;
    return get_arp(fg);
  }
  if(arp_state==ARP_REPLY){
    int i;
    for(i=0; i<6; i++){
      dest_mac[i] = buf[ETH_SRC_MAC+i];
    }
    arp_state=ARP_OK;
    return 1;
  }
}


void send_rfid(){
  int fg=tcp_post(100);
  if(response_http==true){//OK
    speaker(100,300);
    delay(50);
    if(fg!=1){
      randomSeed(analogRead(6));
    }
  }else{//Timeout
    speaker(100,250);
    delay(50);
    speaker(100,300);
    delay(50);
  }
  tcp_state=TCP_IDLE;
  last_ack=0;
  response_http=false;
}

int tcp_post(int fg){
  fg--;
  if(fg==0){
    return 0;
  }
  if(tcp_state!=TCP_IDLE){//接收訊號
    plen=es.ES_enc28j60PacketReceive(BUFFER_SIZE,buf);
    if(plen!=0&&es.ES_eth_type_is_arp_and_my_ip(buf,plen)){
      es.ES_make_arp_answer_from_request(buf);
      Serial.println("ARP_request");
    }
    if(plen==0||es.ES_eth_type_is_ip_and_my_ip(buf,plen)==0){
      delay(10);
      //Serial.print("call tcp_post : ");
      //Serial.println(fg);
      return tcp_post(fg);
    }
  }
  if(arp_state==ARP_OK){
    if(tcp_state==TCP_IDLE){//Send SYN
      es.ES_tcp_client_send_packet(buf,80,local_port,TCP_FLAG_SYN_V,1,1,0,0,dest_mac,dest_ip);
      tcp_state=SYN_SENT;
      Serial.println("SYN_SENT");
      return tcp_post(fg);
    }
    if(tcp_state==SYN_SENT&&buf[TCP_FLAGS_P]==( TCP_FLAG_SYN_V | TCP_FLAG_ACK_V )){//Send ACK
      es.ES_tcp_client_send_packet(buf,80,local_port,TCP_FLAG_ACK_V,0,0,1,0,dest_mac,dest_ip);
      Serial.println("TCP_ESTD");
      tcp_state=TCP_ESTD;
      plen = gen_client_request(buf);
      es.ES_tcp_client_send_packet(buf,80,local_port,TCP_FLAG_ACK_V|TCP_FLAG_PUSH_V,0,0,0,plen,dest_mac,dest_ip);
      return tcp_post(fg);
    }
    if(buf[TCP_FLAGS_P]==( TCP_FLAG_ACK_V )){
      Serial.println("ACK_V");
      return tcp_post(fg);
    }
    if(tcp_state==TCP_ESTD&&buf[TCP_FLAGS_P]==( TCP_FLAG_ACK_V|TCP_FLAG_PUSH_V )){
      tmp_fg=fg;
      get_http();
      fg=tmp_fg;
      if(!response_http){
        Serial.println("HTTP False");
        return 0;
      }
      plen = es.ES_tcp_get_dlength( (uint8_t*)&buf );
      es.ES_tcp_client_send_packet(buf,80,local_port,TCP_FLAG_ACK_V,0,0,plen,0,dest_mac,dest_ip);
      es.ES_tcp_client_send_packet(buf,80,local_port,TCP_FLAG_FIN_V|TCP_FLAG_ACK_V,0,0,0,0,dest_mac,dest_ip);
      Serial.println("CLOSE_WAIT");
      tcp_state=CLOSE_WAIT;
      return tcp_post(fg);
    }
    if(buf[TCP_FLAGS_P]==( TCP_FLAG_FIN_V|TCP_FLAG_ACK_V )){
      Serial.println("CLOSEING");
      if(last_ack==1){
        plen = es.ES_tcp_get_dlength( (uint8_t*)&buf );
        es.ES_tcp_client_send_packet(buf,80,local_port,TCP_FLAG_ACK_V,0,0,1,0,dest_mac,dest_ip);
        return 1;
      }else{
        last_ack++;
        return tcp_post(fg);
      }
    }
    Serial.println("UNKNOW_FLAG");
  }
}

uint16_t gen_client_request(uint8_t *buf ){
  uint16_t plen;
  byte i;
  plen=es.ES_fill_tcp_data_p(buf,0, PSTR ("GET /sensor.php?tag="));
  for(i=0;i<10;i++){
    buf[TCP_DATA_P+plen]=code[i];
    plen++;
  }
  plen= es.ES_fill_tcp_data_p(buf, plen, PSTR ( " HTTP/1.0\r\nHost: localhost\r\nUser-Agent: RDIF Eth-sensor\r\nAccept: text/html\r\nConnection: close\r\n\r\n" ));

  return plen;
}

void get_http(){
      es.ES_init_len_info(buf);
      uint16_t dat_p=es.ES_get_tcp_data_pointer();
      if(dat_p>0){
        Serial.println((char *)&(buf[dat_p]));

        response_http=true;
      }else{
        response_http=false;
      }
}

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