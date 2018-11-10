import java.sql.PreparedStatement; 
import java.sql.Statement;
import java.sql.Connection; 
import java.sql.DriverManager; 
import java.sql.SQLException; 
import java.sql.Array;
import java.sql.ResultSet;

class ConcurrencyAnomaly1 implements Runnable { 

	private static final String CONNECTION = "jdbc:postgresql://localhost/dellstore2";
	private static final String USER = "postgres";
	private static final String PASSWORD = "";
	 
    // let's assume customer 1 is going to place 2 orders simultaneously
	private static final int CUSTOMER = 1;
    
    // customer is going to buy the same product, let's say, product 2
	private static final int PRODUCT = 2; 
	
    // customer is going to buy 3 units
        private static final int QUANTITY = 3 ; 
    
    
        private Integer[] product_array = new Integer[] {PRODUCT};
        private Integer[] quantity_array = new Integer[] {QUANTITY};
     
	  
        //create_order(customer_id, ordered_products, quantity_products, dtax)
	private static final String ORDER = "SELECT create_order(" + CUSTOMER + ", ?, ?, 0.23);";
	
	
        private Connection objConnection = null; 
	private PreparedStatement statement = null;
	private int numThread = 0; 
	private ResultSet objResult = null;
	
	public ConcurrencyAnomaly1(int numThread) { 
		this.numThread = numThread; 
		System.out.println("Creating instance " + numThread); 
	} 
	
	public void run() { 
		
		System.out.println("Starting thread " + numThread ); 
           
		try {          
			objConnection = DriverManager.getConnection(CONNECTION, USER, PASSWORD); 
			objConnection.setAutoCommit(false); 
			
			Array products = objConnection.createArrayOf("integer", product_array);
                        Array quantity = objConnection.createArrayOf("integer", quantity_array); 
					
			try { 
			
				statement = objConnection.prepareStatement(ORDER); 
				statement.setArray(1, products);
                                statement.setArray(2, quantity);                    
				
				System.out.println("Calling now " + numThread ); 
				objResult = statement.executeQuery(); 

				//get first and only record
				objResult.next();
				
				
				//close the statement
				statement.close(); 		
			
				// If done with success commit the operations 
				objConnection.commit(); 
				
			} catch (SQLException e) { 
				// If something has failed rollback the operations 
				statement.close(); 
				objConnection.rollback();  
				System.out.println("Order of thread " + numThread + " was not successful."); 
				System.out.println(e.getMessage());
			} catch (Exception e) {
				System.out.println(e.getMessage());
			}
			
			// Free resources 
			objConnection.close(); 
		} catch (SQLException e) { 
			System.out.println(e.getMessage()); 
		} 
		
		System.out.println("The end of thread " + numThread); 
	} 
	
	public static void main(String args[]) throws SQLException, InterruptedException {
		
                try { 
			Class.forName("org.postgresql.Driver"); 
		} catch (ClassNotFoundException e) { 
			e.printStackTrace(); 
		} 	
				
                ConcurrencyAnomaly1 objInstance1= new ConcurrencyAnomaly1(1);
                ConcurrencyAnomaly1 objInstance2= new ConcurrencyAnomaly1(2);
                
		
                //Create thread for each instance
                Thread objThread1 = new Thread(objInstance1);
                Thread objThread2 = new Thread(objInstance2);
        
                objThread1.start();
                objThread2.start();
		
		  
                try{
                    objThread1.join();
                    objThread2.join();
		} catch (InterruptedException objExcepcao) { 
		}
		
		// to be able to check inventory after operations
		Connection objConnection = null; 
		ResultSet objResult = null;
		Statement objStatement = null;
			
		objConnection = DriverManager.getConnection(CONNECTION, USER, PASSWORD);  
               
		objStatement = objConnection.createStatement();
		objResult = objStatement.executeQuery("SELECT * FROM inventory WHERE prod_id = " + PRODUCT + ";"); 
		
		//get record
		objResult.next();
		
		int quantity = objResult.getInt("quan_in_stock");
		int sales = objResult.getInt("sales");
		
		System.out.println("quan_in_stock of prod_id " + PRODUCT + "= " + quantity + " and sales= " + sales);
		
		// Free resources. 
		objResult.close();
		objStatement.close();
		objConnection.close(); 
					
		System.out.println("The end"); 		
	} 
}