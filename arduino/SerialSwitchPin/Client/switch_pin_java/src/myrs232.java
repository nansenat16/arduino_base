/*
更多資訊請參考
http://www.captain.at/howto-java-serial-port-javax-comm-rxtx.php
http://rxtx.qbang.org/wiki/index.php/Main_Page
http://www.rxtx.org/
*/
import java.io.*;
import java.util.*;
import gnu.io.*; //rxtxSerial 函式庫

public class myrs232{
	static CommPortIdentifier portId;
	static Enumeration portList;
	static SerialPort serialPort;
	static List<String> port_name_list=new ArrayList<String>();

	public myrs232(){
		portList=CommPortIdentifier.getPortIdentifiers();
		while(portList.hasMoreElements()){
			portId=(CommPortIdentifier)portList.nextElement();
			if(portId.getPortType()==CommPortIdentifier.PORT_SERIAL){
				port_name_list.add(portId.getName());
			}
		}
	}

	public Object[] get_port_name_list(){
		return port_name_list.toArray();
	}

	public boolean open(String port_name){
		portList=CommPortIdentifier.getPortIdentifiers();
		while(portList.hasMoreElements()){
			portId=(CommPortIdentifier)portList.nextElement();
			if(portId.getPortType()==CommPortIdentifier.PORT_SERIAL&&portId.getName().equals(port_name)){
				try{
					serialPort=(SerialPort)portId.open("myrs232",2000);
					serialPort.setSerialPortParams(9600, SerialPort.DATABITS_8,SerialPort.STOPBITS_1,SerialPort.PARITY_NONE);
					return true;
				}catch(Exception e){
					e.printStackTrace();
					return false;
				}
			}
		}
		return false;
	}

	public void write(String str)throws Exception{
		serialPort.getOutputStream().write(str.getBytes());
	}

	public void close(){
		serialPort.close();
	}
}