/*
�Q��Serial��J�ӱ�����w��PIN
*/
int value=0;//�x�s��J���ƭ�
int tmp_v=0;//�ƭȼȦs��
boolean change=false;//�ʧ@����X��
boolean led_status[]={false,false,false,false,false,false,false,false,false,false,false,false};//LED���A����

void setup(){
  for(int n=2;n<=13;n++){//���N2~13��PIN�]����X�Ҧ�
    pinMode(n,OUTPUT);
  }
  Serial.begin(9600);
}

void loop(){
    if(Serial.available()){//�p�GSerial����J
      value=0;
      while(Serial.available()>0){//���o��J��Byte,���ഫ��10�i��
        tmp_v=Serial.read();
        tmp_v-=48;//ASCII�X���Ʀr-48=���T��10�i��
        value=(value*10)+tmp_v;
        delay(10);
      }
      change=true;
    }
    if(change==true){
      Serial.print("Switch Pin:");
      Serial.println(value);
      if(value>=2&&value<=13){//�P�_��J�O�_��2~13���Ʀr
        switch_led(value);
      }else{
        Serial.println("Please Input 2~13");
      }
      change=false;
    }
}

void switch_led(int pin){//����PIN���A�����
  if(led_status[pin-2]==false){
    digitalWrite(pin,HIGH);
    led_status[pin-2]=true;
  }else{
    digitalWrite(pin,LOW);
    led_status[pin-2]=false;
  }
}