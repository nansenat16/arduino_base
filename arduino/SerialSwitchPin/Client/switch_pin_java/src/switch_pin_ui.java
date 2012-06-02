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
			System.out.println("�s�����ѡA�Э��s���\n");
			init();
		}
	}
	private String select_port()throws Exception{
		Object[] tmp=rs232.get_port_name_list();
		System.out.println("===�ǦC��C��===");
		for(int n=0;n<tmp.length;n++){
			System.out.println((String)tmp[n]);
		}
		System.out.print("�п�ܳs�����ǦC��W�١G");
		return input.readLine();
	}
	private void switch_pin()throws Exception{
		System.out.print("�п�J�n�������}�츹�X�G");
		String pin=input.readLine();
		if(pin.matches("\\d{1,2}")){
			int n=Integer.valueOf(pin);
			if(n>=2&&n<=13){
				rs232.write(pin);
				System.out.println("����PIN "+pin);
			}else{
				System.out.println("��J���}�츹�X���~!!�п�J�d��2~13���Ʀr\n");
			}
		}else{
			System.out.println("��J���}�츹�X���~!!�п�J�d��2~13���Ʀr\n");
		}
		switch_pin();
	}
}