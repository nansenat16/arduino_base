Arduino Base
===============
這是於2009年間使用Arduino與RFID模組建構低成本與開放的基礎開發環境專題

使用下列零件

* Arduino Duemilanove
* RF-221 RFID module (13.56mhz)
* Parallax brand RFID reader (125khz)
* XPort module
* Arduino Ethernet Shield V1.0 (ENC28J60)
* 壓電式蜂鳴片

成果

* 第一版 enc28j60_EthRfidReader 低頻被動式的唯讀Reader + L2網路模組
* 第二版 XPort_RF221_ethReader 高頻被動式可讀寫Reader + L3的XPort
* Reader與後端連線使用HTTP協定


.. image:: https://github.com/nansenat16/arduino_base/raw/master/doc/system_overview.png