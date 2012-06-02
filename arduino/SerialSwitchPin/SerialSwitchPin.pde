/*
利用Serial輸入來控制指定的PIN
*/
int value=0;//儲存輸入的數值
int tmp_v=0;//數值暫存器
boolean change=false;//動作控制旗標
boolean led_status[]={false,false,false,false,false,false,false,false,false,false,false,false};//LED狀態紀錄

void setup(){
  for(int n=2;n<=13;n++){//先將2~13的PIN設為輸出模式
    pinMode(n,OUTPUT);
  }
  Serial.begin(9600);
}

void loop(){
    if(Serial.available()){//如果Serial有輸入
      value=0;
      while(Serial.available()>0){//取得輸入的Byte,並轉換為10進位
        tmp_v=Serial.read();
        tmp_v-=48;//ASCII碼的數字-48=正確的10進位
        value=(value*10)+tmp_v;
        delay(10);
      }
      change=true;
    }
    if(change==true){
      Serial.print("Switch Pin:");
      Serial.println(value);
      if(value>=2&&value<=13){//判斷輸入是否為2~13的數字
        switch_led(value);
      }else{
        Serial.println("Please Input 2~13");
      }
      change=false;
    }
}

void switch_led(int pin){//切換PIN狀態的函數
  if(led_status[pin-2]==false){
    digitalWrite(pin,HIGH);
    led_status[pin-2]=true;
  }else{
    digitalWrite(pin,LOW);
    led_status[pin-2]=false;
  }
}