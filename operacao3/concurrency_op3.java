
// ----------------------------------------------------------------------------
// testq3.java - Testing query 3 concurrency problems
// ----------------------------------------------------------------------------

// ----------------------------------------------------------------------------


//2018-11-07


// Importação da funcionalidade JDBC.
import java.sql.CallableStatement;
import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.SQLException;


class Testq3 implements Runnable{

  // private:
  // Caminho de acesso à base de dados.
  private static final String LIGACAO = "jdbc:postgresql://localhost:5432/tbd";
  private static final String UTILIZADOR = "postgres";
  private static final String SENHA = "4499947";  


  // AUXILIAR LINES OF CODE TO INSERT TEST TUPLES INTO DB 
 	// 
  // INSERT INTO inventory VALUES (10001, 5000, 4);
  // INSERT INTO inventory VALUES (10001, 5000, 4);
  // INSERT INTO customers VALUES (20001,'VKUUXF','ITHOMQJNYX','4608499546 Dell Way',null,'QSDPAGD','SD',24101,'US',1,'ITHOMQJNYX@dell.com','4608499546',1,'1979279217775911','2012/03','user20001','password',55,100000,'M');

  //usefull string
	private static final String order1 = "SELECT auto_reorder('2018-10-17', '2018-10-17');";
	private static final String order2 = "SELECT create_order (20001,'{10001}','{5000}',1);";

	private String string_inside="";

  private int numThread = 0;


  // Ligação à base de dados.
  private Connection objLigacao = null;
  private CallableStatement objComando = null;


	//public:
	//construtor 
	public Testq3(String a, int numThread) {
		this.string_inside = a;
    this.numThread = numThread;
    System.out.println("Nova instancia da classe Testq3");
  }



  public void run() {
  	System.out.println("Starting a run() method");
    try {
      // Ligação à base de dados.
      objLigacao = DriverManager.getConnection(LIGACAO, UTILIZADOR, SENHA);

      // Tornar explícito o controlo transaccional
      objLigacao.setAutoCommit(false);

      System.out.println("A preparar o comando");
      System.out.println(string_inside);

 		objComando = objLigacao.prepareCall(string_inside);
      objComando.execute();
      objComando.close();

      objLigacao.commit();

    } // try
    catch (SQLException objExcepcao) {
			System.out.println(objExcepcao.getMessage());

          // If something failed rollback the operations
          //objComando.close();
          //objLigacao.rollback();

          System.out.println("fail");
    }
    System.out.println("end of run() method");
  }// run()




	public static void main(String args[]) throws SQLException {
 		System.out.println("Entering into main....");

		// Carregamento do driver PostgreSQL.
		try {
			Class.forName("org.postgresql.Driver");
		} catch (ClassNotFoundException e) {
		e.printStackTrace();
		}

    // Duas instâncias, cada uma com o seu espaço em memória.
    // (?) Reservamos o espaço em memória (?)
    Testq3 objInstancia1 = new Testq3("SELECT auto_reorder_with_locks('2018-10-17', '2018-10-17');",1);
    Testq3 objInstancia2 = new Testq3("SELECT create_order (20001,'{10001}','{5000}',1);",2);

    // Associação de threads às duas instâncias de AcessoConcorrente.
    Thread objThread1 = new Thread(objInstancia1); // ?
    Thread objThread2 = new Thread(objInstancia2);

    // Início de actividade de ambas as threads - ver método run().
    System.out.println("objThread1.start();");
    objThread1.start();

    System.out.println("objThread2.start();");
    objThread2.start();

    // Aguarda fim de actividade de ambas as threads.
    System.out.println("Aguardando fim de actividade de ambas as threads");

    
    try {
      objThread1.join();
    	objThread2.join();
    } catch (InterruptedException objExcepcao) { }
	

    System.out.println("Testing it");
  } // end of main
}//Class Testq3
