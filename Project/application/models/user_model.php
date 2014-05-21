<?php
class user_model extends CI_Model {

	public $logged_in = FALSE;
	/*private $user;
	private $pass;
	private $email;
	private $account;*/
	
	//$this->session->sess_destroy();=logout
	//http://ellislab.com/codeigniter/user-guide/libraries/sessions.html

	public function __construct()
	{
		$this->load->database();
		//$account=[$user, $pass, $email];
		
		
	}
	
	public function index()
	{
		echo 'index';
	}
	
	public function create_account()
	{
		$this->load->helper('url');
		$this->load->helper('security');

		$user = url_title($this->input->post('user'), '_', TRUE);

		$data = array(
			"username" => $user,
			"password_encrypted" => do_hash($this->input->post('pass')),
			"email" =>$this->input->post('email'),
			"logged_in"=>TRUE,
			"highscore"=>0
			);

		$this->user_model->setAccount($data);
		return $this->db->insert("accounts", $data);
	}

	public function setAccount($data)
	{
        $this->session->set_userdata($data);
        $logged_in = TRUE;
	}
	
	public function logOut()
	{
		$logged_in = FALSE;
		$username=$this->session->userdata('username');
		$this->db->query("UPDATE accounts SET logged_in = ? WHERE username = ?", array("0",$username));
		$this->session->sess_destroy();
	}

	public function isAccount($username, $password)
	{
		$this->load->helper('security');
		
		$encrypt = do_hash($password);
		$query = $this->db->select('password_encrypted')->from('accounts')->where('username',$username)->get();
		if ($query->num_rows() == 0)
		{
			return false;
		}
		else
		{
			$row = $query->row();
			$pass=$row->password_encrypted; 
			error_log("
			New Line with user $username: $encrypt|$pass", 3, "error.txt");
			if($encrypt == $row->password_encrypted) {
				return true;
			}
			return false;
		}
	}
	
	public function updateHighscore($highscore, $username){
		$this->db->query("UPDATE accounts SET highscore = ? WHERE username = ?", array($highscore, $username));
	}
	
	//getter methods
	
	public function get_email($user)
	{
		if ($user === FALSE)
		{
			$query = $this->db->get('accounts');
			return $query->result_array();
		}

		$query = $this->db->get_where('accounts', array('username' => $user));
		return $query->row()->email;
	}
	
	public function get_highScore($user)
	{
		if ($user === FALSE)
		{
			$query = $this->db->get('accounts');
			return $query->result_array();
		}

		$query = $this->db->get_where('accounts', array('username' => $user));
		return $query->row()->highscore;
	}
	
	public function isLoggedIn(){
		return $logged_in;
	}
	
	public function highestUser()
	{
		$query= $this->db->query('SELECT username FROM accounts ORDER BY highscore DESC LIMIT 1');
		$row = $query->row();
		return $row->username; 
	}
	
	public function highestScore()
	{
		$query= $this->db->query('SELECT highscore FROM accounts ORDER BY highscore DESC LIMIT 1');
		$row = $query->row();
		return $row->highscore;
	}
	
	public function get_Users()
	{
		$query = $this->db->query("SELECT * FROM accounts ORDER BY highscore ASC");
		return $query->result_array();
	}
	
}
