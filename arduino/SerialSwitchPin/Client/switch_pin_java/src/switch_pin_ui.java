import java.io.*;

public class switch_pin_ui{
	BufferedReader input=new BufferedReader(new InputStreamReader(System.in));
	private myrs232 rs232=new myrs232();
	public static void main(String args[])throws Exception{
		new switch_pin_ui().init();
	}
	private void init()throws Exception{
		if(rs232.open(select_port())){
			switch_pin();
		}else{
			System.out.println("連接失敗，請重新選擇\n");
			init();
		}
	}
	private String select_port()throws Exception{
		Object[] tmp=rs232.get_port_name_list();
		System.out.println("===序列埠列表===");
		for(int n=0;n<tmp.length;n++){
			System.out.println((String)tmp[n]);
		}
		System.out.print("請選擇連接的序列埠名稱：");
		return input.readLine();
	}
	private void switch_pin()throws Exception{
		System.out.print("請輸入要切換的腳位號碼：");
		String pin=input.readLine();
		if(pin.matches("\\d{1,2}")){
			int n=Integer.valueOf(pin);
			if(n>=2&&n<=13){
				rs232.write(pin);
				System.out.println("切換PIN "+pin);
			}else{
				System.out.println("輸入的腳位號碼錯誤!!請輸入範圍2~13的數字\n");
			}
		}else{
			System.out.println("輸入的腳位號碼錯誤!!請輸入範圍2~13的數字\n");
		}
		switch_pin();
	}
}